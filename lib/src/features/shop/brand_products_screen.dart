import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/currency.dart';
import '../../data/models/product.dart';
import '../../data/repositories/shop_repository.dart';
import 'product_details_screen.dart';

/// شاشة لعرض منتجات مفلترة حسب وسم (tagId) أو بحث باسم الماركة (searchName)
class BrandProductsScreen extends ConsumerStatefulWidget {
  final int? tagId;            // فلترة دقيقة بالوسم إن توفر
  final String? searchName;    // بديل: بحث نصّي باسم الماركة
  final String title;          // العنوان الظاهر في AppBar

  const BrandProductsScreen({
    super.key,
    this.tagId,
    this.searchName,
    required this.title,
  });

  @override
  ConsumerState<BrandProductsScreen> createState() => _BrandProductsScreenState();
}

class _BrandProductsScreenState extends ConsumerState<BrandProductsScreen> {
  final _scroll = ScrollController();

  final List<Product> _items = [];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  static const _perPage = 12;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _items.clear();
      _page = 1;
      _hasMore = true;
      _loading = true;
    });

    try {
      final repo = ref.read(shopRepositoryProvider);
      final first = await repo.fetchProducts(
        page: 1,
        perPage: _perPage,
        tagId: widget.tagId,
        search: widget.searchName,
      );
      setState(() {
        _items.addAll(first);
        _hasMore = first.length == _perPage;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر التحميل: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);

    try {
      final repo = ref.read(shopRepositoryProvider);
      final next = await repo.fetchProducts(
        page: _page + 1,
        perPage: _perPage,
        tagId: widget.tagId,
        search: widget.searchName,
      );
      setState(() {
        _page += 1;
        _items.addAll(next);
        _hasMore = next.length == _perPage;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _hasMore = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا مزيد من النتائج')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmtPrice(String? raw, WidgetRef ref) {
    // formatPrice قد تعيد null — نعطي فالباك واضح
    final f = (raw == null || raw.isEmpty) ? null : formatPrice(raw, ref);
    return f ?? '-';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: RefreshIndicator(
        onRefresh: _loadInitial,
        child: GridView.builder(
          controller: _scroll,
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // شبكي 2 عامود
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: .68,
          ),
          itemCount: _items.length + (_loading ? 2 : 0),
          itemBuilder: (_, i) {
            if (i >= _items.length) {
              return const Center(child: CircularProgressIndicator());
            }
            final p = _items[i];
            return InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductDetailsScreen(productId: p.id, initial: p),
                  ),
                );
              },
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: (p.image != null && p.image!.isNotEmpty)
                          ? CachedNetworkImage(imageUrl: p.image!, fit: BoxFit.cover)
                          : const ColoredBox(color: Color(0x11000000)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _fmtPrice(p.price, ref),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
