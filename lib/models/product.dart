class Product {
  final int id;
  final String name;
  final String description;
  final int price;
  final int stock;
  final String imageUrl;
  final int isPromoted;
  final int? productCategoryId;
  final double? averageRating;
  final int? finalPrice;
  final int? discountAmount;
  final int? discountType;
  final String? discountStart; // Changed from DateTime to String
  final String? discountEnd; // Changed from DateTime to String

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.isPromoted,
    required this.stock,
    this.productCategoryId,
    this.averageRating,
    this.finalPrice,
    this.discountAmount,
    this.discountType,
    this.discountStart,
    this.discountEnd,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      imageUrl: json['image_url'] as String? ?? '',
      isPromoted: (json['is_promoted'] as num?)?.toInt() ?? 0,
      productCategoryId: (json['product_category_id'] as num?)?.toInt(),
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      finalPrice: (json['final_price'] as num?)?.toInt(),
      discountAmount: (json['discount_amount'] as num?)?.toInt(),
      discountType: (json['discount_type'] as num?)?.toInt(),
      discountStart: json['discount_start'] as String?,
      discountEnd: json['discount_end'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'stock': stock,
    'image_url': imageUrl,
    'is_promoted': isPromoted,
    'product_category_id': productCategoryId,
    'average_rating': averageRating,
    'final_price': finalPrice,
    'discount_amount': discountAmount,
    'discount_type': discountType,
    'discount_start': discountStart,
    'discount_end': discountEnd,
  };

  // Helper method to check if discount is active
  bool get isDiscountActive {
    if (discountType == 0 || discountStart == null || discountEnd == null) {
      return false;
    }

    try {
      final now = DateTime.now();
      final startDate = DateTime.parse(discountStart!);
      final endDate = DateTime.parse(discountEnd!);

      return now.isAfter(startDate) &&
          now.isBefore(endDate.add(const Duration(days: 1)));
    } catch (e) {
      return false;
    }
  }
}
