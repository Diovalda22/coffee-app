import 'product.dart';

class OrderDetail {
  final int id;
  final int quantity;
  final int price;
  final Product product;

  OrderDetail({
    required this.id,
    required this.quantity,
    required this.price,
    required this.product,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      id: json['id'],
      quantity: json['quantity'],
      price: json['price'],
      product: Product.fromJson(json['product']),
    );
  }
}
