import 'dart:io';

import 'package:baytoti/core/app/session_notifier.dart';
import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/core/network/api_endpoints.dart';
import 'package:baytoti/core/network/token_store.dart';
import 'package:baytoti/core/theme/app_theme.dart';
import 'package:baytoti/core/utils/screen_util_scope.dart';
import 'package:baytoti/core/widgets/app_text_field.dart';
import 'package:baytoti/core/widgets/avatar_photo.dart';
import 'package:baytoti/core/widgets/avatar_picker.dart';
import 'package:baytoti/core/widgets/phone_text_form_field.dart';
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
import 'package:baytoti/features/auth/presentation/widgets/auth_form.dart';
import 'package:baytoti/features/auth/presentation/widgets/terms_checkbox.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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

Finder _input(String labelKey) => find.descendant(
      of: find.byWidgetPredicate(
        (w) => w is LabeledField && w.label == labelKey.tr(),
      ),
      matching: find.byType(TextField),
    );

void main() {
  late FakeNetwork network;
  late _MemoryLocal local;
  late AuthRepositoryImpl repository;
  late Directory temp;

  setUp(() => temp = Directory.systemTemp.createTempSync('avatar'));

  tearDown(() => temp.deleteSync(recursive: true));

  String photo() => (File('${temp.path}/me.png')
        ..writeAsBytesSync(const [0x89, 0x50, 0x4E, 0x47]))
      .path;

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

    test('a photo turns the same account into a multipart POST', () async {
      final path = photo();

      await repository.register(RegisterParams(
        name: _register.name,
        email: _register.email,
        phone: _register.phone,
        password: _register.password,
        passwordConfirmation: _register.passwordConfirmation,
        avatarPath: path,
      ));

      final form = network.last('POST').data! as FormData;
      expect(network.last('POST').url, ApiEndPoint.register);
      expect(Map.fromEntries(form.fields), {
        'name': 'مريم الكندري',
        'email': 'mariam@example.com',
        'phone': '96555512345',
        'password': 'password123',
        'password_confirmation': 'password123',
      });
      expect(form.files.single.key, 'avatar');
      expect(form.files.single.value.filename, 'me.png');
      expect('${form.files.single.value.contentType}', 'image/png');
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

    test('the photo chosen on sign-up goes out with the account', () async {
      await cubit.submit(
        phone: _phone,
        password: 'password123',
        fullName: 'مريم الكندري',
        email: 'mariam@example.com',
        passwordConfirmation: 'password123',
        avatarPath: photo(),
      );

      final register =
          network.calls.firstWhere((c) => c.url == ApiEndPoint.register);
      expect((register.data! as FormData).files.single.key, 'avatar');
      expect(cubit.state.status, OtpRequestStatus.sent);
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

  group('the sign-up form', () {
    late List<String?> submitted;
    late int picks;

    setUp(() {
      submitted = [];
      picks = 0;
    });

    Future<void> pumpForm(
      WidgetTester tester, {
      AuthMode mode = AuthMode.signup,
      String? picked,
    }) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ScreenUtilScope(
        child: Builder(
          builder: (_) => MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: SingleChildScrollView(
                child: AuthForm(
                  mode: mode,
                  isSubmitting: false,
                  onInvalid: (_) {},
                  onPickPhoto: () async {
                    picks++;
                    return picked;
                  },
                  onSubmit: ({
                    required phone,
                    required password,
                    fullName,
                    email,
                    passwordConfirmation,
                    avatarPath,
                  }) =>
                      submitted.add(avatarPath),
                ),
              ),
            ),
          ),
        ),
      ));
    }

    Future<void> fillAndSubmit(WidgetTester tester) async {
      await tester.enterText(_input('auth_full_name'), 'مريم الكندري');
      await tester.enterText(_input('auth_email'), 'mariam@example.com');
      await tester.enterText(
        find.descendant(
          of: find.byType(PhoneTextFormField),
          matching: find.byType(TextField),
        ),
        '55512345',
      );
      await tester.enterText(_input('auth_password'), 'password123');
      await tester.enterText(
        _input('auth_password_confirmation'),
        'password123',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TermsCheckbox));
      await tester.tap(find.text('auth_cta_signup'));
      await tester.pumpAndSettle();
    }

    testWidgets('the photo is optional: signing up without one sends none',
        (tester) async {
      await pumpForm(tester);

      expect(find.byType(AvatarPicker), findsOne);
      expect(find.text('auth_add_photo'), findsOne);

      await fillAndSubmit(tester);

      expect(submitted, [null]);
    });

    testWidgets('a picked photo shows and goes out with the account',
        (tester) async {
      await pumpForm(tester, picked: '/device/me.png');

      await tester.tap(find.text('auth_add_photo'));
      await tester.pump();

      expect(
        tester.widget<AvatarPhoto>(find.byType(AvatarPhoto)).filePath,
        '/device/me.png',
      );
      expect(find.text('profile_change_photo'), findsOne);

      await fillAndSubmit(tester);

      expect(submitted, ['/device/me.png']);
    });

    testWidgets('choosing nothing leaves the form without a photo',
        (tester) async {
      await pumpForm(tester);

      await tester.tap(find.text('auth_add_photo'));
      await tester.pump();

      expect(picks, 1);
      expect(find.text('auth_add_photo'), findsOne);
    });

    testWidgets('logging in asks for no photo', (tester) async {
      await pumpForm(tester, mode: AuthMode.login);

      expect(find.byType(AvatarPicker), findsNothing);
    });
  });
}
