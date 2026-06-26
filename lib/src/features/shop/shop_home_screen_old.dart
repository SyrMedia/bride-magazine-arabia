import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/product.dart';
import '../../data/repositories/shop_repository.dart';
import '../../core/currency.dart';
import '../shop/product_details_screen.dart';

class ShopHomeScreen extends ConsumerStatefulWidget {
  const ShopHomeScreen({super.key});

  @override
  ConsumerState<ShopHomeScreen> createState() => _ShopHomeScreenState();
}

class _ShopHomeScreenState extends ConsumerState<ShopHomeScreen> {
  // بحث
  final _searchCtrl = TextEditingController();

  // فلاتر
  List<Map<String, dynamic>> _categories = const []; // [{id,name}]
  List<Map<String, dynamic>> _tags = const []; // [{id,name,slug,count}]
  int? _selectedCategory;
  int? _selectedTag;

  // منتجات
  List<Product> _items = const [];

  // تحميل وتقسيم صفحات
  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  static const _perPage = 12;

  // إظهار/إخفاء الفلاتر
  bool _filtersExpanded = false;

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
      // التصنيفات
      try {
        _categories = await ref.read(shopRepositoryProvider).fetchCategories();
      } catch (_) {
        _categories = const [];
      }

      // التاجات
      _tags = await ref.read(shopRepositoryProvider).fetchTags(perPage: 100);

      // أول دفعة منتجات
      await _reloadProducts();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reloadProducts() async {
    setState(() {
      _loading = true;
      _page = 1;
      _hasMore = true;
      _items = const [];
    });

    final first = await ref.read(shopRepositoryProvider).fetchProducts(
      page: 1,
      perPage: _perPage,
      category: _selectedCategory,
      tagId: _selectedTag,
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      order: 'desc',
      orderby: 'date',
    );

    setState(() {
      _items = first;
      _hasMore = first.length == _perPage;
      _page = 1;
      _loading = false;
    });
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);

    final next = await ref.read(shopRepositoryProvider).fetchProducts(
      page: _page + 1,
      perPage: _perPage,
      category: _selectedCategory,
      tagId: _selectedTag,
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      order: 'desc',
      orderby: 'date',
    );

    setState(() {
      _items = [..._items, ...next];
      _page += 1;
      _hasMore = next.length == _perPage;
      _loading = false;
    });
  }

  // ===== تنسيقات الأسعار =====

  String? _formatPriceStr(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return formatPrice(raw, ref) ?? raw;
  }

  /// نص البادج (نسبة الخصم أو كلمة "تخفيض")
  String _discountText(Product p) {
    final rp = double.tryParse(p.regularPrice ?? '');
    final sp = double.tryParse(p.salePrice ?? '');
    if (rp != null && sp != null && rp > 0 && sp < rp) {
      final pct = ((rp - sp) / rp * 100).round();
      return '-$pct%';
    }
    return 'تخفيض';
  }

  /// يبني ودجت السعر (سعر جديد + سعر قديم مشطوب إن وُجد خصم)
  Widget _buildPrice(Product p) {
    final current = _formatPriceStr(p.salePrice ?? p.price);
    final regular = _formatPriceStr(p.regularPrice);

    // في حال ما في خصم أو معلومات ناقصة -> اعرض سعر واحد فقط
    if (!p.onSale || current == null || regular == null || current == regular) {
      return Text(
        current ?? '',
        style: const TextStyle(fontWeight: FontWeight.w800),
      );
    }

    // في حال الخصم فعّال
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          current,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          regular,
          style: const TextStyle(
            decoration: TextDecoration.lineThrough,
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
              // شريط الفلاتر
              Card(
                child: ExpansionTile(
                  initiallyExpanded: _filtersExpanded,
                  onExpansionChanged: (v) =>
                      setState(() => _filtersExpanded = v),
                  title: const Text('فلاتر البحث'),
                  childrenPadding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    // حقل البحث
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: TextField(
                        controller: _searchCtrl,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'ابحث عن منتج…',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onSubmitted: (_) => _reloadProducts(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // صف Dropdowns (تصنيف + تاج)
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        // تصنيف
                        SizedBox(
                          width: 280,
                          child: DropdownButtonFormField<int?>(
                            isExpanded: true,
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'التصنيف',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('كل التصنيفات'),
                              ),
                              ..._categories.map((c) {
                                return DropdownMenuItem<int?>(
                                  value: (c['id'] as num?)?.toInt(),
                                  child:
                                  Text((c['name'] ?? '').toString()),
                                );
                              }),
                            ],
                            onChanged: (v) =>
                                setState(() => _selectedCategory = v),
                          ),
                        ),

                        // التاجات
                        SizedBox(
                          width: 280,
                          child: DropdownButtonFormField<int?>(
                            isExpanded: true,
                            value: _selectedTag,
                            decoration: const InputDecoration(
                              labelText: 'العلامة (Tag/Marca)',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('كل العلامات'),
                              ),
                              ..._tags.map((t) {
                                final name =
                                (t['name'] ?? '').toString();
                                final count = (t['count'] is num)
                                    ? (t['count'] as num).toInt()
                                    : 0;
                                return DropdownMenuItem<int?>(
                                  value: (t['id'] as num?)?.toInt(),
                                  child: Text(
                                    count > 0 ? '$name ($count)' : name,
                                  ),
                                );
                              }),
                            ],
                            onChanged: (v) =>
                                setState(() => _selectedTag = v),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: _reloadProducts,
                          icon: const Icon(Icons.filter_alt),
                          label: const Text('تطبيق'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = null;
                              _selectedTag = null;
                              _searchCtrl.clear();
                            });
                            _reloadProducts();
                          },
                          child: const Text('محو الفلاتر'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // شبكة المنتجات
              if (_items.isEmpty && _loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: Text('لا توجد منتجات')),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _items.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: .72,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemBuilder: (_, i) {
                    final p = _items[i];
                    return InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProductDetailsScreen(
                              productId: p.id,
                              initial: p,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: p.image != null
                                        ? CachedNetworkImage(
                                      imageUrl: p.image!,
                                      fit: BoxFit.cover,
                                    )
                                        : const ColoredBox(
                                      color: Color(0x11000000),
                                    ),
                                  ),
                                  if (p.onSale)
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding:
                                        const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent,
                                          borderRadius:
                                          BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _discountText(p),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
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

              if (_loading && _items.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (!_loading && !_hasMore && _items.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text('لا مزيد من المنتجات'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
