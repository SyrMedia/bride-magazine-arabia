import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/repositories/auth_repository.dart';
import 'orders_screen.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});
  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _form = GlobalKey<FormState>();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;

  // الروابط
  static final Uri _registerUrl = Uri.parse('https://bma-events.com/register');
  static final Uri _resetUrl    = Uri.parse('https://bma-events.com/my-account/lost-password/');
  static final Uri _privacyUrl  = Uri.parse('https://bma-events.com/privacy-policy');
  static final String _deletionBase = 'https://bma-events.com/account-deletion-request/';

  Future<void> _openExternal(Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر فتح الرابط')),
      );
    }
  }

  Future<void> _openDeletion() async {
    final auth = ref.read(authProvider);
    final uri = Uri.parse(_deletionBase).replace(queryParameters: {
      if (auth.isAuthed) 'uid': '${auth.user!.id}',
      if (auth.isAuthed && (auth.user!.email).isNotEmpty) 'email': auth.user!.email,
    });
    await _openExternal(uri);
  }

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: auth.isAuthed
            ? _Authed(
          user: auth.user!,
          onLogout: () => ref.read(authProvider.notifier).logout(),
          onOpenOrders: (id) => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => OrdersScreen(customerId: id)),
          ),
          onOpenRegister: () => _openExternal(_registerUrl),
          onOpenPrivacy: () => _openExternal(_privacyUrl),
          onOpenDeletion: _openDeletion,
        )
            : Form(
          key: _form,
          child: ListView(
            children: [
              const Text('تسجيل الدخول',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _user,
                decoration: const InputDecoration(
                  labelText: 'اسم المستخدم أو الإيميل',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pass,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy
                      ? null
                      : () async {
                    if (!_form.currentState!.validate()) return;
                    setState(() => _busy = true);
                    try {
                      await ref.read(authProvider.notifier).login(
                        username: _user.text.trim(),
                        password: _pass.text.trim(),
                      );
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('فشل تسجيل الدخول: $e')),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _busy = false);
                    }
                  },
                  child: _busy
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('دخول'),
                ),
              ),
              const SizedBox(height: 12),

              // إنشاء حساب → صفحة التسجيل مباشرة
              OutlinedButton(
                onPressed: () => _openExternal(_registerUrl),
                child: const Text('إنشاء حساب من الموقع'),
              ),
              TextButton(
                onPressed: () => _openExternal(_resetUrl),
                child: const Text('نسيت كلمة المرور؟'),
              ),

              const Divider(height: 32),

              // سياسة الخصوصية
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('سياسة الخصوصية'),
                subtitle: const Text('اطّلع على كيفية جمع البيانات واستخدامها'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _openExternal(_privacyUrl),
              ),

              // حذف البيانات والحساب (حتى لو مو مسجّل، يفتح الصفحة)
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('حذف البيانات والحساب'),
                subtitle: const Text('بدء عملية حذف الحساب وفق سياسة الخصوصية'),
                trailing: const Icon(Icons.open_in_new, color: Colors.red),
                onTap: _openDeletion,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Authed extends StatelessWidget {
  final AuthUser user;
  final VoidCallback onLogout;
  final void Function(int customerId) onOpenOrders;
  final VoidCallback onOpenRegister;
  final VoidCallback onOpenPrivacy;
  final VoidCallback onOpenDeletion;

  const _Authed({
    required this.user,
    required this.onLogout,
    required this.onOpenOrders,
    required this.onOpenRegister,
    required this.onOpenPrivacy,
    required this.onOpenDeletion,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.person),
          title: Text(user.displayName),
          subtitle: Text(user.email),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.receipt_long),
          title: const Text('طلباتي'),
          trailing: const Icon(Icons.chevron_left),
          onTap: () => onOpenOrders(user.id),
        ),
        const SizedBox(height: 8),

        // روابط مهمة
        ListTile(
          leading: const Icon(Icons.person_add_alt_1),
          title: const Text('إنشاء حساب جديد'),
          onTap: onOpenRegister,
          trailing: const Icon(Icons.open_in_new),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip),
          title: const Text('سياسة الخصوصية'),
          onTap: onOpenPrivacy,
          trailing: const Icon(Icons.open_in_new),
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text('حذف البيانات والحساب'),
          subtitle: const Text('سنفتح صفحة الحذف ونمرّر هويتك (إن وُجدت)'),
          onTap: onOpenDeletion,
          trailing: const Icon(Icons.open_in_new, color: Colors.red),
        ),

        const SizedBox(height: 12),
        FilledButton.tonal(onPressed: onLogout, child: const Text('تسجيل الخروج')),
      ],
    );
  }
}
