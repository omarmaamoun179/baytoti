import 'package:baytoti/core/app/session_notifier.dart';
import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/core/network/api_endpoints.dart';
import 'package:baytoti/core/network/token_store.dart';
import 'package:baytoti/features/auth/data/datasources/auth_data_source.dart';
import 'package:baytoti/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:baytoti/features/auth/data/models/auth_models.dart';
import 'package:baytoti/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:baytoti/features/auth/domain/entities/otp_challenge.dart';
import 'package:baytoti/features/auth/domain/usecases/auth_usecases.dart';
import 'package:baytoti/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:baytoti/features/auth/presentation/cubit/auth_state.dart';
import 'package:baytoti/features/auth/presentation/cubit/otp_request_cubit.dart';
import 'package:baytoti/features/auth/presentation/cubit/otp_verify_cubit.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_network.dart';

class _MemoryLocal implements AuthLocalDataSource {
  TokenPair? tokens;
  CustomerModel? customer;

  @override
  Future<Either<Failure, Unit>> saveSession(
    TokenPair tokens,
    CustomerModel customer,
  ) async {
    this.tokens = tokens;
    this.customer = customer;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, CustomerModel?>> readSession() async =>
      Right(tokens == null ? null : customer);

  @override
  Future<Either<Failure, Unit>> clearSession() async {
    tokens = null;
    customer = null;
    return const Right(unit);
  }
}

const _phone = '+96555512345';

const _register = RegisterParams(
  name: 'مريم الكندري',
  email: 'mariam@example.com',
  phone: _phone,
  password: 'password123',
  passwordConfirmation: 'password123',
);

void main() {
  late FakeNetwork network;
  late _MemoryLocal local;
  late AuthRepositoryImpl repository;

  setUp(() {
    network = FakeNetwork();
    local = _MemoryLocal();
    repository = AuthRepositoryImpl(AuthRemoteDataSource(network), local);
    network
      ..replySample('POST', ApiEndPoint.register, 'auth/register.cloak_shape.json')
      ..replySample(
        'POST',
        ApiEndPoint.requestOtp,
        'auth/request_otp.cloak_shape.json',
      )
      ..replySample(
        'POST',
        ApiEndPoint.verifyOtp,
        'auth/verify_otp.cloak_shape.json',
      )
      ..replySample('POST', ApiEndPoint.logout, 'auth/logout.cloak_shape.json');
  });

  Future<OtpChallenge> registerAndRequestOtp() async {
    (await repository.register(_register))
        .getOrElse(() => throw StateError('registration refused'));
    return (await repository.requestOtp(const RequestOtpParams(phone: _phone)))
        .getOrElse(() => throw StateError('no challenge'));
  }

  group('registration', () {
    test('sends the account and waits for the phone to be verified', () async {
      final result = await repository.register(_register);

      expect(network.last('POST').data, {
        'name': 'مريم الكندري',
        'email': 'mariam@example.com',
        'phone': '96555512345',
        'password': 'password123',
        'password_confirmation': 'password123',
      });
      final outcome = result.getOrElse(() => throw StateError('refused'));
      expect(outcome, const AwaitingVerification('96555512345'));
      expect(local.tokens, isNull);
    });

    test('the live validation answer becomes field errors', () async {
      network.replySample(
        'POST',
        ApiEndPoint.register,
        'betouti/auth_register_422.json',
        status: 422,
      );

      final result = await repository.register(_register);

      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure! as ValidationFailure).fieldErrors.keys,
        containsAll(['name', 'email', 'password']),
      );
    });
  });

  group('the code', () {
    test('goes to the number as digits and reads the stubbed code', () async {
      final otp = await registerAndRequestOtp();

      expect(network.last('POST').data, {'phone': '96555512345'});
      expect(otp.demoCode, '833801');
      expect(otp.digits, 6);
    });

    test('a verified code stores the new token and a verified customer',
        () async {
      final otp = await registerAndRequestOtp();

      final result = await repository.verifyOtp(
        VerifyOtpParams(phone: otp.phone, otp: '833801'),
      );

      expect(network.last('POST').data, {
        'phone': '96555512345',
        'otp': '833801',
      });
      final session = result.getOrElse(() => throw StateError('refused'));
      expect(session.customer.fullName, 'مريم الكندري');
      expect(session.customer.verified, isTrue);
      expect(local.tokens?.accessToken, '14|fresh-token');
    });

    test('a wrong code is refused on the otp field and stores nothing',
        () async {
      network.replySample(
        'POST',
        ApiEndPoint.verifyOtp,
        'auth/verify_otp_invalid.cloak_shape.json',
        status: 422,
      );
      final otp = await registerAndRequestOtp();

      final result = await repository.verifyOtp(
        VerifyOtpParams(phone: otp.phone, otp: '000000'),
      );

      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isA<ValidationFailure>());
      expect((failure! as ValidationFailure)['otp'], isNotEmpty);
      expect(local.tokens, isNull);
    });

    test('a bare confirmation with no token after register is a failure',
        () async {
      network.replySample(
        'POST',
        ApiEndPoint.verifyOtp,
        'auth/verify_otp_bare.cloak_shape.json',
      );
      final otp = await registerAndRequestOtp();

      final result = await repository.verifyOtp(
        VerifyOtpParams(phone: otp.phone, otp: '833801'),
      );

      expect(result.isLeft(), isTrue);
      expect(local.tokens, isNull);
    });
  });

  group('login', () {
    test('a verified account signs in with no code', () async {
      network.replySample(
        'POST',
        ApiEndPoint.login,
        'auth/login_verified.cloak_shape.json',
      );

      final result = await repository.login(
        const LoginParams(phone: _phone, password: 'password123'),
      );

      expect(network.last('POST').data, {
        'login': '96555512345',
        'password': 'password123',
      });
      expect(result.getOrElse(() => throw StateError('refused')), isA<SignedIn>());
      expect(local.tokens?.accessToken, '12|verified-token');
    });

    test('an unverified account is sent to verify, keeping its token',
        () async {
      network
        ..replySample(
          'POST',
          ApiEndPoint.login,
          'auth/login_unverified.cloak_shape.json',
        )
        ..replySample(
          'POST',
          ApiEndPoint.verifyOtp,
          'auth/verify_otp_bare.cloak_shape.json',
        );

      final login = await repository.login(
        const LoginParams(phone: _phone, password: 'password123'),
      );
      expect(
        login.getOrElse(() => throw StateError('refused')),
        isA<AwaitingVerification>(),
      );
      expect(local.tokens, isNull);

      final verified = await repository.verifyOtp(
        const VerifyOtpParams(phone: _phone, otp: '833801'),
      );

      expect(verified.isRight(), isTrue);
      expect(local.tokens?.accessToken, '13|pending-token');
      expect(local.customer?.verified, isTrue);
    });

    test('wrong credentials are refused', () async {
      network.replySample(
        'POST',
        ApiEndPoint.login,
        'auth/login_invalid.cloak_shape.json',
        status: 422,
      );

      final result = await repository.login(
        const LoginParams(phone: _phone, password: 'nope'),
      );

      expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
      expect(local.tokens, isNull);
    });

    test('a server crash is a generic failure, never the raw message',
        () async {
      network.replySample(
        'POST',
        ApiEndPoint.login,
        'betouti/products_guest_500.json',
        status: 500,
      );

      final result = await repository.login(
        const LoginParams(phone: _phone, password: 'password123'),
      );

      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isA<ServerFailure>());
      expect(failure?.message, isNot(contains('LocationContextService')));
    });
  });

  group('OtpRequestCubit', () {
    late OtpRequestCubit cubit;

    setUp(() {
      cubit = OtpRequestCubit(
        RegisterUseCase(repository),
        LoginUseCase(repository),
        RequestOtpUseCase(repository),
        mode: AuthMode.signup,
      );
    });

    tearDown(() => cubit.close());

    test('signing up registers, then sends the code', () async {
      await cubit.submit(
        phone: _phone,
        password: 'password123',
        fullName: 'مريم الكندري',
        email: 'mariam@example.com',
        passwordConfirmation: 'password123',
      );

      expect(cubit.state.status, OtpRequestStatus.sent);
      expect(cubit.state.challenge?.demoCode, '833801');
      expect(
        network.calls.map((c) => c.url),
        [ApiEndPoint.register, ApiEndPoint.requestOtp],
      );
    });

    test('logging in to a verified account skips the code', () async {
      network.replySample(
        'POST',
        ApiEndPoint.login,
        'auth/login_verified.cloak_shape.json',
      );
      cubit.setMode(AuthMode.login);

      await cubit.submit(phone: _phone, password: 'password123');

      expect(cubit.state.status, OtpRequestStatus.signedIn);
      expect(cubit.state.customer?.id, '41');
      expect(network.calls.map((c) => c.url), [ApiEndPoint.login]);
    });
  });

  group('AuthCubit', () {
    late SessionNotifier session;
    late AuthCubit cubit;

    setUp(() {
      session = SessionNotifier();
      cubit = AuthCubit(
        RestoreSessionUseCase(repository),
        SignOutUseCase(repository),
        ClearSessionUseCase(repository),
        session,
      );
    });

    tearDown(() => cubit.close());

    test('no stored session resolves as a guest', () async {
      await cubit.restoreSession();

      expect(cubit.state.status, AuthStatus.guest);
      expect(session.isResolved, isTrue);
      expect(session.isAuthenticated, isFalse);
    });

    test('a stored session is restored and signs the notifier in', () async {
      final otp = await registerAndRequestOtp();
      await repository.verifyOtp(VerifyOtpParams(phone: otp.phone, otp: '1'));

      await cubit.restoreSession();

      expect(cubit.state.isSignedIn, isTrue);
      expect(session.isAuthenticated, isTrue);
    });

    test('signing out calls the server and forgets the session', () async {
      final otp = await registerAndRequestOtp();
      await repository.verifyOtp(VerifyOtpParams(phone: otp.phone, otp: '1'));
      await cubit.restoreSession();

      await cubit.signOut();

      expect(network.last('POST').url, ApiEndPoint.logout);
      expect(cubit.state.status, AuthStatus.guest);
      expect(session.isAuthenticated, isFalse);
      expect(local.tokens, isNull);
    });
  });

  group('OtpVerifyCubit', () {
    late OtpVerifyCubit cubit;

    tearDown(() => cubit.close());

    test('takes six digits, no more, and lets one be removed', () async {
      cubit = OtpVerifyCubit(
        VerifyOtpUseCase(repository),
        ResendOtpUseCase(repository),
        await registerAndRequestOtp(),
      );

      for (final digit in '1234567'.split('')) {
        cubit.addDigit(digit);
      }
      expect(cubit.state.code, '123456');
      expect(cubit.state.isComplete, isTrue);

      cubit.removeDigit();
      expect(cubit.state.code, '12345');
    });

    test('a refused code clears the boxes and counts the rejection', () async {
      network.replySample(
        'POST',
        ApiEndPoint.verifyOtp,
        'auth/verify_otp_invalid.cloak_shape.json',
        status: 422,
      );
      cubit = OtpVerifyCubit(
        VerifyOtpUseCase(repository),
        ResendOtpUseCase(repository),
        await registerAndRequestOtp(),
      );
      for (final digit in '000000'.split('')) {
        cubit.addDigit(digit);
      }

      await cubit.verify();

      expect(cubit.state.status, OtpVerifyStatus.failed);
      expect(cubit.state.code, isEmpty);
      expect(cubit.state.rejections, 1);
      expect(cubit.state.errorMessage, isNotNull);
    });

    test('an accepted code hands over the session', () async {
      cubit = OtpVerifyCubit(
        VerifyOtpUseCase(repository),
        ResendOtpUseCase(repository),
        await registerAndRequestOtp(),
      );
      for (final digit in '833801'.split('')) {
        cubit.addDigit(digit);
      }

      await cubit.verify();

      expect(cubit.state.status, OtpVerifyStatus.verified);
      expect(cubit.state.session?.customer.id, '41');
    });
  });
}
