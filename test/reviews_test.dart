import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/core/exceptions/app_exceptions.dart';
import 'package:baytoti/core/network/api_endpoints.dart';
import 'package:baytoti/core/theme/app_theme.dart';
import 'package:baytoti/core/utils/screen_util_scope.dart';
import 'package:baytoti/core/widgets/sheet_error_note.dart';
import 'package:baytoti/features/product/domain/entities/product_detail.dart';
import 'package:baytoti/features/reviews/data/datasources/reviews_data_source.dart';
import 'package:baytoti/features/reviews/data/repositories/reviews_repository_impl.dart';
import 'package:baytoti/features/reviews/domain/entities/review_draft.dart';
import 'package:baytoti/features/reviews/domain/usecases/reviews_usecases.dart';
import 'package:baytoti/features/reviews/presentation/cubit/review_form_cubit.dart';
import 'package:baytoti/features/reviews/presentation/widgets/review_sheet.dart';
import 'package:baytoti/features/reviews/presentation/widgets/star_rating_picker.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'support/fake_network.dart';

class _OfflineNetwork extends FakeNetwork {
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

Map<String, dynamic> _envelope(Object? data) => {
      'success': true,
      'message': 'Review saved.',
      'data': data,
      'errors': null,
    };

Map<String, dynamic> _review({int id = 31, int rating = 4, String? comment}) => {
      'id': id,
      'rating': rating,
      'comment': comment,
      'is_verified_purchase': true,
      'status': 'approved',
      'user': {'id': 18, 'name': 'Noura'},
      'product_id': 14,
      'order_id': 11,
    };

Map<String, dynamic> _refused(Map<String, List<String>> errors) => {
      'success': false,
      'message': errors.values.first.first,
      'data': null,
      'errors': errors,
    };

const Review _existing = Review(
  id: '7',
  authorId: '18',
  authorName: 'Noura',
  rating: 5,
  body: 'Fresh and warm',
);

T _right<T>(Either<Failure, T> result) =>
    result.fold((failure) => throw StateError('$failure'), (value) => value);

Failure _left<T>(Either<Failure, T> result) =>
    result.fold((failure) => failure, (value) => throw StateError('$value'));

void main() {
  late FakeNetwork network;
  late ReviewsRepositoryImpl repository;

  setUp(() {
    network = FakeNetwork();
    repository = ReviewsRepositoryImpl(ReviewsRemoteDataSource(network));
  });

  group('writing a review', () {
    test('a new review posts the product, the order, the rating and comment',
        () async {
      network.reply(
        'POST',
        ApiEndPoint.reviews,
        body: _envelope(_review(comment: 'Lovely')),
      );

      final saved = _right(await repository.submit(const ReviewDraft(
        productId: '14',
        orderId: '11',
        rating: 4,
        comment: '  Lovely ',
      )));

      expect(network.last('POST').data, {
        'product_id': 14,
        'order_id': 11,
        'rating': 4,
        'comment': 'Lovely',
      });
      expect(saved.id, '31');
      expect(saved.rating, 4);
      expect(saved.body, 'Lovely');
    });

    test('without an order or a comment only the product and rating go out',
        () async {
      network.reply('POST', ApiEndPoint.reviews, body: _envelope(_review()));

      await repository.submit(const ReviewDraft(
        productId: '14',
        rating: 5,
        comment: '   ',
      ));

      expect(network.last('POST').data, {'product_id': 14, 'rating': 5});
    });

    test('an edit patches that review, and a blank comment clears it',
        () async {
      network.reply(
        'PATCH',
        ApiEndPoint.review('7'),
        body: _envelope(_review(id: 7, rating: 3)),
      );

      final saved = _right(await repository.submit(const ReviewDraft(
        productId: '14',
        reviewId: '7',
        rating: 3,
        comment: ' ',
      )));

      expect(network.calls.single.method, 'PATCH');
      expect(network.last('PATCH').data, {'rating': 3, 'comment': null});
      expect(saved.id, '7');
    });

    test('an answer without the review keeps what was sent', () async {
      network.reply('PATCH', ApiEndPoint.review('7'), body: _envelope(null));

      final saved = _right(await repository.submit(const ReviewDraft(
        productId: '14',
        reviewId: '7',
        rating: 2,
        comment: 'Too salty',
      )));

      expect(saved.id, '7');
      expect(saved.rating, 2);
      expect(saved.body, 'Too salty');
    });

    test('a review the server does not allow says so plainly', () async {
      network.reply(
        'POST',
        ApiEndPoint.reviews,
        status: 403,
        body: {'success': false, 'message': 'This action is unauthorized.'},
      );

      final failure = _left(await repository.submit(
        const ReviewDraft(productId: '14', rating: 4),
      ));

      expect(failure.message, 'review_not_allowed');
    });

    test('a 422 hands each field its error', () async {
      network.reply(
        'POST',
        ApiEndPoint.reviews,
        status: 422,
        body: _refused({
          'rating': ['The rating field must be between 1 and 5.'],
        }),
      );

      final failure = _left(await repository.submit(
        const ReviewDraft(productId: '14', rating: 9),
      ));

      expect((failure as ValidationFailure).fieldErrors, {
        'rating': 'The rating field must be between 1 and 5.',
      });
    });

    test('offline is a network failure', () async {
      final offline =
          ReviewsRepositoryImpl(ReviewsRemoteDataSource(_OfflineNetwork()));

      expect(
        _left(await offline.submit(
          const ReviewDraft(productId: '14', rating: 4),
        )),
        isA<NetworkFailure>(),
      );
    });
  });

  group('ReviewFormCubit', () {
    late ReviewFormCubit cubit;

    setUp(() => cubit = ReviewFormCubit(SubmitReviewUseCase(repository)));

    tearDown(() => cubit.close());

    test('a save goes through saving to saved with the review', () async {
      network.reply('POST', ApiEndPoint.reviews, body: _envelope(_review()));
      final states = <ReviewFormStatus>[];
      final sub = cubit.stream.listen((s) => states.add(s.status));

      await cubit.save(const ReviewDraft(productId: '14', rating: 4));
      await Future<void>.delayed(Duration.zero);

      expect(states, [ReviewFormStatus.saving, ReviewFormStatus.saved]);
      expect(cubit.state.saved?.id, '31');
      await sub.cancel();
    });

    test('a second tap while saving sends nothing more', () async {
      network.reply('POST', ApiEndPoint.reviews, body: _envelope(_review()));
      const draft = ReviewDraft(productId: '14', rating: 4);

      await Future.wait([cubit.save(draft), cubit.save(draft)]);

      expect(network.calls, hasLength(1));
    });

    test('a 422 keeps the form open with the errors, and typing clears one',
        () async {
      network.reply(
        'POST',
        ApiEndPoint.reviews,
        status: 422,
        body: _refused({
          'comment': ['The comment is too long.'],
          'rating': ['The rating is required.'],
        }),
      );

      await cubit.save(const ReviewDraft(productId: '14', rating: 4));
      cubit.clearFieldError('comment');

      expect(cubit.state.status, ReviewFormStatus.editing);
      expect(cubit.state.fieldErrors.keys, {'rating'});
      expect(cubit.state.errorMessage, isNotNull);
    });
  });

  group('the review sheet', () {
    late List<Review?> results;

    setUp(() {
      results = [];
      GetIt.instance.registerFactory(
        () => ReviewFormCubit(SubmitReviewUseCase(repository)),
      );
    });

    tearDown(() => GetIt.instance.reset());

    Future<void> open(WidgetTester tester, ReviewTarget target) async {
      tester.view.physicalSize = const Size(900, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ScreenUtilScope(
        child: Builder(
          builder: (_) => MaterialApp(
            theme: AppTheme.light,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async =>
                      results.add(await showReviewSheet(context, target)),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    Finder star(int number) => find
        .descendant(
          of: find.byType(StarRatingPicker),
          matching: find.byType(InkResponse),
        )
        .at(number - 1);

    const newReview = ReviewTarget(
      productId: '14',
      productName: 'Fried kubba',
      orderId: '11',
    );

    testWidgets('it asks for a rating before sending anything',
        (tester) async {
      await open(tester, newReview);

      expect(find.text('review_add_title'), findsOne);
      expect(find.text('Fried kubba'), findsOne);
      expect(find.text('review_pick_rating'), findsOne);

      await tester.tap(find.text('review_submit'));
      await tester.pump();

      expect(find.text('review_rating_required'), findsOne);
      expect(network.calls, isEmpty);

      await tester.tap(star(3));
      await tester.pump();

      expect(find.text('review_rating_required'), findsNothing);
      expect(find.text('review_rating_3'), findsOne);
    });

    testWidgets('a rated review is sent and handed back as the sheet closes',
        (tester) async {
      network.reply(
        'POST',
        ApiEndPoint.reviews,
        body: _envelope(_review(comment: 'Lovely')),
      );
      await open(tester, newReview);

      await tester.tap(star(4));
      await tester.enterText(find.byType(TextField), 'Lovely');
      await tester.tap(find.text('review_submit'));
      await tester.pumpAndSettle();

      expect(network.last('POST').data, {
        'product_id': 14,
        'order_id': 11,
        'rating': 4,
        'comment': 'Lovely',
      });
      expect(find.byType(ReviewSheet), findsNothing);
      expect(results.single?.id, '31');
    });

    testWidgets('an edit opens with the review and patches it',
        (tester) async {
      network.reply(
        'PATCH',
        ApiEndPoint.review('7'),
        body: _envelope(_review(id: 7, rating: 2)),
      );
      await open(
        tester,
        const ReviewTarget(
          productId: '14',
          productName: 'Fried kubba',
          existing: _existing,
        ),
      );

      expect(find.text('review_edit_title'), findsOne);
      expect(find.text('review_rating_5'), findsOne);
      expect(find.text('Fresh and warm'), findsOne);

      await tester.tap(star(2));
      await tester.tap(find.text('review_update'));
      await tester.pumpAndSettle();

      expect(network.last('PATCH').data, {
        'rating': 2,
        'comment': 'Fresh and warm',
      });
      expect(results.single?.rating, 2);
    });

    testWidgets('a refused comment shows under it and the sheet stays open',
        (tester) async {
      network.reply(
        'POST',
        ApiEndPoint.reviews,
        status: 422,
        body: _refused({
          'comment': ['The comment may not be greater than 2000 characters.'],
        }),
      );
      await open(tester, newReview);

      await tester.tap(star(5));
      await tester.tap(find.text('review_submit'));
      await tester.pumpAndSettle();

      expect(
        find.text('The comment may not be greater than 2000 characters.'),
        findsOne,
      );
      expect(find.byType(SheetErrorNote), findsNothing);
      expect(find.byType(ReviewSheet), findsOne);
      expect(results, isEmpty);
    });

    testWidgets('a refusal with no field is a note in the sheet',
        (tester) async {
      network.reply(
        'POST',
        ApiEndPoint.reviews,
        status: 403,
        body: {'success': false, 'message': 'This action is unauthorized.'},
      );
      await open(tester, newReview);

      await tester.tap(star(5));
      await tester.tap(find.text('review_submit'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(SheetErrorNote),
          matching: find.text('review_not_allowed'),
        ),
        findsOne,
      );
      expect(find.byType(ReviewSheet), findsOne);
    });
  });
}
