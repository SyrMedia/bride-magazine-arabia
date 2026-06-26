import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/product.dart';
import '../../data/repositories/shop_repository.dart';
import '../../core/currency.dart';
import '../shop/product_details_screen.dart';

enum ProductFilter { all, newest, onSale }

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  // ============================================================
  // 🎨🎨🎨 منطقة ربط صورك الخاصة 🎨🎨🎨
  // ============================================================
  final Map<String, String> myCategoryImages = {
    'Accessories - إكسسوارات': 'assets/icon/Accessories.png',
    'BMA BOUTIQUE': 'assets/icon/BMA_BOUTIQUE.png',
    'Body care - العناية بالجسم': 'assets/icon/Body_care.png',
    'Makeup - مكياج': 'assets/icon/makeup.png',
    'Lingerie - لانجري': 'assets/icon/Lingerie.png',
    'Bridal Bouquet - مسكة العروس': 'assets/icon/bridal-bouquet.png',
    // أضف باقي الصور هنا بنفس الطريقة...
  };
  // ============================================================

  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _categories = const [];
  List<Map<String, dynamic>> _tags = const [];

  int? _selectedCategory;
  String _selectedCategoryName = '';
  int? _selectedTag;
  ProductFilter _productFilter = ProductFilter.all;

  List<Product> _items = const [];
  final Set<int> _seenIds = {};

  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  static const _perPage = 12;
  bool _filtersExpanded = false;
  static const int _newDaysThreshold = 30;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    try {
      try {
        _categories = await ref.read(shopRepositoryProvider).fetchCategories(perPage: 100);
      } catch (_) {
        _categories = const [];
      }
      _tags = await ref.read(shopRepositoryProvider).fetchTags(perPage: 100);
      await _reloadProducts();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _getCategoryImage(String name) {
    for (var entry in myCategoryImages.entries) {
      if (name.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  // ==========================================
  // 🌳 ويدجت الشجرة (Tree Widget) - مع تخصيص الألوان
  // ==========================================
  Widget _buildCategoryTreeWidget() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 🎨 تعريف الألوان حسب الثيم (ليلي/نهاري)
    final pinkColor = theme.colorScheme.primary;
    const goldColor = Color(0xFFFFD700);

    // 1. لون الإطار
    final borderColor = isDark ? pinkColor : Colors.grey.shade300;
    // 2. لون النص الافتراضي
    final defaultTextColor = isDark ? pinkColor : Colors.black; // ✅ أسود قوي
    // 3. لون الأيقونة الافتراضي (التعديل هنا)
    final defaultIconColor = isDark ? pinkColor : Colors.black; // ✅ أسود قوي بدلاً من الرمادي
    // 4. لون العنصر المحدد
    final selectedItemColor = isDark ? goldColor : pinkColor;

    final allCats = _categories.map((c) {
      return {
        'id': int.tryParse(c['id'].toString()) ?? 0,
        'name': c['name'].toString(),
        'parent': int.tryParse(c['parent'].toString()) ?? 0,
      };
    }).toList();

    final Map<int, List<Map<String, dynamic>>> childrenMap = {};
    for (var cat in allCats) {
      final parentId = cat['parent'] as int;
      if (parentId != 0) {
        if (!childrenMap.containsKey(parentId)) {
          childrenMap[parentId] = [];
        }
        childrenMap[parentId]!.add(cat);
      }
    }

    final parents = allCats.where((c) => c['parent'] == 0).toList();

    if (allCats.isEmpty) return const SizedBox();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
        color: theme.cardColor,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: parents.length,
        separatorBuilder: (ctx, i) => Divider(height: 1, color: isDark ? pinkColor.withOpacity(0.2) : null),
        itemBuilder: (context, i) {
          final parent = parents[i];
          final parentId = parent['id'] as int;
          final parentName = parent['name'] as String;

          final String? parentImagePath = _getCategoryImage(parentName);
          final children = childrenMap[parentId] ?? [];

          // === الحالة 1: تصنيف أب وحيد ===
          if (children.isEmpty) {
            final isSelected = _selectedCategory == parentId;
            final currentColor = isSelected ? selectedItemColor : defaultTextColor;
            final currentIconColor = isSelected ? selectedItemColor : defaultIconColor;

            return ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              title: Text(
                parentName,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: currentColor,
                ),
              ),
              leading: parentImagePath != null
                  ? Image.asset(
                parentImagePath,
                width: 24, height: 24,
                color: currentIconColor,
              )
                  : Icon(
                Icons.circle_outlined,
                size: 16,
                color: currentIconColor,
              ),
              trailing: isSelected
                  ? Icon(Icons.check_circle, size: 20, color: selectedItemColor)
                  : null,
              tileColor: isSelected ? selectedItemColor.withOpacity(0.05) : null,
              onTap: () {
                setState(() {
                  if (_selectedCategory == parentId) {
                    _selectedCategory = null;
                    _selectedCategoryName = '';
                  } else {
                    _selectedCategory = parentId;
                    _selectedCategoryName = parentName;
                  }
                });
              },
            );
          }

          // === الحالة 2: تصنيف أب له فروع ===
          final isChildSelected = children.any((c) => c['id'] == _selectedCategory);
          final isParentSelected = _selectedCategory == parentId;
          final isExpanded = isParentSelected || isChildSelected;

          final parentCurrentColor = isParentSelected ? selectedItemColor : defaultTextColor;
          final parentCurrentIconColor = isParentSelected ? selectedItemColor : defaultIconColor;

          return Theme(
            data: theme.copyWith(
                dividerColor: Colors.transparent,
                expansionTileTheme: ExpansionTileThemeData(
                  textColor: selectedItemColor,
                  iconColor: selectedItemColor,
                )
            ),
            child: ExpansionTile(
              key: Key('cat_expansion_$parentId'),
              initiallyExpanded: isExpanded,

              title: Text(
                parentName,
                style: TextStyle(
                  fontWeight: isParentSelected ? FontWeight.bold : FontWeight.w600,
                  color: parentCurrentColor,
                ),
              ),
              leading: parentImagePath != null
                  ? Image.asset(
                parentImagePath,
                width: 24, height: 24,
                color: parentCurrentIconColor,
              )
                  : Icon(
                isParentSelected ? Icons.folder : Icons.folder_open,
                color: parentCurrentIconColor,
              ),
              children: [
                // خيار عرض الكل
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsetsDirectional.only(start: 40, end: 10),
                  title: Text(
                    "عرض كل $parentName",
                    style: TextStyle(
                      fontWeight: (_selectedCategory == parentId) ? FontWeight.bold : FontWeight.normal,
                      color: (_selectedCategory == parentId) ? selectedItemColor : defaultTextColor,
                      fontSize: 13,
                    ),
                  ),
                  leading: Icon(
                    Icons.grid_view,
                    size: 18,
                    // ✅ تم إلغاء الشفافية ليكون أسود واضح
                    color: (_selectedCategory == parentId) ? selectedItemColor : defaultIconColor,
                  ),
                  trailing: (_selectedCategory == parentId)
                      ? Icon(Icons.check, size: 18, color: selectedItemColor)
                      : null,
                  tileColor: (_selectedCategory == parentId) ? selectedItemColor.withOpacity(0.05) : null,
                  onTap: () {
                    setState(() {
                      if (_selectedCategory == parentId) {
                        _selectedCategory = null;
                        _selectedCategoryName = '';
                      } else {
                        _selectedCategory = parentId;
                        _selectedCategoryName = parentName;
                      }
                    });
                  },
                ),

                // الأبناء
                ...children.map((child) {
                  final childId = child['id'] as int;
                  final childName = child['name'] as String;
                  final isMeSelected = _selectedCategory == childId;

                  final String? childImagePath = _getCategoryImage(childName);

                  final childCurrentColor = isMeSelected ? selectedItemColor : defaultTextColor;
                  final childCurrentIconColor = isMeSelected ? selectedItemColor : defaultIconColor;

                  return ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: const EdgeInsetsDirectional.only(start: 40, end: 10),
                    title: Text(
                      childName,
                      style: TextStyle(
                        fontWeight: isMeSelected ? FontWeight.bold : FontWeight.normal,
                        color: childCurrentColor,
                      ),
                    ),
                    leading: childImagePath != null
                        ? Image.asset(
                      childImagePath,
                      width: 20, height: 20,
                      color: childCurrentIconColor,
                    )
                        : Icon(
                      Icons.subdirectory_arrow_right,
                      size: 16,
                      // ✅ تم إزالة الشفافية ليكون السهم واضحاً
                      color: childCurrentIconColor,
                    ),
                    trailing: isMeSelected ? Icon(Icons.check, size: 18, color: selectedItemColor) : null,
                    tileColor: isMeSelected ? selectedItemColor.withOpacity(0.05) : null,
                    onTap: () {
                      setState(() {
                        if (_selectedCategory == childId) {
                          _selectedCategory = null;
                          _selectedCategoryName = '';
                        } else {
                          _selectedCategory = childId;
                          _selectedCategoryName = childName;
                        }
                      });
                    },
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // بقية الكود (بدون تغيير)
  // ==========================================

  DateTime _computeAfterIsoForNewest() {
    final cutoff = DateTime.now().toUtc().subtract(const Duration(days: _newDaysThreshold));
    return cutoff;
  }

  Future<void> _reloadProducts() async {
    setState(() {
      _loading = true;
      _page = 1;
      _hasMore = true;
      _items = const [];
      _seenIds.clear();
    });

    int fetchPage = 1;
    List<Product> collected = [];

    final bool wantOnSale = _productFilter == ProductFilter.onSale;
    final bool wantNewest = _productFilter == ProductFilter.newest;
    final String? afterIso = wantNewest ? _computeAfterIsoForNewest().toIso8601String() : null;

    while (collected.length < _perPage && _hasMore) {
      final pageItems = await ref.read(shopRepositoryProvider).fetchProducts(
        page: fetchPage,
        perPage: _perPage,
        category: _selectedCategory,
        tagId: _selectedTag,
        search: null,
        order: 'desc',
        orderby: wantNewest ? 'date' : 'date',
        onSale: wantOnSale ? true : null,
        afterIso: afterIso,
      );

      if (pageItems.isEmpty) {
        _hasMore = false;
        break;
      }

      final filtered = pageItems.where((p) {
        final q = _searchCtrl.text.trim();
        if (q.isNotEmpty) {
          final name = (p.name ?? '').toLowerCase();
          if (!name.contains(q.toLowerCase())) return false;
        }
        if (wantOnSale) {
          final rp = _toDouble(p.regularPrice);
          final sp = _toDouble(p.salePrice);
          final onSaleClient = p.onSale == true || (rp != null && sp != null && sp < rp);
          if (!onSaleClient) return false;
        }
        return true;
      }).toList();

      final unique = filtered.where((p) => !_seenIds.contains(p.id)).toList();
      for (final p in unique) {
        _seenIds.add(p.id);
      }

      collected.addAll(unique);
      _hasMore = pageItems.length == _perPage;
      fetchPage += 1;
      if (fetchPage > 20) break;
    }

    final newList = List<Product>.from(collected)..shuffle();

    setState(() {
      _items = newList;
      _page = fetchPage - 1;
      _loading = false;
    });
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);

    int fetchPage = _page + 1;
    List<Product> collected = [];

    final bool wantOnSale = _productFilter == ProductFilter.onSale;
    final bool wantNewest = _productFilter == ProductFilter.newest;
    final String? afterIso = wantNewest ? _computeAfterIsoForNewest().toIso8601String() : null;

    while (collected.length < _perPage && _hasMore) {
      final nextPage = await ref.read(shopRepositoryProvider).fetchProducts(
        page: fetchPage,
        perPage: _perPage,
        category: _selectedCategory,
        tagId: _selectedTag,
        search: null,
        order: 'desc',
        orderby: wantNewest ? 'date' : 'date',
        onSale: wantOnSale ? true : null,
        afterIso: afterIso,
      );

      if (nextPage.isEmpty) {
        _hasMore = false;
        break;
      }

      final filtered = nextPage.where((p) {
        final q = _searchCtrl.text.trim();
        if (q.isNotEmpty) {
          final name = (p.name ?? '').toLowerCase();
          if (!name.contains(q.toLowerCase())) return false;
        }
        if (wantOnSale) {
          final rp = _toDouble(p.regularPrice);
          final sp = _toDouble(p.salePrice);
          final onSaleClient = p.onSale == true || (rp != null && sp != null && sp < rp);
          if (!onSaleClient) return false;
        }
        return true;
      }).toList();

      final unique = filtered.where((p) => !_seenIds.contains(p.id)).toList();
      for (final p in unique) {
        _seenIds.add(p.id);
      }

      collected.addAll(unique);
      _hasMore = nextPage.length == _perPage;
      fetchPage += 1;
      if (fetchPage > _page + 20) break;
    }

    final processedNext = List<Product>.from(collected)..shuffle();

    setState(() {
      _items = [..._items, ...processedNext];
      _page = fetchPage - 1;
      _loading = false;
    });
  }

  double? _toDouble(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.replaceAll(RegExp(r'[^0-9\.\-]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  bool _hasDiscount(Product p) {
    final rp = _toDouble(p.regularPrice);
    final sp = _toDouble(p.salePrice);
    if (rp == null || sp == null) return false;
    if (rp <= 0 || sp <= 0) return false;
    return sp < rp;
  }

  String? _formatPriceStr(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return formatPrice(raw, ref) ?? raw;
  }

  String _discountText(Product p) {
    final rp = _toDouble(p.regularPrice);
    final sp = _toDouble(p.salePrice);
    if (rp != null && sp != null && rp > 0 && sp < rp) {
      final pct = ((rp - sp) / rp * 100).round();
      return '-$pct%';
    }
    return 'تخفيض';
  }

  Widget _buildPrice(Product p) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final strikeColor = scheme.error;
    final priceColor = scheme.primary;
    final hasDisc = _hasDiscount(p);
    final currentRaw = hasDisc ? (p.salePrice ?? p.price) : (p.price ?? p.salePrice);
    final regularRaw = p.regularPrice;
    final current = _formatPriceStr(currentRaw);
    final regular = _formatPriceStr(regularRaw);

    if (!hasDisc || current == null) {
      return Text(
        current ?? '',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: priceColor),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          current,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: priceColor),
        ),
        const SizedBox(height: 2),
        if (regular != null)
          Text(
            regular,
            style: TextStyle(
              decoration: TextDecoration.lineThrough,
              decorationColor: strikeColor,
              decorationThickness: 1.6,
              fontSize: 11,
              color: scheme.onSurface.withOpacity(theme.brightness == Brightness.dark ? 0.6 : 0.45),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ تعريف متغيرات الثيم لاستخدامها في الأزرار
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pinkColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المتجر'),
        centerTitle: true,
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (sn) {
          if (sn.metrics.pixels >= sn.metrics.maxScrollExtent - 300) {
            _loadMore();
          }
          return false;
        },
        child: RefreshIndicator(
          onRefresh: _reloadProducts,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Card(
                child: ExpansionTile(
                  key: Key('filter_panel_$_filtersExpanded'),
                  initiallyExpanded: _filtersExpanded,
                  onExpansionChanged: (v) => setState(() => _filtersExpanded = v),
                  title: const Text('فلاتر البحث', style: TextStyle(fontWeight: FontWeight.bold)),
                  leading: const Icon(Icons.filter_list),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: TextField(
                        controller: _searchCtrl,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'ابحث عن منتج…',
                          prefixIcon: const Icon(Icons.search),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onSubmitted: (_) => _reloadProducts(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCategoryTreeWidget(),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: DropdownButtonFormField<int?>(
                            isExpanded: true,
                            value: _selectedTag,
                            decoration: const InputDecoration(
                              labelText: 'العلامة التجارية (Brand)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('الكل')),
                              ..._tags.map((t) {
                                final name = (t['name'] ?? '').toString();
                                return DropdownMenuItem<int?>(
                                  value: (t['id'] as num?)?.toInt(),
                                  child: Text(name),
                                );
                              }),
                            ],
                            onChanged: (v) => setState(() => _selectedTag = v),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: DropdownButtonFormField<ProductFilter>(
                            isExpanded: true,
                            value: _productFilter,
                            decoration: const InputDecoration(
                              labelText: 'ترتيب حسب',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                            ),
                            items: const [
                              DropdownMenuItem(value: ProductFilter.all, child: Text('الكل')),
                              DropdownMenuItem(value: ProductFilter.newest, child: Text('الجديد فقط')),
                              DropdownMenuItem(value: ProductFilter.onSale, child: Text('العروض فقط')),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _productFilter = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // ✅✅✅ الأزرار ✅✅✅
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              setState(() => _filtersExpanded = false);
                              _reloadProducts();
                            },
                            // إضافة إطار زهري فقط في الوضع الليلي
                            style: FilledButton.styleFrom(
                              side: isDark ? BorderSide(color: pinkColor, width: 1.5) : null,
                            ),
                            icon: const Icon(Icons.check),
                            label: const Text('عرض النتائج'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = null;
                              _selectedCategoryName = '';
                              _selectedTag = null;
                              _productFilter = ProductFilter.all;
                              _searchCtrl.clear();
                            });
                            _reloadProducts();
                          },
                          // إضافة إطار زهري فقط في الوضع الليلي
                          style: OutlinedButton.styleFrom(
                            side: isDark ? BorderSide(color: pinkColor, width: 1.5) : null,
                          ),
                          child: const Text('مسح'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_items.isEmpty && _loading)
                const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Center(child: CircularProgressIndicator()))
              else if (_items.isEmpty)
                GestureDetector(
                  onTap: () {
                    if (_filtersExpanded) setState(() => _filtersExpanded = false);
                  },
                  child: const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Center(child: Text('لا توجد منتجات مطابقة'))),
                )
              else
                GestureDetector(
                  onTap: () {
                    if (_filtersExpanded) setState(() => _filtersExpanded = false);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: .72,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemBuilder: (_, i) {
                      final p = _items[i];
                      final hasDisc = _hasDiscount(p);
                      final brandName = p.brand;
                      final theme = Theme.of(context);
                      return InkWell(
                        onTap: () {
                          if (_filtersExpanded) {
                            setState(() => _filtersExpanded = false);
                            return;
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProductDetailsScreen(productId: p.id, initial: p),
                            ),
                          );
                        },
                        child: Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: p.image != null
                                          ? CachedNetworkImage(imageUrl: p.image!, fit: BoxFit.cover)
                                          : const ColoredBox(color: Color(0x11000000)),
                                    ),
                                    if (hasDisc)
                                      Positioned(
                                        top: 8, left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(8)),
                                          child: Text(_discountText(p), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    if (!p.inStock)
                                      Positioned(
                                        top: 8, right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                          decoration: BoxDecoration(color: theme.colorScheme.onSurface.withOpacity(0.9), borderRadius: BorderRadius.circular(8)),
                                          child: Text('نفد من المخزون', style: TextStyle(color: theme.brightness == Brightness.dark ? theme.colorScheme.primary : Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: theme.colorScheme.onSurface)),
                                    if (brandName != null && brandName.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(brandName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.7))),
                                    ],
                                    const SizedBox(height: 6),
                                    _buildPrice(p),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              if (_loading && _items.isNotEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: CircularProgressIndicator())),
              if (!_loading && !_hasMore && _items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'لا مزيد من المنتجات',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}