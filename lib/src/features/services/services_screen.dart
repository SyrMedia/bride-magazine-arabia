import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  // بيانات التواصل
  static const _phoneRaw = '00963937202526';
  static const _phonePretty = '00963937202526';
  static const _whatsappUrl = 'https://wa.me/963937202526';
  static const _websiteUrl = 'https://bma-events.com/';
  static const _emailUrl = 'mailto:cs@bma-events.com';

  // قائمة الخدمات (عنوان + ملخّص قصير + وصف كامل)
  final _services = const [
    (
    icon: Icons.event,
    title: 'EVENTS PLANNER تنظيم مناسبات',
    short:
    'خدمة متكاملة لتخطيط وتنفيذ حفلك من الفكرة إلى يوم الحدث.',
    full:
    'نوفّر إدارة كاملة للمناسبة: تحديد الثيم والهوية البصرية، إعداد الميزانية،'
        ' ترشيح وإدارة الموردين (قاعة، ضيافة، تصوير، موسيقى، ديكور)، وضع جدول يوم الزفاف،'
        ' والإشراف الميداني لضمان تنفيذ كل التفاصيل بسلاسة وذوق رفيع.'
    ),
    (
    icon: Icons.camera_alt,
    title: 'خدمة Wedding Content Creator',
    short:
    'توثيق لحظاتك بالصور والفيديو ونشر محتوى فوري على الانستغرام و TikTok.',
    full:
    'فريق مختص لتغطية الفعاليات على السوشيال: ستوريز لحظية، مقاطع Reels،'
        ' صور احترافية، ولقطات فيديو قصيرة مناسبة للنشر. هدفنا نقل الأجواء الحقيقية للحفل'
        ' للضيوف والمتابعين بأسلوب أنيق وممتع.'
        ' بالاضافة لظهور مميز على حساب الانستغرام لبرايد مجازين آريبيا .'
    ),
    (
    icon: Icons.favorite,
    title: 'Bride Assistant مساعدة للعروس',
    short:
    'مساعدة شخصية قبل وأثناء يوم الزفاف تهتم بكل التفاصيل الصغيرة.',
    full:
    'منسّقة عرائس شخصية—خبيرة ترافقك من الإلهام إلى التنفيذ: مواعيد، مهام، تواصل مع الفريق،'
        'وTimeline مضبوط، مع Checklists واضحة وPlan B جاهز'
        ' بدون توتر — لتستمتعي بكل لحظة.'
    ),
    (
    icon: Icons.star,
    title: 'كوني عروس العدد القادم',
    short:
    'شاركي قصتك وصورك في مجلة Bride Magazine Arabia.',
    full:
    'ندعوكِ لتكوني نجمة غلافنا القادمة! ننسّق جلسة تصوير وقصة مميّزة تعكس شخصيتك وذوقك،'
        ' ثم ننشرها ضمن صفحات المجلة وعلى قنواتنا الرقمية.'
    ),
    (
    icon: Icons.shopping_cart,
    title: 'المتجر وكيفية الشراء',
    short:
    'تصفّحي المنتجات، أضيفي للسلة، وادفعي بأمان.',
    full:
    'الشراء بسيط: ادخلي إلى “المتجر”، اختاري المنتج، اضيفيه للسلة، ثم اتجهي للدفع.'
        ' يمكنك متابعة حالة الطلب وخدمة مابعد البيع عبر فريق الدعم.'
    ),
  ];

  // فتح الروابط/الاتصال
  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر فتح الرابط: $url')),
      );
    }
  }

  Widget _contactTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(value),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('خدماتنا')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // عنوان
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('خدماتنا', style: theme.textTheme.headlineSmall),
          ),

          // ستايل عام للـ ExpansionTile ليتماشى مع الثيم
          ExpansionTileTheme(
            data: ExpansionTileThemeData(
              tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              backgroundColor: theme.colorScheme.surface,
              collapsedBackgroundColor: theme.colorScheme.surface,
              textColor: theme.colorScheme.onSurface,
              iconColor: theme.colorScheme.primary,
              collapsedTextColor: theme.colorScheme.onSurface,
              collapsedIconColor: theme.colorScheme.onSurfaceVariant,
              expandedAlignment: Alignment.centerLeft,
            ),
            child: Column(
              children: [
                for (final s in _services)
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    clipBehavior: Clip.antiAlias,
                    child: ExpansionTile(
                      leading: Icon(s.icon, size: 28, color: theme.colorScheme.primary),
                      title: Text(
                        s.title,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          s.short,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      children: [
                        // نص موسّع يظهر عند التمديد
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            s.full,
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.start,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // CTA سريع لطلب الخدمة (واتساب)
                        Row(
                          children: [
                            FilledButton.icon(
                              icon: const Icon(Icons.chat_bubble), // لا يوجد أيقونة WhatsApp أصلية
                              label: const Text('اطلبي الخدمة عبر واتساب'),
                              onPressed: () => _openUrl(_whatsappUrl),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.phone),
                              label: const Text('اتصال'),
                              onPressed: () => _openUrl('tel:$_phoneRaw'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Text('تواصل معنا', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),

          _contactTile(
            icon: Icons.phone,
            label: 'الهاتف',
            value: _phonePretty,
            onTap: () => _openUrl('tel:$_phoneRaw'),
          ),
          _contactTile(
            icon: Icons.chat_bubble, // بديل لأيكون واتساب
            label: 'واتساب',
            value: _phonePretty,
            onTap: () => _openUrl(_whatsappUrl),
          ),
          _contactTile(
            icon: Icons.language,
            label: 'الموقع الإلكتروني',
            value: 'bma-events.com',
            onTap: () => _openUrl(_websiteUrl),
          ),
          _contactTile(
            icon: Icons.email,
            label: 'البريد الإلكتروني',
            value: 'cs@bma-events.com',
            onTap: () => _openUrl(_emailUrl),
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('ارسلي طلبك الآن عبر واتساب'),
              onPressed: () => _openUrl(_whatsappUrl),
            ),
          ),
        ],
      ),
    );
  }
}
