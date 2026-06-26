import 'features/shop/shop_screen.dart';
import 'features/magazine/magazine_screen.dart';
import 'features/tools/tools_screen.dart';
import 'features/account/account_screen.dart';
import 'features/services/services_screen.dart'; // 👈 التاب الجديد “خدماتنا”

// Shop sub-screens
import 'features/shop/product_details_screen.dart';
import 'features/shop/cart_screen.dart';
import 'features/shop/checkout_screen.dart';
import 'features/shop/order_success_screen.dart';

// ✅ الاستيراد الصحيح لأن app_router.dart داخل lib/src/
import 'splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/magazine/article_screen.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // ---------- Flutter Splash ----------
      GoRoute(
        path: '/',
        builder: (_, __) => const SplashScreen(),
      ),

      // ---------- Shell + Bottom Tabs ----------
      StatefulShellRoute.indexedStack(
        builder: (context, state, navShell) {
          return WillPopScope(
            onWillPop: () async {
              // index 0 = المتجر
              final currentIndex = navShell.currentIndex;

              // لو المستخدم على أي تب غير المتجر:
              // → رجّعه على المتجر بدل ما يطلع من التطبيق
              if (currentIndex != 0) {
                navShell.goBranch(0);
                return false; // لا تنفّذ الباك الافتراضي
              }

              // لو هو على فرع المتجر (index == 0):
              // نسمح للـ back يشتغل طبيعي:
              // - لو في صفحة داخلية → يرجع لها
              // - لو هو على /tabs/shop بالضبط → يطلع من التطبيق
              return true;
            },
            child: Scaffold(
              body: navShell,
              bottomNavigationBar: NavigationBar(
                selectedIndex: navShell.currentIndex,
                onDestinationSelected: (i) => navShell.goBranch(i),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.storefront),
                    label: 'المتجر',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.menu_book),
                    label: 'المجلة',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.checklist),
                    label: 'الأدوات',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.miscellaneous_services),
                    label: 'خدماتنا', // 👈 جديد
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person),
                    label: 'حسابي',
                  ),
                ],
              ),
            ),
          );
        },
        branches: [
          // ---------- Shop ----------
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tabs/shop',
                builder: (_, __) => const ShopScreen(),
                routes: [
                  GoRoute(
                    path: 'p/:id',
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return ProductDetailsScreen(
                        productId: id,
                        initial: state.extra,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'cart',
                    builder: (_, __) => const CartScreen(),
                  ),
                  GoRoute(
                    path: 'checkout',
                    builder: (_, __) => const CheckoutScreen(),
                  ),
                  GoRoute(
                    path: 'success/:orderId',
                    builder: (context, state) => OrderSuccessScreen(
                      orderId: int.parse(state.pathParameters['orderId']!),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ---------- Magazine ----------
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tabs/mag',
                builder: (_, __) => const MagazineScreen(),
                routes: [
                  GoRoute(
                    path: 'a/:id',
                    builder: (context, state) => ArticleScreen(
                      postId: int.parse(state.pathParameters['id']!),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ---------- Tools ----------
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tabs/tools',
                builder: (_, __) => const ToolsScreen(),
              ),
            ],
          ),

          // ---------- Services (خدماتنا) ----------
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tabs/services',
                builder: (_, __) => const ServicesScreen(),
              ),
            ],
          ),

          // ---------- Account ----------
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tabs/account',
                builder: (_, __) => const AccountScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
