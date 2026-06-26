// lib/src/features/magazine/magazine_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/wp_post.dart';
import '../../data/repositories/wp_repository.dart';
import '../magazine/article_screen.dart';

class MagazineScreen extends ConsumerStatefulWidget {
  const MagazineScreen({super.key});

  @override
  ConsumerState<MagazineScreen> createState() => _MagazineScreenState();
}

class _MagazineScreenState extends ConsumerState<MagazineScreen> {
  final _scroll = ScrollController();
  final _searchCtrl = TextEditingController();

  // سكشنات
  List<Map<String, dynamic>> _sections = const [];
  int? _selectedSection; // null = الكل

  // الأعداد (مع بيانات ميتا من الـ API)
  // [{id,name,cover,release_date,is_upcoming}]
  List<Map<String, dynamic>> _issues = const [];
  int? _currentIssueId; // العدد الحالي (غير upcoming والأحدث)
  int? _previousIssueId; // العدد السابق مباشرة

  // مقالات كنماذج
  final List<WpPost> _posts = [];

  // صفحة/تحميل
  int _page = 1;
  int _totalPages = 1;
  bool _loading = false;
  bool _hasMore = true;

  static const int _perPage = 10;

  // الفلتر الحالي للأعداد
  IssueChip _selectedIssueChip = IssueChip.current;

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
    _searchCtrl.dispose();
    super.dispose();
  }

  String _cleanText(String? t) =>
      (t ?? '').replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ').trim();

  // 🛠️ تم التعديل هنا: تطبيق المنطق الزمني وإزالة firstWhere/orElse
  Future<void> _ensureFiltersLoaded() async {
    if (_sections.isEmpty) {
      final secs = await ref.read(wpRepoProvider).fetchSections();
      _sections = secs;
    }

    if (_issues.isEmpty) {
      final iss = await ref.read(wpRepoProvider).fetchIssues();
      _issues = iss;

      if (iss.isNotEmpty) {
        final now = DateTime.now();

        // 1. تصفية وتحويل الأعداد إلى صيغة تحتوي على تاريخ DateTime
        final allIssues = iss.map((c) {
          final dateStr = (c['release_date'] ?? '').toString();
          final date = DateTime.tryParse(dateStr);
          // 🛠️ نستخدم cast لفرض نوع آمن لتجنب RSOD
          return {'data': c, 'date': date}.cast<String, dynamic>();
        }).where((e) => e['date'] != null).toList();

        // 2. ترتيب جميع الأعداد زمنياً (من الأقدم للأحدث)
        allIssues.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

        // 3. تحديد العدد الحالي (آخر عدد تم نشره/حان موعد نشره)
        Map<String, dynamic>? current;
        int currentIndex = -1;

        // نبحث بدءاً من الأحدث (نهاية القائمة) للوراء
        for (int i = allIssues.length - 1; i >= 0; i--) {
          final issue = allIssues[i];
          final releaseDate = issue['date'] as DateTime;

          if (releaseDate.isBefore(now) || releaseDate.isAtSameMomentAs(now)) {
            // وجدنا أحدث عدد منشور
            current = issue['data'] as Map<String, dynamic>;
            currentIndex = i;
            break;
          }
        }

        // 4. تحديد العدد السابق (العدد الذي يسبق الحالي مباشرة في القائمة الزمنية)
        Map<String, dynamic>? previous;
        if (currentIndex > 0) {
          previous = allIssues[currentIndex - 1]['data'] as Map<String, dynamic>;
        }

        // 5. في حالة عدم وجود أي عدد منشور، نجعل العدد القادم الأول هو الحالي
        if (current == null && allIssues.isNotEmpty) {
          current = allIssues.first['data'] as Map<String, dynamic>;
        }

        _currentIssueId = current?['id'] as int?;
        _previousIssueId = previous?['id'] as int?;
      }
    }

    // إذا ما في عدد حالي لأي سبب، رجّع الفلتر لـ "كل الأعداد"
    if (_currentIssueId == null && _selectedIssueChip == IssueChip.current) {
      _selectedIssueChip = IssueChip.all;
    }
  }

  int? get _selectedIssueForFilter {
    switch (_selectedIssueChip) {
      case IssueChip.current:
        return _currentIssueId;
      case IssueChip.previous:
        return _previousIssueId;
      case IssueChip.all:
      default:
        return null;
    }
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
      // 1) السكشنات + الأعداد (مع تحديد العدد الحالي/السابق)
      await _ensureFiltersLoaded();

      // 2) أول صفحة مقالات (بحسب الفلتر الحالي)
      final pageResp = await ref.read(wpRepoProvider).fetchPostsPaged(
        page: 1,
        perPage: _perPage,
        section: _selectedSection,
        issue: _selectedIssueForFilter,
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        order: 'desc',
        orderby: 'date',
      );

      setState(() {
        _page = pageResp.page;
        _totalPages = pageResp.totalPages;
        _posts.addAll(pageResp.posts);
        _hasMore = _page < _totalPages && pageResp.posts.isNotEmpty;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تحميل البيانات: $e')),
        );
      }
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
      final nextResp = await ref.read(wpRepoProvider).fetchPostsPaged(
        page: _page + 1,
        perPage: _perPage,
        section: _selectedSection,
        issue: _selectedIssueForFilter,
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        order: 'desc',
        orderby: 'date',
      );

      setState(() {
        _page = nextResp.page;
        _totalPages = nextResp.totalPages;
        _posts.addAll(nextResp.posts);
        _hasMore = _page < _totalPages && nextResp.posts.isNotEmpty;
      });
    } catch (_) {
      setState(() => _hasMore = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا مزيد من النتائج.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _onRefresh() => _loadInitial();

  void _onTapPost(WpPost p) {
    final id = p.id;
    if (id == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ArticleScreen(postId: id)),
    );
  }

  // ===== غلاف العدد الحالي =====
  Widget _buildCurrentCover() {
    if (_issues.isEmpty || _currentIssueId == null) return const SizedBox.shrink();

    // 🛠️ تم الحل هنا: استخدام try-catch و cast لضمان أن currentIssueMap صحيح
    Map<String, dynamic> currentIssueMap;
    try {
      currentIssueMap = _issues.firstWhere(
            (it) => it['id'] == _currentIssueId,
      ).cast<String, dynamic>();
    } catch (_) {
      // في حالة فشل البحث (وهو نادر جداً بعد تهيئة _currentIssueId)، نستخدم أحدث عدد متوفر كـ Fallback
      final latest = _issues.toList();
      latest.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
      if (latest.isNotEmpty) {
        currentIssueMap = latest.first.cast<String, dynamic>();
      } else {
        return const SizedBox.shrink();
      }
    }

    final url = (currentIssueMap['cover'] ?? '').toString().trim();
    if (url.isEmpty) return const SizedBox.shrink();

    final title = (currentIssueMap['name'] ?? '').toString().trim();

    final width = MediaQuery.of(context).size.width;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final targetCacheWidth = (width * dpr).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title.isEmpty ? 'العدد الحالي' : title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.fitWidth,
            width: double.infinity,
            memCacheWidth: targetCacheWidth,
            fadeInDuration: const Duration(milliseconds: 200),
            placeholder: (ctx, _) => Container(
              height: 180,
              color: Colors.black12,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
            errorWidget: (ctx, _, __) => Container(
              color: Colors.black12,
              height: 180,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image),
            ),
          ),
        ),
      ],
    );
  }

  // ===== كرت عدد (يُستخدم للعدد السابق / القادم) =====
  Widget _buildIssueCard({
    required String cover,
    required String title,
    required String releaseDate,
    VoidCallback? onTap,
  }) {
    final hasCover = cover.trim().isNotEmpty;
    final theme = Theme.of(context);

    final inner = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 2 / 3,
            child: hasCover
                ? CachedNetworkImage(
              imageUrl: cover,
              fit: BoxFit.cover,
              placeholder: (ctx, url) => Container(
                color: Colors.black12,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
              errorWidget: (ctx, url, error) => Container(
                color: Colors.black12,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image),
              ),
            )
                : Container(
              color: Colors.black12,
              alignment: Alignment.center,
              child: const Icon(Icons.menu_book_outlined),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            height: 1.3,
          ),
        ),
        if (releaseDate.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            releaseDate,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
        ],
      ],
    );

    final card = Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: inner,
      ),
    );

    if (onTap == null) {
      return SizedBox(
        width: 160,
        child: card,
      );
    }

    return SizedBox(
      width: 160,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: card,
      ),
    );
  }

  // ===== صف "العدد السابق" + "العدد القادم" =====
  Widget _buildPrevAndUpcomingRow() {
    if (_issues.isEmpty) return const SizedBox.shrink();

    Map<String, dynamic>? previous;
    Map<String, dynamic>? upcoming;

    // 1. تحديد العدد السابق باستخدام ID (المحدد بالمنطق الزمني في _ensureFiltersLoaded)
    if (_previousIssueId != null) {
      try {
        previous = _issues.firstWhere(
              (e) => e['id'] == _previousIssueId,
        ).cast<String, dynamic>();
      } catch (_) {
        previous = null;
      }
    }

    // 2. تحديد العدد القادم (الأقرب زمنياً)
    final now = DateTime.now();
    final allIssues = _issues.map((c) {
      final dateStr = (c['release_date'] ?? '').toString();
      final date = DateTime.tryParse(dateStr);
      // 🛠️ تم التصحيح هنا
      return {'data': c, 'date': date}.cast<String, dynamic>();
    }).where((e) => e['date'] != null).toList();

    // ترتيب الأعداد من الأقدم للأحدث
    allIssues.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    // البحث عن أول عدد تاريخه لم يأتِ بعد (الأقرب للمستقبل)
    final upcomingList = allIssues
        .where((i) => (i['date'] as DateTime).isAfter(now))
        .toList();

    if (upcomingList.isNotEmpty) {
      upcoming = upcomingList.first['data'] as Map<String, dynamic>;
    }

    if (previous == null && upcoming == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (upcoming != null) ...[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'العدد القادم',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildIssueCard(
                      cover: (upcoming['cover'] ?? '').toString(),
                      title: (upcoming['name'] ?? '').toString(),
                      releaseDate:
                      (upcoming['release_date'] ?? '').toString(),
                      onTap: null, // للعرض فقط
                    ),
                  ],
                ),
              ),
            ],
            if (upcoming != null && previous != null)
              const SizedBox(width: 12),
            if (previous != null) ...[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'العدد السابق',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildIssueCard(
                      cover: (previous['cover'] ?? '').toString(),
                      title: (previous['name'] ?? '').toString(),
                      releaseDate:
                      (previous['release_date'] ?? '').toString(),
                      onTap: () {
                        setState(() {
                          _selectedIssueChip = IssueChip.previous;
                        });
                        _loadInitial();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasIssues = _issues.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('المجلة')),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // غلاف العدد الحالي
            if (hasIssues) _buildCurrentCover(),
            if (hasIssues) const SizedBox(height: 12),

            // العدد السابق + العدد القادم
            if (hasIssues) _buildPrevAndUpcomingRow(),
            if (hasIssues) const SizedBox(height: 12),

            // ===== حقل البحث =====
            Directionality(
              textDirection: TextDirection.rtl,
              child: TextField(
                controller: _searchCtrl,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'ابحث في المقالات…',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (_) => _loadInitial(),
              ),
            ),
            const SizedBox(height: 12),

            // ===== فلتر الأعداد: العدد الحالي / كل الأعداد / العدد السابق =====
            if (hasIssues) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  children: [
                    // العدد الحالي
                    if (_currentIssueId != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: const Text('العدد الحالي'),
                          selected: _selectedIssueChip == IssueChip.current,
                          onSelected: (_) {
                            setState(() => _selectedIssueChip = IssueChip.current);
                            _loadInitial();
                          },
                        ),
                      ),
                    // كل الأعداد
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: const Text('كل الأعداد'),
                        selected: _selectedIssueChip == IssueChip.all,
                        onSelected: (_) {
                          setState(() => _selectedIssueChip = IssueChip.all);
                          _loadInitial();
                        },
                      ),
                    ),
                    // العدد السابق
                    if (_previousIssueId != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: const Text('العدد السابق'),
                          selected: _selectedIssueChip == IssueChip.previous,
                          onSelected: (_) {
                            setState(() => _selectedIssueChip = IssueChip.previous);
                            _loadInitial();
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // ===== فلتر السكشنات =====
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: const Text('الكل'),
                      selected: _selectedSection == null,
                      onSelected: (_) {
                        setState(() => _selectedSection = null);
                        _loadInitial();
                      },
                    ),
                  ),
                  // الفلاتر الفرعية (تم التعديل عليها لتعمل كمفتاح تبديل)
                  for (final s in _sections)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text((s['name'] ?? '').toString()),
                        selected: _selectedSection == s['id'],
                        onSelected: (isSelected) {
                          setState(() {
                            // إذا كان هذا الفلتر محدداً بالفعل، ألغه (null). وإلا، حدده.
                            if (_selectedSection == s['id']) {
                              _selectedSection = null;
                            } else {
                              _selectedSection = (s['id'] as num).toInt();
                            }
                          });
                          _loadInitial();
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ===== قائمة المقالات =====
            if (_posts.isEmpty && _loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_posts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: Text('لا توجد مقالات حالياً')),
              )
            else
              ..._posts.map((p) {
                final img = p.image;
                final title = _cleanText(p.title);
                final excerpt = _cleanText(p.excerpt ?? '');

                return Card(
                  clipBehavior: Clip.antiAlias,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _onTapPost(p),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (img != null && img.isNotEmpty)
                          SizedBox(
                            width: 120,
                            height: 100,
                            child: CachedNetworkImage(
                              imageUrl: img,
                              fit: BoxFit.cover,
                            ),
                          ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title.isEmpty ? 'بدون عنوان' : title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  excerpt,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                          ? 0.85
                                          : 0.72,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

            if (_loading && _posts.isNotEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!_hasMore && _posts.isNotEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('لا مزيد من المقالات')),
              ),
          ],
        ),
      ),
    );
  }
}

enum IssueChip { current, all, previous }