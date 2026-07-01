import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import 'shop_repository.dart' show apiClientProvider;
import '../models/cart_item.dart';

/// مزوّد المستودع عبر Riverpod
final ordersRepoProvider = Provider<OrdersRepository>((ref) {
  final wcClient = ref.read(apiClientProvider).wc; // Dio مهيأ على /wp-json/wc/v3
  return OrdersRepository(wcClient);
});

class OrdersRepository {
  final Dio client;
  OrdersRepository(this.client);

  /// إنشاء طلب COD على WooCommerce
  Future<int> createCodOrder({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String address1,
    required String city,
    required List<CartItem> items,
    int? customerId, // لو المستخدم مسجّل دخول
  }) async {
    final lineItems = items
        .map((i) => {'product_id': i.productId, 'quantity': i.quantity})
        .toList();

    final payload = {
      'payment_method': 'cod',
      'payment_method_title': 'Cash on Delivery',
      'set_paid': false,
      if (customerId != null) 'customer_id': customerId, // نربط الطلب بالحساب
      'billing': {
        'first_name': firstName,
        'last_name': lastName,
        'address_1': address1,
        'city': city,
        'email': email,
        'phone': phone,
      },
      'shipping': {
        'first_name': firstName,
        'last_name': lastName,
        'address_1': address1,
        'city': city,
      },
      'line_items': lineItems,
    };

    final res = await client.post('/orders', data: payload);
    final data = res.data;

    if (data is Map) {
      final id = data['id'] ?? data['order_id'];
      return int.parse(id.toString());
    }

    throw Exception('Invalid order response: ${data.runtimeType}');
  }

  /// طلب مفرد لتفاصيل الطلب
  Future<Map<String, dynamic>> getOrder(int orderId) async {
    final res = await client.get('/orders/$orderId');
    return (res.data as Map<String, dynamic>);
  }

  /// (افتراضي) جلب الطلبات عبر customer=
  Future<List<Map<String, dynamic>>> _fetchByCustomer(int customerId) async {
    final res = await client.get('/orders', queryParameters: {
      'customer': customerId,
      'orderby': 'date',
      'order': 'desc',
      'per_page': 30,
    });
    return (res.data as List).cast<Map<String, dynamic>>();
  }

  /// بعض البيئات تتوقع customer_id بدل customer
  Future<List<Map<String, dynamic>>> _fetchByCustomerId(int customerId) async {
    final res = await client.get('/orders', queryParameters: {
      'customer_id': customerId,
      'orderby': 'date',
      'order': 'desc',
      'per_page': 30,
    });
    return (res.data as List).cast<Map<String, dynamic>>();
  }

  /// فلترة محلية لطلبات الضيف بنفس بريد الفوترة (خطة بديلة)
  Future<List<Map<String, dynamic>>> getRecentOrdersFilteredByEmail(
      String email, {
        int pages = 2,
        int perPage = 30,
      }) async {
    final results = <Map<String, dynamic>>[];
    for (var page = 1; page <= pages; page++) {
      final res = await client.get('/orders', queryParameters: {
        'orderby': 'date',
        'order': 'desc',
        'per_page': perPage,
        'page': page,
      });
      final list = (res.data as List).cast<Map<String, dynamic>>();
      results.addAll(list.where((o) =>
      (o['billing'] is Map) &&
          (o['billing']['email']?.toString().toLowerCase() ==
              email.toLowerCase())));
      if (list.length < perPage) break; // لا مزيد من الصفحات
    }
    return results;
  }

  /// دالة ذكية: تجرّب customer ثم customer_id ثم (اختياري) فلترة بالبريد
  Future<List<Map<String, dynamic>>> getOrdersSmart({
    required int customerId,
    String? fallbackEmail,
  }) async {
    final a = await _fetchByCustomer(customerId);
    if (a.isNotEmpty) return a;

    final b = await _fetchByCustomerId(customerId);
    if (b.isNotEmpty) return b;

    if (fallbackEmail != null && fallbackEmail.isNotEmpty) {
      final c = await getRecentOrdersFilteredByEmail(fallbackEmail);
      if (c.isNotEmpty) return c;
    }
    return const [];
  }
}
