import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import 'shop_repository.dart' show apiClientProvider; // لإعادة استخدام ApiClient.base
import '../models/inspiration_item.dart';

final inspirationRepoProvider = Provider<InspirationRepository>((ref) {
  final base = ref.read(apiClientProvider).base; // points to https://domain
  return InspirationRepository(base);
});

class InspirationRepository {
  final Dio base;
  InspirationRepository(this.base);

  Future<List<InspirationItem>> fetchInspiration({
    int page = 1,
    int perPage = 20,
    int? category, // إن كان في taxonomy مثل insp_cat
    String? search,
  }) async {
    final qp = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      '_embed': 1,
      'status': 'publish',
    };
    if (category != null) qp['insp_cat'] = category; // عدّل الاسم إذا مختلف
    if (search != null && search.trim().isNotEmpty) qp['search'] = search!.trim();

    // endpoint: /wp-json/wp/v2/inspiration
    final res = await base.get('/wp-json/wp/v2/inspiration', queryParameters: qp);
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(InspirationItem.fromJson).toList();
  }

  Future<Map<String, dynamic>> fetchInspirationRaw(int id) async {
    final res = await base.get('/wp-json/wp/v2/inspiration/$id', queryParameters: {'_embed': 1});
    return (res.data as Map<String, dynamic>);
  }
}
