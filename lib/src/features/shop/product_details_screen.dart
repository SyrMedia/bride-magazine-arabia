import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../../core/api_client.dart';
import '../../core/currency.dart';
import '../../data/models/product.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/models/cart_item.dart';
import '../../data/repositories/cart_provider.dart';
import '../../widgets/cart_icon_button.dart';

import 'brand_products_screen.dart';
// import '../../../main.dart'; // ❌ تم إزالة الاستيراد غير الضروري AppColors

class ProductDetailsScreen extends ConsumerWidget {
  final int productId;
  final Object? initial;

  const ProductDetailsScreen({
    super.key,
    required this.productId,
    this.initial,
  });

  // تطبيع الاسم لتفادي التكرارات (فرق حالة الأحرف والمسافات)
  String _norm(String? s) => (s ?? '').trim().toLowerCase();

  Future<Map<String, dynamic>?> _loadExtra(WidgetRef ref) async {
    try {
      final dio = ref.read(apiClientProvider).base;
      final res = await dio.get('/wp-json/wc/store/v1/products/$productId');
      if (res.statusCode != null &&
          res.statusCode! >= 200 &&
          res.statusCode! < 300) {
        final data = res.data;
        if (data is Map<String, dynamic>) return data;
      }
    } catch (_) {}
    return null;
  }

  String? _safeString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  List<String> _extractImages(Product p, Map<String, dynamic>? extra) {
    final urls = <String>[];
    if (_safeString(p.image) != null) urls.add(p.image!);

    final imgs = extra?['images'];
    if (imgs is List) {
      for (final it in imgs) {
        if (it is Map && _safeString(it['src']) != null) {
          final u = it['src'].toString();
          if (!urls.contains(u)) urls.add(u);
        }
      }
    }
    return urls;
  }

  String? _extractHtmlDesc(Map<String, dynamic>? extra) {
    if (extra == null) return null;
    return _safeString(extra['description']) ??
        _safeString(extra['short_description']) ??
        _safeString(extra['excerpt']);
  }

  Map<String, String?> _extractPrices(Product p, Map<String, dynamic>? extra) {
    final prices = (extra?['prices'] is Map) ? extra!['prices'] as Map : const {};
    final priceStr = _safeString(p.price) ?? _safeString(prices['price']);
    final regularStr = _safeString(prices['regular_price']);
    final saleStr = _safeString(prices['sale_price']);

    return {'price': priceStr, 'regular': regularStr, 'sale': saleStr};
  }

  double _minorToAmountForCart(String raw, Map<String, dynamic>? extra) {
    final cleaned = raw.replaceAll(',', '').trim();
    final n = double.tryParse(cleaned);
    if (n == null) return 0;
    if (cleaned.contains('.')) return n;

    int? minor;
    final prices = extra?['prices'];
    if (prices is Map && prices['currency_minor_unit'] is num) {
      minor = (prices['currency_minor_unit'] as num).toInt();
    } else if (extra?['currency_minor_unit'] is num) {
      minor = (extra!['currency_minor_unit'] as num).toInt();
    }

    if (minor == null || minor == 0) return n;
    final denom = math.pow(10, minor).toDouble();
    return n / denom;
  }

  // استخراج الماركة من tags أو من attributes أو من extra
  ({int? tagId, String? brandName}) _extractBrand(
      Product p,
      Map<String, dynamic>? extra,
      ) {
    // من الـ tags الموجودة في الموديل
    if (p.tags.isNotEmpty) {
      final t = p.tags.firstWhere(
            (t) => (t['name']?.toString().isNotEmpty ?? false),
        orElse: () => p.tags.first,
      );
      return (tagId: (t['id'] as int?), brandName: t['name']?.toString());
    }

    // من الـ attributes (مثلاً اسم "Brand" أو "ماركة")
    for (final a in p.attributes) {
      final name = (a['name'] ?? '').toString().toLowerCase();
      if (name.contains('brand') || name.contains('ماركة')) {
        final opts = (a['options'] is List) ? (a['options'] as List) : const [];
        if (opts.isNotEmpty) {
          return (tagId: null, brandName: opts.first.toString());
        }
      }
    }

    // من استجابة store/v1 (extra)
    if (extra?['tags'] is List) {
      final list = extra!['tags'] as List;
      if (list.isNotEmpty) {
        final t0 = list.first;
        if (t0 is Map) {
          final id = (t0['id'] is num) ? (t0['id'] as num).toInt() : null;
          final name = (t0['name'] ?? '').toString();
          return (tagId: id, brandName: name.isEmpty ? null : name);
        } else if (t0 is String) {
          return (tagId: null, brandName: t0);
        }
      }
    }

    return (tagId: null, brandName: null);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initialProduct = (initial is Product) ? initial as Product : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المنتج'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          CartIconButton(onPressed: () => context.go('/tabs/shop/cart')),
        ],
      ),
      body: FutureBuilder<Product>(
        future: ref.read(shopRepositoryProvider).fetchProduct(productId),
        initialData: initialProduct,
        builder: (context, snap) {
          if (!snap.hasData && snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('حدث خطأ: ${snap.error}'));
          }

          final p = snap.data!;
          return FutureBuilder<Map<String, dynamic>?>(
            future: _loadExtra(ref),
            builder: (context, extraSnap) {
              final extra = extraSnap.data;
              final images = _extractImages(p, extra);
              final descHtml = _extractHtmlDesc(extra);
              final prices = _extractPrices(p, extra);

              final regular = prices['regular'];
              final sale = prices['sale'];
              final base = prices['price'];

              final formattedRegular =
              regular != null ? formatPrice(regular, ref) : null;
              final formattedSale =
              sale != null ? formatPrice(sale, ref) : null;
              final formattedBase = base != null ? formatPrice(base, ref) : null;

              // ===== حالة المخزون =====
              bool isInStock = true;
              String? stockText;

              if (extra != null) {
                // WooCommerce Blocks API: is_in_stock + stock_availability.text
                if (extra['is_in_stock'] == false) {
                  isInStock = false;

                  final stockAvail = extra['stock_availability'];
                  if (stockAvail is Map &&
                      stockAvail['text'] != null &&
                      stockAvail['text'].toString().trim().isNotEmpty) {
                    stockText = stockAvail['text'].toString();
                  } else {
                    stockText = 'غير متوفر في المخزون';
                  }
                }
              }

              // ===== ويدجت السعر =====
              Widget _priceWidget() {
                final theme = Theme.of(context);
                final scheme = theme.colorScheme;
                final onSurface = scheme.onSurface;

                // 💡 نستخدم لون الخطأ (Error) كلون لخط الشطب
                final strikeColor = scheme.error;

                // في خصم حقيقي
                if (formattedSale != null &&
                    formattedRegular != null &&
                    formattedSale != formattedRegular) {
                  return Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      // حتى يكون السعر الأصلي على اليمين وسعر الخصم على اليسار
                      textDirection: TextDirection.rtl,
                      children: [
                        // السعر الأصلي مشطوب
                        Text(
                          formattedRegular!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: strikeColor, // ✅ استخدام لون strikeColor من ColorScheme
                            decorationThickness: 1.6,
                            color: onSurface.withOpacity(
                              theme.brightness == Brightness.dark ? 0.7 : 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // السعر المخفّض (واضح، سميك)
                        Text(
                          formattedSale!,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: onSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // لا يوجد خصم – سعر واحد فقط
                final only = formattedBase ?? formattedRegular ?? formattedSale;
                if (only == null) return const SizedBox.shrink();

                return Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    only,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: onSurface,
                    ),
                  ),
                );
              }

              final brand = _extractBrand(p, extra);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // صورة / سلايدر الصور
                  AspectRatio(
                    aspectRatio: 1,
                    child: images.isNotEmpty
                        ? PageView.builder(
                      itemCount: images.length,
                      itemBuilder: (context, i) => CachedNetworkImage(
                        imageUrl: images[i],
                        fit: BoxFit.cover,
                      ),
                    )
                        : const ColoredBox(
                      color: Color(0x11000000),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // الاسم
                  Text(
                    p.name,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.start,
                  ),

                  // سطر الماركة الصغير تحت الاسم (إن وجد)
                  if (brand.brandName != null &&
                      brand.brandName!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        brand.brandName!,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                          // ✅ استخدام onSurface (Warm Charcoal) كلون للماركة
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  // السعر
                  _priceWidget(),

                  // حالة المخزون تحت السعر
                  if (!isInStock && (stockText ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          // نستخدم لون أغمق في Light/Primary في Dark
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.8)
                              : Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          stockText!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // 🔹 الماركة + الوسوم كـ Chips (لتصفية منتجات مشابهة)
                  if (brand.brandName != null || p.tags.isNotEmpty) ...[
                    Builder(
                      builder: (context) {
                        final usedNames = <String>{};
                        final usedIds = <int>{};
                        final chips = <Widget>[];

                        // Chip للماركة
                        if ((brand.brandName ?? '').isNotEmpty) {
                          usedNames.add(_norm(brand.brandName));
                          if (brand.tagId != null) {
                            usedIds.add(brand.tagId!);
                          }

                          chips.add(
                            ActionChip(
                              avatar: const Icon(Icons.sell, size: 18),
                              label: Text(brand.brandName!),
                              onPressed: () {
                                if (brand.tagId != null) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => BrandProductsScreen(
                                        tagId: brand.tagId!,
                                        title: brand.brandName!,
                                      ),
                                    ),
                                  );
                                } else {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => BrandProductsScreen(
                                        searchName: brand.brandName!,
                                        title: brand.brandName!,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        }

                        // بقية الوسوم بدون تكرار
                        for (final t in p.tags) {
                          final name = t['name']?.toString() ?? '';
                          if (name.isEmpty) continue;

                          final id =
                          (t['id'] is num) ? (t['id'] as num).toInt() : null;

                          if (id != null && usedIds.contains(id)) {
                            continue;
                          }
                          if (usedNames.contains(_norm(name))) {
                            continue;
                          }

                          if (id != null) usedIds.add(id);
                          usedNames.add(_norm(name));

                          chips.add(
                            ActionChip(
                              label: Text(name),
                              onPressed: () {
                                if (id != null) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => BrandProductsScreen(
                                        tagId: id,
                                        title: name,
                                      ),
                                    ),
                                  );
                                } else {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => BrandProductsScreen(
                                        searchName: name,
                                        title: name,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        }

                        if (chips.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: chips,
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 16),

                  // الوصف
                  if (descHtml != null && descHtml.isNotEmpty) ...[
                    Text(
                      'الوصف',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    HtmlWidget(
                      descHtml,
                      textStyle: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ] else ...[
                    const Text(
                      'وصف قصير للمنتج سيظهر هنا.',
                    ),
                  ],

                  const SizedBox(height: 24),

                  // زر إضافة إلى السلة
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.add_shopping_cart),
                      label: Text(
                        isInStock ? 'أضف إلى السلة' : 'غير متوفر حالياً',
                      ),
                      onPressed: isInStock
                          ? () {
                        final raw = sale ?? base ?? regular ?? p.price ?? '0';
                        final unitPrice = _minorToAmountForCart(raw, extra);
                        ref.read(cartProvider.notifier).add(
                          CartItem(
                            productId: p.id,
                            name: p.name,
                            image: (images.isNotEmpty ? images.first : p.image),
                            price: unitPrice,
                            quantity: 1,
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('أُضيف إلى السلة'),
                          ),
                        );
                      }
                          : null, // 🔒 معطّل إذا ما في مخزون
                    ),
                  ),

                  if (extraSnap.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}