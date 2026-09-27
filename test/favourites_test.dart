import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/core/exceptions/app_exceptions.dart';
import 'package:baytoti/core/network/api_endpoints.dart';
import 'package:baytoti/features/catalog/data/datasources/favourites_data_source.dart';
import 'package:baytoti/features/catalog/data/repositories/favourites_repository_impl.dart';
import 'package:baytoti/features/catalog/domain/usecases/favourite_usecases.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_network.dart';

class _BrokenNetwork extends FakeNetwork {
  final AppException error;

  _BrokenNetwork(this.error);

  @override
  Future<Response> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  }) async =>
      throw error;

  @override
  Future<Response> post(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  }) async =>
      throw error;
}

Failure _failure<T>(Either<Failure, T> result) =>
    result.fold((failure) => failure, (value) => fail('expected a failure'));

T _value<T>(Either<Failure, T> result) =>
    result.getOrElse(() => fail('expected a value, got $result'));

void main() {
  late FakeNetwork network;
  late FavouritesRemoteDataSource source;

  setUp(() {
    network = FakeNetwork()
      ..replySample(
        'GET',
        ApiEndPoint.wishlist,
        'wishlist/wishlist.cloak_shape.json',
      )
      ..replySample(
        'POST',
        ApiEndPoint.wishlistItems,
        'wishlist/add.cloak_shape.json',
        status: 201,
      )
      ..replySample(
        'DELETE',
        ApiEndPoint.wishlistItem('7'),
        'wishlist/remove.cloak_shape.json',
      );
    source = FavouritesRemoteDataSource(network);
  });

  group('reading the wishlist', () {
    test('the saved ids are the products inside each row', () async {
      final ids = _value(await source.getFavouriteIds());

      expect(ids, {'14', '16'});
      expect(network.last('GET').url, ApiEndPoint.wishlist);
    });

    test('an empty wishlist is an empty set', () async {
      network.replySample(
        'GET',
        ApiEndPoint.wishlist,
        'wishlist/empty.cloak_shape.json',
      );

      expect(_value(await source.getFavouriteIds()), isEmpty);
    });

    test('an answer without items is a failure, not an empty wishlist',
        () async {
      network.reply(
        'GET',
        ApiEndPoint.wishlist,
        body: {'success': true, 'message': '', 'data': null, 'errors': null},
      );

      final failure = _failure(await source.getFavouriteIds());

      expect(failure, isA<UnexpectedFailure>());
      expect(failure.message, 'favourite_failed');
    });
  });

  group('saving a product', () {
    test('posts the numeric product id and reads the wishlist back',
        () async {
      final saved = _value(await source.setFavourite('15', true));

      expect(saved, isTrue);
      expect(network.last('POST').url, ApiEndPoint.wishlistItems);
      expect(network.last('POST').data, {'product_id': 15});
    });

    test('a wishlist answer without the product says it is not saved',
        () async {
      expect(_value(await source.setFavourite('99', true)), isFalse);
    });

    test('a success that carries no wishlist still counts as saved',
        () async {
      network.reply(
        'POST',
        ApiEndPoint.wishlistItems,
        body: {'success': true, 'message': 'Added', 'data': null},
      );

      expect(_value(await source.setFavourite('15', true)), isTrue);
    });

    test('a refused product is a validation failure', () async {
      network.reply(
        'POST',
        ApiEndPoint.wishlistItems,
        status: 422,
        body: {
          'success': false,
          'message': 'The selected product id is invalid.',
          'data': null,
          'errors': {
            'product_id': ['The selected product id is invalid.'],
          },
        },
      );

      final failure = _failure(await source.setFavourite('15', true));

      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure)['product_id'], isNotEmpty);
    });
  });

  group('removing a product', () {
    test('deletes the wishlist row, not the product id', () async {
      final saved = _value(await source.setFavourite('14', false));

      expect(saved, isFalse);
      expect(
        network.calls.map((c) => '${c.method} ${c.url}'),
        [
          'GET ${ApiEndPoint.wishlist}',
          'DELETE ${ApiEndPoint.wishlistItem('7')}',
        ],
      );
    });

    test('a product that is not saved sends no delete', () async {
      expect(_value(await source.setFavourite('99', false)), isFalse);
      expect(network.calls.map((c) => c.method), ['GET']);
    });

    test('a failed delete is a failure', () async {
      network.replySample(
        'DELETE',
        ApiEndPoint.wishlistItem('7'),
        'betouti/products_guest_500.json',
        status: 500,
      );

      final failure = _failure(await source.setFavourite('14', false));

      expect(failure, isA<ServerFailure>());
      expect(failure.statusCode, 500);
      expect(failure.message, 'server_error');
    });
  });

  group('failures', () {
    test('a signed-out answer is a 401 failure', () async {
      network.replySample(
        'GET',
        ApiEndPoint.wishlist,
        'betouti/unauthenticated_401.json',
        status: 401,
      );

      final failure = _failure(await source.getFavouriteIds());

      expect(failure, isA<ServerFailure>());
      expect(failure.statusCode, 401);
    });

    test('offline is a network failure', () async {
      final offline = FavouritesRemoteDataSource(
        _BrokenNetwork(const ConnectionException()),
      );

      expect(_failure(await offline.getFavouriteIds()), isA<NetworkFailure>());
      expect(
        _failure(await offline.setFavourite('15', true)),
        isA<NetworkFailure>(),
      );
    });

    test('an expired session says so', () async {
      final expired = FavouritesRemoteDataSource(
        _BrokenNetwork(const SessionExpiredException()),
      );

      final failure = _failure(await expired.setFavourite('14', false));

      expect(failure.message, 'session_expired');
      expect(failure.statusCode, 401);
    });
  });

  test('the use case goes through the repository to the wishlist', () async {
    final setFavourite = SetFavouriteUseCase(FavouritesRepositoryImpl(source));

    final saved = await setFavourite(
      const SetFavouriteParams(productId: '15', favourite: true),
    );
    final removed = await setFavourite(
      const SetFavouriteParams(productId: '14', favourite: false),
    );

    expect(saved, const Right<Failure, bool>(true));
    expect(removed, const Right<Failure, bool>(false));
  });
}
