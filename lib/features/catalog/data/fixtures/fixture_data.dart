class FixtureText {
  final String ar;
  final String en;

  const FixtureText(this.ar, this.en);

  String of(String lang) => lang == 'ar' ? ar : en;
}

class FixtureFamily {
  final String id;
  final FixtureText name;
  final FixtureText city;
  final double rating;
  final int productCount;
  final int followerCount;
  final FixtureText story;

  const FixtureFamily({
    required this.id,
    required this.name,
    required this.city,
    required this.rating,
    required this.productCount,
    required this.followerCount,
    required this.story,
  });
}

class FixtureProduct {
  final String id;
  final String familyId;
  final String categoryId;
  final FixtureText name;
  final int priceFils;
  final int compareAtFils;
  final String badge;
  final double rating;
  final int sold;
  final int stock;
  final String growth;
  final FixtureText description;

  const FixtureProduct({
    required this.id,
    required this.familyId,
    required this.categoryId,
    required this.name,
    required this.priceFils,
    required this.compareAtFils,
    required this.badge,
    required this.rating,
    required this.sold,
    required this.stock,
    required this.growth,
    required this.description,
  });
}

class FixtureCategory {
  final String id;
  final String icon;
  final FixtureText name;
  final int productCount;

  const FixtureCategory(this.id, this.icon, this.name, this.productCount);
}

class FixtureData {
  FixtureData._();

  static const families = [
    FixtureFamily(
      id: 'fam_1',
      name: FixtureText('أسرة أم عبدالله', 'Umm Abdullah Family'),
      city: FixtureText('حولي', 'Hawalli'),
      rating: 4.9,
      productCount: 24,
      followerCount: 1243,
      story: FixtureText(
        'مطبخ منزلي في حولي منذ ٢٠١٤. نصنع الحلويات الكويتية بوصفات العائلة، ونخبز يومياً بكميات محدودة.',
        'A home kitchen in Hawalli since 2014. Kuwaiti sweets from family recipes, baked daily in small batches.',
      ),
    ),
    FixtureFamily(
      id: 'fam_2',
      name: FixtureText('بيت الزعفران', 'Bait Al Zafaran'),
      city: FixtureText('السالمية', 'Salmiya'),
      rating: 4.7,
      productCount: 18,
      followerCount: 862,
      story: FixtureText(
        'بهارات وخلطات منزلية تُطحن عند الطلب.',
        'Home-ground spice blends, milled to order.',
      ),
    ),
    FixtureFamily(
      id: 'fam_3',
      name: FixtureText('أسرة الحرفة', 'Al Hirfa Family'),
      city: FixtureText('الجهراء', 'Jahra'),
      rating: 4.8,
      productCount: 31,
      followerCount: 1418,
      story: FixtureText(
        'سدو ومنسوجات يدوية بأنامل كويتية.',
        'Hand-woven Sadu textiles made in Kuwait.',
      ),
    ),
    FixtureFamily(
      id: 'fam_4',
      name: FixtureText('مخبز الدار', 'Al Dar Bakery'),
      city: FixtureText('الفروانية', 'Farwaniya'),
      rating: 4.6,
      productCount: 12,
      followerCount: 540,
      story: FixtureText(
        'خبز ومعجنات طازجة كل صباح.',
        'Fresh bread and pastries every morning.',
      ),
    ),
  ];

  static const products = [
    FixtureProduct(
      id: 'prd_1',
      familyId: 'fam_1',
      categoryId: 'cat_sweets',
      name: FixtureText('كيك التمر بالهيل', 'Cardamom date cake'),
      priceFils: 4250,
      compareAtFils: 5000,
      badge: 'best_seller',
      rating: 4.9,
      sold: 212,
      stock: 8,
      growth: '+38%',
      description: FixtureText(
        'كيك تمر طري بالهيل والزعفران، يُخبز عند الطلب بدون مواد حافظة. يكفي ٦ إلى ٨ أشخاص.',
        'Soft date cake with cardamom and saffron, baked to order with no preservatives. Serves six to eight.',
      ),
    ),
    FixtureProduct(
      id: 'prd_2',
      familyId: 'fam_1',
      categoryId: 'cat_sweets',
      name: FixtureText('درابيل محشية', 'Filled darabeel'),
      priceFils: 2750,
      compareAtFils: 3250,
      badge: 'new',
      rating: 4.8,
      sold: 96,
      stock: 20,
      growth: '+21%',
      description: FixtureText(
        'درابيل منزلية محشية بالتمر والجوز، تُقدم في علبة من ١٢ حبة.',
        'Home-made darabeel filled with dates and walnut, boxed by twelve.',
      ),
    ),
    FixtureProduct(
      id: 'prd_3',
      familyId: 'fam_2',
      categoryId: 'cat_spices',
      name: FixtureText('بهار الكبسة المنزلي', 'House kabsa spice'),
      priceFils: 1900,
      compareAtFils: 2400,
      badge: 'trending',
      rating: 4.7,
      sold: 340,
      stock: 44,
      growth: '+64%',
      description: FixtureText(
        'خلطة بهارات تُطحن يوم الطلب، ١٥٠ جرام في علبة زجاجية.',
        'Blend milled on the day of order, 150g in a glass jar.',
      ),
    ),
    FixtureProduct(
      id: 'prd_4',
      familyId: 'fam_3',
      categoryId: 'cat_crafts',
      name: FixtureText('وسادة سدو مطرزة', 'Embroidered Sadu cushion'),
      priceFils: 9500,
      compareAtFils: 12000,
      badge: 'trending',
      rating: 5.0,
      sold: 54,
      stock: 5,
      growth: '+52%',
      description: FixtureText(
        'وسادة منسوجة يدوياً بنقوش السدو التقليدية، ٤٥×٤٥ سم.',
        'Hand-woven cushion in traditional Sadu patterns, 45×45cm.',
      ),
    ),
    FixtureProduct(
      id: 'prd_5',
      familyId: 'fam_4',
      categoryId: 'cat_bakery',
      name: FixtureText('خبز التنور الطازج', 'Fresh tanoor bread'),
      priceFils: 1250,
      compareAtFils: 1500,
      badge: 'best_seller',
      rating: 4.6,
      sold: 480,
      stock: 60,
      growth: '+12%',
      description: FixtureText(
        'أربعة أرغفة تنور تُخبز صباح التسليم.',
        'Four tanoor loaves baked the morning of delivery.',
      ),
    ),
    FixtureProduct(
      id: 'prd_6',
      familyId: 'fam_2',
      categoryId: 'cat_spices',
      name: FixtureText('زعفران معبأ يدوياً', 'Hand-packed saffron'),
      priceFils: 6750,
      compareAtFils: 8000,
      badge: 'new',
      rating: 4.9,
      sold: 77,
      stock: 14,
      growth: '+29%',
      description: FixtureText(
        'خيوط زعفران مختارة، ١ جرام في علبة محكمة.',
        'Selected saffron threads, 1g in a sealed tin.',
      ),
    ),
  ];

  static const categories = [
    FixtureCategory('cat_sweets', 'sweets', FixtureText('حلويات', 'Sweets'), 128),
    FixtureCategory('cat_bakery', 'bakery', FixtureText('مخبوزات', 'Bakery'), 96),
    FixtureCategory('cat_spices', 'spices', FixtureText('بهارات', 'Spices'), 74),
    FixtureCategory('cat_crafts', 'crafts', FixtureText('حرف يدوية', 'Crafts'), 41),
    FixtureCategory('cat_perfume', 'perfume', FixtureText('عطور', 'Perfume'), 23),
    FixtureCategory('cat_savoury', 'savoury', FixtureText('مأكولات', 'Savoury'), 88),
  ];

  static const hashtags = FixtureText(
    '#حلويات_كويتية|#سدو|#بهارات|#خبز_طازج|#هدايا|#زعفران',
    '#kuwaitisweets|#sadu|#spices|#freshbread|#gifts|#saffron',
  );

  static const bannerKicker = FixtureText('معرض', 'Exhibition');
  static const bannerTitle =
      FixtureText('معرض بيتوتي الخريفي', 'Baytouti Autumn Market');
  static const bannerSubtitle = FixtureText(
    'أربعون أسرة منتجة في مكان واحد، وكل جناح له رمز QR يفتح متجره داخل التطبيق.',
    'Forty producing families in one hall. Every stand carries a QR that opens its store in the app.',
  );
  static const bannerDate =
      FixtureText('٢ — ٥ أكتوبر · أرض المعارض', '2 — 5 Oct · Fairgrounds');
  static const bannerAction = FixtureText('امسح رمز الجناح', 'Scan a stand');

  static const reviews = [
    (
      FixtureText('مريم ا.', 'Mariam A.'),
      5,
      FixtureText(
        'وصل طازج وبتغليف ممتاز، والطعم منزلي فعلاً.',
        'Arrived fresh, beautifully packed, and tastes genuinely home-made.',
      ),
    ),
    (
      FixtureText('عبدالله ح.', 'Abdullah H.'),
      4,
      FixtureText(
        'الكمية أقل مما توقعت لكن الجودة عالية.',
        'Smaller portion than I expected, but the quality is high.',
      ),
    ),
  ];
  static const reviewAge = FixtureText('قبل أسبوع', '1 week ago');
  static const preparation = FixtureText('٢٤ ساعة', '24 hours');

  static const addressLabel = FixtureText('المنزل — حولي', 'Home — Hawalli');
  static const addressLine = FixtureText(
    'قطعة ٣، شارع ١٢، منزل ٤٥ · الكويت',
    'Block 3, Street 12, House 45 · Kuwait',
  );

  static const delivery = (
    FixtureText('توصيل', 'Delivery'),
    FixtureText('خلال ٤٨ ساعة', 'Within 48 hours'),
  );
  static const pickup = (
    FixtureText('استلام', 'Pickup'),
    FixtureText('من موقع الأسرة', 'From the family'),
  );

  static const payments = [
    ('knet', FixtureText('K-NET', 'K-NET'), FixtureText('بطاقة كويتية', 'Kuwaiti debit')),
    ('card', FixtureText('بطاقة ائتمان', 'Credit card'), FixtureText('Visa · Mastercard', 'Visa · Mastercard')),
    ('apple', FixtureText('Apple Pay', 'Apple Pay'), FixtureText('دفع سريع', 'Express')),
  ];

  static const orderSteps = [
    ('placed', FixtureText('تم استلام الطلب', 'Order received'), FixtureText('١٠:٠٤ ص', '10:04')),
    ('accepted', FixtureText('قبول الأسرة', 'Accepted by family'), FixtureText('١٠:١٩ ص', '10:19')),
    ('preparing', FixtureText('قيد التجهيز', 'Being prepared'), FixtureText('١١:٤٠ ص', '11:40')),
    ('out_for_delivery', FixtureText('في الطريق', 'Out for delivery'), FixtureText('٠١:٢٥ م', '13:25')),
    ('delivered', FixtureText('تم التسليم', 'Delivered'), FixtureText('٠٢:١٠ م', '14:10')),
  ];

  static const orderEta = FixtureText(
    'التسليم المتوقع اليوم بين ١٢ و ٣ ظهراً',
    'Expected today between 12:00 and 15:00',
  );
  static const orderDeliveredEta =
      FixtureText('تم التسليم يوم الأحد', 'Delivered on Sunday');

  static const defaultCustomerName = 'نورة العنزي';
  static const defaultCustomerPhone = '+96551502244';

  static const notifications = [
    (
      'ntf_6',
      'order_status',
      false,
      FixtureText('طلبك BT-2041 قيد التجهيز', 'Order BT-2041 is being prepared'),
      FixtureText('أسرة أم عبدالله بدأت تجهيز طلبك.', 'Umm Abdullah Family started preparing your order.'),
      FixtureText('الآن', 'now'),
      ('order', 'ord_2041'),
    ),
    (
      'ntf_5',
      'offer',
      false,
      FixtureText('خصم ٢٠٪ على البهارات', '20% off spices'),
      FixtureText('بيت الزعفران، حتى الجمعة.', 'Bait Al Zafaran, until Friday.'),
      FixtureText('٢ س', '2h'),
      ('family', 'fam_2'),
    ),
    (
      'ntf_4',
      'exhibition',
      false,
      FixtureText('معرض بيتوتي الخريفي يفتح غداً', 'Autumn Market opens tomorrow'),
      FixtureText('أربعون أسرة، أرض المعارض.', 'Forty families, at the Fairgrounds.'),
      FixtureText('أمس', '1d'),
      null,
    ),
    (
      'ntf_3',
      'family_update',
      true,
      FixtureText('أسرة الحرفة أضافت ٤ منتجات', 'Al Hirfa Family added 4 products'),
      FixtureText('أنت تتابع هذه الأسرة.', 'You follow this family.'),
      FixtureText('أمس', '1d'),
      ('family', 'fam_3'),
    ),
    (
      'ntf_2',
      'rating_request',
      true,
      FixtureText('قيّم طلبك BT-1998', 'Rate your order BT-1998'),
      FixtureText('تم التسليم يوم الأحد.', 'Delivered on Sunday.'),
      FixtureText('٣ أيام', '3d'),
      ('order', 'ord_1998'),
    ),
    (
      'ntf_1',
      'support',
      true,
      FixtureText('رد فريق الدعم على استفسارك', 'Support replied to your request'),
      FixtureText('تذكرة #4412.', 'Ticket #4412.'),
      FixtureText('أسبوع', '1w'),
      null,
    ),
  ];
}
