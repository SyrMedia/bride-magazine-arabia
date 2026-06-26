import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ ضروري للـ SystemChrome
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'src/app_router.dart';
import 'src/core/app_cache.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔔 [BG] ${message.notification?.title}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ 1. تفعيل وضع Edge-to-Edge (العرض حتى الحافة)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // ✅ 2. جعل أشرطة النظام شفافة
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // شريط الحالة شفاف
    systemNavigationBarColor: Colors.transparent, // شريط التنقل السفلي شفاف
    statusBarIconBrightness: Brightness.dark, // أيقونات داكنة (يمكنك تغييرها حسب ذوقك)
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await _setupFCM();

  await Hive.initFlutter();
  await AppCache.init();
  await Hive.openBox('toolsBox');

  runApp(const ProviderScope(child: BmaApp()));
}

Future<void> _setupFCM() async {
  final fcm = FirebaseMessaging.instance;

  await fcm.requestPermission(alert: true, badge: true, sound: true);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('🔔 [FG] ${message.notification?.title}');
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('🔔 [CLICK] ${message.notification?.title}');
  });
}

class BmaApp extends StatelessWidget {
  const BmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 🎨 الألوان الأساسية
    const roseAccent = Color(0xFFF2C2D4);   // وردي
    const goldAccent = Color(0xFFEBC13D);   // ذهبي
    const warmCharcoal = Color(0xFF4A4A4A); // فحمي
    const darkBackground = Color(0xFF333333); // فحمي غامق
    const pearlWhite = Color(0xFFFFFAF0);   // أبيض لؤلؤي

    // 🆕 الألوان الجديدة للثيم النهاري
    const lightBgNew = Color(0xFFEEDECF);   // خلفية #eedecf
    const lightCardNew = Color(0xFFE9BBB6); // كروت #e9bbb6

    // 🆕 ألوان الشريط السفلي
    const navIconsColor = Color(0xFFEEDECF); // أيقونات #eedecf
    const navTextColor = Color(0xFFDEC170);  // كتابة #dec170
    const navIndicatorColor = Color(0xFFE9BBB6); // تركيز #e9bbb6

    // 🆕 ألوان أزرار المجلة (Chips)
    const chipBgColor = Color(0xFF4A4A4A);
    const chipTextColor = Color(0xFFEEDECF);
    const chipSelectedColor = Color(0xFFE9BBB6);

    // 🆕 لون كتابة أزرار المقالة
    const articleButtonTextColor = Color(0xFFE9BBB6);

    // 🆕 لون أيقونات الخدمات (ذهبي)
    const serviceIconsColor = Color(0xFFDEC170);

    // 📝 Text Theme
    TextTheme buildTextTheme(ColorScheme scheme) {
      const fallback = ['Cairo'];

      return TextTheme(
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          fontFamilyFallback: fallback,
          color: scheme.onSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          fontFamilyFallback: fallback,
          color: scheme.primary, // لون السعر
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.35,
          fontFamilyFallback: fallback,
          color: scheme.onSurface.withOpacity(.9),
        ),
        // 💡 إضافة bodySmall لإصلاح لون "وقت القراءة"
        bodySmall: TextStyle(
          fontSize: 12,
          fontFamilyFallback: fallback,
          // في الليلي (primary=وردي)، في النهاري (primary=فحمي)
          color: scheme.primary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontFamilyFallback: fallback,
          color: scheme.primary, // توحيد اللون للنصوص الصغيرة
        ),
      );
    }

    // 🌞 Light Scheme
    final lightScheme = ColorScheme(
      brightness: Brightness.light,
      primary: warmCharcoal,
      onPrimary: lightCardNew,
      secondary: goldAccent,
      onSecondary: warmCharcoal,
      background: lightBgNew,
      onBackground: warmCharcoal,
      surface: lightCardNew,
      onSurface: warmCharcoal,
      error: const Color(0xFFBA1A1A),
      onError: Colors.white,
      outline: warmCharcoal.withOpacity(.2),
    );

    // 🌙 Dark Scheme
    final darkScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: lightCardNew, // الوردي الترابي #E9BBB6 (للسعر ووقت القراءة)
      onPrimary: warmCharcoal,
      secondary: goldAccent,
      onSecondary: warmCharcoal,
      background: darkBackground,
      onBackground: pearlWhite,
      surface: warmCharcoal,
      onSurface: pearlWhite,
      error: const Color(0xFFFFB4AB),
      onError: warmCharcoal,
      outline: goldAccent.withOpacity(.4),
    );

    ThemeData buildTheme(ColorScheme scheme, TextTheme text) {

      final cartButtonBg = scheme.brightness == Brightness.light ? roseAccent : goldAccent;

      return ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: scheme.background,
        fontFamily: 'Poppins',

        textTheme: text.copyWith(
          titleLarge: text.titleLarge?.copyWith(
            color: scheme.onBackground,
          ),
          titleMedium: text.titleMedium?.copyWith(
            color: scheme.primary,
          ),
          bodySmall: text.bodySmall?.copyWith(
            color: scheme.primary, // تأكيد اللون الوردي في الليلي
          ),
        ),

        appBarTheme: AppBarTheme(
          backgroundColor: scheme.background,
          foregroundColor: scheme.onBackground,
          elevation: 0,
          centerTitle: true,
        ),

        cardTheme: CardThemeData(
          color: scheme.surface,
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
        ),

        // الأيقونات الذهبية
        iconTheme: const IconThemeData(
          color: serviceIconsColor,
          size: 24,
        ),
        primaryIconTheme: const IconThemeData(
          color: serviceIconsColor,
        ),
        listTileTheme: ListTileThemeData(
          iconColor: serviceIconsColor,
          titleTextStyle: text.titleMedium,
          subtitleTextStyle: text.bodySmall,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),

        // ChipTheme
        chipTheme: ChipThemeData(
          backgroundColor: chipBgColor,
          selectedColor: chipSelectedColor,
          disabledColor: chipBgColor.withOpacity(0.5),
          labelStyle: const TextStyle(
            color: chipTextColor,
            fontWeight: FontWeight.w600,
            fontFamilyFallback: ['Cairo'],
          ),
          secondaryLabelStyle: const TextStyle(
            color: warmCharcoal,
            fontWeight: FontWeight.w600,
            fontFamilyFallback: ['Cairo'],
          ),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),

        // زر الإضافة للسلة
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: cartButtonBg,
            foregroundColor: warmCharcoal,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontFamilyFallback: ['Cairo'],
            ),
          ),
        ),

        // أزرار الشير الخارجية
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            backgroundColor: warmCharcoal,
            foregroundColor: articleButtonTextColor,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontFamilyFallback: ['Cairo'],
            ),
          ),
        ),

        // زر المشاركة الممتلئ
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: warmCharcoal,
            foregroundColor: articleButtonTextColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontFamilyFallback: ['Cairo'],
            ),
          ),
        ),

        // الشريط السفلي
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: warmCharcoal,
          indicatorColor: navIndicatorColor,

          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(
              color: navTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamilyFallback: ['Cairo'],
            ),
          ),

          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: warmCharcoal);
            }
            return const IconThemeData(color: navIconsColor);
          }),
        ),
      );
    }

    final lightText = buildTextTheme(lightScheme);
    final darkText = buildTextTheme(darkScheme);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Bride Magazine Arabia',
      routerConfig: createRouter(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildTheme(lightScheme, lightText),
      darkTheme: buildTheme(darkScheme, darkText),
      themeMode: ThemeMode.system,
    );
  }
}