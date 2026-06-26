import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OrderSuccessScreen extends StatelessWidget {
  final int orderId;
  const OrderSuccessScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تم إرسال الطلب'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: c.primary.withOpacity(.12),
                  child: Icon(Icons.check_circle, color: c.primary, size: 56),
                ),
                const SizedBox(height: 16),
                Text(
                  'شكرًا لك!',
                  style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'تم استلام طلبك بنجاح',
                  style: t.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'رقم الطلب: #$orderId',
                  style: t.labelLarge?.copyWith(color: c.primary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // ✅ التوضيح المطلوب
                Card(
                  margin: const EdgeInsets.only(top: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ماذا بعد؟', style: t.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          'تم استلام طلبك وسيتواصل معك أحد موظفينا عبر معلومات التواصل التي أدخلتها '
                              '(الهاتف/البريد/العنوان) لتأكيد الطلب وترتيب التوصيل.',
                          style: t.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'إذا احتجنا أي تفاصيل إضافية سنقوم بالاتصال بك. شكرًا لثقتك بنا ❤️',
                          style: t.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.storefront),
                    label: const Text('متابعة التسوق'),
                    onPressed: () => context.go('/tabs/shop'),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('العودة إلى الرئيسية'),
                  onPressed: () => context.go('/tabs/shop'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
