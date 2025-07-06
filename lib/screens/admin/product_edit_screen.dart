import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/product.dart';
import '../../models/product_category.dart';
import '../../services/api_service.dart';
import 'package:coffee_app/widgets/product_image.dart';

class ProductEditScreen extends StatefulWidget {
  final Product product;

  const ProductEditScreen({super.key, required this.product});

  @override
  State<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Main product fields
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;

  // Discount fields
  late TextEditingController _discountAmountController;
  late TextEditingController _discountStartController;
  late TextEditingController _discountEndController;
  int? _selectedDiscountType;

  // Category and image
  ProductCategory? _selectedCategory;
  List<ProductCategory> _categories = [];
  File? _imageFile;
  String? _currentImageUrl;

  bool _isLoading = false;
  bool _isCategoryLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize all controllers with product data
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController = TextEditingController(
      text: widget.product.description,
    );
    _priceController = TextEditingController(
      text: widget.product.price.toString(),
    );
    _stockController = TextEditingController(
      text: widget.product.stock.toString(),
    );

    // Initialize discount fields
    _discountAmountController = TextEditingController(
      text: widget.product.discountAmount?.toString() ?? '',
    );
    _selectedDiscountType = widget.product.discountType;

    // Format dates if they exist
    if (widget.product.discountStart != null) {
      _discountStartController = TextEditingController(
        text: widget.product.discountStart!.substring(0, 10),
      );
    } else {
      _discountStartController = TextEditingController();
    }

    if (widget.product.discountEnd != null) {
      _discountEndController = TextEditingController(
        text: widget.product.discountEnd!.substring(0, 10),
      );
    } else {
      _discountEndController = TextEditingController();
    }

    _currentImageUrl = widget.product.imageUrl;
    _fetchCategories();
  }

  @override
  void dispose() {
    // Dispose all controllers
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _discountAmountController.dispose();
    _discountStartController.dispose();
    _discountEndController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isCategoryLoading = true);
    try {
      final categories = await _apiService.fetchProductCategories();
      setState(() {
        _categories = categories;
        if (widget.product.productCategoryId != null) {
          _selectedCategory = _categories.firstWhere(
            (cat) => cat.id == widget.product.productCategoryId,
          );
        }
        _isCategoryLoading = false;
      });
    } catch (e) {
      setState(() => _isCategoryLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat kategori: $e')));
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _currentImageUrl = null;
      });
    }
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _apiService.updateProduct(
        id: widget.product.id,
        name: _nameController.text,
        description: _descriptionController.text,
        price: int.parse(_priceController.text),
        stock: int.parse(_stockController.text),
        categoryId: _selectedCategory?.id,
        imageFile: _imageFile,
        discountAmount: _discountAmountController.text.isNotEmpty
            ? int.parse(_discountAmountController.text)
            : null,
        discountType: _selectedDiscountType,
        discountStart: _discountStartController.text.isNotEmpty
            ? _discountStartController.text
            : null,
        discountEnd: _discountEndController.text.isNotEmpty
            ? _discountEndController.text
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui produk: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Produk')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Produk*',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama produk wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Product Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi Produk*',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Deskripsi produk wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Product Price
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Harga*',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Harga wajib diisi';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Masukkan angka yang valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Product Stock
                    TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(
                        labelText: 'Stok*',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Stok wajib diisi';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Masukkan angka yang valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Product Category
                    _isCategoryLoading
                        ? const CircularProgressIndicator()
                        : DropdownButtonFormField<ProductCategory>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Kategori Produk',
                              border: OutlineInputBorder(),
                            ),
                            items: _categories.map((category) {
                              return DropdownMenuItem<ProductCategory>(
                                value: category,
                                child: Text(category.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                          ),
                    const SizedBox(height: 16),

                    // Discount Amount
                    TextFormField(
                      controller: _discountAmountController,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah Diskon (Rp)',
                        border: OutlineInputBorder(),
                        hintText: 'Misal: 10000',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            int.tryParse(value) == null) {
                          return 'Masukkan angka yang valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Discount Type
                    DropdownButtonFormField<int>(
                      value: _selectedDiscountType,
                      decoration: const InputDecoration(
                        labelText: 'Tipe Diskon',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Pilih tipe diskon'),
                      items: const [
                        DropdownMenuItem(
                          value: 0,
                          child: Text('Pilih tipe diskon'),
                        ),
                        DropdownMenuItem(value: 1, child: Text('Persentase')),
                        DropdownMenuItem(value: 2, child: Text('Nominal')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedDiscountType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Discount Start Date
                    TextFormField(
                      controller: _discountStartController,
                      decoration: const InputDecoration(
                        labelText: 'Mulai Diskon',
                        border: OutlineInputBorder(),
                        hintText: 'YYYY-MM-DD',
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          _discountStartController.text =
                              "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Discount End Date
                    TextFormField(
                      controller: _discountEndController,
                      decoration: const InputDecoration(
                        labelText: 'Berakhir Diskon',
                        border: OutlineInputBorder(),
                        hintText: 'YYYY-MM-DD',
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          _discountEndController.text =
                              "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                        }
                      },
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            _discountStartController.text.isNotEmpty) {
                          final start = DateTime.parse(
                            _discountStartController.text,
                          );
                          final end = DateTime.parse(value);
                          if (end.isBefore(start)) {
                            return 'Tanggal berakhir harus setelah tanggal mulai';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Image Upload Section
                    const Text(
                      'Gambar Produk*',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Pilih Gambar Baru'),
                    ),
                    const SizedBox(height: 8),
                    _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _imageFile!,
                              height: 150,
                              width: 150,
                              fit: BoxFit.cover,
                            ),
                          )
                        : _currentImageUrl != null &&
                              _currentImageUrl!.isNotEmpty
                        ? ProductImage(
                            imagePath: _currentImageUrl!,
                            width: 150,
                            height: 150,
                            borderRadius: 8,
                          )
                        : Container(
                            height: 150,
                            width: 150,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image, size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  'No Image',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                    const SizedBox(height: 24),

                    // Submit Button
                    Center(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateProduct,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'SIMPAN PERUBAHAN',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
