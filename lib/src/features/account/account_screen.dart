import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository.dart';
import 'orders_screen.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

enum _AccountMode { login, register, resetPassword }

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _form = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _busy = false;
  bool _hidePassword = true;
  _AccountMode _mode = _AccountMode.login;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  String _title() {
    switch (_mode) {
      case _AccountMode.login:
        return 'تسجيل الدخول';
      case _AccountMode.register:
        return 'إنشاء حساب';
      case _AccountMode.resetPassword:
        return 'استعادة كلمة المرور';
    }
  }

  String _mainButtonText() {
    switch (_mode) {
      case _AccountMode.login:
        return 'دخول';
      case _AccountMode.register:
        return 'إنشاء الحساب';
      case _AccountMode.resetPassword:
        return 'إرسال رابط الاستعادة';
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    setState(() => _busy = true);

    try {
      final auth = ref.read(authProvider.notifier);

      switch (_mode) {
        case _AccountMode.login:
          await auth.login(
            username: _email.text.trim(),
            password: _password.text,
          );
          break;

        case _AccountMode.register:
          await auth.register(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
          );
          break;

        case _AccountMode.resetPassword:
          await auth.resetPassword(email: _email.text.trim());
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم إرسال رابط استعادة كلمة المرور إلى بريدك الإلكتروني'),
              ),
            );
            setState(() => _mode = _AccountMode.login);
          }
          break;
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الحساب'),
        content: const Text(
          'هل أنت متأكد من حذف حسابك؟ هذا الإجراء لا يمكن التراجع عنه.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف الحساب'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _busy = true);

    try {
      await ref.read(authProvider.notifier).deleteAccount();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الحساب بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
          busy: _busy,
          onLogout: () => ref.read(authProvider.notifier).logout(),
          onOpenOrders: (id) => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OrdersScreen(
                customerId: id,
                customerEmail: auth.user!.email,
              ),
            ),
          ),
          onDeleteAccount: _confirmDeleteAccount,
        )
            : Form(
          key: _form,
          child: ListView(
            children: [
              Text(
                _title(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              if (_mode == _AccountMode.register) ...[
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'الاسم',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (_mode != _AccountMode.register) return null;
                    return (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null;
                  },
                ),
                const SizedBox(height: 12),
              ],

              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: _mode == _AccountMode.resetPassword
                    ? TextInputAction.done
                    : TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return 'البريد الإلكتروني مطلوب';
                  if (!value.contains('@')) return 'البريد الإلكتروني غير صحيح';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              if (_mode != _AccountMode.resetPassword) ...[
                TextFormField(
                  controller: _password,
                  obscureText: _hidePassword,
                  textInputAction: _mode == _AccountMode.register
                      ? TextInputAction.next
                      : TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _hidePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _hidePassword = !_hidePassword);
                      },
                    ),
                  ),
                  validator: (v) {
                    if (_mode == _AccountMode.resetPassword) return null;
                    final value = v ?? '';
                    if (value.isEmpty) return 'كلمة المرور مطلوبة';
                    if (_mode == _AccountMode.register && value.length < 6) {
                      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],

              if (_mode == _AccountMode.register) ...[
                TextFormField(
                  controller: _confirmPassword,
                  obscureText: _hidePassword,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'تأكيد كلمة المرور',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (_mode != _AccountMode.register) return null;
                    if ((v ?? '').isEmpty) return 'تأكيد كلمة المرور مطلوب';
                    if (v != _password.text) return 'كلمتا المرور غير متطابقتين';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text(_mainButtonText()),
                ),
              ),

              const SizedBox(height: 12),

              if (_mode == _AccountMode.login) ...[
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () {
                    _form.currentState?.reset();
                    setState(() => _mode = _AccountMode.register);
                  },
                  child: const Text('إنشاء حساب جديد'),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () {
                    _form.currentState?.reset();
                    setState(() => _mode = _AccountMode.resetPassword);
                  },
                  child: const Text('نسيت كلمة المرور؟'),
                ),
              ] else ...[
                TextButton(
                  onPressed: _busy
                      ? null
                      : () {
                    _form.currentState?.reset();
                    setState(() => _mode = _AccountMode.login);
                  },
                  child: const Text('العودة إلى تسجيل الدخول'),
                ),
              ],

              const Divider(height: 32),

              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('سياسة الخصوصية'),
                subtitle: const Text('سياسة الخصوصية متاحة داخل صفحة التطبيق في المتجر والموقع الرسمي.'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('يمكنك الاطلاع على سياسة الخصوصية من صفحة التطبيق الرسمية.'),
                    ),
                  );
                },
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
  final bool busy;
  final VoidCallback onLogout;
  final void Function(int customerId) onOpenOrders;
  final VoidCallback onDeleteAccount;

  const _Authed({
    required this.user,
    required this.busy,
    required this.onLogout,
    required this.onOpenOrders,
    required this.onDeleteAccount,
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

        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text('حذف الحساب'),
          subtitle: const Text('حذف حسابك وبياناته من داخل التطبيق'),
          trailing: const Icon(Icons.chevron_left, color: Colors.red),
          onTap: busy ? null : onDeleteAccount,
        ),

        const SizedBox(height: 16),

        FilledButton.tonal(
          onPressed: busy ? null : onLogout,
          child: const Text('تسجيل الخروج'),
        ),
      ],
    );
  }
}