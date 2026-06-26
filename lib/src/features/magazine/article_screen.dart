import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:html/dom.dart' as dom;

import '../../data/repositories/wp_repository.dart';
import '../../data/repositories/bookmarks_provider.dart';
import '../../data/models/wp_post.dart';

class ArticleScreen extends ConsumerStatefulWidget {
  final int postId;
  const ArticleScreen({super.key, required this.postId});

  @override
  ConsumerState<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends ConsumerState<ArticleScreen> {
  final _scrollCtrl = ScrollController();
  double _progress = 0.0;

  late Future<Map<String, dynamic>> _future;
  double _textScale = 1.0;

  // الرابط والعنوان الأحدث للمقال الحالي (يُحدَّثان بعد الجلب)
  String _latestLink = '';
  String _latestTitle = '';

  // ===== مشابه/التالي/السابق =====
  bool _loadingRelated = false;
  List<WpPost> _related = const [];
  int? _nextId; // الأحدث (حسب order=desc)
  int? _prevId; // الأقدم

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_calcProgress);
    _future = ref.read(wpRepoProvider).fetchPostRaw(widget.postId);
  }

  @override
  void didUpdateWidget(covariant ArticleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.postId != widget.postId) {
      // انتقلنا لمقال جديد: نظّف وحمّل من جديد
      _future = ref.read(wpRepoProvider).fetchPostRaw(widget.postId);
      _latestLink = '';
      _latestTitle = '';
      _related = const [];
      _nextId = null;
      _prevId = null;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_calcProgress);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _calcProgress() {
    if (!_scrollCtrl.hasClients) return;
    final max = _scrollCtrl.position.maxScrollExtent;
    final off = _scrollCtrl.offset;
    if (max <= 0) {
      setState(() => _progress = 0);
      return;
    }
    final p = (off / max).clamp(0.0, 1.0);
    if ((p - _progress).abs() > 0.003) {
      setState(() => _progress = p);
    }
  }

  Future<bool> _onTapUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  // ====== Elementor Gallery utils ======
  String? _bgUrlFromStyle(String? style) {
    if (style == null || style.isEmpty) return null;
    final re = RegExp(
      r'''background-image\s*:\s*url\((['"]?)([^'")]+)\1\)''',
      caseSensitive: false,
    );
    final m = re.firstMatch(style);
    return m?.group(2)?.trim();
  }

  List<String> _extractElementorGallery(dom.Element e) {
    final urls = <String>{};

    final bgImgs = e.getElementsByClassName('e-gallery-image');
    for (final el in bgImgs) {
      final u = _bgUrlFromStyle(el.attributes['style']);
      if (u != null && u.isNotEmpty) urls.add(u);

      final thumb = el.attributes['data-thumbnail']?.trim();
      if (thumb != null && thumb.isNotEmpty) urls.add(thumb);
    }

    final anchors = e.getElementsByTagName('a');
    final hrefRe = RegExp(r'\.(png|jpe?g|webp|gif)(\?.*)?$', caseSensitive: false);
    for (final a in anchors) {
      final href = a.attributes['href']?.trim();
      if (href != null && hrefRe.hasMatch(href)) urls.add(href);
    }
    return urls.toList();
  }

  bool _isElementorGallery(dom.Element e) {
    final tag = e.localName ?? '';
    final classes = e.classes.join(' ');
    return tag == 'div' &&
        classes.contains('elementor-widget') &&
        classes.contains('elementor-widget-gallery');
  }

  String _readingTimeFromHtml(String html) {
    final text = html
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (text.isEmpty) return '1 دقيقة';
    final words = text.split(' ').length;
    final minutes = (words / 200).ceil().clamp(1, 120);
    return '$minutes دقيقة';
  }

  Future<void> _reload() async {
    setState(() {
      _future = ref.read(wpRepoProvider).fetchPostRaw(widget.postId);
    });
    await _future;
  }

  // شاشة حجم الخط — تحديث فوري أثناء السحب
  void _showTextScaleSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        double temp = _textScale;
        return StatefulBuilder(
          builder: (context, setSheet) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('حجم الخط', style: TextStyle(fontWeight: FontWeight.w700)),
                  Row(
                    children: [
                      const Text('صغير'),
                      Expanded(
                        child: Slider(
                          value: temp,
                          min: 0.9,
                          max: 1.5,
                          divisions: 12,
                          label: temp.toStringAsFixed(2),
                          onChanged: (v) {
                            setSheet(() => temp = v);     // يحدث الليبل داخل الـ Sheet
                            setState(() => _textScale = v); // يطبّق فوري على المقال
                          },
                        ),
                      ),
                      const Text('كبير'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // فتح بالموقع/نسخ الرابط من AppBar
  Future<void> _handleMenu(_ArticleMenu m) async {
    switch (m) {
      case _ArticleMenu.openInBrowser:
        if (_latestLink.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرابط غير متاح بعد')));
          return;
        }
        await launchUrl(Uri.parse(_latestLink), mode: LaunchMode.externalApplication);
        break;
      case _ArticleMenu.copyLink:
        if (_latestLink.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرابط غير متاح بعد')));
          return;
        }
        await Clipboard.setData(ClipboardData(text: _latestLink));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ الرابط')));
        break;
      case _ArticleMenu.font:
        _showTextScaleSheet();
        break;
    }
  }

  // === مشاركة ===
  Future<void> _shareGeneric() async {
    if (_latestLink.isEmpty) return;
    final uri = Uri.tryParse(_latestLink);
    if (uri != null) {
      await Share.shareUri(uri);
    } else {
      await Share.share(_latestLink);
    }
  }

  Future<void> _shareWhatsApp() async {
    if (_latestLink.isEmpty) return;
    final text = '$_latestTitle\n$_latestLink';
    final wa = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(wa)) {
      await launchUrl(wa, mode: LaunchMode.externalApplication);
    } else {
      // fallback مشاركة عامة
      await Share.share(text);
    }
  }

  Future<void> _shareFacebook() async {
    if (_latestLink.isEmpty) return;
    final fb = Uri.parse('https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(_latestLink)}');
    await launchUrl(fb, mode: LaunchMode.externalApplication);
  }

  // ===== استخراج أول id لتصنيف مُعيّن من JSON الخام =====
  int? _firstTaxId(Map<String, dynamic> j, String taxonomy) {
    final emb = j['_embedded'];
    if (emb is Map && emb['wp:term'] is List) {
      final termsLists = emb['wp:term'] as List;
      for (final group in termsLists) {
        if (group is List) {
          for (final term in group) {
            if (term is Map && term['taxonomy'] == taxonomy) {
              final id = term['id'];
              if (id is int) return id;
              if (id is num) return id.toInt();
            }
          }
        }
      }
    }
    return null;
  }

  Future<void> _loadRelatedFor(Map<String, dynamic> j) async {
    if (_loadingRelated) return;
    _loadingRelated = true;
    setState(() {});
    try {
      final currentId = (j['id'] as num).toInt();
      final sectionId = _firstTaxId(j, 'section');
      final issueId = _firstTaxId(j, 'issue');

      // نفضّل السكشن، وإن لم يوجد نستخدم العدد
      final filterSection = sectionId;
      final filterIssue = sectionId == null ? issueId : null;

      // نجيب دفعة صغيرة مرتبة من الأحدث للأقدم
      final posts = await ref.read(wpRepoProvider).fetchPosts(
        page: 1,
        perPage: 12,
        section: filterSection,
        issue: filterIssue,
        order: 'desc',
        orderby: 'date',
      );

      // نحذف الحالي من قائمة "مشابهة"
      final similar = posts.where((p) => p.id != currentId).toList();

      // نحاول إيجاد موضع الحالي داخل القائمة (لو موجود) لبناء السابق/التالي
      int idx = posts.indexWhere((p) => p.id == currentId);
      int? nextId; // الأحدث
      int? prevId; // الأقدم
      if (idx != -1) {
        // بما أننا order=desc: index-1 = الأحدث، index+1 = الأقدم
        if (idx - 1 >= 0) nextId = posts[idx - 1].id;
        if (idx + 1 < posts.length) prevId = posts[idx + 1].id;
      } else {
        // لو غير موجود (مثلاً غير ضمن أول 12)، بنعيّن التالي = أول عنصر
        if (posts.isNotEmpty) nextId = posts.first.id;
      }

      setState(() {
        _related = similar;
        _nextId = nextId;
        _prevId = prevId;
      });
    } catch (_) {
      // تجاهل الخطأ: القسم اختياري
    } finally {
      _loadingRelated = false;
      if (mounted) setState(() {});
    }
  }

  void _openArticle(int id, {bool replace = false}) {
    final page = ArticleScreen(postId: id);
    if (replace) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => page));
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(bookmarksProvider);
    final bookmarks = ref.read(bookmarksProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مقال'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: saved.contains(widget.postId) ? 'إزالة من المحفوظات' : 'حفظ للمطالعة لاحقًا',
            onPressed: () async {
              await bookmarks.toggle(widget.postId);
              if (!mounted) return;
              final added = saved.contains(widget.postId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(added ? 'أُزيل من المحفوظات' : 'تم الحفظ'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: Icon(saved.contains(widget.postId) ? Icons.bookmark : Icons.bookmark_border),
          ),
          PopupMenuButton<_ArticleMenu>(
            tooltip: 'خيارات',
            onSelected: _handleMenu,
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: _ArticleMenu.openInBrowser,
                child: Row(
                  children: [Icon(Icons.open_in_browser), SizedBox(width: 8), Text('فتح بالموقع')],
                ),
              ),
              PopupMenuItem(
                value: _ArticleMenu.copyLink,
                child: Row(
                  children: [Icon(Icons.link), SizedBox(width: 8), Text('نسخ الرابط')],
                ),
              ),
              PopupMenuItem(
                value: _ArticleMenu.font,
                child: Row(
                  children: [Icon(Icons.text_increase), SizedBox(width: 8), Text('حجم الخط')],
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: _progress <= 0 ? null : _progress,
            minHeight: 3,
            backgroundColor: Colors.black12,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('خطأ: ${snap.error}'));
          }

          final j = snap.data!;
          final title = (j['title']?['rendered'] ?? '').toString();
          final contentHtml = (j['content']?['rendered'] ?? '').toString();
          final timeToRead = _readingTimeFromHtml(contentHtml);
          final link = (j['link'] ?? '').toString().trim();
          _latestTitle = title.replaceAll(RegExp(r'<[^>]*>'), '').trim();

          // حدّث الرابط بعد الجلب لخيارات المشاركة والفتح بالموقع
          if (link.isNotEmpty && link != _latestLink) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _latestLink = link);
            });
          }

          // حمّل مشابه/سابق/التالي مرة واحدة لكل مقال
          if (_related.isEmpty && !_loadingRelated) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _loadRelatedFor(j));
          }

          String? featured;
          final emb = j['_embedded'];
          if (emb is Map &&
              emb['wp:featuredmedia'] is List &&
              (emb['wp:featuredmedia'] as List).isNotEmpty) {
            featured = (emb['wp:featuredmedia'] as List).first['source_url']?.toString();
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              children: [
                if (featured != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(featured!, fit: BoxFit.cover),
                  ),
                const SizedBox(height: 12),

                Text(
                  _latestTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.start,
                ),

                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text(
                      'وقت القراءة: $timeToRead',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 🔗 شريط المشاركة
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _shareWhatsApp,
                      icon: const Icon(Icons.chat),
                      label: const Text('واتساب'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _shareFacebook,
                      icon: const Icon(Icons.public),
                      label: const Text('فيسبوك'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        if (_latestLink.isEmpty) return;
                        await Clipboard.setData(ClipboardData(text: _latestLink));
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم نسخ الرابط')),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('نسخ الرابط'),
                    ),
                    FilledButton.icon(
                      onPressed: _shareGeneric,
                      icon: const Icon(Icons.share),
                      label: const Text('مشاركة'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // تطبيق textScaleFactor على المقال كله
                MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaleFactor: _textScale),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: HtmlWidget(
                      contentHtml,
                      textStyle: Theme.of(context).textTheme.bodyMedium,
                      onTapUrl: _onTapUrl,
                      customWidgetBuilder: (dom.Element e) {
                        final tag = e.localName ?? '';
                        final classes = e.classes;

                        final isWpGallery =
                            (tag == 'figure' && classes.contains('wp-block-gallery')) ||
                                (tag == 'ul' && classes.contains('blocks-gallery-grid'));

                        if (isWpGallery) {
                          final imgs = e.getElementsByTagName('img');
                          final urls = <String>[];
                          for (final img in imgs) {
                            final src = img.attributes['src']?.trim();
                            if (src != null && src.isNotEmpty && !urls.contains(src)) {
                              urls.add(src);
                            }
                          }
                          if (urls.isEmpty) return const SizedBox.shrink();
                          return _WpGalleryGrid(urls: urls);
                        }

                        if (_isElementorGallery(e)) {
                          final urls = _extractElementorGallery(e);
                          if (urls.isEmpty) return const SizedBox.shrink();
                          return _WpGalleryGrid(urls: urls);
                        }

                        return null;
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ===== أزرار السابق / التالي ضمن نفس المجموعة =====
                if (_nextId != null || _prevId != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // السابق (أقدم)
                      if (_prevId != null)
                        OutlinedButton.icon(
                          onPressed: () => _openArticle(_prevId!, replace: true),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('السابق'),
                        )
                      else
                        const SizedBox(width: 1),
                      // التالي (أحدث)
                      if (_nextId != null)
                        FilledButton.icon(
                          onPressed: () => _openArticle(_nextId!, replace: true),
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('التالي'),
                        )
                      else
                        const SizedBox(width: 1),
                    ],
                  ),

                const SizedBox(height: 16),

                // ===== مقالات مشابهة =====
                if (_loadingRelated)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ))
                else if (_related.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('مقالات مشابهة', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      reverse: true, // RTL
                      itemCount: _related.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) {
                        final p = _related[i];
                        return SizedBox(
                          width: 240,
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => _openArticle(p.id),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (p.image != null)
                                    SizedBox(
                                      height: 100,
                                      width: double.infinity,
                                      child: CachedNetworkImage(
                                        imageUrl: p.image!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      p.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                Center(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _scrollCtrl.animateTo(
                        0,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                      );
                    },
                    icon: const Icon(Icons.arrow_upward),
                    label: const Text('العودة للأعلى'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

enum _ArticleMenu { openInBrowser, copyLink, font }

class _WpGalleryGrid extends StatelessWidget {
  final List<String> urls;
  const _WpGalleryGrid({required this.urls});

  void _openViewer(BuildContext context, int startIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _GalleryViewer(urls: urls, initialIndex: startIndex),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: urls.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1,
        ),
        itemBuilder: (_, i) => ClipRRect(
          borderRadius: radius,
          child: InkWell(
            onTap: () => _openViewer(context, i),
            child: CachedNetworkImage(
              imageUrl: urls[i],
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

class _GalleryViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  const _GalleryViewer({required this.urls, required this.initialIndex});

  @override
  State<_GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<_GalleryViewer> {
  late final PageController _pc;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.urls.length - 1);
    _pc = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.urls.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pc,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: total,
            itemBuilder: (_, i) {
              final url = widget.urls[i];
              return Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: 'إغلاق',
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_index + 1} / $total',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
