import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scale = CurvedAnimation(parent: _c, curve: Curves.easeOutBack);
    _fade  = CurvedAnimation(parent: _c, curve: Curves.easeInOut);

    // شغّل الأنيميشن ثم انتقل للتبويبات
    _c.forward();
    Timer(const Duration(milliseconds: 1050), () {
      if (!mounted) return;
      context.go('/tabs/shop');
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface, // نفس لون الخلفية
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // اللوجو
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Image.asset(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'assets/splash/logo_full_dark.png'
                        : 'assets/splash/logo_full.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 18),
                // سطر صغير (اختياري)
                Text(
                  'Bride Magazine Arabia',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface.withOpacity(.75),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
