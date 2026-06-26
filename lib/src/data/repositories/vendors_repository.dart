import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import 'shop_repository.dart' show apiClientProvider; // لإعادة استخدام الـ ApiClient.base
import '../models/vendor.dart';

final vendorsRepoProvider = Provider<VendorsRepository>((ref) {
  final base = ref.read(apiClientProvider).base; // /wp-json
  return VendorsRepository(base);
});

class VendorsRepository {
  final Dio base;
  VendorsRepository(this.base);

  Future<List<Vendor>> fetchVendors({
    int page = 1,
    int perPage = 10,
    int? vendorCat, // فلترة بالفئة
    int? city,      // فلترة بالمدينة
    String? search, // بحث بالعنوان
  }) async {
    final qp = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      '_embed': 1,
      'status': 'publish',
    };
    if (vendorCat != null) qp['vendor_cat'] = vendorCat;
    if (city != null) qp['city'] = city;
    if (search != null && search.trim().isNotEmpty) qp['search'] = search!.trim();

    final res = await base.get('/wp-json/wp/v2/vendor', queryParameters: qp);
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(Vendor.fromJson).toList();
  }

  Future<Vendor> fetchVendor(int id) async {
    final res = await base.get('/wp-json/wp/v2/vendor/$id', queryParameters: {'_embed': 1});
    return Vendor.fromJson(res.data as Map<String, dynamic>);
  }

  // جلب مصطلحات التصنيفات لعرض أسماء الفلاتر
  Future<List<Map<String, dynamic>>> fetchTerms(String taxonomy) async {
    final res = await base.get('/wp-json/wp/v2/$taxonomy', queryParameters: {'per_page': 100});
    final list = (res.data as List).cast<Map<String, dynamic>>();
    // نحولها List<{id,name}>
    return list.map((j) => {'id': j['id'], 'name': j['name']}).toList();
  }
}
