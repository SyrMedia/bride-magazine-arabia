import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('السلة')),
      body: cart.isEmpty
          ? const Center(child: Text('سلتك فارغة'))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (_, i) {
                final it = cart.items[i];
                return ListTile(
                  leading: it.image != null
                      ? CachedNetworkImage(imageUrl: it.image!, width: 56, height: 56, fit: BoxFit.cover)
                      : const Icon(Icons.image),
                  title: Text(it.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text('السعر: ${it.price} × ${it.quantity} = ${it.total.toStringAsFixed(2)}'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(onPressed: () => ref.read(cartProvider.notifier).setQty(it.productId, it.quantity - 1), icon: const Icon(Icons.remove)),
                    Text('${it.quantity}'),
                    IconButton(onPressed: () => ref.read(cartProvider.notifier).setQty(it.productId, it.quantity + 1), icon: const Icon(Icons.add)),
                  ]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('الإجمالي'),
                  Text(cart.subtotal.toStringAsFixed(2)),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.go('/tabs/shop/checkout'),
                    child: const Text('متابعة للدفع عند الاستلام'),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
