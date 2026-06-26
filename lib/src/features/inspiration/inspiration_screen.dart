// lib/src/features/inspiration/inspiration_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/wp_post.dart';
import '../../data/repositories/wp_repository.dart';
import '../magazine/article_screen.dart';

enum _Tax { season, style, palette }

class InspirationScreen extends ConsumerStatefulWidget {
  const InspirationScreen({super.key});

  @override
  ConsumerState<InspirationScreen> createState() => _InspirationScreenState();
}

class _InspirationScreenState extends ConsumerState<InspirationScreen> {
  final _scroll = ScrollController();

  // يمين: نوع الفلتر
  _Tax _selectedTax = _Tax.season;

  // مصطلحات كل تاكسنومي
  List<Map<String, dynamic>> _seasons = const [];
  List<Map<String, dynamic>> _styles = const [];
  List<Map<String, dynamic>> _palettes = const [];

  // يسار: المصطلح المختار
  int? _selectedTermId;

  // بيانات التصفح
  final List<WpPost> _posts = [];
  int _page = 1;
  int _totalPages = 1;
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

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _page = 1;
      _totalPages = 1;
      _hasMore = true;
      _posts.clear();
    });

    try {
      await _ensureTaxTermsLoaded();

      final pageResp = await _fetchInspiration(
        page: 1,
        tax: _selectedTax,
        termId: _selectedTermId,
      );

      setState(() {
        _posts.addAll(pageResp.posts);
        _page = pageResp.page;
        _totalPages = pageResp.totalPages;
        _hasMore = _page < _totalPages && pageResp.posts.isNotEmpty;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر تحميل الإلهام: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    if (_page >= _totalPages) {
      setState(() => _hasMore = false);
      return;
    }

    setState(() => _loading = true);
    try {
      final next = await _fetchInspiration(
        page: _page + 1,
        tax: _selectedTax,
        termId: _selectedTermId,
      );
      setState(() {
        _posts.addAll(next.posts);
        _page = next.page;
        _totalPages = next.totalPages;
        _hasMore = _page < _totalPages && next.posts.isNotEmpty;
      });
    } catch (_) {
      setState(() => _hasMore = false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) _loadMore();
  }

  Future<void> _ensureTaxTermsLoaded() async {
    final repo = ref.read(wpRepoProvider);
    if (_seasons.isEmpty) _seasons = await repo.fetchSeasons();
    if (_styles.isEmpty) _styles = await repo.fetchStyles();
    if (_palettes.isEmpty) _palettes = await repo.fetchPalettes();

    final terms = _termsFor(_selectedTax);
    if (_selectedTermId != null &&
        terms.indexWhere((e) => (e['id'] as num?)?.toInt() == _selectedTermId) == -1) {
      _selectedTermId = null;
    }
  }

  Future<WpPostsPage> _fetchInspiration({
    required int page,
    required _Tax tax,
    int? termId,
  }) {
    final repo = ref.read(wpRepoProvider);
    switch (tax) {
      case _Tax.season:
        return repo.fetchInspirationPaged(page: page, perPage: _perPage, season: termId);
      case _Tax.style:
        return repo.fetchInspirationPaged(page: page, perPage: _perPage, style: termId);
      case _Tax.palette:
        return repo.fetchInspirationPaged(page: page, perPage: _perPage, palette: termId);
    }
  }

  List<Map<String, dynamic>> _termsFor(_Tax tax) {
    switch (tax) {
      case _Tax.season:
        return _seasons;
      case _Tax.style:
        return _styles;
      case _Tax.palette:
        return _palettes;
    }
  }

  String _labelOfTax(_Tax t) {
    switch (t) {
      case _Tax.season:
        return 'سيزون';
      case _Tax.style:
        return 'ستايل';
      case _Tax.palette:
        return 'الألوان';
    }
  }

  Future<void> _onChangeTax(_Tax t) async {
    setState(() {
      _selectedTax = t;
      _selectedTermId = null;
    });
    await _loadInitial();
  }

  Future<void> _onChangeTerm(int? id) async {
    setState(() => _selectedTermId = id);
    await _loadInitial();
  }

  String _clean(String? t) =>
      (t ?? '').replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ').trim();

  void _openPost(WpPost p) {
    final id = p.id;
    if (id == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ArticleScreen(postId: id)),
    );
  }

  // ====== عنصر الكارد مع عنوان فقط فوق الصورة + تدرّج أغمق ======
  Widget _InspirationCard(WpPost p) {
    final img = p.image;
    final title = _clean(p.title);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _openPost(p),
        child: Stack(
          children: [
            // الصورة
            Positioned.fill(
              child: (img != null && img.isNotEmpty)
                  ? CachedNetworkImage(imageUrl: img, fit: BoxFit.cover)
                  : const ColoredBox(color: Color(0x11000000)),
            ),
            // تدرّج سفلي أغمق + عنوان فقط
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 36, 12, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: const Alignment(0, -0.1),
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.10),
                      Colors.black.withOpacity(0.72),
                      Colors.black.withOpacity(0.95), // أغمق
                    ],
                  ),
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    title.isEmpty ? 'بدون عنوان' : title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 17, // أكبر قليلًا
                      height: 1.22,
                      shadows: [
                        Shadow(color: Colors.black87, blurRadius: 3, offset: Offset(0, 1)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // تأثير لمس خفيف
            Positioned.fill(
              child: InkWell(
                onTap: () => _openPost(p),
                splashColor: Colors.white10,
                highlightColor: Colors.white10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final terms = _termsFor(_selectedTax);
    final ddPadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6);

    return Scaffold(
      appBar: AppBar(title: const Text('الإلهام')),
      body: RefreshIndicator(
        onRefresh: _loadInitial,
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // --- الفلاتر: نوع الفلتر (يمين) + المصطلح (يسار) ---
            Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: ddPadding,
                      child: DropdownButtonFormField<_Tax>(
                        isExpanded: true,
                        value: _selectedTax,
                        decoration: InputDecoration(
                          labelText: 'نوع الفلتر',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: const [
                          DropdownMenuItem(value: _Tax.season, child: Text('سيزون')),
                          DropdownMenuItem(value: _Tax.style, child: Text('ستايل')),
                          DropdownMenuItem(value: _Tax.palette, child: Text('الألوان')),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          _onChangeTax(v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: ddPadding,
                      child: DropdownButtonFormField<int?>(
                        isExpanded: true,
                        value: _selectedTermId,
                        decoration: InputDecoration(
                          labelText: _labelOfTax(_selectedTax),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('الكل'),
                          ),
                          ...terms.map((t) => DropdownMenuItem<int?>(
                            value: (t['id'] as num).toInt(),
                            child: Text((t['name'] ?? '').toString()),
                          )),
                        ],
                        onChanged: (v) => _onChangeTerm(v),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // --- الشبكة ---
            if (_posts.isEmpty && _loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_posts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: Text('لا توجد نتائج حالياً')),
              )
            else
              LayoutBuilder(
                builder: (ctx, c) {
                  final w = c.maxWidth;
                  final cross = w >= 900 ? 4 : (w >= 600 ? 3 : 2);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _posts.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cross,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 3 / 4,
                    ),
                    itemBuilder: (_, i) {
                      final p = _posts[i];
                      return _InspirationCard(p);
                    },
                  );
                },
              ),

            if (_loading && _posts.isNotEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!_hasMore && _posts.isNotEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('لا مزيد من النتائج')),
              ),
          ],
        ),
      ),
    );
  }
}
