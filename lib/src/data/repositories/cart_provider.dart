import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';

class CartState {
  final List<CartItem> items;
  const CartState(this.items);

  double get subtotal => items.fold(0, (s, i) => s + i.total);
  bool get isEmpty => items.isEmpty;
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState([]));

  void add(CartItem item) {
    final idx = state.items.indexWhere((i) => i.productId == item.productId);
    if (idx >= 0) {
      final updated = List<CartItem>.from(state.items);
      updated[idx] = updated[idx].copyWith(quantity: updated[idx].quantity + item.quantity);
      state = CartState(updated);
    } else {
      state = CartState([...state.items, item]);
    }
  }

  void remove(int productId) {
    state = CartState(state.items.where((i) => i.productId != productId).toList());
  }

  void setQty(int productId, int qty) {
    if (qty <= 0) return remove(productId);
    final updated = state.items.map((i) => i.productId == productId ? i.copyWith(quantity: qty) : i).toList();
    state = CartState(updated);
  }

  void clear() => state = const CartState([]);
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) => CartNotifier());
