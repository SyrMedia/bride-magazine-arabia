import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/cart_provider.dart';

/// زر السلة مع شارة (badge) بعدد العناصر.
/// استخدمه داخل AppBar.actions.
class CartIconButton extends ConsumerWidget {
  final VoidCallback? onPressed;
  const CartIconButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    // احسب العدد الإجمالي (لو عندك totalQuantity جاهزة، استخدمها بدل الجمع)
    final count = cart.items.fold<int>(0, (sum, it) => sum + (it.quantity));

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined),
          tooltip: 'السلة',
          onPressed: onPressed,
        ),
        if (count > 0)
          Positioned(
            // زاوية أعلى-يسار/يمين حسب اتجاه الـ IconButton
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
