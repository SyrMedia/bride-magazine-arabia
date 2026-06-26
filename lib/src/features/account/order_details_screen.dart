import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/orders_repository.dart';

class OrderDetailsScreen extends ConsumerWidget {
  final int orderId;
  const OrderDetailsScreen({super.key, required this.orderId});

  String _statusLabel(String s) {
    switch (s) {
      case 'pending': return 'بانتظار الدفع';
      case 'processing': return 'قيد المعالجة';
      case 'on-hold': return 'قيد الانتظار';
      case 'completed': return 'مكتمل';
      case 'cancelled': return 'ملغي';
      case 'refunded': return 'مسترجع';
      case 'failed': return 'فشل';
      default: return s;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('تفاصيل الطلب #$orderId')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: ref.read(ordersRepoProvider).getOrder(orderId),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('خطأ: ${snap.error}'));
          final o = snap.data!;
          final status = o['status']?.toString() ?? '';
          final created = DateTime.tryParse(o['date_created'] ?? '')?.toLocal();
          final billing = (o['billing'] ?? {}) as Map<String, dynamic>;
          final shipping = (o['shipping'] ?? {}) as Map<String, dynamic>;
          final items = ((o['line_items'] ?? []) as List).cast<Map<String, dynamic>>();
          final subtotal = o['subtotal']?.toString() ?? o['total']?.toString() ?? '';
          final shippingTotal = o['shipping_total']?.toString() ?? '0';
          final total = o['total']?.toString() ?? '';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text('الحالة: ${_statusLabel(status)}'),
                subtitle: Text(created != null ? created.toString() : ''),
              ),
              const Divider(),

              Text('البنود', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...items.map((it) {
                final name = it['name']?.toString() ?? '';
                final qty = it['quantity']?.toString() ?? '1';
                final total = it['total']?.toString() ?? '';
                return ListTile(
                  dense: true,
                  title: Text(name),
                  subtitle: Text('الكمية: $qty'),
                  trailing: Text(total),
                );
              }),

              const Divider(),
              Text('الإجماليات', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _row('الإجمالي الفرعي', subtotal),
              _row('الشحن', shippingTotal),
              _row('الإجمالي', total, bold: true),

              const Divider(),
              Text('عنوان الفوترة', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(_formatAddress(billing)),

              const SizedBox(height: 12),
              Text('عنوان الشحن', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(_formatAddress(shipping).isNotEmpty ? _formatAddress(shipping) : 'مطابق للفوترة'),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String k, String v, {bool bold = false}) {
    final style = bold ? const TextStyle(fontWeight: FontWeight.bold) : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(k, style: style), Text(v, style: style)],
      ),
    );
  }

  String _formatAddress(Map<String, dynamic> j) {
    final parts = [
      j['first_name'], j['last_name'],
      j['address_1'], j['city'],
      j['phone'], j['email']
    ].where((e) => (e?.toString().trim().isNotEmpty ?? false)).map((e) => e.toString()).toList();
    return parts.join(' • ');
  }
}
