import 'dart:async';

import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/core/exceptions/app_exceptions.dart';
import 'package:baytoti/core/network/api_endpoints.dart';
import 'package:baytoti/core/theme/app_theme.dart';
import 'package:baytoti/core/utils/phone.dart';
import 'package:baytoti/core/utils/screen_util_scope.dart';
import 'package:baytoti/features/auth/domain/entities/customer.dart';
import 'package:baytoti/features/profile/data/datasources/profile_data_source.dart';
import 'package:baytoti/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:baytoti/features/profile/domain/usecases/profile_usecases.dart';
import 'package:baytoti/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:baytoti/features/profile/presentation/cubit/profile_state.dart';
import 'package:baytoti/features/profile/presentation/widgets/profile_identity.dart';
import 'package:baytoti/features/profile/presentation/widgets/profile_row.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_network.dart';

const String _me = 'profile/me.cloak_shape.json';

const Customer _noura = Customer(
  id: '18',
  fullName: 'Noura Al-Anzi',
  phone: '96551502244',
);

class _AccountNetwork extends FakeNetwork {
  bool offline = false;
  Completer<void>? gate;

  @override
  Future<Response> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  }) async {
    if (offline) throw const ConnectionException();
    final waiting = gate;
    if (waiting != null) await waiting.future;
    return super.get(
      url,
      queryParameters: queryParameters,
      headers: headers,
      skipAuthRefresh: skipAuthRefresh,
    );
  }
}

Map<String, dynamic> _envelope(Object? data) => {
      'success': true,
      'message': 'User retrieved successfully.',
      'data': data,
      'errors': null,
    };

T _right<T>(Either<Failure, T> result) =>
    result.fold((failure) => throw StateError('$failure'), (value) => value);

Failure _left<T>(Either<Failure, T> result) =>
    result.fold((failure) => failure, (value) => throw StateError('$value'));

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _AccountNetwork network;
  late ProfileRepositoryImpl repository;

  ProfileCubit cubit() => ProfileCubit(GetProfileUseCase(repository));

  setUp(() {
    network = _AccountNetwork()..replySample('GET', ApiEndPoint.me, _me);
    repository = ProfileRepositoryImpl(ProfileRemoteDataSource(network));
  });

  group('auth/me as cloak sends it', () {
    test('the account is read from a GET on auth/me', () async {
      final customer = _right(await repository.getProfile());

      expect(customer.props, _noura.props);
      expect(customer.email, isNull);
      expect(customer.avatarUrl, isNull);
      expect(customer.verified, isTrue);
      expect(network.calls.single.method, 'GET');
      expect(network.calls.single.url, ApiEndPoint.me);
    });

    test('an account wrapped under user is read the same way', () async {
      network.reply(
        'GET',
        ApiEndPoint.me,
        body: _envelope({
          'user': {'id': 18, 'name': 'Noura Al-Anzi', 'phone': '96551502244'},
        }),
      );

      expect(_right(await repository.getProfile()).props, _noura.props);
    });

    test('an unverified account and its email and avatar are kept', () async {
      network.reply(
        'GET',
        ApiEndPoint.me,
        body: _envelope({
          'id': '18',
          'name': 'Noura Al-Anzi',
          'email': 'noura@example.com',
          'phone': '96551502244',
          'avatar': 'https://example.com/noura.jpg',
          'status': 0,
        }),
      );

      final customer = _right(await repository.getProfile());

      expect(customer.id, '18');
      expect(customer.email, 'noura@example.com');
      expect(customer.avatarUrl, 'https://example.com/noura.jpg');
      expect(customer.verified, isFalse);
    });

    test('an answer without an account is a failure, not a blank profile',
        () async {
      network.reply('GET', ApiEndPoint.me, body: _envelope(null));

      final failure = _left(await repository.getProfile());

      expect(failure, isA<UnexpectedFailure>());
      expect(failure.message, 'profile_failed');
    });

    test('a 401 is a server failure carrying its status', () async {
      network.replySample(
        'GET',
        ApiEndPoint.me,
        'betouti/unauthenticated_401.json',
        status: 401,
      );

      final failure = _left(await repository.getProfile());

      expect(failure, isA<ServerFailure>());
      expect(failure.statusCode, 401);
    });

    test('a server crash never shows its exception text', () async {
      network.replySample(
        'GET',
        ApiEndPoint.me,
        'betouti/products_guest_500.json',
        status: 500,
      );

      final failure = _left(await repository.getProfile());

      expect(failure, isA<ServerFailure>());
      expect(failure.message, isNot(contains('LocationContextService')));
    });

    test('offline is a network failure', () async {
      network.offline = true;

      expect(_left(await repository.getProfile()), isA<NetworkFailure>());
    });
  });

  group('the phone as the design prints it', () {
    test('a Kuwaiti number splits four and four after the dial code', () {
      expect(displayPhone('+96551502244'), '+965 5150 2244');
      expect(displayPhone('96551502244'), '+965 5150 2244');
    });

    test('an Egyptian number splits three, three and four', () {
      expect(displayPhone('+201064780620'), '+20 106 478 0620');
      expect(displayPhone('201064780620'), '+20 106 478 0620');
    });

    test('anything else is shown as the server sent it', () {
      expect(displayPhone('51502244'), '51502244');
      expect(displayPhone(''), '');
    });
  });

  group('ProfileCubit', () {
    test('the account loads', () async {
      final profile = cubit();
      final states = <ProfileState>[];
      final sub = profile.stream.listen(states.add);

      await profile.load();
      await _settle();

      expect(states.map((s) => s.status), [
        ProfileStatus.loading,
        ProfileStatus.loaded,
      ]);
      expect(profile.state.customer?.props, _noura.props);

      await sub.cancel();
      await profile.close();
    });

    test('a failed first read reports the failure', () async {
      network.offline = true;
      final profile = cubit();

      await profile.load();

      expect(profile.state.status, ProfileStatus.error);
      expect(profile.state.customer, isNull);
      expect(profile.state.errorMessage, 'connection_failed');
      await profile.close();
    });

    test('a failed refresh keeps the account', () async {
      final profile = cubit();
      await profile.load();

      network.replySample(
        'GET',
        ApiEndPoint.me,
        'betouti/products_guest_500.json',
        status: 500,
      );
      await profile.load();

      expect(profile.state.status, ProfileStatus.loaded);
      expect(profile.state.customer?.props, _noura.props);
      expect(profile.state.errorMessage, 'server_error');
      await profile.close();
    });

    test('two loads at once send one request', () async {
      final gate = network.gate = Completer<void>();
      final profile = cubit();

      final first = profile.load();
      final second = profile.load();
      gate.complete();
      await Future.wait([first, second]);

      expect(network.calls, hasLength(1));
      expect(profile.state.customer?.props, _noura.props);
      await profile.close();
    });
  });

  group('profile widgets', () {
    Future<void> pump(WidgetTester tester, Widget child) =>
        tester.pumpWidget(ScreenUtilScope(
          child: Builder(
            builder: (_) => MaterialApp(
              theme: AppTheme.light,
              home: Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(body: Column(children: [child])),
              ),
            ),
          ),
        ));

    testWidgets('the identity prints the phone left to right', (tester) async {
      await pump(
        tester,
        ProfileIdentity(name: 'نورة العنزي', phone: _noura.phone),
      );

      final phone = find.text('+965 5150 2244');
      expect(phone, findsOneWidget);
      expect(
        Directionality.of(tester.element(phone)),
        TextDirection.ltr,
      );
      expect(find.text('نورة العنزي'), findsOneWidget);
    });

    testWidgets('a row shows its meta and answers a tap', (tester) async {
      var taps = 0;
      await pump(
        tester,
        ProfileRow(label: 'Delivery area', meta: 'KW', onTap: () => taps++),
      );

      expect(find.text('KW'), findsOneWidget);
      await tester.tap(find.text('Delivery area'));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a row without meta shows only its label', (tester) async {
      await pump(tester, ProfileRow(label: 'My orders', onTap: () {}));

      expect(find.byType(Text), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
