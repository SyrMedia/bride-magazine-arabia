// lib/src/features/directory/directory_screen.dart
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/vendors_repository.dart';
import '../../data/models/vendor.dart';

class DirectoryScreen extends ConsumerStatefulWidget {
  const DirectoryScreen({super.key});

  @override
  ConsumerState<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends ConsumerState<DirectoryScreen> {
  late Future<List<Vendor>> _future;
  List<Map<String, dynamic>> cats = [];
  List<Map<String, dynamic>> cities = [];

  int? selectedCat;
  int? selectedCity;

  Timer? _reloadDebounce;

  @override
  void initState() {
    super.initState();
    // أول تحميل
    _future = ref.read(vendorsRepoProvider).fetchVendors(page: 1, perPage: 20);
    _loadFilters();
  }

  @override
  void dispose() {
    _reloadDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    final repo = ref.read(vendorsRepoProvider);
    try {
      final c1 = await repo.fetchTerms('vendor_cat');
      final c2 = await repo.fetchTerms('city');
      if (!mounted) return;
      setState(() {
        cats = c1;
        cities = c2;
      });
    } catch (_) {
      // تجاهل بهدوء
    }
  }

  void _scheduleApply() {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 300), () {
      _apply();
    });
  }

  Future<void> _apply() async {
    setState(() {
      _future = ref.read(vendorsRepoProvider).fetchVendors(
        page: 1,
        perPage: 20,
        vendorCat: selectedCat,
        city: selectedCity,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دليل الخدمات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _scheduleApply, // نفس سلوك الفلاتر (debounced)
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Column(
        children: [
          // فلاتر بسيطة
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    decoration: const InputDecoration(
                      labelText: 'الفئة',
                      border: OutlineInputBorder(),
                      contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    value: selectedCat,
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('الكل')),
                      ...cats.map(
                            (e) => DropdownMenuItem<int?>(
                          value: (e['id'] as num).toInt(),
                          child: Text(e['name'].toString()),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => selectedCat = v);
                      _scheduleApply();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    decoration: const InputDecoration(
                      labelText: 'المدينة',
                      border: OutlineInputBorder(),
                      contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    value: selectedCity,
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('الكل')),
                      ...cities.map(
                            (e) => DropdownMenuItem<int?>(
                          value: (e['id'] as num).toInt(),
                          child: Text(e['name'].toString()),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => selectedCity = v);
                      _scheduleApply();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: FutureBuilder<List<Vendor>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('خطأ: ${snap.error}'));
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return const Center(child: Text('لا توجد نتائج'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (_, i) {
                    final v = items[i];
                    return InkWell(
                      onTap: () => context.go('/tabs/directory/v/${v.id}'),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: v.image != null
                                ? CachedNetworkImage(
                              imageUrl: v.image!,
                              width: 96,
                              height: 96,
                              fit: BoxFit.cover,
                            )
                                : const SizedBox(width: 96, height: 96),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  v.title,
                                  style:
                                  Theme.of(context).textTheme.titleMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                if (v.address != null)
                                  Text(
                                    v.address!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (v.rating != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.star, size: 16),
                                      const SizedBox(width: 4),
                                      Text(v.rating!.toStringAsFixed(1)),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemCount: items.length,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
