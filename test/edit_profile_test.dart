import 'dart:io';

import 'package:baytoti/core/app/session_notifier.dart';
import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/core/exceptions/app_exceptions.dart';
import 'package:baytoti/core/network/api_endpoints.dart';
import 'package:baytoti/core/network/token_store.dart';
import 'package:baytoti/core/theme/app_theme.dart';
import 'package:baytoti/core/utils/screen_util_scope.dart';
import 'package:baytoti/core/widgets/app_icon.dart';
import 'package:baytoti/core/widgets/app_text_field.dart';
import 'package:baytoti/core/widgets/avatar_photo.dart';
import 'package:baytoti/core/widgets/network_photo.dart';
import 'package:baytoti/features/auth/data/datasources/auth_data_source.dart';
import 'package:baytoti/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:baytoti/features/auth/data/models/auth_models.dart';
import 'package:baytoti/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:baytoti/features/auth/domain/entities/customer.dart';
import 'package:baytoti/features/auth/domain/usecases/auth_usecases.dart';
import 'package:baytoti/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:baytoti/features/auth/presentation/cubit/auth_state.dart';
import 'package:baytoti/features/profile/data/datasources/profile_data_source.dart';
import 'package:baytoti/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:baytoti/features/profile/domain/entities/profile_update.dart';
import 'package:baytoti/features/profile/domain/usecases/profile_usecases.dart';
import 'package:baytoti/features/profile/presentation/cubit/edit_profile_cubit.dart';
import 'package:baytoti/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:baytoti/features/profile/presentation/widgets/edit_profile_form.dart';
import 'package:baytoti/features/profile/presentation/widgets/profile_identity.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_network.dart';

const String _me = 'profile/me.cloak_shape.json';

const Customer _noura = Customer(
  id: '18',
  fullName: 'Noura Al-Anzi',
  phone: '96551502244',
  email: 'noura@example.com',
);

const ProfileUpdate _update = ProfileUpdate(
  name: ' Noura Alanzi ',
  email: ' noura@betouti.com ',
);

Map<String, dynamic> _envelope(Object? data) => {
      'success': true,
      'message': 'Profile updated successfully.',
      'data': data,
      'errors': null,
    };

Map<String, dynamic> _account({Object? avatar}) => {
      'id': 18,
      'name': 'Noura Alanzi',
      'email': 'noura@betouti.com',
      'phone': '96551502244',
      'avatar': avatar,
      'status': 1,
    };

Map<String, dynamic> _refused(Map<String, List<String>> errors) => {
      'success': false,
      'message': errors.values.first.first,
      'data': null,
      'errors': errors,
    };

class _OfflineNetwork extends FakeNetwork {
  @override
  Future<Response> patch(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  }) async =>
      throw const ConnectionException();
}

class _NoSession implements AuthLocalDataSource {
  @override
  Future<Either<Failure, Unit>> saveSession(
    TokenPair tokens,
    CustomerModel customer,
  ) async =>
      const Right(unit);

  @override
  Future<Either<Failure, CustomerModel?>> readSession() async =>
      const Right(null);

  @override
  Future<Either<Failure, Unit>> clearSession() async => const Right(unit);
}

T _right<T>(Either<Failure, T> result) =>
    result.fold((failure) => throw StateError('$failure'), (value) => value);

Failure _left<T>(Either<Failure, T> result) =>
    result.fold((failure) => failure, (value) => throw StateError('$value'));

Widget _app(Widget child) => ScreenUtilScope(
      child: Builder(
        builder: (_) => MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: child),
        ),
      ),
    );

void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Finder _input(String labelKey) => find.descendant(
      of: find.byWidgetPredicate(
        (w) => w is LabeledField && w.label == labelKey.tr(),
      ),
      matching: find.byType(TextField),
    );

void main() {
  late FakeNetwork network;
  late ProfileRepositoryImpl repository;

  setUp(() {
    network = FakeNetwork();
    repository = ProfileRepositoryImpl(ProfileRemoteDataSource(network));
  });

  group('PATCH auth/profile', () {
    late Directory temp;

    setUp(() => temp = Directory.systemTemp.createTempSync('avatar'));

    tearDown(() => temp.deleteSync(recursive: true));

    String photo() => (File('${temp.path}/avatar.jpg')
          ..writeAsBytesSync(const [0xFF, 0xD8, 0xFF]))
        .path;

    test('name and email go out trimmed as JSON, and never the phone',
        () async {
      network.reply(
        'PATCH',
        ApiEndPoint.updateProfile,
        body: _envelope(_account()),
      );

      final customer = _right(await repository.updateProfile(_update));

      expect(network.calls, hasLength(1));
      expect(network.last('PATCH').url, ApiEndPoint.updateProfile);
      expect(network.last('PATCH').data, {
        'name': 'Noura Alanzi',
        'email': 'noura@betouti.com',
      });
      expect(customer.fullName, 'Noura Alanzi');
      expect(customer.email, 'noura@betouti.com');
    });

    test('a cleared email goes out empty, so the server drops it', () async {
      network.reply(
        'PATCH',
        ApiEndPoint.updateProfile,
        body: _envelope(_account()),
      );

      await repository.updateProfile(
        const ProfileUpdate(name: 'Noura', email: ''),
      );

      expect(network.last('PATCH').data, {'name': 'Noura', 'email': ''});
    });

    test('a photo goes out as a multipart POST that Laravel reads as a PATCH',
        () async {
      network.reply(
        'POST',
        ApiEndPoint.updateProfile,
        body: _envelope(_account(avatar: 'https://example.com/noura.jpg')),
      );

      final customer = _right(await repository.updateProfile(ProfileUpdate(
        name: _update.name,
        email: _update.email,
        avatarPath: photo(),
      )));

      final form = network.last('POST').data! as FormData;
      expect(Map.fromEntries(form.fields), {
        'name': 'Noura Alanzi',
        'email': 'noura@betouti.com',
        '_method': 'PATCH',
      });
      expect(form.files.single.key, 'avatar');
      expect(form.files.single.value.filename, 'avatar.jpg');
      expect('${form.files.single.value.contentType}', 'image/jpeg');
      expect(network.calls.where((c) => c.method == 'PATCH'), isEmpty);
      expect(customer.avatarUrl, 'https://example.com/noura.jpg');
    });

    test('an answer that carries no account is followed by auth/me',
        () async {
      network
        ..reply('PATCH', ApiEndPoint.updateProfile, body: _envelope(null))
        ..replySample('GET', ApiEndPoint.me, _me);

      final customer = _right(await repository.updateProfile(_update));

      expect(network.calls.map((c) => c.method), ['PATCH', 'GET']);
      expect(customer.fullName, 'Noura Al-Anzi');
    });

    test('an account wrapped under user is read without a second request',
        () async {
      network.reply(
        'PATCH',
        ApiEndPoint.updateProfile,
        body: _envelope({'user': _account()}),
      );

      final customer = _right(await repository.updateProfile(_update));

      expect(customer.fullName, 'Noura Alanzi');
      expect(network.calls, hasLength(1));
    });

    test('a 422 hands each field its error', () async {
      network.reply(
        'PATCH',
        ApiEndPoint.updateProfile,
        status: 422,
        body: _refused({
          'email': ['The email has already been taken.'],
        }),
      );

      final failure = _left(await repository.updateProfile(_update));

      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).fieldErrors, {
        'email': 'The email has already been taken.',
      });
    });

    test('a server crash never shows its exception text', () async {
      network.replySample(
        'PATCH',
        ApiEndPoint.updateProfile,
        'betouti/products_guest_500.json',
        status: 500,
      );

      final failure = _left(await repository.updateProfile(_update));

      expect(failure, isA<ServerFailure>());
      expect(failure.message, 'server_error');
    });

    test('offline is a network failure', () async {
      final offline =
          ProfileRepositoryImpl(ProfileRemoteDataSource(_OfflineNetwork()));

      expect(
        _left(await offline.updateProfile(_update)),
        isA<NetworkFailure>(),
      );
    });
  });

  group('EditProfileCubit', () {
    late EditProfileCubit cubit;

    setUp(() {
      network.reply(
        'PATCH',
        ApiEndPoint.updateProfile,
        body: _envelope(_account()),
      );
      cubit = EditProfileCubit(UpdateProfileUseCase(repository));
    });

    tearDown(() => cubit.close());

    test('a save goes through saving to saved with the account', () async {
      final states = <EditProfileStatus>[];
      final sub = cubit.stream.listen((s) => states.add(s.status));

      await cubit.save(_update);
      await Future<void>.delayed(Duration.zero);

      expect(states, [EditProfileStatus.saving, EditProfileStatus.saved]);
      expect(cubit.state.saved?.fullName, 'Noura Alanzi');
      await sub.cancel();
    });

    test('a second tap while saving, or after, sends nothing more', () async {
      await Future.wait([cubit.save(_update), cubit.save(_update)]);
      await cubit.save(_update);

      expect(network.calls, hasLength(1));
    });

    test('a 422 hands each field its error, and typing clears one', () async {
      network.reply(
        'PATCH',
        ApiEndPoint.updateProfile,
        status: 422,
        body: _refused({
          'name': ['The name field is required.'],
          'email': ['The email has already been taken.'],
        }),
      );

      await cubit.save(_update);

      expect(cubit.state.status, EditProfileStatus.editing);
      expect(cubit.state.fieldErrors.keys, {'name', 'email'});
      expect(cubit.state.errorMessage, isNotNull);

      cubit.clearFieldError('email');

      expect(cubit.state.fieldErrors.keys, {'name'});
    });

    test('offline can be tried again', () async {
      final offline = EditProfileCubit(UpdateProfileUseCase(
        ProfileRepositoryImpl(ProfileRemoteDataSource(_OfflineNetwork())),
      ));
      addTearDown(offline.close);

      await offline.save(_update);

      expect(offline.state.errorMessage, 'connection_failed');
      expect(offline.state.isSaving, isFalse);
    });
  });

  group('the form', () {
    late List<ProfileUpdate> submitted;
    late List<String> changed;
    late int picks;

    setUp(() {
      submitted = [];
      changed = [];
      picks = 0;
    });

    EditProfileForm form({
      Map<String, String> fieldErrors = const {},
      bool isSaving = false,
      String? picked,
    }) =>
        EditProfileForm(
          initial: _noura,
          isSaving: isSaving,
          fieldErrors: fieldErrors,
          onFieldChanged: changed.add,
          onPickPhoto: () async {
            picks++;
            return picked;
          },
          onSubmit: submitted.add,
        );

    Future<void> save(WidgetTester tester) async {
      await tester.tap(find.text('profile_save'));
      await tester.pumpAndSettle();
    }

    testWidgets('it opens with the account filled in', (tester) async {
      _tallView(tester);
      await tester.pumpWidget(_app(form()));

      expect(tester.takeException(), isNull);
      expect(find.text('Noura Al-Anzi'), findsOne);
      expect(find.text('noura@example.com'), findsOne);
      expect(find.byType(AvatarPhoto), findsOne);
    });

    testWidgets('a short name and a bad email are refused locally',
        (tester) async {
      _tallView(tester);
      await tester.pumpWidget(_app(form()));

      await tester.enterText(_input('auth_full_name'), 'No');
      await tester.enterText(_input('auth_email'), 'noura@');
      await save(tester);

      expect(find.text('name_too_short'), findsOne);
      expect(find.text('invalid_email'), findsOne);
      expect(submitted, isEmpty);
    });

    testWidgets('a save hands back the fields trimmed, with no photo',
        (tester) async {
      _tallView(tester);
      await tester.pumpWidget(_app(form()));

      await tester.enterText(_input('auth_full_name'), '  Noura Alanzi ');
      await save(tester);

      expect(submitted, [
        const ProfileUpdate(name: 'Noura Alanzi', email: 'noura@example.com'),
      ]);
    });

    testWidgets('a blank email is allowed, so an account can drop it',
        (tester) async {
      _tallView(tester);
      await tester.pumpWidget(_app(form()));

      await tester.enterText(_input('auth_email'), '   ');
      await save(tester);

      expect(submitted.single.email, '');
    });

    testWidgets('a picked photo replaces the avatar and goes out with the save',
        (tester) async {
      _tallView(tester);
      await tester.pumpWidget(_app(form(picked: '/device/avatar.jpg')));

      await tester.tap(find.text('profile_change_photo'));
      await tester.pump();

      expect(
        tester.widget<AvatarPhoto>(find.byType(AvatarPhoto)).filePath,
        '/device/avatar.jpg',
      );
      expect(changed, contains('avatar'));

      await save(tester);

      expect(submitted.single.avatarPath, '/device/avatar.jpg');
    });

    testWidgets('choosing nothing keeps the current photo', (tester) async {
      _tallView(tester);
      await tester.pumpWidget(_app(form()));

      await tester.tap(find.text('profile_change_photo'));
      await tester.pump();

      expect(picks, 1);
      expect(
        tester.widget<AvatarPhoto>(find.byType(AvatarPhoto)).filePath,
        isNull,
      );
      expect(changed, isEmpty);

      await save(tester);

      expect(submitted.single.avatarPath, isNull);
    });

    testWidgets('while saving the photo cannot be changed', (tester) async {
      _tallView(tester);
      await tester.pumpWidget(_app(form(isSaving: true, picked: '/a.jpg')));

      await tester.tap(find.text('profile_change_photo'));
      await tester.pump();

      expect(picks, 0);
      expect(find.text('profile_save'), findsNothing);
    });

    testWidgets('server field errors show under their inputs until typed over',
        (tester) async {
      _tallView(tester);
      await tester.pumpWidget(_app(form(fieldErrors: const {
        'email': 'The email has already been taken.',
        'avatar': 'The avatar must be an image.',
      })));

      expect(find.text('The email has already been taken.'), findsOne);
      expect(find.text('The avatar must be an image.'), findsOne);

      await tester.enterText(_input('auth_email'), 'n@x.com');

      expect(changed, contains('email'));
    });
  });

  group('the page', () {
    late AuthCubit auth;

    setUp(() {
      final accounts = AuthRepositoryImpl(
        AuthRemoteDataSource(network),
        _NoSession(),
      );
      auth = AuthCubit(
        RestoreSessionUseCase(accounts),
        SignOutUseCase(accounts),
        ClearSessionUseCase(accounts),
        SessionNotifier(),
      )..completeSignIn(_noura);
      GetIt.instance.registerFactory(
        () => EditProfileCubit(UpdateProfileUseCase(repository)),
      );
    });

    tearDown(() async {
      await auth.close();
      await GetIt.instance.reset();
    });

    Future<void> pumpPage(WidgetTester tester) async {
      _tallView(tester);
      final router = GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(
            path: '/profile',
            builder: (context, _) => Scaffold(
              body: Column(
                children: [
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (_, state) =>
                        Text('signed in as ${state.customer?.fullName}'),
                  ),
                  TextButton(
                    onPressed: () => context.push('/profile/edit'),
                    child: const Text('open edit'),
                  ),
                ],
              ),
            ),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (_, _) => const EditProfilePage(),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(BlocProvider<AuthCubit>.value(
        value: auth,
        child: ScreenUtilScope(
          child: Builder(
            builder: (_) => MaterialApp.router(
              theme: AppTheme.light,
              routerConfig: router,
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open edit'));
      await tester.pumpAndSettle();
    }

    Future<void> save(WidgetTester tester) async {
      await tester.tap(find.text('profile_save'));
      await tester.pumpAndSettle();
    }

    testWidgets('a save updates the signed-in account, says so and goes back',
        (tester) async {
      network.reply(
        'PATCH',
        ApiEndPoint.updateProfile,
        body: _envelope(_account()),
      );
      await pumpPage(tester);

      expect(find.text('title_profile_edit'), findsOne);
      expect(find.text('Noura Al-Anzi'), findsOne);

      await tester.enterText(_input('auth_full_name'), 'Noura Alanzi');
      await save(tester);

      expect(network.last('PATCH').data, containsPair('name', 'Noura Alanzi'));
      expect(find.text('signed in as Noura Alanzi'), findsOne);
      expect(find.text('profile_saved'), findsOne);
      expect(auth.state.customer?.fullName, 'Noura Alanzi');
    });

    testWidgets('a refused save stays open with the error on its field',
        (tester) async {
      network.reply(
        'PATCH',
        ApiEndPoint.updateProfile,
        status: 422,
        body: _refused({
          'email': ['The email has already been taken.'],
        }),
      );
      await pumpPage(tester);

      await save(tester);

      expect(find.text('title_profile_edit'), findsOne);
      expect(find.text('The email has already been taken.'), findsOne);
      expect(find.byType(SnackBar), findsNothing);
      expect(auth.state.customer, _noura);
    });

    testWidgets('a refusal the form has no field for is a toast',
        (tester) async {
      network.reply(
        'PATCH',
        ApiEndPoint.updateProfile,
        status: 422,
        body: _refused({
          'account': ['This account cannot be changed.'],
        }),
      );
      await pumpPage(tester);

      await save(tester);

      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('This account cannot be changed.'),
        ),
        findsOne,
      );
    });

    testWidgets('a failure with no field errors is a toast', (tester) async {
      network.replySample(
        'PATCH',
        ApiEndPoint.updateProfile,
        'betouti/products_guest_500.json',
        status: 500,
      );
      await pumpPage(tester);

      await save(tester);

      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('server_error'),
        ),
        findsOne,
      );
      expect(find.text('title_profile_edit'), findsOne);
    });
  });

  group('the avatar', () {
    testWidgets('the identity shows the account photo', (tester) async {
      await tester.pumpWidget(_app(ProfileIdentity(
        name: 'Noura',
        phone: _noura.phone,
        avatarUrl: 'https://example.com/noura.jpg',
      )));

      expect(
        tester.widget<NetworkPhoto>(find.byType(NetworkPhoto)).url,
        'https://example.com/noura.jpg',
      );
    });

    testWidgets('without a photo it draws a placeholder', (tester) async {
      await tester.pumpWidget(_app(
        ProfileIdentity(name: 'Noura', phone: _noura.phone),
      ));

      expect(find.byType(NetworkPhoto), findsNothing);
      expect(
        tester.widget<AppIcon>(find.byType(AppIcon)).icon,
        AppIcons.user,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
