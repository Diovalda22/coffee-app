class ProductCategory {
  final int id;
  final String name;
  final String? deletedAt; // Nullable jika tidak dihapus
  final String? createdAt; // <<< UBAH MENJADI NULLABLE
  final String?
  updatedAt; // <<< JIKA ANDA MEMILIKI INI DI MODEL ANDA, UBAH JUGA KE NULLABLE

  ProductCategory({
    required this.id,
    required this.name,
    this.deletedAt,
    this.createdAt, // <<< UBAH KE NULLABLE DI CONSTRUCTOR
    this.updatedAt, // <<< JIKA ADA, UBAH KE NULLABLE DI CONSTRUCTOR
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      deletedAt: json['deleted_at'] as String?,
      createdAt: json['created_at'] as String?, // <<< UBAH KE NULLABLE CAST
      updatedAt: json['updated_at'] as String?,
    );
  }
}
