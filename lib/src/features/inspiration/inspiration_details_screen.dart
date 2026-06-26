import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/repositories/inspiration_repository.dart';
import '../../data/repositories/favorites_provider.dart';

class InspirationDetailsScreen extends ConsumerWidget {
  final int id;
  const InspirationDetailsScreen({super.key, required this.id});

  Future<bool> _onTapUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(favoritesProvider).contains(id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('فكرة إلهام'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        actions: [
          IconButton(
            onPressed: () => ref.read(favoritesProvider.notifier).toggle(id),
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
            tooltip: isFav ? 'إزالة من المحفوظ' : 'حفظ',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: ref.read(inspirationRepoProvider).fetchInspirationRaw(id),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('خطأ: ${snap.error}'));
          final j = snap.data!;

          // صورة بارزة (إن وُجدت)
          String? featured;
          final emb = j['_embedded'];
          if (emb is Map && emb['wp:featuredmedia'] is List && (emb['wp:featuredmedia'] as List).isNotEmpty) {
            featured = (emb['wp:featuredmedia'] as List).first['source_url']?.toString();
          }

          final title = (j['title']?['rendered'] ?? '').toString();
          final contentHtml = (j['content']?['rendered'] ?? '').toString();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (featured != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(featured!, fit: BoxFit.cover),
                ),
              const SizedBox(height: 12),
              Text(
                title.replaceAll(RegExp(r'<[^>]*>'), ''),
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 12),
              Directionality(
                textDirection: TextDirection.rtl,
                child: HtmlWidget(
                  contentHtml,
                  textStyle: Theme.of(context).textTheme.bodyMedium,
                  onTapUrl: _onTapUrl,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
