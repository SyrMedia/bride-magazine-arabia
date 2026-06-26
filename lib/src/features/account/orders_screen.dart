import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/orders_repository.dart';
import 'order_details_screen.dart';

class OrdersScreen extends ConsumerWidget {
  final int customerId;
  const OrdersScreen({super.key, required this.customerId});

  String _statusLabel(String s) {
    switch (s) {
      case 'pending':
        return 'بانتظار الدفع';
      case 'processing':
        return 'قيد المعالجة';
      case 'on-hold':
        return 'قيد الانتظار';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      case 'refunded':
        return 'مسترجع';
      case 'failed':
        return 'فشل';
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(ordersRepoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('طلباتي')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        // “صارمة”: نعرض الطلبات المرتبطة بالحساب فقط
        future: repo.getOrdersSmart(customerId: customerId, fallbackEmail: null),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('خطأ: ${snap.error}'));
          }

          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('لا توجد طلبات'));
          }

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final o = items[i];
              final int id = (o['id'] as num).toInt();
              final total = o['total']?.toString() ?? '';
              final status = o['status']?.toString() ?? '';
              final created =
              DateTime.tryParse(o['date_created']?.toString() ?? '');

              return ListTile(
                leading: CircleAvatar(child: Text('#$id'.substring(0, 2))),
                title: Text('طلب #$id • ${_statusLabel(status)}'),
                subtitle: Text(
                  created != null ? created.toLocal().toString() : '',
                ),
                trailing: Text(total),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OrderDetailsScreen(orderId: id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
