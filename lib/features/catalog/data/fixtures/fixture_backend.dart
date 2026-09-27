import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/utils/app_assets.dart';
import '../../../../core/utils/money.dart';
import 'fixture_data.dart';

class _Line {
  final String productId;
  int quantity;

  _Line(this.productId, this.quantity);
}

class _Order {
  final String id;
  final String reference;
  final String familyId;
  final List<_Line> lines;
  final String fulfilment;
  int stepIndex;
  bool rated = false;

  _Order({
    required this.id,
    required this.reference,
    required this.familyId,
    required this.lines,
    required this.fulfilment,
    required this.stepIndex,
  });
}

class FixtureBackend {
  static const Duration latency = Duration(milliseconds: 350);
  static const String validCoupon = 'BAYT10';
  static const int couponDiscountFils = 500;
  static const int deliveryFeeFils = 1500;

  final Set<String> _favourites = {'prd_4'};
  final Set<String> _following = {'fam_3'};
  final List<_Line> _cart = [_Line('prd_1', 1), _Line('prd_3', 2)];
  String? _coupon = validCoupon;
  final Set<String> _readNotifications = {};
  final Map<String, (String, String, String?)> _otpRequests = {};
  String _customerName = FixtureData.defaultCustomerName;
  String _customerPhone = FixtureData.defaultCustomerPhone;
  int _nextOrder = 2042;

  late final List<_Order> _orders = [
    _Order(
      id: 'ord_2041',
      reference: 'BT-2041',
      familyId: 'fam_1',
      lines: [_Line('prd_1', 1), _Line('prd_3', 2)],
      fulfilment: 'delivery',
      stepIndex: 2,
    ),
    _Order(
      id: 'ord_1998',
      reference: 'BT-1998',
      familyId: 'fam_4',
      lines: [_Line('prd_5', 2), _Line('prd_2', 1)],
      fulfilment: 'delivery',
      stepIndex: 4,
    ),
  ];

  Future<void> wait() => Future<void>.delayed(latency);

  FixtureProduct _product(String id, String lang) =>
      FixtureData.products.firstWhere(
        (p) => p.id == id,
        orElse: () => throw RequestException(
          lang == 'ar' ? 'هذا المنتج لم يعد متاحاً.' : 'This product is no longer available.',
          code: 'not_found',
          statusCode: 404,
        ),
      );

  FixtureFamily _family(String id, String lang) =>
      FixtureData.families.firstWhere(
        (f) => f.id == id,
        orElse: () => throw RequestException(
          lang == 'ar' ? 'متجر الأسرة غير موجود.' : 'This family store does not exist.',
          code: 'not_found',
          statusCode: 404,
        ),
      );

  Map<String, dynamic> _image(String url, int size, String alt, {int? height}) =>
      {'url': url, 'width': size, 'height': height ?? size, 'alt': alt};

  Map<String, dynamic> _productImage(FixtureProduct p, String lang) =>
      _image(AppAssets.productPhoto(p.id), 800, p.name.of(lang));

  Map<String, dynamic> _familyAvatar(FixtureFamily f, String lang) =>
      _image(AppAssets.familyAvatar(f.id), 320, f.name.of(lang));

  Map<String, dynamic> _familyCover(FixtureFamily f, String lang) => _image(
        AppAssets.familyPhoto(f.id),
        1200,
        f.name.of(lang),
        height: 600,
      );

  Map<String, dynamic> _money(String key, int fils, String lang) => {
        '${key}_fils': fils,
        '${key}_display': Money.format(fils, lang),
      };

  Map<String, dynamic> productSummary(FixtureProduct p, String lang) {
    final family = _family(p.familyId, lang);
    return {
      'id': p.id,
      'name': p.name.of(lang),
      'family': {
        'id': family.id,
        'name': family.name.of(lang),
        'city': family.city.of(lang),
      },
      ..._money('price', p.priceFils, lang),
      ..._money('compare_at', p.compareAtFils, lang),
      'badge': p.badge,
      'rating': p.rating,
      'in_stock': p.stock > 0,
      'images': [_productImage(p, lang)],
      'is_favourite': _favourites.contains(p.id),
    };
  }

  Map<String, dynamic> _familySummary(FixtureFamily f, String lang) => {
        'id': f.id,
        'name': f.name.of(lang),
        'city': f.city.of(lang),
        'rating': f.rating,
        'product_count': f.productCount,
        'is_verified': true,
        'images': [_familyCover(f, lang)],
      };

  Map<String, dynamic> home(String lang) => {
        'banner': {
          'kind': 'exhibition',
          'id': 'exh_9',
          'kicker': FixtureData.bannerKicker.of(lang),
          'title': FixtureData.bannerTitle.of(lang),
          'subtitle': FixtureData.bannerSubtitle.of(lang),
          'date_display': FixtureData.bannerDate.of(lang),
          'action': {
            'label': FixtureData.bannerAction.of(lang),
            'type': 'qr_scan',
          },
        },
        'categories': [
          for (final c in FixtureData.categories)
            {
              'id': c.id,
              'name': c.name.of(lang),
              'icon': c.icon,
              'product_count': c.productCount,
            },
        ],
        'featured_families': [
          for (final f in FixtureData.families) _familySummary(f, lang),
        ],
        'best_sellers': [
          for (final p in FixtureData.products) productSummary(p, lang),
        ],
      };

  Map<String, dynamic> explore(String tab, String lang) {
    final ordered = switch (tab) {
      'weekly' => [...FixtureData.products]..sort((a, b) => b.sold.compareTo(a.sold)),
      'new' => FixtureData.products.where((p) => p.badge == 'new').toList(),
      'nearby' => FixtureData.products.where((p) => p.familyId == 'fam_1' || p.familyId == 'fam_2').toList(),
      _ => FixtureData.products,
    };

    return {
      'hashtags': FixtureData.hashtags.of(lang).split('|'),
      'rising': [
        for (var i = 0; i < ordered.length && i < 4; i++)
          {
            'rank': i + 1,
            'product': productSummary(ordered[i], lang),
            'growth_display': ordered[i].growth,
          },
      ],
      'most_viewed': [
        for (final p in [...FixtureData.products, ...FixtureData.products.take(3)])
          productSummary(p, lang),
      ],
      'next_cursor': null,
    };
  }

  Map<String, dynamic> search({
    required String lang,
    String? query,
    String? categoryId,
    String? city,
    double? minRating,
    String sort = 'relevance',
  }) {
    final q = query?.trim().toLowerCase() ?? '';
    final matches = FixtureData.products.where((p) {
      final family = _family(p.familyId, lang);
      if (q.isNotEmpty &&
          !p.name.of(lang).toLowerCase().contains(q) &&
          !family.name.of(lang).toLowerCase().contains(q)) {
        return false;
      }
      if (categoryId != null && p.categoryId != categoryId) return false;
      if (city != null && family.city.of(lang) != city) return false;
      if (minRating != null && p.rating < minRating) return false;
      return true;
    }).toList();

    switch (sort) {
      case 'top_rated':
        matches.sort((a, b) => b.rating.compareTo(a.rating));
      case 'price_asc':
        matches.sort((a, b) => a.priceFils.compareTo(b.priceFils));
      case 'price_desc':
        matches.sort((a, b) => b.priceFils.compareTo(a.priceFils));
    }

    final prices = matches.map((p) => p.priceFils).toList()..sort();

    return {
      'total': matches.length,
      'facets': {
        'categories': [
          for (final c in FixtureData.categories)
            {
              'id': c.id,
              'name': c.name.of(lang),
              'count': matches.where((p) => p.categoryId == c.id).length,
            },
        ],
        'cities': [
          for (final f in FixtureData.families)
            {
              'value': f.city.of(lang),
              'count': matches.where((p) => p.familyId == f.id).length,
            },
        ],
        'price_range_fils': {
          'min': prices.isEmpty ? 0 : prices.first,
          'max': prices.isEmpty ? 0 : prices.last,
        },
      },
      'items': [for (final p in matches) productSummary(p, lang)],
      'next_cursor': null,
    };
  }

  Map<String, dynamic> product(String id, String lang) {
    final p = _product(id, lang);
    final family = _family(p.familyId, lang);

    return {
      ...productSummary(p, lang),
      'description': p.description.of(lang),
      'rating_count': (p.sold * .3).round(),
      'sold_count': p.sold,
      'stock': p.stock,
      'preparation_time_display': FixtureData.preparation.of(lang),
      'fulfilment': const ['delivery', 'pickup'],
      'max_per_order': p.stock < 10 ? p.stock : 10,
      'family': {
        'id': family.id,
        'name': family.name.of(lang),
        'city': family.city.of(lang),
        'rating': family.rating,
        'is_verified': true,
        'avatar': _familyAvatar(family, lang),
      },
      'reviews_preview': [
        for (var i = 0; i < FixtureData.reviews.length; i++)
          {
            'id': 'rev_${i + 4}',
            'author_name': FixtureData.reviews[i].$1.of(lang),
            'rating': FixtureData.reviews[i].$2,
            'body': FixtureData.reviews[i].$3.of(lang),
            'created_display': FixtureData.reviewAge.of(lang),
          },
      ],
    };
  }

  Map<String, dynamic> family(String id, String lang) {
    final f = _family(id, lang);
    return {
      'id': f.id,
      'name': f.name.of(lang),
      'story': f.story.of(lang),
      'city': f.city.of(lang),
      'is_verified': true,
      'cover': _familyCover(f, lang),
      'avatar': _familyAvatar(f, lang),
      'stats': {
        'product_count': f.productCount,
        'rating': f.rating,
        'follower_count': f.followerCount + (_following.contains(id) ? 1 : 0),
      },
      'is_following': _following.contains(id),
    };
  }

  Map<String, dynamic> familyProducts(String id, String lang) {
    _family(id, lang);
    final own = FixtureData.products.where((p) => p.familyId == id);
    final others = FixtureData.products.where((p) => p.familyId != id);
    return {
      'items': [
        for (final p in [...own, ...others].take(4)) productSummary(p, lang),
      ],
      'next_cursor': null,
    };
  }

  void follow(String id, {required bool following, required String lang}) {
    _family(id, lang);
    following ? _following.add(id) : _following.remove(id);
  }

  Map<String, dynamic> setFavourite(
    String productId, {
    required bool favourite,
    required String lang,
  }) {
    _product(productId, lang);
    favourite ? _favourites.add(productId) : _favourites.remove(productId);
    return {'is_favourite': favourite, 'count': _favourites.length};
  }

  Map<String, dynamic> _totals(List<_Line> lines, String lang, {
    required bool delivery,
    required int discount,
  }) {
    final subtotal = lines.fold<int>(
      0,
      (sum, line) => sum + _product(line.productId, lang).priceFils * line.quantity,
    );
    final shipping = lines.isEmpty || !delivery ? 0 : deliveryFeeFils;
    final applied = lines.isEmpty ? 0 : discount;
    return {
      ..._money('subtotal', subtotal, lang),
      ..._money('discount', applied, lang),
      ..._money('shipping', shipping, lang),
      ..._money('total', subtotal - applied + shipping, lang),
    };
  }

  Map<String, dynamic> _lineJson(_Line line, String lang) {
    final p = _product(line.productId, lang);
    final family = _family(p.familyId, lang);
    return {
      'id': 'ci_${p.id}',
      'product_id': p.id,
      'name': p.name.of(lang),
      'family': {'id': family.id, 'name': family.name.of(lang)},
      'image': _productImage(p, lang),
      ..._money('unit_price', p.priceFils, lang),
      'quantity': line.quantity,
      ..._money('line_total', p.priceFils * line.quantity, lang),
      'max_quantity': p.stock < 10 ? p.stock : 10,
    };
  }

  Map<String, dynamic> cart(String lang) => {
        'id': 'crt_55',
        'items': [for (final line in _cart) _lineJson(line, lang)],
        'coupon': _coupon == null || _cart.isEmpty
            ? null
            : {'code': _coupon, 'discount_fils': couponDiscountFils},
        'totals': _totals(
          _cart,
          lang,
          delivery: true,
          discount: _coupon == null ? 0 : couponDiscountFils,
        ),
        'item_count': _cart.length,
      };

  _Line _lineById(String itemId, String lang) => _cart.firstWhere(
        (l) => 'ci_${l.productId}' == itemId,
        orElse: () => throw RequestException(
          lang == 'ar' ? 'هذا المنتج لم يعد في السلة.' : 'This item is no longer in the cart.',
          code: 'not_found',
          statusCode: 404,
        ),
      );

  void _checkStock(FixtureProduct p, int quantity, String lang) {
    final max = p.stock < 10 ? p.stock : 10;
    if (quantity <= max) return;
    throw RequestException(
      lang == 'ar' ? 'الكمية المطلوبة غير متوفرة' : 'The requested quantity is not available',
      code: 'stock_insufficient',
      statusCode: 422,
      errors: {'quantity': lang == 'ar' ? 'المتاح $max' : '$max available'},
      details: {'available': max},
    );
  }

  Map<String, dynamic> addToCart(String productId, int quantity, String lang) {
    final p = _product(productId, lang);
    final existing = _cart.where((l) => l.productId == productId).firstOrNull;
    final next = (existing?.quantity ?? 0) + quantity;
    _checkStock(p, next, lang);
    if (existing == null) {
      _cart.add(_Line(productId, quantity));
    } else {
      existing.quantity = next;
    }
    return cart(lang);
  }

  Map<String, dynamic> updateCartItem(String itemId, int quantity, String lang) {
    final line = _lineById(itemId, lang);
    _checkStock(_product(line.productId, lang), quantity, lang);
    line.quantity = quantity < 1 ? 1 : quantity;
    return cart(lang);
  }

  Map<String, dynamic> removeCartItem(String itemId, String lang) {
    _cart.remove(_lineById(itemId, lang));
    return cart(lang);
  }

  Map<String, dynamic> applyCoupon(String code, String lang) {
    if (code.trim().toUpperCase() != validCoupon) {
      throw RequestException(
        lang == 'ar' ? 'رمز الخصم غير صالح' : 'That discount code is not valid',
        code: 'coupon_invalid',
        statusCode: 422,
      );
    }
    _coupon = validCoupon;
    return cart(lang);
  }

  Map<String, dynamic> checkoutOptions(String lang) => {
        'addresses': [
          {
            'id': 'adr_2',
            'label': FixtureData.addressLabel.of(lang),
            'line': FixtureData.addressLine.of(lang),
            'is_default': true,
          },
        ],
        'fulfilment_methods': [
          {
            'id': 'delivery',
            'label': FixtureData.delivery.$1.of(lang),
            'sublabel': FixtureData.delivery.$2.of(lang),
            'fee_fils': deliveryFeeFils,
            'available': true,
          },
          {
            'id': 'pickup',
            'label': FixtureData.pickup.$1.of(lang),
            'sublabel': FixtureData.pickup.$2.of(lang),
            'fee_fils': 0,
            'available': true,
          },
        ],
        'payment_methods': [
          for (final (id, label, meta) in FixtureData.payments)
            {
              'id': id,
              'label': label.of(lang),
              'meta': meta.of(lang),
              'available': true,
            },
        ],
      };

  Map<String, dynamic> placeOrder({
    required String fulfilment,
    required String lang,
  }) {
    if (_cart.isEmpty) {
      throw RequestException(
        lang == 'ar' ? 'السلة فارغة' : 'The cart is empty',
        code: 'cart_empty',
        statusCode: 422,
      );
    }
    final number = _nextOrder++;
    final order = _Order(
      id: 'ord_$number',
      reference: 'BT-$number',
      familyId: _product(_cart.first.productId, lang).familyId,
      lines: [for (final l in _cart) _Line(l.productId, l.quantity)],
      fulfilment: fulfilment,
      stepIndex: 0,
    );
    final totals = _totals(
      order.lines,
      lang,
      delivery: fulfilment == 'delivery',
      discount: _coupon == null ? 0 : couponDiscountFils,
    );
    _orders.insert(0, order);
    _cart.clear();
    _coupon = null;

    return {
      'order': {
        'id': order.id,
        'reference': order.reference,
        'status': 'placed',
        'total_display': totals['total_display'],
      },
      'payment': {'state': 'succeeded'},
    };
  }

  _Order _order(String id, String lang) => _orders.firstWhere(
        (o) => o.id == id,
        orElse: () => throw RequestException(
          lang == 'ar' ? 'لم يتم العثور على هذا الطلب.' : 'This order could not be found.',
          code: 'not_found',
          statusCode: 404,
        ),
      );

  Map<String, dynamic> orders(String lang) => {
        'items': [
          for (final o in _orders)
            {
              'id': o.id,
              'reference': o.reference,
              'status': FixtureData.orderSteps[o.stepIndex].$1,
              'total_display': _orderTotals(o, lang)['total_display'],
            },
        ],
        'next_cursor': null,
      };

  Map<String, dynamic> _orderTotals(_Order o, String lang) => _totals(
        o.lines,
        lang,
        delivery: o.fulfilment == 'delivery',
        discount: couponDiscountFils,
      );

  Map<String, dynamic> order(String id, String lang) {
    final o = _order(id, lang);
    final family = _family(o.familyId, lang);
    final delivered = o.stepIndex == FixtureData.orderSteps.length - 1;

    return {
      'id': o.id,
      'reference': o.reference,
      'status': FixtureData.orderSteps[o.stepIndex].$1,
      'eta_display': delivered
          ? FixtureData.orderDeliveredEta.of(lang)
          : FixtureData.orderEta.of(lang),
      'timeline': [
        for (var i = 0; i < FixtureData.orderSteps.length; i++)
          {
            'status': FixtureData.orderSteps[i].$1,
            'label': FixtureData.orderSteps[i].$2.of(lang),
            'at': null,
            'at_display': i <= o.stepIndex ? FixtureData.orderSteps[i].$3.of(lang) : null,
            'done': i <= o.stepIndex,
          },
      ],
      'items': [
        for (final line in o.lines)
          {
            'product_id': line.productId,
            'name': _product(line.productId, lang).name.of(lang),
            'quantity': line.quantity,
            ..._money('line_total', _product(line.productId, lang).priceFils * line.quantity, lang),
            'image': _productImage(_product(line.productId, lang), lang),
          },
      ],
      'totals': _orderTotals(o, lang),
      'family': {'id': family.id, 'name': family.name.of(lang)},
      'can_rate': delivered && !o.rated,
      'can_cancel': o.stepIndex < 2,
    };
  }

  void rateOrder(String id, int rating, String lang) {
    final o = _order(id, lang);
    if (o.stepIndex != FixtureData.orderSteps.length - 1 || o.rated) {
      throw RequestException(
        lang == 'ar' ? 'لا يمكن تقييم هذا الطلب الآن.' : 'This order cannot be rated yet.',
        code: 'rating_unavailable',
        statusCode: 422,
      );
    }
    o.rated = true;
  }

  Map<String, dynamic> notifications(String lang) {
    final items = [
      for (final (id, type, read, title, body, created, target)
          in FixtureData.notifications)
        {
          'id': id,
          'type': type,
          'is_read': read || _readNotifications.contains(id),
          'title': title.of(lang),
          'body': body.of(lang),
          'created_display': created.of(lang),
          'target': target == null ? null : {'kind': target.$1, 'id': target.$2},
        },
    ];
    return {
      'unread_count': items.where((n) => n['is_read'] != true).length,
      'items': items,
      'next_cursor': null,
    };
  }

  void markNotificationsRead() {
    for (final n in FixtureData.notifications) {
      _readNotifications.add(n.$1);
    }
  }

  Map<String, dynamic> me(String lang) => {
        'id': 'usr_18',
        'full_name': _customerName,
        'phone': _customerPhone,
        'avatar': null,
        'language': lang,
        'stats': {
          'order_count': _orders.length,
          'favourite_count': _favourites.length,
          'following_count': _following.length,
        },
      };

  Map<String, dynamic> requestOtp({
    required String phone,
    required String mode,
    String? fullName,
  }) {
    final requestId = 'otp_${_otpRequests.length + 1}';
    _otpRequests[requestId] = (phone, mode, fullName);
    return {
      'request_id': requestId,
      'expires_in': 120,
      'resend_after': 30,
      'digits': 4,
    };
  }

  Map<String, dynamic> resendOtp(String requestId, String lang) {
    if (!_otpRequests.containsKey(requestId)) {
      throw RequestException(
        lang == 'ar' ? 'انتهت صلاحية الرمز. اطلب رمزاً جديداً.' : 'The code has expired. Request a new one.',
        code: 'otp_expired',
        statusCode: 410,
      );
    }
    return {
      'request_id': requestId,
      'expires_in': 120,
      'resend_after': 30,
      'digits': 4,
    };
  }

  Map<String, dynamic> verifyOtp(String requestId, String code, String lang) {
    final request = _otpRequests[requestId];
    if (request == null) {
      throw RequestException(
        lang == 'ar' ? 'انتهت صلاحية الرمز. اطلب رمزاً جديداً.' : 'The code has expired. Request a new one.',
        code: 'otp_expired',
        statusCode: 410,
      );
    }
    if (code == '0000') {
      throw RequestException(
        lang == 'ar' ? 'الرمز غير صحيح.' : 'That code is not right.',
        code: 'otp_invalid',
        statusCode: 401,
        details: const {'attempts_left': 2},
      );
    }

    final (phone, mode, fullName) = request;
    _customerPhone = phone;
    if (fullName != null && fullName.trim().isNotEmpty) {
      _customerName = fullName.trim();
    }
    _otpRequests.remove(requestId);

    return {
      'access_token': 'fixture-access-$requestId',
      'refresh_token': 'fixture-refresh-$requestId',
      'expires_in': 3600,
      'is_new_user': mode == 'signup',
      'user': {
        'id': 'usr_18',
        'full_name': _customerName,
        'phone': _customerPhone,
        'avatar': null,
        'role': 'customer',
      },
    };
  }
}
