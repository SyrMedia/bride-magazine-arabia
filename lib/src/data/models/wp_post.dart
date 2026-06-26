import 'package:equatable/equatable.dart';

class WpPost extends Equatable {
  final int id;
  final String title;     // عنوان بدون HTML
  final String? excerpt;  // مقتطف نصي بسيط
  final String? image;    // أول صورة بارزة
  final DateTime date;

  const WpPost({
    required this.id,
    required this.title,
    required this.date,
    this.excerpt,
    this.image,
  });

  static String _stripHtml(String input) =>
      input.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  factory WpPost.fromJson(Map<String, dynamic> j, {String? image}) {
    final titleRendered = (j['title']?['rendered'] ?? '').toString();
    final excerptRendered = (j['excerpt']?['rendered'] ?? '').toString();
    return WpPost(
      id: j['id'] as int,
      title: _stripHtml(titleRendered),
      excerpt: excerptRendered.isEmpty ? null : _stripHtml(excerptRendered),
      image: image,
      date: DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, title, excerpt, image, date];
}
