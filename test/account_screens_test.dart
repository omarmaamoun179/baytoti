import 'package:baytoti/core/network/api_endpoints.dart';
import 'package:baytoti/features/catalog/data/datasources/favourites_data_source.dart';
import 'package:baytoti/features/catalog/data/repositories/favourites_repository_impl.dart';
import 'package:baytoti/features/catalog/domain/usecases/favourite_usecases.dart';
import 'package:baytoti/features/favourites/presentation/cubit/favourites_cubit.dart';
import 'package:baytoti/features/orders/data/datasources/orders_data_source.dart';
import 'package:baytoti/features/orders/data/repositories/orders_repository_impl.dart';
import 'package:baytoti/features/orders/domain/usecases/orders_usecases.dart';
import 'package:baytoti/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:baytoti/features/orders/presentation/cubit/orders_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_network.dart';

Map<String, dynamic> _ordersPage(int page, int last) {
  final sample = Map<String, dynamic>.from(
    apiSample('orders/orders_page.cloak_shape.json')! as Map,
  );
  return {
    ...sample,
    'meta': {
      ...Map<String, dynamic>.from(sample['meta'] as Map),
      'current_page': page,
      'last_page': last,
    },
  };
}

void main() {
  group('the orders list', () {
    late FakeNetwork network;
    late OrdersCubit cubit;

    setUp(() {
      network = FakeNetwork();
      cubit = OrdersCubit(
        GetOrdersUseCase(OrdersRepositoryImpl(OrdersRemoteDataSource(network))),
      );
    });

    tearDown(() => cubit.close());

    test('reads the first page and pages on to the last', () async {
      network.reply('GET', ApiEndPoint.orders, body: _ordersPage(1, 2));
      await cubit.load();

      expect(cubit.state.status, OrdersStatus.loaded);
      expect(cubit.state.orders, isNotEmpty);
      expect(cubit.state.page.hasMore, isTrue);
      final first = cubit.state.orders.length;

      network.reply('GET', ApiEndPoint.orders, body: _ordersPage(2, 2));
      await cubit.loadMore();

      expect(network.last('GET').query, {'page': 2});
      expect(cubit.state.orders.length, first * 2);
      expect(cubit.state.page.hasMore, isFalse);

      await cubit.loadMore();
      expect(network.calls.length, 2);
    });

    test('a failed first page is an error the screen can retry', () async {
      network.replySample(
        'GET',
        ApiEndPoint.orders,
        'betouti/unauthenticated_401.json',
        status: 401,
      );

      await cubit.load();

      expect(cubit.state.status, OrdersStatus.error);
      expect(cubit.state.errorMessage, isNotNull);
    });

    test('a failed next page keeps the list already shown', () async {
      network.reply('GET', ApiEndPoint.orders, body: _ordersPage(1, 2));
      await cubit.load();
      final shown = cubit.state.orders;

      network.reply('GET', ApiEndPoint.orders, status: 500, body: '<html>');
      await cubit.loadMore();

      expect(cubit.state.orders, shown);
      expect(cubit.state.status, OrdersStatus.loaded);
      expect(cubit.state.errorMessage, isNotNull);
    });
  });

  group('saved products', () {
    late FakeNetwork network;
    late FavouritesCubit cubit;

    setUp(() {
      network = FakeNetwork()
        ..replySample(
          'GET',
          ApiEndPoint.wishlist,
          'wishlist/wishlist.cloak_shape.json',
        );
      final repository = FavouritesRepositoryImpl(
        FavouritesRemoteDataSource(network),
      );
      cubit = FavouritesCubit(
        GetFavouritesUseCase(repository),
        SetFavouriteUseCase(repository),
      );
    });

    tearDown(() => cubit.close());

    test('come from the wishlist rows, each already saved', () async {
      await cubit.load();

      final products = cubit.state.products;
      expect(products.map((p) => p.id), ['14', '16']);
      expect(products.first.slug, 'kb-mkly-14');
      expect(products.first.family.name, 'مطبخ أميرة');
      expect(products.every((p) => p.isFavourite), isTrue);
    });

    test('removing one deletes its wishlist row and drops it', () async {
      network.reply(
        'DELETE',
        ApiEndPoint.wishlistItem('7'),
        body: const {'success': true, 'message': '', 'data': null},
      );
      await cubit.load();

      await cubit.remove(cubit.state.products.first);

      expect(network.last('DELETE').url, ApiEndPoint.wishlistItem('7'));
      expect(cubit.state.products.map((p) => p.id), ['16']);
    });

    test('a refused removal puts the product back', () async {
      network.reply('DELETE', ApiEndPoint.wishlistItem('7'), status: 500);
      await cubit.load();
      final before = cubit.state.products;

      await cubit.remove(before.first);

      expect(cubit.state.products, before);
      expect(cubit.state.errorMessage, isNotNull);
    });
  });
}
