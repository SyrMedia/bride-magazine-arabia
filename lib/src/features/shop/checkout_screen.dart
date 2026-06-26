import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/cart_provider.dart';
import '../../data/repositories/orders_repository.dart';
import '../../data/repositories/auth_repository.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _form = GlobalKey<FormState>();

  final _first = TextEditingController();
  final _last = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();

  bool _busy = false;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      // كان: 'الدفع عند الاستلام' — خليه عنوان عام أو اتركه كما تحب
      appBar: AppBar(title: const Text('إتمام الشراء')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ملاحظة أعلى صفحة التشيك أوت
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'يرجى تعبئة جميع المعلومات بطريقة صحيحة (باستثناء الحقول الاختيارية).',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 8),
                    Text('طرق الدفع المتاحة:'),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.payments, size: 18),
                        SizedBox(width: 6),
                        Text('الدفع عند الاستلام'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // الحقول
            _field('الاسم', _first),
            _field('الكنية', _last),
            _field('الهاتف', _phone, keyboard: TextInputType.phone),
            _field('الإيميل (اختياري)', _email, keyboard: TextInputType.emailAddress, required: false),
            _field('العنوان', _address),
            _field('المدينة', _city),

            const SizedBox(height: 8),
            // سكشن طريقة الدفع (توضيح فقط)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.local_shipping),
              title: const Text(
                'الدفع عند الاستلام',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('سوف يتم الدفع نقداً عند استلام الطلب.'),
            ),

            const SizedBox(height: 8),
            const Divider(height: 24),

            // الإجمالي
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('إجمالي السلة'),
                Text(cart.subtotal.toStringAsFixed(2)),
              ],
            ),
            const SizedBox(height: 16),

            // زر تأكيد الطلب (بدون COD بالنص)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy
                    ? null
                    : () async {
                  if (!_form.currentState!.validate()) return;
                  if (cart.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('السلة فارغة')),
                    );
                    return;
                  }

                  setState(() => _busy = true);
                  try {
                    // لو المستخدم مسجّل دخول نمرّر customer_id للطلب
                    final auth = ref.read(authProvider);

                    final orderId = await ref.read(ordersRepoProvider).createCodOrder(
                      firstName: _first.text.trim(),
                      lastName: _last.text.trim(),
                      phone: _phone.text.trim(),
                      email: _email.text.trim().isEmpty
                          ? 'guest@example.com'
                          : _email.text.trim(),
                      address1: _address.text.trim(),
                      city: _city.text.trim(),
                      items: cart.items,
                      customerId: auth.isAuthed ? auth.user!.id : null,
                    );

                    // تنظيف السلة والانتقال لصفحة النجاح
                    ref.read(cartProvider.notifier).clear();
                    if (mounted) context.go('/tabs/shop/success/$orderId');
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('فشل إنشاء الطلب: $e')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _busy = false);
                  }
                },
                child: _busy
                    ? const SizedBox(
                    height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('تأكيد الطلب'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c,
      {TextInputType? keyboard, bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (v) {
          if (!required) return null;
          return (v == null || v.trim().isEmpty) ? 'مطلوب' : null;
        },
      ),
    );
  }
}
