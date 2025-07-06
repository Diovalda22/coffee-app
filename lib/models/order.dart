// import 'package:coffee_app/models/order_detail.dart';

// class Order {
//   final int id;
//   final int totalPrice;
//   final String paymentStatus;
//   final String? paymentMethod;
//   final DateTime createdAt;
//   final DateTime deletedAt;
//   final List<OrderDetail> details;

//   Order({
//     required this.id,
//     required this.totalPrice,
//     required this.paymentStatus,
//     required this.paymentMethod,
//     required this.createdAt,
//     required this.details,
//     required this.deletedAt,
//   });

//   factory Order.fromJson(Map<String, dynamic> json) {
//     return Order(
//       id: json['id'],
//       totalPrice: json['total_price'],
//       paymentStatus: json['payment_status'] ?? 'unknown',
//       paymentMethod: json['payment_method'],
//       createdAt: json['created_at'] != null
//           ? DateTime.parse(json['created_at'])
//           : DateTime.now(),
//       deletedAt: json['deleted_at'] != null
//           ? DateTime.parse(json['created_at'])
//           : DateTime.now(),
//       details:
//           (json['details'] as List?)
//               ?.map((d) => OrderDetail.fromJson(d))
//               .toList() ??
//           [],
//     );
//   }
// }

// lib/models/order.dart
import 'package:intl/intl.dart';
import 'product_category.dart';

class Order {
  final int id;
  final int? userId;
  final int totalPrice;
  final String paymentStatus;
  final int? totalQuantity;
  final String? paymentMethod;
  final OrderUser user;
  final String? orderDate;
  final List<OrderDetail> details;
  final DateTime createdAt;
  final DateTime? deletedAt;

  Order({
    required this.id,
    this.userId,
    required this.totalPrice,
    required this.paymentStatus,
    this.totalQuantity,
    this.paymentMethod,
    required this.user,
    this.orderDate,
    required this.details,
    required this.createdAt,
    this.deletedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int,
      userId: json['user_id'] as int?,
      totalPrice: json['total_price'],
      paymentStatus: json['payment_status'] as String,
      totalQuantity: json['total_quantity'] as int?,
      paymentMethod: json['payment_method'] as String?,
      user: json['user'] != null
          ? OrderUser.fromJson(json['user'])
          : OrderUser(id: 0, name: 'Tidak diketahui', email: '-'),
      orderDate: json['order_date'] as String?,
      details:
          (json['details'] as List<dynamic>?)
              ?.map((e) => OrderDetail.fromJson(e))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'])
          : null,
    );
  }

  String get formattedPrice => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  ).format(totalPrice);

  String get formattedDate {
    if (orderDate != null) {
      try {
        final dateTime = DateTime.parse(orderDate!).toLocal();
        return DateFormat('dd MMM, HH:mm').format(dateTime);
      } catch (_) {}
    }
    if (createdAt != null) {
      return DateFormat('dd MMM, HH:mm').format(createdAt!.toLocal());
    }
    return 'Tanggal Tidak Tersedia';
  }
}

class OrderUser {
  final int id;
  final String name;
  final String email;

  OrderUser({required this.id, required this.name, required this.email});

  factory OrderUser.fromJson(Map<String, dynamic> json) {
    return OrderUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }
}

class OrderDetail {
  final int id;
  final int orderId;
  final int productId;
  final int quantity;
  final double price;
  final OrderProduct product;

  OrderDetail({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.product,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      productId: json['product_id'] as int,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      product: OrderProduct.fromJson(json['product']),
    );
  }

  String get formattedPrice {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }
}

class OrderProduct {
  final int id;
  final int productCategoryId;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String imageUrl;
  final int isPromoted;
  final ProductCategory category;

  OrderProduct({
    required this.id,
    required this.productCategoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.imageUrl,
    required this.isPromoted,
    required this.category,
  });

  factory OrderProduct.fromJson(Map<String, dynamic> json) {
    return OrderProduct(
      id: json['id'] as int,
      productCategoryId: json['product_category_id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int,
      imageUrl: json['image_url'] as String,
      isPromoted: json['is_promoted'] as int,
      category: ProductCategory.fromJson(json['category']),
    );
  }
}
