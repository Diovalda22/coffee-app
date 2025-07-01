class Product {
  final int id;
  final String name;
  final String description;
  final int price;
  final int stock;
  final String imageUrl;
  final int isPromoted;
  final int? productCategoryId;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.isPromoted,
    required this.stock,
    this.productCategoryId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] ?? 0,
      imageUrl: json['image_url'] ?? '',
      isPromoted: json['is_promoted'] ?? 0,
      stock: json['stock'] as int,
      productCategoryId: json['product_category_id'] as int?,
    );
  }
}
