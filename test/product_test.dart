import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/core/exceptions/app_exceptions.dart';
import 'package:baytoti/core/network/api_endpoints.dart';
import 'package:baytoti/core/theme/app_theme.dart';
import 'package:baytoti/core/utils/money.dart';
import 'package:baytoti/core/utils/screen_util_scope.dart';
import 'package:baytoti/features/catalog/data/datasources/favourites_data_source.dart';
import 'package:baytoti/features/catalog/data/repositories/favourites_repository_impl.dart';
import 'package:baytoti/features/catalog/domain/entities/family_ref.dart';
import 'package:baytoti/features/catalog/domain/entities/image_ref.dart';
import 'package:baytoti/features/catalog/domain/entities/product_badge.dart';
import 'package:baytoti/features/catalog/domain/usecases/favourite_usecases.dart';
import 'package:baytoti/features/product/data/datasources/product_data_source.dart';
import 'package:baytoti/features/product/data/models/product_detail_model.dart';
import 'package:baytoti/features/product/data/repositories/product_repository_impl.dart';
import 'package:baytoti/features/product/domain/entities/product_detail.dart';
import 'package:baytoti/features/product/domain/usecases/product_usecases.dart';
import 'package:baytoti/features/product/presentation/cubit/product_cubit.dart';
import 'package:baytoti/features/product/presentation/cubit/product_state.dart';
import 'package:baytoti/features/product/presentation/widgets/product_gallery.dart';
import 'package:baytoti/features/product/presentation/widgets/product_meta_rows.dart';
import 'package:baytoti/features/product/presentation/widgets/product_reviews.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_network.dart';

const _food = 'product/food_detail.cloak_shape.json';
const _unavailable = 'product/food_detail_unavailable.cloak_shape.json';
const _foodSlug = 'kb-mkly-14';
const _unavailableSlug = 'mkbws-dgag-15';

Map<String, dynamic> _data(String sample) => Map<String, dynamic>.from(
      (apiSample(sample)! as Map)['data'] as Map,
    );

Map<String, dynamic> _envelope(Map<String, dynamic> data) =>
    {'success': true, 'message': '', 'data': data, 'errors': null};

ProductDetail _product({
  int? stock,
  bool inStock = true,
  int? maxPerOrder,
  int? preparationMinutes,
  double? rating,
  int? soldCount,
}) =>
    ProductDetail(
      id: '14',
      name: 'Fried kubba',
      price: const Money(fils: 4500),
      stock: stock,
      inStock: inStock,
      maxPerOrder: maxPerOrder,
      preparationMinutes: preparationMinutes,
      rating: rating,
      soldCount: soldCount,
      family: const FamilyRef(id: '1', name: 'Amira Kitchen'),
    );

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
}

class _PagedReviews extends FakeNetwork {
  final Map<int, List<Map<String, dynamic>>> pages;

  _PagedReviews(this.pages);

  @override
  Future<Response> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  }) async {
    calls.add(FakeCall('GET', url, queryParameters, null, headers));
    final page = queryParameters?['page'] as int? ?? 1;
    return Response<dynamic>(
      requestOptions: RequestOptions(path: url),
      statusCode: 200,
      data: {
        'success': true,
        'data': pages[page] ?? const [],
        'meta': {
          'current_page': page,
          'last_page': pages.length,
          'per_page': ProductRemoteDataSource.reviewPageSize,
          'total': pages.length,
        },
      },
    );
  }
}

Map<String, dynamic> _reviewJson(int id, {required int author}) => {
      'id': id,
      'rating': 4,
      'comment': 'review $id',
      'user': {'id': author, 'name': 'User $author'},
    };

FakeNetwork _backend() => FakeNetwork()
  ..replySample('GET', ApiEndPoint.product(_foodSlug), _food)
  ..replySample('GET', ApiEndPoint.product(_unavailableSlug), _unavailable)
  ..replySample(
    'GET',
    ApiEndPoint.productReviews('14'),
    'product/reviews.cloak_shape.json',
  )
  ..replySample(
    'GET',
    ApiEndPoint.productReviews('15'),
    'product/reviews.cloak_shape.json',
  )
  ..replySample('GET', ApiEndPoint.wishlist, 'wishlist/wishlist.cloak_shape.json')
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

ProductRepositoryImpl _repository(FakeNetwork network) => ProductRepositoryImpl(
      ProductRemoteDataSource(network),
      FavouritesRemoteDataSource(network),
    );

ProductCubit _cubit(FakeNetwork network) {
  final repository = _repository(network);

  return ProductCubit(
    GetProductUseCase(repository),
    GetProductReviewsUseCase(repository),
    SetFavouriteUseCase(
      FavouritesRepositoryImpl(FavouritesRemoteDataSource(network)),
    ),
  );
}

Failure _failure<T>(Either<Failure, T> result) =>
    result.fold((failure) => failure, (value) => fail('expected a failure'));

T _value<T>(Either<Failure, T> result) =>
    result.getOrElse(() => fail('expected a value, got $result'));

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
  group('ProductDetailModel reads the real shapes', () {
    test('the live engine detail parses without its colours', () {
      final product =
          ProductDetailModel.fromJson(_data('cloak/product_detail.json'));

      expect(product.id, '32');
      expect(product.slug, 'aabay-mnasbat-fakhr-6');
      expect(product.name, isNotEmpty);
      expect(product.description, isNotEmpty);
      expect(product.price.fils, 55000);
      expect(product.compareAt?.fils, 65000);
      expect(product.badge, ProductBadge.featured);
      expect(product.images, isEmpty);
      expect(product.family.id, '6');
      expect(product.family.slug, 'mkhml-6');
      expect(product.family.name, 'مخمل');
      expect(product.rating, isNull);
      expect(product.soldCount, isNull);
      expect(product.stock, isNull);
      expect(product.preparationMinutes, isNull);
      expect(product.fulfilment, isEmpty);
      expect(product.inStock, isTrue);
      expect(product.maxQuantity, ProductDetail.quantityCeiling);
      expect(product.isFavourite, isFalse);
    });

    test('a food product reads its base price, photos and preparation', () {
      final product = ProductDetailModel.fromJson(_data(_food));

      expect(product.id, '14');
      expect(product.slug, _foodSlug);
      expect(product.price.fils, 4500);
      expect(product.compareAt?.fils, 5250);
      expect(product.badge, isNull);
      expect(product.preparationMinutes, 45);
      expect(product.inStock, isTrue);
      expect(product.canOrder, isTrue);
      expect(product.description, startsWith('كبة محضرة'));
      expect(product.images.map((i) => i.alt), ['كبة مقلية', isNotEmpty]);
      expect(product.images.first.url, contains('photo-1541518763669'));
      expect(product.family.slug, 'mtbkh-amyr-1');
      expect(product.family.isVerified, isTrue);
      expect(product.family.images.firstUrl, contains('photo-1556910103'));
    });

    test('an unavailable product cannot be ordered', () {
      final product = ProductDetailModel.fromJson(_data(_unavailable));

      expect(product.inStock, isFalse);
      expect(product.canOrder, isFalse);
      expect(product.compareAt, isNull);
      expect(product.badge, ProductBadge.featured);
      expect(product.preparationMinutes, 1440);
      expect(product.description, 'مكبوس دجاج بالبهارات الكويتية.');
      expect(product.images, isEmpty);
    });

    test('counts the design shows are read when the server sends them', () {
      final product = ProductDetailModel.fromJson({
        ..._data(_food),
        'stock': 6,
        'max_per_order': 4,
        'sold_count': 212,
        'average_rating': 4.8,
        'fulfilment': ['pickup', 'drone'],
        'is_favorite': true,
      });

      expect(product.stock, 6);
      expect(product.maxPerOrder, 4);
      expect(product.maxQuantity, 4);
      expect(product.soldCount, 212);
      expect(product.rating, 4.8);
      expect(product.fulfilment, {Fulfilment.pickup});
      expect(product.isFavourite, isTrue);
    });

    test('a product without an id is refused', () {
      expect(
        () => ProductDetailModel.fromJson(const {'name': 'x'}),
        throwsFormatException,
      );
    });

    test('the quantity is limited by stock, the order cap and the ceiling', () {
      expect(_product(stock: 2, maxPerOrder: 10).maxQuantity, 2);
      expect(_product(stock: 30, maxPerOrder: 10).maxQuantity, 10);
      expect(_product().maxQuantity, ProductDetail.quantityCeiling);
      expect(_product(stock: 5, inStock: false).maxQuantity, 0);
      expect(_product(stock: 0).canOrder, isFalse);
    });

    test('reviews read the nested reviewer and the comment', () {
      final reviews = ReviewModel.listFrom(
        (apiSample('product/reviews.cloak_shape.json')! as Map)['data'],
      );

      expect(reviews.length, 2);
      expect(reviews.first.id, '7');
      expect(reviews.first.authorName, 'نور العلي');
      expect(reviews.first.authorId, '3');
      expect(reviews.first.rating, 5);
      expect(reviews.first.body, startsWith('الكبة'));
      expect(reviews.first.stars, '★★★★★');
      expect(reviews.last.authorName, 'سارة');
      expect(reviews.last.body, isEmpty);
      expect(reviews.last.stars, '★★★★☆');
    });
  });

  group('ProductRemoteDataSource', () {
    late FakeNetwork network;
    late ProductRemoteDataSource source;

    setUp(() {
      network = _backend();
      source = ProductRemoteDataSource(network);
    });

    test('a product is read by its slug', () async {
      final product = _value(await source.getProduct(_foodSlug));

      expect(product.id, '14');
      expect(network.last('GET').url, ApiEndPoint.product(_foodSlug));
    });

    test('an unknown slug is a not-found failure', () async {
      network.replySample(
        'GET',
        ApiEndPoint.product('no-such-slug'),
        'product/not_found_404.cloak_shape.json',
        status: 404,
      );

      final failure = _failure(await source.getProduct('no-such-slug'));

      expect(failure, isA<ServerFailure>());
      expect(failure.statusCode, 404);
      expect(failure.message, 'product_not_found');
    });

    test('a server error stays generic', () async {
      network.replySample(
        'GET',
        ApiEndPoint.product(_foodSlug),
        'betouti/products_guest_500.json',
        status: 500,
      );

      final failure = _failure(await source.getProduct(_foodSlug));

      expect(failure.statusCode, 500);
      expect(failure.message, 'server_error');
    });

    test('a signed-out answer is a 401 failure', () async {
      network.replySample(
        'GET',
        ApiEndPoint.product(_foodSlug),
        'betouti/unauthenticated_401.json',
        status: 401,
      );

      expect(_failure(await source.getProduct(_foodSlug)).statusCode, 401);
    });

    test('offline is a network failure', () async {
      final offline =
          ProductRemoteDataSource(_BrokenNetwork(const ConnectionException()));

      expect(
        _failure(await offline.getProduct(_foodSlug)),
        isA<NetworkFailure>(),
      );
      expect(
        _failure(await offline.getReviews(const ReviewsQuery(productId: '14'))),
        isA<NetworkFailure>(),
      );
    });

    test('a payload without an id is an unexpected failure', () async {
      network.reply(
        'GET',
        ApiEndPoint.product(_foodSlug),
        body: _envelope({'name': 'x'}),
      );

      final failure = _failure(await source.getProduct(_foodSlug));

      expect(failure, isA<UnexpectedFailure>());
      expect(failure.message, 'product_failed');
    });

    test('reviews are read by product id, one large page when nobody is '
        'looked for', () async {
      final digest =
          _value(await source.getReviews(const ReviewsQuery(productId: '14')));

      expect(digest.latest.length, 2);
      expect(digest.mine, isNull);
      expect(network.calls, hasLength(1));
      expect(network.last('GET').url, ApiEndPoint.productReviews('14'));
      expect(network.last('GET').query, {
        'page': 1,
        'per_page': ProductRemoteDataSource.reviewPageSize,
      });
    });

    test('your own review is found on the first page without asking again',
        () async {
      final digest = _value(await source.getReviews(
        const ReviewsQuery(productId: '14', authorId: '5'),
      ));

      expect(digest.mine?.id, '9');
      expect(digest.mine?.authorId, '5');
      expect(network.calls, hasLength(1));
    });

    test('your own review is looked for on the next pages', () async {
      final paged = _PagedReviews({
        1: [_reviewJson(1, author: 3), _reviewJson(2, author: 4)],
        2: [_reviewJson(3, author: 6)],
        3: [_reviewJson(4, author: 18)],
      });

      final digest = _value(await ProductRemoteDataSource(paged).getReviews(
        const ReviewsQuery(productId: '14', authorId: '18'),
      ));

      expect(digest.mine?.id, '4');
      expect(digest.latest.map((r) => r.id), ['1', '2']);
      expect(paged.calls.map((c) => c.query?['page']), [1, 2, 3]);
    });

    test('the search gives up after a few pages', () async {
      final paged = _PagedReviews({
        for (var page = 1; page <= 9; page++) page: [_reviewJson(page, author: 3)],
      });

      final digest = _value(await ProductRemoteDataSource(paged).getReviews(
        const ReviewsQuery(productId: '14', authorId: '18'),
      ));

      expect(digest.mine, isNull);
      expect(paged.calls, hasLength(ProductRemoteDataSource.reviewScanPages));
    });

    test('a reviews answer without a list is a failure', () async {
      network.reply(
        'GET',
        ApiEndPoint.productReviews('14'),
        body: _envelope({'id': 1}),
      );

      expect(
        _failure(await source.getReviews(const ReviewsQuery(productId: '14'))),
        isA<UnexpectedFailure>(),
      );
    });
  });

  group('ProductRepositoryImpl', () {
    test('a product in the wishlist comes back saved', () async {
      final network = _backend();

      final product = _value(await _repository(network).getProduct(_foodSlug));

      expect(product.isFavourite, isTrue);
      expect(
        network.calls.map((c) => c.url),
        containsAll([ApiEndPoint.wishlist, ApiEndPoint.product(_foodSlug)]),
      );
    });

    test('a product missing from the wishlist is not saved', () async {
      final product = _value(
        await _repository(_backend()).getProduct(_unavailableSlug),
      );

      expect(product.isFavourite, isFalse);
    });

    test('an unreadable wishlist does not hide the product', () async {
      final network = _backend()
        ..replySample(
          'GET',
          ApiEndPoint.wishlist,
          'betouti/products_guest_500.json',
          status: 500,
        );

      final product = _value(await _repository(network).getProduct(_foodSlug));

      expect(product.id, '14');
      expect(product.isFavourite, isFalse);
    });

    test('a missing product is a failure whatever the wishlist says',
        () async {
      final network = _backend()
        ..replySample(
          'GET',
          ApiEndPoint.product(_foodSlug),
          'product/not_found_404.cloak_shape.json',
          status: 404,
        );

      final failure =
          _failure(await _repository(network).getProduct(_foodSlug));

      expect(failure.message, 'product_not_found');
    });
  });

  group('ProductCubit', () {
    late FakeNetwork network;
    late ProductCubit cubit;

    setUp(() {
      network = _backend();
      cubit = _cubit(network);
    });

    tearDown(() => cubit.close());

    test('a load shows the product, whether it is saved, and its reviews',
        () async {
      await cubit.load(_foodSlug);

      expect(cubit.state.status, ProductStatus.loaded);
      expect(cubit.state.product?.id, '14');
      expect(cubit.state.product?.isFavourite, isTrue);
      expect(cubit.state.quantity, 1);
      expect(cubit.state.reviews.length, 2);
      expect(cubit.state.reviewsLoaded, isTrue);
      expect(cubit.state.myReview, isNull);
      expect(cubit.state.isLoadingReviews, isFalse);
      expect(cubit.state.errorMessage, isNull);
      expect(network.last('GET').url, ApiEndPoint.productReviews('14'));
    });

    test('a signed-in reader finds their own review', () async {
      await cubit.load(_foodSlug, customerId: '3');

      expect(cubit.state.myReview?.id, '7');
    });

    test('a saved review becomes yours at once', () async {
      await cubit.load(_foodSlug, customerId: '99');
      expect(cubit.state.myReview, isNull);

      cubit.reviewSaved(const Review(
        id: '31',
        authorName: '',
        rating: 4,
        body: 'Lovely',
      ));

      expect(cubit.state.myReview?.id, '31');
      expect(cubit.state.reviews.length, 2);
    });

    test('failing reviews keep the product and show none', () async {
      network.replySample(
        'GET',
        ApiEndPoint.productReviews('14'),
        'betouti/products_guest_500.json',
        status: 500,
      );

      await cubit.load(_foodSlug);

      expect(cubit.state.status, ProductStatus.loaded);
      expect(cubit.state.reviews, isEmpty);
      expect(cubit.state.reviewsLoaded, isFalse);
      expect(cubit.state.isLoadingReviews, isFalse);
      expect(cubit.state.errorMessage, isNull);
    });

    test('a failed load is an error and asks for no reviews', () async {
      network.replySample(
        'GET',
        ApiEndPoint.product(_foodSlug),
        'product/not_found_404.cloak_shape.json',
        status: 404,
      );

      await cubit.load(_foodSlug);

      expect(cubit.state.status, ProductStatus.error);
      expect(cubit.state.errorMessage, 'product_not_found');
      expect(cubit.state.product, isNull);
      expect(
        network.calls.map((c) => c.url),
        isNot(contains(ApiEndPoint.productReviews('14'))),
      );
    });

    test('a retry reads the same slug again', () async {
      network.replySample(
        'GET',
        ApiEndPoint.product(_foodSlug),
        'betouti/products_guest_500.json',
        status: 500,
      );
      await cubit.load(_foodSlug);
      network.replySample('GET', ApiEndPoint.product(_foodSlug), _food);

      await cubit.retry();

      expect(cubit.state.status, ProductStatus.loaded);
      expect(cubit.state.product?.slug, _foodSlug);
    });

    test('the quantity stays between one and the order cap', () async {
      network.reply(
        'GET',
        ApiEndPoint.product(_foodSlug),
        body: _envelope({..._data(_food), 'max_per_order': 3}),
      );
      await cubit.load(_foodSlug);

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

    test('an unavailable product cannot be ordered', () async {
      await cubit.load(_unavailableSlug);

      cubit.increment();

      expect(cubit.state.canOrder, isFalse);
      expect(cubit.state.quantity, 1);
      expect(cubit.state.canDecrement, isFalse);
    });

    test('unsaving shows at once and removes the wishlist row', () async {
      await cubit.load(_foodSlug);

      final toggle = cubit.toggleFavourite();
      expect(cubit.state.product?.isFavourite, isFalse);
      expect(cubit.state.isSavingFavourite, isTrue);

      await cubit.toggleFavourite();
      await toggle;

      expect(cubit.state.product?.isFavourite, isFalse);
      expect(cubit.state.isSavingFavourite, isFalse);
      expect(cubit.state.errorMessage, isNull);
      expect(network.last('DELETE').url, ApiEndPoint.wishlistItem('7'));
      expect(network.calls.where((c) => c.method == 'DELETE').length, 1);
    });

    test('saving posts the product id', () async {
      await cubit.load(_unavailableSlug);

      await cubit.toggleFavourite();

      expect(cubit.state.product?.isFavourite, isTrue);
      expect(network.last('POST').data, {'product_id': 15});
    });

    test('a refused save rolls back and reports', () async {
      network.replySample(
        'POST',
        ApiEndPoint.wishlistItems,
        'betouti/products_guest_500.json',
        status: 500,
      );
      await cubit.load(_unavailableSlug);

      await cubit.toggleFavourite();

      expect(cubit.state.product?.isFavourite, isFalse);
      expect(cubit.state.status, ProductStatus.loaded);
      expect(cubit.state.errorMessage, 'server_error');
    });
  });

  group('product widgets', () {
    testWidgets('meta rows show only what the server sent', (tester) async {
      await _pump(
        tester,
        ProductMetaRows(product: _product(preparationMinutes: 45)),
      );

      expect(find.text('product_preparation'), findsOneWidget);
      expect(find.text('product_preparation_minutes'), findsOneWidget);
      expect(find.text('product_stock'), findsNothing);
      expect(find.text('product_rating'), findsNothing);
      expect(find.text('product_fulfilment'), findsNothing);
    });

    testWidgets('an unavailable product says so', (tester) async {
      await _pump(
        tester,
        ProductMetaRows(product: _product(inStock: false)),
      );

      expect(find.text('product_out_of_stock'), findsOneWidget);
    });

    test('the meta values read the optional fields', () {
      expect(ProductMetaRows.preparation(null), isNull);
      expect(ProductMetaRows.preparation(0), isNull);
      expect(ProductMetaRows.preparation(1440), 'product_preparation_hours');
      expect(ProductMetaRows.preparation(90), 'product_preparation_minutes');
      expect(ProductMetaRows.stock(_product()), isNull);
      expect(ProductMetaRows.stock(_product(stock: 4)), 'product_in_stock');
      expect(ProductMetaRows.rating(_product()), isNull);
      expect(ProductMetaRows.rating(_product(rating: 4.8)), '★ 4.8');
      expect(
        ProductMetaRows.rating(_product(rating: 4.8, soldCount: 12)),
        'product_rating_value',
      );
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

    const others = [
      Review(id: 'r1', authorName: 'Mariam A.', rating: 5, body: 'Fresh'),
      Review(id: 'r2', authorName: 'Abdullah H.', rating: 4, body: ''),
    ];

    testWidgets('reviews draw one card each, with stars, and offer to add one',
        (tester) async {
      await _pump(
        tester,
        ProductReviews(product: _product(), reviews: others, onSaved: (_) {}),
      );

      expect(find.byType(ReviewCard), findsNWidgets(2));
      expect(find.text('★★★★★'), findsOneWidget);
      expect(find.text('★★★★☆'), findsOneWidget);
      expect(find.text('Fresh'), findsOneWidget);
      expect(find.text(''), findsNothing);
      expect(find.text('review_add'), findsOneWidget);
      expect(find.text('review_edit'), findsNothing);
    });

    testWidgets('your review leads, once, and the button offers to edit it',
        (tester) async {
      await _pump(
        tester,
        ProductReviews(
          product: _product(),
          reviews: others,
          mine: others.last,
          onSaved: (_) {},
        ),
      );

      final cards = tester.widgetList<ReviewCard>(find.byType(ReviewCard));
      expect(cards.map((c) => (c.review.id, c.isMine)), [
        ('r2', true),
        ('r1', false),
      ]);
      expect(find.text('review_yours'), findsOneWidget);
      expect(find.text('Abdullah H.'), findsNothing);
      expect(find.text('review_edit'), findsOneWidget);
      expect(find.text('review_add'), findsNothing);
    });

    testWidgets('no reviews yet still offers to add the first', (tester) async {
      await _pump(
        tester,
        ProductReviews(product: _product(), reviews: const [], onSaved: (_) {}),
      );

      expect(find.byType(ReviewCard), findsNothing);
      expect(find.text('product_reviews_empty'), findsOneWidget);
      expect(find.text('review_add'), findsOneWidget);
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
