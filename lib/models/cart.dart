import 'product.dart';

class Cart {
  final int id;
  final int productId;
  final int quantity;
  final Product product;

  Cart({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.product,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'],
      productId: json['product_id'],
      quantity: json['quantity'],
      product: Product.fromJson(json['product']),
    );
  }
}
