import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/core/exceptions/app_exceptions.dart';
import 'package:baytoti/core/network/api_endpoints.dart';
import 'package:baytoti/core/theme/app_theme.dart';
import 'package:baytoti/core/utils/screen_util_scope.dart';
import 'package:baytoti/core/widgets/confirm_sheet.dart';
import 'package:baytoti/core/widgets/phone_text_form_field.dart';
import 'package:baytoti/features/addresses/data/datasources/addresses_data_source.dart';
import 'package:baytoti/features/addresses/data/models/address_model.dart';
import 'package:baytoti/features/addresses/data/repositories/addresses_repository_impl.dart';
import 'package:baytoti/features/addresses/domain/entities/address.dart';
import 'package:baytoti/features/addresses/domain/usecases/addresses_usecases.dart';
import 'package:baytoti/features/addresses/presentation/cubit/address_form_cubit.dart';
import 'package:baytoti/features/addresses/presentation/cubit/addresses_cubit.dart';
import 'package:baytoti/features/addresses/presentation/pages/address_form_page.dart';
import 'package:baytoti/features/addresses/presentation/pages/addresses_page.dart';
import 'package:baytoti/features/addresses/presentation/widgets/address_default_toggle.dart';
import 'package:baytoti/features/addresses/presentation/widgets/address_field.dart';
import 'package:baytoti/features/addresses/presentation/widgets/address_form.dart';
import 'package:baytoti/features/addresses/presentation/widgets/address_tile.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_network.dart';

class _OfflineNetwork extends FakeNetwork {
  @override
  Future<Response> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  }) async =>
      throw const ConnectionException();

  @override
  Future<Response> post(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  }) async =>
      throw const ConnectionException();
}

const String _sample = 'addresses/addresses.cloak_shape.json';

const AddressParams _params = AddressParams(
  label: ' Home ',
  recipientName: 'Mariam Alkandari',
  phone: '+96555123456',
  country: Address.kuwait,
  city: 'Hawalli',
  area: 'Salmiya',
  block: '4',
  street: '12',
  building: '  ',
  apartment: '3',
);

const Map<String, dynamic> _paramsBody = {
  'label': 'Home',
  'recipient_name': 'Mariam Alkandari',
  'phone': '+96555123456',
  'country': 'Kuwait',
  'city': 'Hawalli',
  'area': 'Salmiya',
  'block': '4',
  'street': '12',
  'building': null,
  'floor': null,
  'apartment': '3',
  'additional_directions': null,
  'is_default': false,
};

Map<String, dynamic> _row(int id, {Object? isDefault = false}) => {
      'id': id,
      'label': 'Address $id',
      'recipient_name': 'Mariam Alkandari',
      'phone': '+96555123456',
      'country': 'Kuwait',
      'city': 'Hawalli',
      'area': 'Salmiya',
      'street': '$id',
      'is_default': isDefault,
    };

Map<String, dynamic> _list(List<Map<String, dynamic>> rows) => {
      'success': true,
      'message': 'Addresses retrieved successfully.',
      'data': rows,
    };

T _valueOf<T>(Either<Failure, T> result) =>
    result.getOrElse(() => throw StateError('refused: $result'));

Failure _failureOf(Either<Failure, Object?> result) =>
    result.fold((f) => f, (_) => throw StateError('succeeded'));

int _reads(FakeNetwork network) => network.calls
    .where((c) => c.method == 'GET' && c.url == ApiEndPoint.addresses)
    .length;

AddressesCubit _listCubit(AddressesRepositoryImpl repository) =>
    AddressesCubit(
      GetAddressesUseCase(repository),
      DeleteAddressUseCase(repository),
      SetDefaultAddressUseCase(repository),
    );

AddressFormCubit _formCubit(AddressesRepositoryImpl repository) =>
    AddressFormCubit(
      CreateAddressUseCase(repository),
      UpdateAddressUseCase(repository),
    );

Widget _app(Widget child) => ScreenUtilScope(
      child: Builder(
        builder: (_) => MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: child),
        ),
      ),
    );

Widget _routed(GoRouter router) => ScreenUtilScope(
      child: Builder(
        builder: (_) => MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
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
        (w) => w is AddressField && w.label == labelKey.tr(),
      ),
      matching: find.byType(TextField),
    );

Finder get _phoneInput => find.descendant(
      of: find.byType(PhoneTextFormField),
      matching: find.byType(TextField),
    );

Future<void> _fillRequired(WidgetTester tester) async {
  await tester.enterText(_input('address_field_label'), ' Home ');
  await tester.enterText(_input('address_field_recipient'), 'Mariam');
  await tester.enterText(_phoneInput, '55123456');
  await tester.enterText(_input('address_field_city'), 'Hawalli');
  await tester.enterText(_input('address_field_area'), 'Salmiya');
  await tester.enterText(_input('address_field_street'), '12');
  await tester.pumpAndSettle();
}

void main() {
  late FakeNetwork network;
  late AddressesRemoteDataSource source;
  late AddressesRepositoryImpl repository;

  setUp(() {
    network = FakeNetwork()
      ..replySample('GET', ApiEndPoint.addresses, _sample)
      ..replySample(
        'POST',
        ApiEndPoint.addresses,
        'addresses/address_created.cloak_shape.json',
        status: 201,
      )
      ..replySample(
        'PUT',
        ApiEndPoint.address('1'),
        'addresses/address_updated.cloak_shape.json',
      )
      ..replySample(
        'PATCH',
        ApiEndPoint.defaultAddress('1'),
        'addresses/address_default.cloak_shape.json',
      )
      ..replySample(
        'DELETE',
        ApiEndPoint.address('1'),
        'addresses/address_deleted.cloak_shape.json',
      );
    source = AddressesRemoteDataSource(network);
    repository = AddressesRepositoryImpl(source);
  });

  group('the cloak address shape', () {
    test('a row reads every field, blanks as null', () async {
      final addresses = _valueOf(await repository.getAddresses());

      expect(addresses.map((a) => a.id), ['1', '2']);
      final home = addresses.last;
      expect(home.label, 'Home');
      expect(home.recipientName, 'Mariam Alkandari');
      expect(home.phone, '+96555123456');
      expect(home.country, Address.kuwait);
      expect(home.city, 'Hawalli');
      expect(home.floor, isNull);
      expect(home.apartment, '3');
      expect(home.additionalDirections, isNull);
      expect(home.isDefault, isTrue);
      expect(home.line, 'Salmiya, 4, 12, 8, 3');
      expect(addresses.first.line, 'Sharq, 2, Jaber Al-Mubarak, 14, 6');
    });

    test('is_default arrives as a bool, a number or a string', () {
      expect(AddressModel.fromJson(_row(1, isDefault: 1)).isDefault, isTrue);
      expect(AddressModel.fromJson(_row(1, isDefault: '1')).isDefault, isTrue);
      expect(AddressModel.fromJson(_row(1, isDefault: '0')).isDefault, isFalse);
      expect(AddressModel.fromJson(_row(1, isDefault: null)).isDefault, isFalse);
    });

    test('a row without an id is dropped: nothing could be sent for it', () {
      final addresses = AddressModel.listFrom([
        {'label': 'Nowhere'},
        _row(3),
      ]);

      expect(addresses.map((a) => a.id), ['3']);
    });

    test('a blank label shows the city, and no parts leave the city', () {
      final address = AddressModel.fromJson(const {
        'id': 4,
        'label': ' ',
        'city': 'Hawalli',
      });

      expect(address.title, 'Hawalli');
      expect(address.line, 'Hawalli');
    });
  });

  group('the request body', () {
    test('every key goes, trimmed, with blank optionals as null', () {
      final body = _params.toJson();

      expect(body, _paramsBody);
      expect(body.keys, hasLength(13));
    });
  });

  group('the remote data source', () {
    test('the book is read from GET /addresses', () async {
      await source.getAddresses();

      expect(network.last('GET').url, ApiEndPoint.addresses);
    });

    test('a new address is a POST of the full body, with a + phone', () async {
      final created = _valueOf(await repository.create(_params));

      final call = network.last('POST');
      expect(call.url, ApiEndPoint.addresses);
      expect(call.data, _paramsBody);
      expect((call.data! as Map)['phone'], startsWith('+965'));
      expect(created.id, '3');
      expect(created.block, isNull);
      expect(created.additionalDirections, 'Blue gate');
    });

    test('an edit is a PUT on the address, never a PATCH', () async {
      final updated = _valueOf(await repository.update('1', _params));

      expect(network.last('PUT').url, ApiEndPoint.address('1'));
      expect(network.last('PUT').data, _paramsBody);
      expect(network.calls.where((c) => c.method == 'PATCH'), isEmpty);
      expect(updated.country, Address.egypt);
      expect(updated.phone, '+201001234567');
    });

    test('the default is a PATCH on …/default with no body', () async {
      _valueOf(await repository.setDefault('1'));

      expect(network.last('PATCH').url, ApiEndPoint.defaultAddress('1'));
      expect(network.last('PATCH').data, isNull);
    });

    test('a delete answers data: null and is still a success', () async {
      _valueOf(await repository.delete('1'));

      expect(network.last('DELETE').url, ApiEndPoint.address('1'));
    });

    test('a refused address keeps every field error', () async {
      network.replySample(
        'POST',
        ApiEndPoint.addresses,
        'addresses/address_422.cloak_shape.json',
        status: 422,
      );

      final failure = _failureOf(await repository.create(_params));

      expect(failure, isA<ValidationFailure>());
      final validation = failure as ValidationFailure;
      expect(
        validation['recipient_name'],
        'The recipient name field is required.',
      );
      expect(validation['phone'], contains('30 characters'));
    });

    test('an unknown address is a readable 404, not debug text', () async {
      network.replySample(
        'DELETE',
        ApiEndPoint.address('99'),
        'addresses/address_404.cloak_shape.json',
        status: 404,
      );

      final failure = _failureOf(await repository.delete('99'));

      expect(failure.statusCode, 404);
      expect(failure.message, 'address_not_found');
    });

    test('without a token the book is a 401', () async {
      network.replySample(
        'GET',
        ApiEndPoint.addresses,
        'betouti/unauthenticated_401.json',
        status: 401,
      );

      final failure = _failureOf(await repository.getAddresses());

      expect(failure, isA<ServerFailure>());
      expect(failure.statusCode, 401);
    });

    test('a server error shows the generic message', () async {
      network.replySample(
        'PUT',
        ApiEndPoint.address('1'),
        'betouti/products_guest_500.json',
        status: 500,
      );

      final failure = _failureOf(await repository.update('1', _params));

      expect(failure.message, 'server_error');
    });

    test('offline is a network failure', () async {
      final offline = AddressesRepositoryImpl(
        AddressesRemoteDataSource(_OfflineNetwork()),
      );

      expect(_failureOf(await offline.getAddresses()), isA<NetworkFailure>());
      expect(_failureOf(await offline.create(_params)), isA<NetworkFailure>());
    });
  });

  group('AddressesCubit', () {
    late AddressesCubit cubit;

    setUp(() => cubit = _listCubit(repository));

    tearDown(() => cubit.close());

    test('loads the book', () async {
      await cubit.load();

      expect(cubit.state.status, AddressesStatus.loaded);
      expect(cubit.state.addresses, hasLength(2));
      expect(cubit.state.isEmpty, isFalse);
    });

    test('an empty book is loaded and empty', () async {
      network.replySample(
        'GET',
        ApiEndPoint.addresses,
        'addresses/addresses_empty.cloak_shape.json',
      );

      await cubit.load();

      expect(cubit.state.isEmpty, isTrue);
    });

    test('a failed first read is an error screen', () async {
      network.replySample(
        'GET',
        ApiEndPoint.addresses,
        'betouti/products_guest_500.json',
        status: 500,
      );

      await cubit.load();

      expect(cubit.state.status, AddressesStatus.error);
      expect(cubit.state.errorMessage, 'server_error');
    });

    test('a delete is sent, then the book is read again', () async {
      await cubit.load();
      network.reply(
        'GET',
        ApiEndPoint.addresses,
        body: _list([_row(2, isDefault: true)]),
      );

      await cubit.delete('1');

      expect(network.last('DELETE').url, ApiEndPoint.address('1'));
      expect(_reads(network), 2);
      expect(cubit.state.addresses.map((a) => a.id), ['2']);
      expect(cubit.state.busyId, isNull);
    });

    test('a new default is sent, then the book is read again', () async {
      await cubit.load();
      network.reply(
        'GET',
        ApiEndPoint.addresses,
        body: _list([_row(1, isDefault: true), _row(2)]),
      );

      await cubit.makeDefault('1');

      expect(network.last('PATCH').url, ApiEndPoint.defaultAddress('1'));
      expect(_reads(network), 2);
      expect(
        cubit.state.addresses.where((a) => a.isDefault).single.id,
        '1',
      );
    });

    test('a refused change keeps the list and says why', () async {
      network.replySample(
        'DELETE',
        ApiEndPoint.address('1'),
        'addresses/address_404.cloak_shape.json',
        status: 404,
      );
      await cubit.load();

      await cubit.delete('1');

      expect(cubit.state.status, AddressesStatus.loaded);
      expect(cubit.state.addresses, hasLength(2));
      expect(cubit.state.errorMessage, 'address_not_found');
      expect(cubit.state.busyId, isNull);
      expect(_reads(network), 1);
    });

    test('one change at a time', () async {
      await cubit.load();

      final first = cubit.delete('1');
      final second = cubit.makeDefault('1');
      await Future.wait([first, second]);

      expect(network.calls.where((c) => c.method == 'DELETE'), hasLength(1));
      expect(network.calls.where((c) => c.method == 'PATCH'), isEmpty);
    });
  });

  group('AddressFormCubit', () {
    late AddressFormCubit cubit;

    setUp(() => cubit = _formCubit(repository));

    tearDown(() => cubit.close());

    test('without an id it creates, and is saved', () async {
      await cubit.save(_params);

      expect(network.last('POST').url, ApiEndPoint.addresses);
      expect(cubit.state.isSaved, isTrue);
      expect(cubit.state.saved?.id, '3');
    });

    test('with an id it updates that address', () async {
      await cubit.save(_params, id: '1');

      expect(network.last('PUT').url, ApiEndPoint.address('1'));
      expect(network.calls.where((c) => c.method == 'POST'), isEmpty);
      expect(cubit.state.isSaved, isTrue);
    });

    test('a 422 hands each field its error, and typing clears one', () async {
      network.replySample(
        'POST',
        ApiEndPoint.addresses,
        'addresses/address_422.cloak_shape.json',
        status: 422,
      );

      await cubit.save(_params);

      expect(cubit.state.status, AddressFormStatus.editing);
      expect(cubit.state.fieldErrors.keys, {'recipient_name', 'phone'});
      expect(cubit.state.errorMessage, isNotNull);

      cubit.clearFieldError('recipient_name');

      expect(cubit.state.fieldErrors.keys, {'phone'});
    });

    test('a 401 is a message with no field errors', () async {
      network.replySample(
        'POST',
        ApiEndPoint.addresses,
        'betouti/unauthenticated_401.json',
        status: 401,
      );

      await cubit.save(_params);

      expect(cubit.state.fieldErrors, isEmpty);
      expect(cubit.state.errorMessage, 'Unauthenticated.');
      expect(cubit.state.isSaved, isFalse);
    });

    test('offline can be tried again', () async {
      final offline = _formCubit(AddressesRepositoryImpl(
        AddressesRemoteDataSource(_OfflineNetwork()),
      ));
      addTearDown(offline.close);

      await offline.save(_params);

      expect(offline.state.errorMessage, 'connection_failed');
      expect(offline.state.isSaving, isFalse);
    });
  });

  group('the form', () {
    testWidgets('an empty form is refused locally and sends nothing',
        (tester) async {
      _tallView(tester);
      AddressParams? submitted;

      await tester.pumpWidget(_app(AddressForm(
        isSaving: false,
        fieldErrors: const {},
        onFieldChanged: (_) {},
        onSubmit: (params) => submitted = params,
      )));
      await tester.tap(find.text('address_save'));
      await tester.pumpAndSettle();

      expect(find.text('field_required'), findsNWidgets(5));
      expect(submitted, isNull);
    });

    testWidgets('a filled form hands back trimmed params and an E.164 phone',
        (tester) async {
      _tallView(tester);
      AddressParams? submitted;

      await tester.pumpWidget(_app(AddressForm(
        isSaving: false,
        fieldErrors: const {},
        onFieldChanged: (_) {},
        onSubmit: (params) => submitted = params,
      )));
      await _fillRequired(tester);
      await tester.tap(find.text('address_set_default'));
      await tester.tap(find.text('address_save'));
      await tester.pumpAndSettle();

      expect(submitted?.phone, '+96555123456');
      expect(submitted?.toJson(), {
        'label': 'Home',
        'recipient_name': 'Mariam',
        'phone': '+96555123456',
        'country': 'Kuwait',
        'city': 'Hawalli',
        'area': 'Salmiya',
        'block': null,
        'street': '12',
        'building': null,
        'floor': null,
        'apartment': null,
        'additional_directions': null,
        'is_default': true,
      });
    });

    testWidgets('server field errors show under their inputs until typed over',
        (tester) async {
      _tallView(tester);
      final changed = <String>[];

      await tester.pumpWidget(_app(AddressForm(
        isSaving: false,
        fieldErrors: const {
          'recipient_name': 'The recipient name field is required.',
          'phone': 'The phone field must not be greater than 30 characters.',
        },
        onFieldChanged: changed.add,
        onSubmit: (_) {},
      )));

      expect(find.text('The recipient name field is required.'), findsOne);
      expect(
        find.text('The phone field must not be greater than 30 characters.'),
        findsOne,
      );

      await tester.enterText(_input('address_field_recipient'), 'M');

      expect(changed, contains('recipient_name'));
    });

    testWidgets('an edit is prefilled, stays default and keeps its country',
        (tester) async {
      _tallView(tester);
      AddressParams? submitted;
      const initial = Address(
        id: '1',
        label: 'Office',
        recipientName: 'Mariam',
        phone: '+201001234567',
        country: Address.egypt,
        city: 'Cairo',
        area: 'Zamalek',
        street: '26 July',
        isDefault: true,
      );

      await tester.pumpWidget(_app(AddressForm(
        initial: initial,
        isSaving: false,
        fieldErrors: const {},
        onFieldChanged: (_) {},
        onSubmit: (params) => submitted = params,
      )));
      await tester.pumpAndSettle();

      expect(find.byType(AddressDefaultToggle), findsNothing);
      expect(find.text('Office'), findsOne);

      await tester.tap(find.text('address_save'));
      await tester.pumpAndSettle();

      expect(submitted?.phone, '+201001234567');
      expect(submitted?.country, Address.egypt);
      expect(submitted?.isDefault, isTrue);
      expect(submitted?.street, '26 July');
    });
  });

  group('the pages', () {
    tearDown(() => GetIt.instance.reset());

    Future<GoRouter> pumpBook(WidgetTester tester) async {
      GetIt.instance.registerFactory(() => _listCubit(repository));
      final router = GoRouter(
        initialLocation: '/profile/addresses',
        routes: [
          GoRoute(
            path: '/profile',
            builder: (_, _) => const Text('profile root'),
            routes: [
              GoRoute(
                path: 'addresses',
                builder: (_, _) => const AddressesPage(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => Scaffold(
                      body: TextButton(
                        onPressed: () => context.pop(true),
                        child: Text(
                          'form ${(state.extra as Address?)?.id ?? 'new'}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(_routed(router));
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('the book shows each address, its default and phone',
        (tester) async {
      await pumpBook(tester);

      expect(find.byType(AddressTile), findsNWidgets(2));
      expect(find.text('address_default_badge'), findsOne);
      expect(find.text('address_make_default'), findsOne);
      expect(
        find.textContaining(RegExp(r'\+965 5512 3456')),
        findsNWidgets(2),
      );
    });

    testWidgets('an empty book says so and offers to add', (tester) async {
      network.replySample(
        'GET',
        ApiEndPoint.addresses,
        'addresses/addresses_empty.cloak_shape.json',
      );
      await pumpBook(tester);

      expect(find.text('addresses_empty'), findsOne);
      expect(find.text('address_add'), findsOne);
    });

    testWidgets('a failed read offers a retry', (tester) async {
      network.replySample(
        'GET',
        ApiEndPoint.addresses,
        'betouti/products_guest_500.json',
        status: 500,
      );
      await pumpBook(tester);

      expect(find.text('server_error'), findsOne);

      network.replySample('GET', ApiEndPoint.addresses, _sample);
      await tester.tap(find.text('retry'));
      await tester.pumpAndSettle();

      expect(find.byType(AddressTile), findsNWidgets(2));
    });

    testWidgets('a delete asks first', (tester) async {
      await pumpBook(tester);

      await tester.tap(find.text('address_delete').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('go_back'));
      await tester.pumpAndSettle();

      expect(network.calls.where((c) => c.method == 'DELETE'), isEmpty);

      network.reply(
        'GET',
        ApiEndPoint.addresses,
        body: _list([_row(2, isDefault: true)]),
      );
      await tester.tap(find.text('address_delete').first);
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
        of: find.byType(ConfirmSheet),
        matching: find.text('address_delete'),
      ));
      await tester.pumpAndSettle();

      expect(network.last('DELETE').url, ApiEndPoint.address('1'));
      expect(find.byType(AddressTile), findsOne);
    });

    testWidgets('make default patches and rereads', (tester) async {
      await pumpBook(tester);

      await tester.tap(find.text('address_make_default'));
      await tester.pumpAndSettle();

      expect(network.last('PATCH').url, ApiEndPoint.defaultAddress('1'));
      expect(_reads(network), 2);
    });

    testWidgets('adding opens the form, and a save reloads the book',
        (tester) async {
      await pumpBook(tester);

      await tester.tap(find.text('address_add'));
      await tester.pumpAndSettle();
      expect(find.text('form new'), findsOne);

      network.reply(
        'GET',
        ApiEndPoint.addresses,
        body: _list([_row(1), _row(2, isDefault: true), _row(3)]),
      );
      await tester.tap(find.text('form new'));
      await tester.pumpAndSettle();

      expect(find.byType(AddressTile), findsNWidgets(3));
    });

    testWidgets('editing opens the form with the address', (tester) async {
      await pumpBook(tester);

      await tester.tap(find.text('address_edit').first);
      await tester.pumpAndSettle();

      expect(find.text('form 1'), findsOne);
    });

    Future<List<bool?>> pumpForm(WidgetTester tester) async {
      _tallView(tester);
      GetIt.instance.registerFactory(() => _formCubit(repository));
      final results = <bool?>[];
      final router = GoRouter(
        initialLocation: '/cart',
        routes: [
          GoRoute(
            path: '/cart',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () async =>
                    results.add(await context.push<bool>('/cart/addresses/new')),
                child: const Text('open form'),
              ),
            ),
            routes: [
              GoRoute(
                path: 'addresses/new',
                builder: (_, state) =>
                    AddressFormPage(initial: state.extra as Address?),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(_routed(router));
      await tester.tap(find.text('open form'));
      await tester.pumpAndSettle();
      return results;
    }

    testWidgets('a saved address pops the form with true', (tester) async {
      final results = await pumpForm(tester);

      expect(find.text('title_address_new'), findsOne);
      await _fillRequired(tester);
      await tester.tap(find.text('address_save'));
      await tester.pumpAndSettle();

      expect(network.last('POST').data, containsPair('phone', '+96555123456'));
      expect(results, [true]);
      expect(find.text('address_saved'), findsOne);
    });

    testWidgets('a refused address stays open with the errors on the fields',
        (tester) async {
      network.replySample(
        'POST',
        ApiEndPoint.addresses,
        'addresses/address_422.cloak_shape.json',
        status: 422,
      );
      final results = await pumpForm(tester);

      await _fillRequired(tester);
      await tester.tap(find.text('address_save'));
      await tester.pumpAndSettle();

      expect(results, isEmpty);
      expect(find.text('The recipient name field is required.'), findsOne);
      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
