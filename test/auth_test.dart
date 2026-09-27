import 'package:baytoti/core/app/session_notifier.dart';
import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/core/network/token_store.dart';
import 'package:baytoti/features/auth/data/datasources/auth_data_source.dart';
import 'package:baytoti/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:baytoti/features/auth/data/models/auth_models.dart';
import 'package:baytoti/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:baytoti/features/auth/domain/entities/otp_challenge.dart';
import 'package:baytoti/features/auth/domain/usecases/auth_usecases.dart';
import 'package:baytoti/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:baytoti/features/auth/presentation/cubit/auth_state.dart';
import 'package:baytoti/features/auth/presentation/cubit/otp_verify_cubit.dart';
import 'package:baytoti/features/catalog/data/fixtures/fixture_backend.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

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

void main() {
  late FixtureBackend backend;
  late _MemoryLocal local;
  late AuthRepositoryImpl repository;

  setUp(() {
    backend = FixtureBackend();
    local = _MemoryLocal();
    repository = AuthRepositoryImpl(
      AuthMockDataSource(backend, () async => 'ar'),
      local,
    );
  });

  Future<OtpChallenge> challenge({AuthMode mode = AuthMode.login}) async =>
      (await repository.requestOtp(RequestOtpParams(
        phone: '+96551502244',
        mode: mode,
        fullName: mode == AuthMode.signup ? 'مريم الكندري' : null,
      )))
          .getOrElse(() => throw StateError('no challenge'));

  group('the OTP contract', () {
    test('a request answers the request id, timers and digit count', () async {
      final otp = await challenge();

      expect(otp.requestId, isNotEmpty);
      expect(otp.digits, 4);
      expect(otp.resendAfter, 30);
      expect(otp.phone, '+96551502244');
    });

    test('a verified code stores the tokens and the customer', () async {
      final otp = await challenge(mode: AuthMode.signup);

      final result = await repository.verifyOtp(
        VerifyOtpParams(requestId: otp.requestId, code: '4821'),
      );

      final session = result.getOrElse(() => throw StateError('refused'));
      expect(session.isNewUser, isTrue);
      expect(session.customer.fullName, 'مريم الكندري');
      expect(local.tokens?.accessToken, isNotEmpty);
      expect(local.tokens?.refreshToken, isNotNull);
    });

    test('a wrong code is refused with its contract code', () async {
      final otp = await challenge();

      final result = await repository.verifyOtp(
        VerifyOtpParams(requestId: otp.requestId, code: '0000'),
      );

      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isA<ServerFailure>());
      expect(failure?.code, 'otp_invalid');
      expect(local.tokens, isNull);
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
      final otp = await challenge();
      await repository.verifyOtp(
        VerifyOtpParams(requestId: otp.requestId, code: '1234'),
      );

      await cubit.restoreSession();

      expect(cubit.state.isSignedIn, isTrue);
      expect(session.isAuthenticated, isTrue);
    });

    test('signing out forgets the session everywhere', () async {
      final otp = await challenge();
      await repository.verifyOtp(
        VerifyOtpParams(requestId: otp.requestId, code: '1234'),
      );
      await cubit.restoreSession();

      await cubit.signOut();

      expect(cubit.state.status, AuthStatus.guest);
      expect(session.isAuthenticated, isFalse);
      expect(local.tokens, isNull);
    });
  });

  group('OtpVerifyCubit', () {
    late OtpVerifyCubit cubit;

    tearDown(() => cubit.close());

    test('takes four digits, no more, and lets one be removed', () async {
      cubit = OtpVerifyCubit(
        VerifyOtpUseCase(repository),
        ResendOtpUseCase(repository),
        await challenge(),
      );

      for (final digit in ['1', '2', '3', '4', '5']) {
        cubit.addDigit(digit);
      }
      expect(cubit.state.code, '1234');
      expect(cubit.state.isComplete, isTrue);

      cubit.removeDigit();
      expect(cubit.state.code, '123');
    });

    test('a refused code clears the boxes and counts the rejection', () async {
      cubit = OtpVerifyCubit(
        VerifyOtpUseCase(repository),
        ResendOtpUseCase(repository),
        await challenge(),
      );
      for (final digit in ['0', '0', '0', '0']) {
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
        await challenge(),
      );
      for (final digit in ['4', '8', '2', '1']) {
        cubit.addDigit(digit);
      }

      await cubit.verify();

      expect(cubit.state.status, OtpVerifyStatus.verified);
      expect(cubit.state.session?.customer.id, 'usr_18');
    });
  });
}
