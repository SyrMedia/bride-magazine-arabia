// lib/src/data/repositories/shop_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../models/product.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  final dio = ref.read(apiClientProvider).base;
  return ShopRepository(dio);
});

class ShopRepository {
  final Dio _dio;
  ShopRepository(this._dio);

  /// ===== المنتجات (مع فلترة بالتصنيف/التاج) =====
  Future<List<Product>> fetchProducts({
    int page = 1,
    int perPage = 12,
    String? search,
    int? category,
    int? tagId,
    String order = 'desc',
    String orderby = 'date',
    bool? onSale,
    String? afterIso,
  }) async {
    try {
      final qp = <String, dynamic>{
        'page': page,
        'per_page': perPage,
        if (search != null && search.trim().isNotEmpty)
          'search': search.trim(),
        if (category != null && category > 0) 'category': category,
        if (tagId != null && tagId > 0) 'tag': tagId,
        'order': order,
        'orderby': orderby,
        if (onSale == true) 'on_sale': true,
        if (afterIso != null && afterIso.isNotEmpty) 'after': afterIso,
      };

      final res = await _dio.get(
        '/wp-json/wc/store/v1/products',
        queryParameters: qp,
      );
      final data = res.data;
      if (data is! List) {
        print('⚠️ Unexpected products response: ${res.data.runtimeType}');
        return const [];
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map(_mapStoreV1ToCompatJson)
          .map(Product.fromJson)
          .toList();
    } catch (e, st) {
      print('❌ fetchProducts error: $e');
      print(st);
      return const [];
    }
  }

  Future<Product> fetchProduct(int id) async {
    final res = await _dio.get('/wp-json/wc/store/v1/products/$id');
    final j = res.data;
    if (j is! Map<String, dynamic>) {
      throw Exception('Unexpected product response');
    }
    final compat = _mapStoreV1ToCompatJson(j);
    return Product.fromJson(compat);
  }

  /// ===== التصنيفات (مع Fallback تلقائي) =====
  Future<List<Map<String, dynamic>>> fetchCategories({
    int perPage = 100,
    String order = 'asc',
    String orderby = 'name',
    bool hideEmpty = true,
  }) async {
    // 1) حاول store/v1
    try {
      final store = await _fetchStoreV1Categories(
        perPage: perPage,
        order: order,
        orderby: orderby,
        hideEmpty: hideEmpty,
      );
      if (store.isNotEmpty) return store;
    } catch (_) {
      // تجاهل وانتقل للـ fallback
    }

    // 2) fallback إلى wp/v2
    try {
      final wp = await _fetchWpV2Categories(
        perPage: perPage,
        order: order,
        orderby: orderby,
        hideEmpty: hideEmpty,
      );
      return wp;
    } catch (_) {
      return const [];
    }
  }

  /// ===== العلامات (Tags) =====
  Future<List<Map<String, dynamic>>> fetchTags({
    int perPage = 100,
    String order = 'asc',
    String orderby = 'name',
    bool hideEmpty = true,
  }) async {
    try {
      final store = await _fetchStoreV1Tags(
        perPage: perPage,
        order: order,
        orderby: orderby,
        hideEmpty: hideEmpty,
      );
      if (store.isNotEmpty) return store;
    } catch (_) {}

    try {
      final wp = await _fetchWpV2Tags(
        perPage: perPage,
        order: order,
        orderby: orderby,
        hideEmpty: hideEmpty,
      );
      return wp;
    } catch (_) {
      return const [];
    }
  }

  // ---------- مصادر الجلب ----------

  // store/v1: product-categories
  Future<List<Map<String, dynamic>>> _fetchStoreV1Categories({
    required int perPage,
    required String order,
    required String orderby,
    required bool hideEmpty,
  }) async {
    final qp = <String, dynamic>{
      'per_page': perPage,
      'order': order,
      'orderby': orderby,
      if (hideEmpty) 'hide_empty': true,
    };
    final res = await _dio.get(
      '/wp-json/wc/store/v1/product-categories',
      queryParameters: qp,
    );
    final data = res.data;
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().map((c) {
      return {
        'id': (c['id'] is num) ? (c['id'] as num).toInt() : null,
        'name': (c['name'] ?? '').toString(),
        'slug': (c['slug'] ?? '').toString(),
        // ✅✅✅ التصحيح هنا: إضافة حقل الأب
        'parent': (c['parent'] is num) ? (c['parent'] as num).toInt() : 0,
        'count': (c['count'] is num) ? (c['count'] as num).toInt() : 0,
      };
    }).toList();
  }

  // wp/v2: product_cat
  Future<List<Map<String, dynamic>>> _fetchWpV2Categories({
    required int perPage,
    required String order,
    required String orderby,
    required bool hideEmpty,
  }) async {
    final qp = <String, dynamic>{
      'per_page': perPage,
      'order': order,
      'orderby': orderby,
      if (hideEmpty) 'hide_empty': true,
    };
    final res = await _dio.get(
      '/wp-json/wp/v2/product_cat',
      queryParameters: qp,
    );
    final data = res.data;
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().map((c) {
      return {
        'id': (c['id'] is num) ? (c['id'] as num).toInt() : null,
        'name': (c['name'] ?? '').toString(),
        'slug': (c['slug'] ?? '').toString(),
        // ✅✅✅ التصحيح هنا: إضافة حقل الأب
        'parent': (c['parent'] is num) ? (c['parent'] as num).toInt() : 0,
        'count': (c['count'] is num) ? (c['count'] as num).toInt() : 0,
      };
    }).toList();
  }

  // store/v1: product-tags
  Future<List<Map<String, dynamic>>> _fetchStoreV1Tags({
    required int perPage,
    required String order,
    required String orderby,
    required bool hideEmpty,
  }) async {
    final qp = <String, dynamic>{
      'per_page': perPage,
      'order': order,
      'orderby': orderby,
      if (hideEmpty) 'hide_empty': true,
    };
    final res = await _dio.get(
      '/wp-json/wc/store/v1/product-tags',
      queryParameters: qp,
    );
    final data = res.data;
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().map((t) {
      return {
        'id': (t['id'] is num) ? (t['id'] as num).toInt() : null,
        'name': (t['name'] ?? '').toString(),
        'slug': (t['slug'] ?? '').toString(),
        'count': (t['count'] is num) ? (t['count'] as num).toInt() : 0,
      };
    }).toList();
  }

  // wp/v2: product_tag
  Future<List<Map<String, dynamic>>> _fetchWpV2Tags({
    required int perPage,
    required String order,
    required String orderby,
    required bool hideEmpty,
  }) async {
    final qp = <String, dynamic>{
      'per_page': perPage,
      'order': order,
      'orderby': orderby,
      if (hideEmpty) 'hide_empty': true,
    };
    final res = await _dio.get(
      '/wp-json/wp/v2/product_tag',
      queryParameters: qp,
    );
    final data = res.data;
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().map((t) {
      return {
        'id': (t['id'] is num) ? (t['id'] as num).toInt() : null,
        'name': (t['name'] ?? '').toString(),
        'slug': (t['slug'] ?? '').toString(),
        'count': (t['count'] is num) ? (t['count'] as num).toInt() : 0,
      };
    }).toList();
  }

  // ---------- محوِّل استجابة المنتجات ----------
  Map<String, dynamic> _mapStoreV1ToCompatJson(Map<String, dynamic> j) {
    String? price;
    String? regularPrice;
    String? salePrice;

    if (j['prices'] is Map) {
      final prices = j['prices'] as Map;
      if ((prices['price']?.toString().isNotEmpty ?? false)) {
        price = prices['price'].toString();
      }
      if ((prices['regular_price']?.toString().isNotEmpty ?? false)) {
        regularPrice = prices['regular_price'].toString();
      }
      if ((prices['sale_price']?.toString().isNotEmpty ?? false)) {
        salePrice = prices['sale_price'].toString();
      }
    } else {
      if (j['price'] != null && j['price'].toString().trim().isNotEmpty) {
        price = j['price'].toString();
      }
      if (j['regular_price'] != null && j['regular_price'].toString().trim().isNotEmpty) {
        regularPrice = j['regular_price'].toString();
      }
      if (j['sale_price'] != null && j['sale_price'].toString().trim().isNotEmpty) {
        salePrice = j['sale_price'].toString();
      }
    }

    final bool onSale = j['on_sale'] == true ||
        (salePrice != null && salePrice.isNotEmpty && salePrice != regularPrice);

    final bool isInStock = j['is_in_stock'] == true || j['in_stock'] == true;

    final createdGmt = j['date_created_gmt'] ?? j['date_created'] ?? j['date_created_utc'];

    final images = (j['images'] is List) ? j['images'] as List : const [];

    List<Map<String, dynamic>> normTags = [];
    if (j['tags'] is List) {
      for (final t in (j['tags'] as List)) {
        if (t is Map) {
          final id = (t['id'] is num) ? (t['id'] as num).toInt() : null;
          final name = (t['name'] ?? '').toString();
          final slug = (t['slug'] ?? '').toString();
          normTags.add({'id': id, 'name': name, 'slug': slug});
        } else if (t is String) {
          normTags.add({'id': null, 'name': t, 'slug': ''});
        }
      }
    }

    List<Map<String, dynamic>> normAttrs = [];
    if (j['attributes'] is List) {
      for (final a in (j['attributes'] as List)) {
        if (a is Map) {
          final name = (a['name'] ?? '').toString();
          final options = <String>[];
          if (a['terms'] is List) {
            for (final term in (a['terms'] as List)) {
              if (term is Map && term['name'] != null) {
                options.add(term['name'].toString());
              } else if (term is String) {
                options.add(term);
              }
            }
          }
          if (a['options'] is List) {
            for (final opt in (a['options'] as List)) {
              options.add(opt.toString());
            }
          }
          normAttrs.add({'name': name, 'options': options});
        }
      }
    }

    return <String, dynamic>{
      'id': j['id'],
      'name': j['name'],
      'price': price,
      'regular_price': regularPrice,
      'sale_price': salePrice,
      'on_sale': onSale,
      'is_in_stock': isInStock,
      'date_created_gmt': createdGmt,
      'images': images,
      'tags': normTags,
      'attributes': normAttrs,
    };
  }
}