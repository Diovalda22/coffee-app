import 'package:coffee_app/models/order_detail.dart';

class Order {
  final int id;
  final int totalPrice;
  final String paymentStatus;
  final String? paymentMethod;
  final DateTime createdAt;
  final DateTime deletedAt;
  final List<OrderDetail> details;

  Order({
    required this.id,
    required this.totalPrice,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.createdAt,
    required this.details,
    required this.deletedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      totalPrice: json['total_price'],
      paymentStatus: json['payment_status'] ?? 'unknown',
      paymentMethod: json['payment_method'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      details:
          (json['details'] as List?)
              ?.map((d) => OrderDetail.fromJson(d))
              .toList() ??
          [],
    );
  }
}
