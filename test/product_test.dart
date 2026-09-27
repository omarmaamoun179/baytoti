import 'dart:async';

import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/core/theme/app_theme.dart';
import 'package:baytoti/core/utils/money.dart';
import 'package:baytoti/core/utils/screen_util_scope.dart';
import 'package:baytoti/features/catalog/data/fixtures/fixture_backend.dart';
import 'package:baytoti/features/catalog/domain/entities/family_ref.dart';
import 'package:baytoti/features/catalog/domain/entities/image_ref.dart';
import 'package:baytoti/features/catalog/domain/entities/product_badge.dart';
import 'package:baytoti/features/catalog/domain/repositories/favourites_repository.dart';
import 'package:baytoti/features/catalog/domain/usecases/favourite_usecases.dart';
import 'package:baytoti/features/product/data/datasources/product_data_source.dart';
import 'package:baytoti/features/product/data/models/product_detail_model.dart';
import 'package:baytoti/features/product/data/repositories/product_repository_impl.dart';
import 'package:baytoti/features/product/domain/entities/product_detail.dart';
import 'package:baytoti/features/product/domain/repositories/product_repository.dart';
import 'package:baytoti/features/product/domain/usecases/product_usecases.dart';
import 'package:baytoti/features/product/presentation/cubit/product_cubit.dart';
import 'package:baytoti/features/product/presentation/cubit/product_state.dart';
import 'package:baytoti/features/product/presentation/widgets/product_gallery.dart';
import 'package:baytoti/features/product/presentation/widgets/product_meta_rows.dart';
import 'package:baytoti/features/product/presentation/widgets/product_reviews.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProductDetail _product({
  bool favourite = false,
  int stock = 8,
  bool inStock = true,
  int maxPerOrder = 3,
}) =>
    ProductDetail(
      id: 'prd_1',
      name: 'Cardamom date cake',
      price: const Money(fils: 4250, display: '4.250 KWD'),
      stock: stock,
      inStock: inStock,
      maxPerOrder: maxPerOrder,
      family: const FamilyRef(id: 'fam_1', name: 'Umm Abdullah Family'),
      isFavourite: favourite,
    );

class _FakeProductRepository implements ProductRepository {
  Either<Failure, ProductDetail> answer;

  _FakeProductRepository(this.answer);

  @override
  Future<Either<Failure, ProductDetail>> getProduct(String productId) async =>
      answer;
}

class _FakeFavouritesRepository implements FavouritesRepository {
  Completer<Either<Failure, bool>> pending = Completer();
  final List<bool> calls = [];

  @override
  Future<Either<Failure, bool>> setFavourite(
    String productId,
    bool favourite,
  ) {
    calls.add(favourite);
    return pending.future;
  }
}

Future<void> _pump(WidgetTester tester, Widget child) =>
    tester.pumpWidget(ScreenUtilScope(
      child: Builder(
        builder: (_) => MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    ));

void main() {
  group('ProductDetailModel reads the contract', () {
    test('the fixture product parses whole', () {
      final json = FixtureBackend().product('prd_1', 'en');
      final product = ProductDetailModel.fromJson(json);

      expect(product.id, 'prd_1');
      expect(product.name, 'Cardamom date cake');
      expect(product.price.fils, 4250);
      expect(product.compareAt?.fils, 5000);
      expect(product.badge, ProductBadge.bestSeller);
      expect(product.rating, 4.9);
      expect(product.soldCount, 212);
      expect(product.stock, 8);
      expect(product.inStock, isTrue);
      expect(product.maxPerOrder, 8);
      expect(product.maxQuantity, 8);
      expect(product.fulfilment, {Fulfilment.delivery, Fulfilment.pickup});
      expect(product.preparationTime, isNotEmpty);
      expect(product.description, isNotEmpty);
      expect(product.family.id, 'fam_1');
      expect(product.family.isVerified, isTrue);
      expect(product.familyAvatar?.url, 'assets/images/catalog/fam_1_avatar.jpg');
      expect(product.images.single.url, 'assets/images/catalog/prd_1.jpg');
      expect(product.reviews, isNotEmpty);
      expect(product.reviews.first.authorName, isNotEmpty);
    });

    test('the API sample reads images, avatar and reviews', () {
      final product = ProductDetailModel.fromJson({
        'id': 'prd_1',
        'name': 'Cake',
        'description': 'Soft',
        'price_fils': 4250,
        'price_display': '4.250 د.ك',
        'compare_at_fils': null,
        'badge': 'new',
        'rating': 4.9,
        'rating_count': 63,
        'sold_count': 212,
        'stock': 0,
        'in_stock': false,
        'preparation_time_display': '٢٤ ساعة',
        'fulfilment': ['pickup', 'drone'],
        'max_per_order': 10,
        'images': [
          {'url': 'https://cdn/a.jpg', 'width': 800, 'height': 800, 'alt': 'a'},
          {'url': 'https://cdn/b.jpg'},
        ],
        'family': {
          'id': 'fam_1',
          'name': 'Family',
          'city': 'حولي',
          'rating': 4.9,
          'is_verified': true,
          'avatar': {'url': 'https://cdn/avatar.jpg'},
        },
        'is_favourite': true,
        'reviews_preview': [
          {
            'id': 'rev_4',
            'author_name': 'مريم ا.',
            'rating': 4,
            'body': 'Good',
            'created_display': 'قبل أسبوع',
          },
        ],
      });

      expect(product.compareAt, isNull);
      expect(product.badge, ProductBadge.newArrival);
      expect(product.images.length, 2);
      expect(product.images.first.width, 800);
      expect(product.familyAvatar?.url, 'https://cdn/avatar.jpg');
      expect(product.fulfilment, {Fulfilment.pickup});
      expect(product.isFavourite, isTrue);
      expect(product.canOrder, isFalse);
      expect(product.reviews.single.stars, '★★★★☆');
      expect(product.reviews.single.createdDisplay, 'قبل أسبوع');
    });

    test('the quantity is limited by stock and by the order cap', () {
      expect(_product(stock: 2, maxPerOrder: 10).maxQuantity, 2);
      expect(_product(stock: 30, maxPerOrder: 10).maxQuantity, 10);
      expect(_product(stock: 5, inStock: false).maxQuantity, 0);
    });
  });

  group('the mock data source through the repository', () {
    final repository = ProductRepositoryImpl(
      ProductMockDataSource(FixtureBackend(), () async => 'ar'),
    );

    test('a known product comes back in the asked language', () async {
      final result = await repository.getProduct('prd_1');

      expect(result.isRight(), isTrue);
      result.fold((_) {}, (product) {
        expect(product.name, 'كيك التمر بالهيل');
        expect(product.price.display, contains('د.ك'));
      });
    });

    test('an unknown product is a not-found failure', () async {
      final result = await repository.getProduct('prd_missing');

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.statusCode, 404);
          expect(failure.message, 'product_not_found');
        },
        (_) => fail('expected a failure'),
      );
    });
  });

  group('ProductCubit', () {
    late _FakeProductRepository products;
    late _FakeFavouritesRepository favourites;
    late ProductCubit cubit;

    setUp(() {
      products = _FakeProductRepository(Right(_product()));
      favourites = _FakeFavouritesRepository();
      cubit = ProductCubit(
        GetProductUseCase(products),
        SetFavouriteUseCase(favourites),
      );
    });

    tearDown(() => cubit.close());

    test('a load shows the product with a quantity of one', () async {
      await cubit.load('prd_1');

      expect(cubit.state.status, ProductStatus.loaded);
      expect(cubit.state.product?.id, 'prd_1');
      expect(cubit.state.quantity, 1);
      expect(cubit.state.errorMessage, isNull);
    });

    test('a failed load is an error with the message', () async {
      products.answer = const Left(NetworkFailure(message: 'offline'));

      await cubit.load('prd_1');

      expect(cubit.state.status, ProductStatus.error);
      expect(cubit.state.errorMessage, 'offline');
      expect(cubit.state.product, isNull);
    });

    test('a retry reads the same product again', () async {
      products.answer = const Left(NetworkFailure(message: 'offline'));
      await cubit.load('prd_1');
      products.answer = Right(_product());

      await cubit.retry();

      expect(cubit.state.status, ProductStatus.loaded);
    });

    test('the quantity stays between one and the limit', () async {
      await cubit.load('prd_1');

      cubit.decrement();
      expect(cubit.state.quantity, 1);

      cubit
        ..increment()
        ..increment()
        ..increment()
        ..increment();
      expect(cubit.state.quantity, 3);
      expect(cubit.state.canIncrement, isFalse);

      cubit.decrement();
      expect(cubit.state.quantity, 2);
    });

    test('an out-of-stock product cannot be ordered', () async {
      products.answer = Right(_product(stock: 0, inStock: false));
      await cubit.load('prd_1');

      cubit.increment();

      expect(cubit.state.canOrder, isFalse);
      expect(cubit.state.quantity, 1);
      expect(cubit.state.canDecrement, isFalse);
    });

    test('a favourite shows at once and stays when confirmed', () async {
      await cubit.load('prd_1');

      final toggle = cubit.toggleFavourite();
      expect(cubit.state.product?.isFavourite, isTrue);
      expect(cubit.state.isSavingFavourite, isTrue);

      cubit.toggleFavourite();
      expect(favourites.calls, [true]);

      favourites.pending.complete(const Right(true));
      await toggle;

      expect(cubit.state.product?.isFavourite, isTrue);
      expect(cubit.state.isSavingFavourite, isFalse);
      expect(cubit.state.errorMessage, isNull);
    });

    test('a refused favourite rolls back and reports', () async {
      await cubit.load('prd_1');

      final toggle = cubit.toggleFavourite();
      favourites.pending.complete(
        const Left(ServerFailure(message: 'favourite_failed')),
      );
      await toggle;

      expect(cubit.state.product?.isFavourite, isFalse);
      expect(cubit.state.status, ProductStatus.loaded);
      expect(cubit.state.errorMessage, 'favourite_failed');
    });
  });

  group('product widgets', () {
    testWidgets('meta rows name the stock and the fulfilment', (tester) async {
      await _pump(
        tester,
        ProductMetaRows(product: _product(stock: 0, inStock: false)),
      );

      expect(find.text('product_out_of_stock'), findsOneWidget);
      expect(find.text('product_rating'), findsNothing);
      expect(
        ProductMetaRows.fulfilmentKey({Fulfilment.delivery, Fulfilment.pickup}),
        'fulfilment_delivery_or_pickup',
      );
      expect(
        ProductMetaRows.fulfilmentKey({Fulfilment.pickup}),
        'fulfilment_pickup',
      );
      expect(ProductMetaRows.fulfilmentKey({}), isNull);
    });

    testWidgets('reviews draw one card each, with stars', (tester) async {
      await _pump(
        tester,
        const ProductReviews(
          reviews: [
            Review(id: 'r1', authorName: 'Mariam A.', rating: 5, body: 'Fresh'),
            Review(id: 'r2', authorName: 'Abdullah H.', rating: 4, body: 'Ok'),
          ],
        ),
      );

      expect(find.byType(ReviewCard), findsNWidgets(2));
      expect(find.text('★★★★★'), findsOneWidget);
      expect(find.text('★★★★☆'), findsOneWidget);
    });

    testWidgets('the gallery draws a bar per image and follows the swipe',
        (tester) async {
      await _pump(
        tester,
        const ProductGallery(
          images: [ImageRef(url: ''), ImageRef(url: ''), ImageRef(url: '')],
        ),
      );

      Iterable<Color?> bars() => tester
          .widgetList<Container>(find.byWidgetPredicate(
            (w) => w is Container && w.constraints?.maxWidth == 22,
          ))
          .map((c) => c.color);

      expect(bars().length, 3);
      final first = bars().toList();
      expect(first[0], isNot(first[1]));

      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();

      final second = bars().toList();
      expect(second[1], first[0]);
      expect(second[0], first[1]);
    });
  });
}
