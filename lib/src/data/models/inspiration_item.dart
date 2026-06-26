import 'package:equatable/equatable.dart';

class InspirationItem extends Equatable {
  final int id;
  final String title;
  final String? image;   // featured image
  final String? excerpt; // نص مختصر (اختياري)
  final DateTime date;

  const InspirationItem({
    required this.id,
    required this.title,
    this.image,
    this.excerpt,
    required this.date,
  });

  static String _stripHtml(String s) =>
      s.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  factory InspirationItem.fromJson(Map<String, dynamic> j) {
    String? img;
    final emb = j['_embedded'];
    if (emb is Map && emb['wp:featuredmedia'] is List && (emb['wp:featuredmedia'] as List).isNotEmpty) {
      final media = (emb['wp:featuredmedia'] as List).first;
      img = media['source_url']?.toString();
    }
    final titleRendered = (j['title']?['rendered'] ?? '').toString();
    final excerptRendered = (j['excerpt']?['rendered'] ?? '').toString();

    return InspirationItem(
      id: j['id'] as int,
      title: _stripHtml(titleRendered),
      excerpt: excerptRendered.isEmpty ? null : _stripHtml(excerptRendered),
      image: img,
      date: DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, title, image, excerpt, date];
}
