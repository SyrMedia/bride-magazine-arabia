// lib/src/data/repositories/wp_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import 'shop_repository.dart' show apiClientProvider;

import '../models/wp_post.dart';
import '../models/mag_landing.dart';

final wpRepoProvider = Provider<WpRepository>((ref) {
  final dio = ref.read(apiClientProvider).base; // Dio مهيأ على الدومين
  return WpRepository(dio);
});

class _IssueInfo {
  final int id;
  final String title;
  final String? cover;
  final String? releaseDateStr;
  final DateTime? releaseDate;

  _IssueInfo({
    required this.id,
    required this.title,
    this.cover,
    this.releaseDateStr,
    this.releaseDate,
  });
}

class WpRepository {
  final Dio base;
  WpRepository(this.base);

  // ===========================
  //       Magazine (sections/issues/posts)
  // ===========================

  Future<List<Map<String, dynamic>>> fetchSections() async {
    final res = await base.get(
      '/wp-json/wp/v2/section',
      queryParameters: {
        'per_page': 100,
        'hide_empty': true,
        'orderby': 'name',
        'order': 'asc',
      },
    );
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list
        .map((c) => {
      'id': (c['id'] as num).toInt(),
      'name': (c['name'] ?? '').toString(),
    })
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchIssues() async {
    final res = await base.get(
      '/wp-json/wp/v2/issue',
      queryParameters: {
        'per_page': 100,
        'hide_empty': false,
        'orderby': 'id',
        'order': 'desc',
      },
    );

    final list = (res.data as List).cast<Map<String, dynamic>>();

    return list.map((c) {
      final id = (c['id'] as num).toInt();
      final name = (c['name'] ?? '').toString();

      // الحقول اللي أضفناها في REST:
      final cover = (c['issue_cover'] ?? '').toString();
      final releaseDate = (c['issue_release_date'] ?? '').toString();
      final isUpcoming = c['issue_is_upcoming'] == true;

      return {
        'id': id,
        'name': name,
        'cover': cover,
        'release_date': releaseDate,
        'is_upcoming': isUpcoming,
      };
    }).toList();
  }


  // ---------------------------
  // Magazine landing (current + upcoming)
  // ---------------------------

  Future<MagazineLanding> fetchMagazineLanding() async {
    try {
      // 1. جلب البيانات الخام
      final res = await base.get(
        '/wp-json/wp/v2/issue',
        queryParameters: {
          'per_page': 100,
          'hide_empty': true,
          // لا نعتمد على ترتيب الـ API، سنرتب يدوياً بالتاريخ
        },
      );

      final rawList = (res.data as List).cast<Map<String, dynamic>>();

      // دوال مساعدة لاستخراج البيانات
      DateTime? _parseDate(dynamic v) {
        if (v == null) return null;
        final s = v.toString().trim();
        if (s.isEmpty) return null;
        try {
          return DateTime.parse(s);
        } catch (_) {
          return null;
        }
      }

      String? _pickString(Map<String, dynamic> j, List<String> keys) {
        for (final key in keys) {
          final v = j[key];
          if (v != null && v.toString().trim().isNotEmpty) {
            return v.toString().trim();
          }
        }
        // بحث داخل acf إذا وجد
        if (j['acf'] is Map) {
          final acf = j['acf'] as Map;
          for (final key in keys) {
            final v = acf[key];
            if (v != null && v.toString().trim().isNotEmpty) {
              return v.toString().trim();
            }
          }
        }
        return null;
      }

      final issues = <_IssueInfo>[];

      // 2. تحويل البيانات إلى كائنات
      for (final j in rawList) {
        final id = (j['id'] as num?)?.toInt() ?? 0;
        final title = (j['name'] ?? '').toString();

        final cover = _pickString(j, [
          'cover',
          'image',
          'mag_cover',
          'issue_cover',
          'thumbnail',
          'thumb',
          'featured_media_url' // إضافة احتمال آخر للصور
        ]);

        final releaseStr = _pickString(j, [
          'release_date',
          'issue_date',
          'publish_date',
          'date'
        ]);

        final releaseDate = _parseDate(releaseStr);

        issues.add(
          _IssueInfo(
            id: id,
            title: title,
            cover: cover,
            releaseDateStr: releaseStr,
            releaseDate: releaseDate,
          ),
        );
      }

      // حذف أي عنصر لا يحتوي على تاريخ أو صورة (بيانات تالفة)
      issues.removeWhere((i) => i.releaseDate == null);

      if (issues.isEmpty) {
        return _fetchMagazineLandingLegacy();
      }

      final now = DateTime.now();

      // 3. الترتيب الزمني الصارم (من القديم إلى الحديث)
      // مثال: [تشرين الأول, تشرين الثاني, كانون الأول]
      issues.sort((a, b) => a.releaseDate!.compareTo(b.releaseDate!));

      _IssueInfo? currentIssue;
      List<_IssueInfo> bottomList = [];

      // 4. تحديد العدد الحالي (المنطق المصحح)
      // العدد الحالي هو: آخر عدد في القائمة تاريخه <= اليوم
      // بمعنى: أحدث عدد تم إصداره بالفعل
      final releasedIssues = issues.where((i) {
        return i.releaseDate!.isBefore(now) || i.releaseDate!.isAtSameMomentAs(now);
      }).toList();

      if (releasedIssues.isNotEmpty) {
        currentIssue = releasedIssues.last; // هذا يجب أن يكون تشرين الثاني
      } else {
        // في حال لم يصدر أي عدد بعد (كل التواريخ مستقبلية)، نأخذ أول واحد قادم
        if (issues.isNotEmpty) currentIssue = issues.first;
      }

      // 5. بناء القائمة السفلية (السابق + القادم)
      if (currentIssue != null) {
        final currentIndex = issues.indexOf(currentIssue);

        // أ) إضافة العدد السابق (تشرين الأول) كأول عنصر في القائمة السفلية
        if (currentIndex > 0) {
          bottomList.add(issues[currentIndex - 1]);
        }

        // ب) إضافة الأعداد القادمة (كانون الأول وما بعده)
        if (currentIndex < issues.length - 1) {
          // نضيف كل ما يأتي بعد العدد الحالي
          bottomList.addAll(issues.sublist(currentIndex + 1));
        }
      } else {
        // حالة طوارئ
        bottomList = issues;
      }

      // طباعة للفحص (Debug)
      print('--- MAGAZINE LOGIC FIX ---');
      print('Now: $now');
      print('Detected Current Issue: ${currentIssue?.title} (${currentIssue?.releaseDateStr})');
      print('Bottom List Items: ${bottomList.map((e) => e.title).toList()}');
      print('--------------------------');

      // 6. تجهيز الـ JSON النهائي
      final normalized = <String, dynamic>{
        'current_cover': currentIssue?.cover ?? '',
        'upcoming': bottomList.map((u) {
          // نرسل المفاتيح المحتملة للصورة لضمان ظهورها
          return {
            'title': u.title,
            'cover': u.cover ?? '',
            'image': u.cover ?? '', // تكرار للصورة باسم مفتاح آخر للحماية
            'release_date': u.releaseDateStr ?? '',
          };
        }).toList(),
      };

      return MagazineLanding.fromJson(normalized);

    } catch (e, st) {
      print('❌ fetchMagazineLanding Error: $e');
      print(st);
      return _fetchMagazineLandingLegacy();
    }
  }

  /// Fallback: Legacy API
  Future<MagazineLanding> _fetchMagazineLandingLegacy() async {
    try {
      final res = await base.get('/wp-json/bma/v1/magazine');
      final raw = res.data;
      final map = raw is Map<String, dynamic> ? raw : <String, dynamic>{};

      String? cover;
      for (final key in [
        'current_cover',
        'currentCover',
        'cover',
        'image',
        'current_cover_url',
      ]) {
        final v = map[key];
        if (v != null && v.toString().trim().isNotEmpty) {
          cover = v.toString().trim();
          break;
        }
      }

      final upcomingRaw =
      (map['upcoming'] is List) ? map['upcoming'] as List : const [];

      final normalized = <String, dynamic>{
        'current_cover': cover ?? '',
        'upcoming': upcomingRaw,
      };

      return MagazineLanding.fromJson(normalized);
    } catch (e) {
      return MagazineLanding.fromJson({
        'current_cover': '',
        'upcoming': [],
      });
    }
  }

  // ===========================
  //       Posts / Articles
  // ===========================

  Future<List<WpPost>> fetchPosts({
    int page = 1,
    int perPage = 10,
    int? category,
    String? search,
    int? issue,
    int? section,
    String order = 'desc',
    String orderby = 'date',
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      '_embed': 1,
      'status': 'publish',
      'order': order,
      'orderby': orderby,
    };

    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    if (section != null && section > 0) params['section'] = section;
    if (issue != null && issue > 0) params['issue'] = issue;
    if (category != null && category > 0) params['categories'] = category;

    final res = await base.get('/wp-json/wp/v2/posts', queryParameters: params);
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(_mapPost).toList();
  }

  Future<List<WpPost>> fetchPostsRaw({
    int page = 1,
    int perPage = 10,
    int? category,
    int? categoryId,
    String? search,
    int? issue,
    int? section,
    String order = 'desc',
    String orderby = 'date',
  }) {
    final effectiveCategory = category ?? categoryId;
    return fetchPosts(
      page: page,
      perPage: perPage,
      category: effectiveCategory,
      search: search,
      issue: issue,
      section: section,
      order: order,
      orderby: orderby,
    );
  }

  Future<WpPostsPage> fetchPostsPaged({
    int page = 1,
    int perPage = 10,
    int? category,
    int? categoryId,
    String? search,
    int? issue,
    int? section,
    String order = 'desc',
    String orderby = 'date',
  }) async {
    final effectiveCategory = category ?? categoryId;

    final params = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      '_embed': 1,
      'status': 'publish',
      'order': order,
      'orderby': orderby,
    };
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    if (section != null && section > 0) params['section'] = section;
    if (issue != null && issue > 0) params['issue'] = issue;
    if (effectiveCategory != null && effectiveCategory > 0) {
      params['categories'] = effectiveCategory;
    }

    final res = await base.get('/wp-json/wp/v2/posts', queryParameters: params);
    final list = (res.data as List).cast<Map<String, dynamic>>();

    final total = int.tryParse(res.headers.value('X-WP-Total') ?? '') ?? 0;
    final totalPages =
        int.tryParse(res.headers.value('X-WP-TotalPages') ?? '') ?? 0;

    return WpPostsPage(
      posts: list.map(_mapPost).toList(),
      total: total,
      totalPages: totalPages,
      page: page,
      perPage: perPage,
    );
  }

  Future<Map<String, dynamic>> fetchPostRaw(int id) async {
    const candidates = <String>[
      'posts',
      'inspiration',
      'page',
    ];

    DioException? lastErr;

    for (final slug in candidates) {
      try {
        final res = await base.get(
          '/wp-json/wp/v2/$slug/$id',
          queryParameters: const {'_embed': 1},
        );
        return (res.data as Map<String, dynamic>);
      } on DioException catch (e) {
        lastErr = e;
        if (e.response?.statusCode != 404) {
          rethrow;
        }
      }
    }

    if (lastErr != null) throw lastErr!;
    throw Exception('لم أستطع جلب المحتوى للمعرّف $id');
  }

  WpPost _mapPost(Map<String, dynamic> j) {
    String? img;
    final emb = j['_embedded'];
    if (emb is Map &&
        emb['wp:featuredmedia'] is List &&
        (emb['wp:featuredmedia'] as List).isNotEmpty) {
      final media = (emb['wp:featuredmedia'] as List).first;
      img = media['source_url']?.toString();
    }
    return WpPost.fromJson(j, image: img);
  }

  // ===========================
  //       Inspiration (CPT + tax)
  // ===========================

  static const String _inspoType = 'inspiration';
  final Map<String, String> _taxBaseCache = {};

  Future<String?> _resolveTaxBase(String preferred) async {
    if (_taxBaseCache.containsKey(preferred)) {
      return _taxBaseCache[preferred];
    }

    try {
      final taxIndex = await base.get('/wp-json/wp/v2/taxonomies');
      if (taxIndex.data is! Map<String, dynamic>) return null;
      final map = taxIndex.data as Map<String, dynamic>;

      final candidates = <String>{
        preferred,
        if (preferred.endsWith('s'))
          preferred.substring(0, preferred.length - 1),
        '${preferred}s',
      };

      for (final key in candidates) {
        if (map.containsKey(key) && map[key] is Map) {
          final obj = map[key] as Map;
          final restBase = (obj['rest_base'] ?? key).toString();
          if (await _pingTaxBase(restBase)) {
            _taxBaseCache[preferred] = restBase;
            return restBase;
          }
        }
      }

      for (final e in map.entries) {
        final obj = e.value;
        if (obj is Map) {
          final slug = (obj['slug'] ?? '').toString();
          if (candidates.contains(slug)) {
            final restBase = (obj['rest_base'] ?? e.key).toString();
            if (await _pingTaxBase(restBase)) {
              _taxBaseCache[preferred] = restBase;
              return restBase;
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<bool> _pingTaxBase(String baseName) async {
    try {
      final res = await base.get(
        '/wp-json/wp/v2/$baseName',
        queryParameters: {'per_page': 1},
      );
      return res.statusCode != null &&
          res.statusCode! >= 200 &&
          res.statusCode! < 300;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchInspirationTaxonomy(
      String taxonomy, {
        bool hideEmpty = true,
      }) async {
    final restBase = await _resolveTaxBase(taxonomy);
    if (restBase == null) return const [];

    try {
      final res = await base.get(
        '/wp-json/wp/v2/$restBase',
        queryParameters: {
          'per_page': 100,
          'hide_empty': hideEmpty,
          'orderby': 'name',
          'order': 'asc',
        },
      );
      final list = (res.data as List).cast<Map<String, dynamic>>();
      return list
          .map((c) => {
        'id': (c['id'] as num).toInt(),
        'name': (c['name'] ?? '').toString(),
      })
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchSeasons() =>
      fetchInspirationTaxonomy('season');
  Future<List<Map<String, dynamic>>> fetchStyles() =>
      fetchInspirationTaxonomy('styles');
  Future<List<Map<String, dynamic>>> fetchPalettes() =>
      fetchInspirationTaxonomy('palettes');

  Future<WpPostsPage> fetchInspirationPaged({
    int page = 1,
    int perPage = 12,
    int? season,
    int? style,
    int? palette,
    String? search,
    String order = 'desc',
    String orderby = 'date',
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      '_embed': 1,
      'status': 'publish',
      'order': order,
      'orderby': orderby,
    };
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }

    Future<void> addTax(String pref, int? id) async {
      if (id == null || id <= 0) return;
      final rb = await _resolveTaxBase(pref);
      if (rb != null) {
        params[rb] = id;
        if (rb != pref) params[pref] = id;
      } else {
        params[pref] = id;
      }
    }

    await Future.wait([
      addTax('season', season),
      addTax('styles', style),
      addTax('palettes', palette),
    ]);

    try {
      final res = await base.get(
        '/wp-json/wp/v2/$_inspoType',
        queryParameters: params,
      );
      final list = (res.data as List).cast<Map<String, dynamic>>();

      final total =
          int.tryParse(res.headers.value('X-WP-Total') ?? '') ?? list.length;
      final totalPages =
          int.tryParse(res.headers.value('X-WP-TotalPages') ?? '') ??
              (list.isEmpty ? 0 : 1);

      return WpPostsPage(
        posts: list.map(_mapPost).toList(),
        total: total,
        totalPages: totalPages,
        page: page,
        perPage: perPage,
      );
    } catch (_) {
      return WpPostsPage(
        posts: const [],
        total: 0,
        totalPages: 0,
        page: page,
        perPage: perPage,
      );
    }
  }
}

class WpPostsPage {
  final List<WpPost> posts;
  final int total;
  final int totalPages;
  final int page;
  final int perPage;

  WpPostsPage({
    required this.posts,
    required this.total,
    required this.totalPages,
    required this.page,
    required this.perPage,
  });
}