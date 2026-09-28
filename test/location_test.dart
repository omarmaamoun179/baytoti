import 'package:baytoti/core/app/session_notifier.dart';
import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/core/network/api_endpoints.dart';
import 'package:baytoti/core/utils/market.dart';
import 'package:baytoti/core/utils/money.dart';
import 'package:baytoti/features/location/data/datasources/location_data_source.dart';
import 'package:baytoti/features/location/data/repositories/location_repository_impl.dart';
import 'package:baytoti/features/location/domain/entities/location.dart';
import 'package:baytoti/features/location/domain/usecases/location_usecases.dart';
import 'package:baytoti/features/location/presentation/cubit/location_cubit.dart';
import 'package:baytoti/features/location/presentation/cubit/location_setup_cubit.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_network.dart';

class _MemoryLocation implements LocationLocalDataSource {
  LocationContext stored = LocationContext.none;

  @override
  Future<Either<Failure, LocationContext>> read() async => Right(stored);

  @override
  Future<Either<Failure, Unit>> save(LocationContext context) async {
    stored = context;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> clear() async {
    stored = LocationContext.none;
    return const Right(unit);
  }
}

void main() {
  late FakeNetwork network;
  late _MemoryLocation local;
  late LocationRepositoryImpl repository;

  setUp(() {
    network = FakeNetwork()
      ..replySample('GET', ApiEndPoint.countries, 'betouti/countries.json')
      ..replySample(
        'GET',
        ApiEndPoint.countryGovernorates('1'),
        'betouti/governorates.json',
      )
      ..replySample(
        'GET',
        ApiEndPoint.locationContext,
        'location/context.pdf_guess.json',
      )
      ..replySample(
        'POST',
        ApiEndPoint.locationContext,
        'location/context.pdf_guess.json',
      );
    local = _MemoryLocation();
    repository = LocationRepositoryImpl(LocationRemoteDataSource(network), local);
  });

  tearDown(() => Money.market = Market.fallback);

  group('the live lists', () {
    test('countries read with their code', () async {
      final countries = (await repository.getCountries())
          .getOrElse(() => throw StateError('refused'));

      final egypt = countries.single;
      expect([egypt.id, egypt.name, egypt.code], ['1', 'Egypt', 'EG']);
    });

    test('governorates belong to their country', () async {
      final governorates = (await repository.getGovernorates('1'))
          .getOrElse(() => throw StateError('refused'));

      expect(governorates.first.name, 'Cairo');
      expect(governorates.every((g) => g.countryId == '1'), isTrue);
    });
  });

  group('the browsing context', () {
    test('reads the selected country, governorate and code', () async {
      final context = (await repository.getContext())
          .getOrElse(() => throw StateError('refused'));

      expect(context.countryId, '1');
      expect(context.governorateId, '3');
      expect(context.countryCode, 'EG');
      expect(context.isSet, isTrue);
    });

    test('an empty answer means none is set yet', () async {
      network.replySample(
        'GET',
        ApiEndPoint.locationContext,
        'location/context_empty.pdf_guess.json',
      );

      final context = (await repository.getContext())
          .getOrElse(() => throw StateError('refused'));

      expect(context.isSet, isFalse);
    });

    test('a manual choice posts both ids and is remembered with its code',
        () async {
      const country = Country(id: '1', name: 'Egypt', code: 'EG');
      const governorate = Governorate(id: '3', countryId: '1', name: 'Alex');

      final saved = await repository.setManual(
        country: country,
        governorate: governorate,
      );

      expect(network.last('POST').data, {
        'mode': 'manual',
        'country_id': 1,
        'governorate_id': 3,
      });
      expect(saved.isRight(), isTrue);
      expect(local.stored.countryCode, 'EG');
    });

    test('a governorate from another country is refused on its field',
        () async {
      network.replySample(
        'POST',
        ApiEndPoint.locationContext,
        'location/context_mismatch_422.pdf_guess.json',
        status: 422,
      );

      final result = await repository.setManual(
        country: const Country(id: '1', name: 'Egypt', code: 'EG'),
        governorate: const Governorate(id: '99', countryId: '2', name: 'X'),
      );

      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isA<ValidationFailure>());
      expect((failure! as ValidationFailure)['governorate_id'], isNotEmpty);
    });
  });

  group('LocationCubit', () {
    test('a sign-in reads the context, sets the market and the session',
        () async {
      final session = SessionNotifier();
      final cubit = LocationCubit(
        GetLocationContextUseCase(repository),
        ForgetLocationUseCase(repository),
        session,
      );
      addTearDown(cubit.close);

      session.signedIn();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.countryCode, 'EG');
      expect(Money.market, Market.eg);
      expect(session.hasLocation, isTrue);
    });

    test('only a switch between two set areas counts as a move', () {
      const cairo = LocationContext(countryId: '1', governorateId: '1');
      const giza = LocationContext(countryId: '1', governorateId: '2');

      expect(giza.movedFrom(cairo), isTrue);
      expect(cairo.withCode('EG').movedFrom(cairo), isFalse);
      expect(cairo.movedFrom(LocationContext.none), isFalse);
      expect(LocationContext.none.movedFrom(cairo), isFalse);
    });

    test('a customer with no context is marked as needing one', () async {
      network.replySample(
        'GET',
        ApiEndPoint.locationContext,
        'location/context_empty.pdf_guess.json',
      );
      final session = SessionNotifier();
      final cubit = LocationCubit(
        GetLocationContextUseCase(repository),
        ForgetLocationUseCase(repository),
        session,
      );
      addTearDown(cubit.close);

      session.signedIn();
      await Future<void>.delayed(Duration.zero);

      expect(session.isLocationResolved, isTrue);
      expect(session.hasLocation, isFalse);
    });
  });

  group('LocationSetupCubit', () {
    test('a single country is chosen for the customer and its areas load',
        () async {
      final cubit = LocationSetupCubit(
        GetCountriesUseCase(repository),
        GetGovernoratesUseCase(repository),
        SetManualLocationUseCase(repository),
      );
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.country?.code, 'EG');
      expect(cubit.state.governorates, isNotEmpty);
      expect(cubit.state.canSave, isFalse);

      cubit.selectGovernorate(cubit.state.governorates.first);
      await cubit.save();

      expect(cubit.state.status, LocationSetupStatus.saved);
      expect(cubit.state.saved?.isSet, isTrue);
    });

    test('a failed list is a retryable failure', () async {
      network.reply('GET', ApiEndPoint.countries, status: 500, body: '<html>');
      final cubit = LocationSetupCubit(
        GetCountriesUseCase(repository),
        GetGovernoratesUseCase(repository),
        SetManualLocationUseCase(repository),
      );
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, LocationSetupStatus.failed);
      expect(cubit.state.errorMessage, isNotNull);
    });
  });
}
