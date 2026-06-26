import 'package:equatable/equatable.dart';

class CartItem extends Equatable {
  final int productId;
  final String name;
  final String? image;
  final double price; // سعر للوحدة
  final int quantity;

  const CartItem({
    required this.productId,
    required this.name,
    this.image,
    required this.price,
    required this.quantity,
  });

  CartItem copyWith({int? quantity}) =>
      CartItem(productId: productId, name: name, image: image, price: price, quantity: quantity ?? this.quantity);

  double get total => price * quantity;

  @override
  List<Object?> get props => [productId, name, image, price, quantity];
}
