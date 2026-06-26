import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final int id;
  final String name;

  /// السعر الحالي (المستخدم كـ default)
  final String? price;

  /// السعر الأصلي (قبل الخصم)
  final String? regularPrice;

  /// سعر الخصم (إن وجد)
  final String? salePrice;

  /// هل المنتج on_sale حسب Woo
  final bool onSale;

  /// هل المنتج متوفر في المخزون
  final bool inStock;

  /// الصورة الرئيسية
  final String? image;

  /// قائمة التاقات القادمة من WooCommerce: [{id, name, slug}]
  final List<Map<String, dynamic>> tags;

  /// قائمة الخصائص Attributes: [{id, name, options: ["..."]}]
  final List<Map<String, dynamic>> attributes;

  const Product({
    required this.id,
    required this.name,
    this.price,
    this.regularPrice,
    this.salePrice,
    this.onSale = false,
    this.inStock = true,
    this.image,
    this.tags = const [],
    this.attributes = const [],
  });

  factory Product.fromJson(Map<String, dynamic> j) {
    // id و name بأمان
    final int parsedId =
    (j['id'] is num) ? (j['id'] as num).toInt() : (j['id'] as int);
    final String parsedName = (j['name'] ?? '').toString();

    // السعر الأساسي (متوافق مع _mapStoreV1ToCompatJson)
    final String? parsedPrice =
    (j['price']?.toString().trim().isNotEmpty ?? false)
        ? j['price'].toString()
        : null;

    // أسعار Woo (regular / sale)
    final String? parsedRegularPrice =
    (j['regular_price']?.toString().trim().isNotEmpty ?? false)
        ? j['regular_price'].toString()
        : null;

    final String? parsedSalePrice =
    (j['sale_price']?.toString().trim().isNotEmpty ?? false)
        ? j['sale_price'].toString()
        : null;

    // on_sale من الـ JSON أو استنتاج من الأسعار
    bool parsedOnSale = j['on_sale'] == true;
    if (!parsedOnSale &&
        parsedRegularPrice != null &&
        parsedSalePrice != null &&
        parsedRegularPrice != parsedSalePrice) {
      parsedOnSale = true;
    }

    // حالة المخزون
    final bool parsedInStock = j['is_in_stock'] == true ||
        (j['stock_status']?.toString() == 'instock');

    // الصورة الرئيسية من أول عنصر في images (إن وُجد)
    String? parsedImage;
    final imgs = j['images'];
    if (imgs is List && imgs.isNotEmpty) {
      final first = imgs.first;
      if (first is Map && first['src'] != null) {
        parsedImage = first['src'].toString();
      }
    }

    // التاقات
    final rawTags = j['tags'];
    final parsedTags = <Map<String, dynamic>>[];
    if (rawTags is List) {
      for (final t in rawTags) {
        if (t is Map) {
          parsedTags.add({
            'id': (t['id'] is num)
                ? (t['id'] as num).toInt()
                : (t['id'] ?? 0),
            'name': (t['name'] ?? '').toString(),
            'slug': (t['slug'] ?? '').toString(),
          });
        }
      }
    }

    // الخصائص
    final rawAttrs = j['attributes'];
    final parsedAttrs = <Map<String, dynamic>>[];
    if (rawAttrs is List) {
      for (final a in rawAttrs) {
        if (a is Map) {
          final options = <String>[];
          final rawOptions = a['options'];
          if (rawOptions is List) {
            for (final o in rawOptions) {
              options.add(o.toString());
            }
          }
          parsedAttrs.add({
            'id': (a['id'] is num)
                ? (a['id'] as num).toInt()
                : (a['id'] ?? 0),
            'name': (a['name'] ?? '').toString(),
            'options': options,
          });
        }
      }
    }

    return Product(
      id: parsedId,
      name: parsedName,
      price: parsedPrice,
      regularPrice: parsedRegularPrice,
      salePrice: parsedSalePrice,
      onSale: parsedOnSale,
      inStock: parsedInStock,
      image: parsedImage,
      tags: parsedTags,
      attributes: parsedAttrs,
    );
  }

  /// اسم الماركة (إن وُجد):
  /// 1) من أول Tag (الأبسط)
  /// 2) أو من Attribute اسمها "Brand" أو "ماركة"
  String? get brand {
    // من التاقات
    if (tags.isNotEmpty) {
      final n = (tags.first['name'] ?? '').toString().trim();
      if (n.isNotEmpty) return n;
    }
    // من الخصائص
    if (attributes.isNotEmpty) {
      final attr = attributes.firstWhere(
            (a) {
          final n = (a['name'] ?? '').toString().toLowerCase().trim();
          return n == 'brand' || n == 'ماركة';
        },
        orElse: () => const {},
      );
      if (attr.isNotEmpty) {
        final opts = (attr['options'] as List?) ?? const [];
        if (opts.isNotEmpty) {
          final v = opts.first.toString().trim();
          if (v.isNotEmpty) return v;
        }
      }
    }
    return null;
  }

  /// رقم التاق المستخدم كماركة (للفلترة عبر REST باستخدام ?tag=)
  int? get brandTagId {
    if (tags.isEmpty) return null;
    final id = tags.first['id'];
    if (id is int && id > 0) return id;
    if (id is num) return id.toInt();
    return null;
  }

  /// بادج "غير متوفر" (لو حابب تستخدمه مباشرة)
  bool get isOutOfStock => !inStock;

  /// بادج "جديد" مبني على التاقات:
  /// إذا كان للمنتج Tag اسمه "New" أو "جديد" أو الـ slug فيه "new"
  bool get isNewBadge {
    if (tags.isEmpty) return false;
    for (final t in tags) {
      final name = (t['name'] ?? '').toString().toLowerCase();
      final slug = (t['slug'] ?? '').toString().toLowerCase();
      if (name.contains('new') ||
          name.contains('جديد') ||
          slug.contains('new')) {
        return true;
      }
    }
    return false;
  }

  @override
  List<Object?> get props =>
      [id, name, price, regularPrice, salePrice, onSale, inStock, image, tags, attributes];
}
