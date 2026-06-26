import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/vendors_repository.dart';
import '../../data/models/vendor.dart';
import 'package:url_launcher/url_launcher.dart';

class VendorDetailsScreen extends ConsumerWidget {
  final int vendorId;
  const VendorDetailsScreen({super.key, required this.vendorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مزود خدمة'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: FutureBuilder<Vendor>(
        future: ref.read(vendorsRepoProvider).fetchVendor(vendorId),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('خطأ: ${snap.error}'));
          final v = snap.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (v.image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(imageUrl: v.image!, height: 220, fit: BoxFit.cover),
                ),
              const SizedBox(height: 12),
              Text(v.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (v.address != null) Row(children: [const Icon(Icons.location_on), const SizedBox(width: 6), Expanded(child: Text(v.address!))]),
              const SizedBox(height: 8),
              if (v.rating != null)
                Row(children: [const Icon(Icons.star), const SizedBox(width: 6), Text(v.rating!.toStringAsFixed(1))]),
              if (v.minPrice != null || v.maxPrice != null) ...[
                const SizedBox(height: 8),
                Text('السعر التقديري: ${v.minPrice ?? '-'} - ${v.maxPrice ?? '-'}'),
              ],
              const SizedBox(height: 12),
              if (v.description != null) Text(v.description!),

              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (v.phones.isNotEmpty)
                    FilledButton.tonal(
                      onPressed: () async {
                        final uri = Uri.parse('tel:${v.phones.first}');
                        if (await canLaunchUrl(uri)) launchUrl(uri);
                      },
                      child: const Text('اتصال'),
                    ),
                  if (v.whatsapp != null && v.whatsapp!.trim().isNotEmpty)
                    FilledButton.tonal(
                      onPressed: () async {
                        final phone = v.whatsapp!.replaceAll(RegExp(r'[^0-9+]'), '');
                        final uri = Uri.parse('https://wa.me/$phone');
                        if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      child: const Text('واتساب'),
                    ),
                  if (v.instagram != null && v.instagram!.trim().isNotEmpty)
                    FilledButton.tonal(
                      onPressed: () async {
                        final uri = Uri.parse(v.instagram!);
                        if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      child: const Text('إنستغرام'),
                    ),
                  if (v.website != null && v.website!.trim().isNotEmpty)
                    FilledButton.tonal(
                      onPressed: () async {
                        final uri = Uri.parse(v.website!);
                        if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      child: const Text('الموقع'),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
