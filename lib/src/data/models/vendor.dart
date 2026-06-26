import 'package:equatable/equatable.dart';

class Vendor extends Equatable {
  final int id;
  final String title;
  final String? image;
  final List<String> categories;
  final String? city;
  final double? rating;
  final int? minPrice;
  final int? maxPrice;
  final List<String> phones;
  final String? whatsapp;
  final String? instagram;
  final String? website;
  final String? address;
  final String? description; // من المحتوى

  const Vendor({
    required this.id,
    required this.title,
    this.image,
    required this.categories,
    this.city,
    this.rating,
    this.minPrice,
    this.maxPrice,
    required this.phones,
    this.whatsapp,
    this.instagram,
    this.website,
    this.address,
    this.description,
  });

  static String _stripHtml(String s) =>
      s.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  factory Vendor.fromJson(Map<String, dynamic> j) {
    // العنوان والوصف
    final titleRendered = (j['title']?['rendered'] ?? '').toString();
    final contentRendered = (j['content']?['rendered'] ?? '').toString();

    // الصورة البارزة من _embedded أو من ACF cover
    String? cover;
    final emb = j['_embedded'];
    if (emb is Map && emb['wp:featuredmedia'] is List && (emb['wp:featuredmedia'] as List).isNotEmpty) {
      cover = (emb['wp:featuredmedia'] as List).first['source_url']?.toString();
    }
    final acf = j['acf'] as Map<String, dynamic>?;

    cover ??= acf?['cover'] is Map ? (acf?['cover']?['url']?.toString()) : null;

    // تصنيفات
    final categories = <String>[];
    if (j['vendor_cat'] is List) {
      for (final c in (j['vendor_cat'] as List)) {
        if (c is int) continue; // بعض النسخ تعيد IDs فقط إلا إذا استخدمنا _embed للterms
      }
    }

    // المدينة (لو رجعت IDs فقط، سنجلب الاسم في الواجهة من API آخر — هنا نخزن نصًّا إن توفر)
    String? city;

    // حقول ACF
    final rating = (acf?['rating'] is num) ? (acf!['rating'] as num).toDouble() : null;
    final minPrice = (acf?['min_price'] is num) ? (acf!['min_price'] as num).toInt() : null;
    final maxPrice = (acf?['max_price'] is num) ? (acf!['max_price'] as num).toInt() : null;

    // phones: ممكن تكون نص بفواصل أو Array (حسب ACF)
    final phones = <String>[];
    final rawPhones = acf?['phones'];
    if (rawPhones is String) {
      phones.addAll(rawPhones.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
    } else if (rawPhones is List) {
      phones.addAll(rawPhones.map((e) => e.toString()));
    }

    return Vendor(
      id: j['id'] as int,
      title: _stripHtml(titleRendered),
      description: contentRendered.isEmpty ? null : _stripHtml(contentRendered),
      image: cover,
      categories: categories, // سنملأ أسماء الفئات لاحقًا من استدعاء منفصل للفلاتر
      city: city,             // نفس الشيء للمدينة
      rating: rating,
      minPrice: minPrice,
      maxPrice: maxPrice,
      phones: phones,
      whatsapp: acf?['whatsapp']?.toString(),
      instagram: acf?['instagram']?.toString(),
      website: acf?['website']?.toString(),
      address: acf?['address']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, title, image, categories, city, rating, minPrice, maxPrice, phones, whatsapp, instagram, website, address, description];
}
