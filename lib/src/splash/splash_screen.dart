import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  late final Animation<double> _fade =
  CurvedAnimation(parent: _c, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    _c.forward();

    Future.delayed(const Duration(milliseconds: 1200), () {
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fade,
        child: SafeArea(
          child: Center(
            child: Image.asset(
              'assets/splash/splash_full.png',
              width: MediaQuery.of(context).size.width * 0.72,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}