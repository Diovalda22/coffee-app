import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../models/product_category.dart';

class ProductAddScreen extends StatefulWidget {
  const ProductAddScreen({super.key});

  @override
  State<ProductAddScreen> createState() => _ProductAddScreenState();
}

class _ProductAddScreenState extends State<ProductAddScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  // Controller untuk field utama
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  // Controller untuk field diskon
  final TextEditingController _discountAmountController =
      TextEditingController();
  final TextEditingController _discountStartController =
      TextEditingController();
  final TextEditingController _discountEndController = TextEditingController();

  // Variabel state
  ProductCategory? _selectedCategory;
  List<ProductCategory> _categories = [];
  File? _imageFile;
  int? _selectedDiscountType; // 0 = persentase, 1 = nominal, 2 = custom

  bool _isLoading = false;
  bool _isCategoryLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
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
    setState(() {
      _isCategoryLoading = true;
    });
    try {
      final categories = await _apiService.fetchProductCategories();
      setState(() {
        _categories = categories;
        _isCategoryLoading = false;
      });
    } catch (e) {
      print('Error loading categories: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat kategori: $e')));
      }
      setState(() {
        _isCategoryLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_imageFile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Harap pilih gambar produk.')),
          );
        }
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        await _apiService.createProduct(
          name: _nameController.text,
          description: _descriptionController.text,
          price: int.parse(_priceController.text),
          stock: int.parse(_stockController.text),
          categoryId: _selectedCategory?.id,
          imageFile: _imageFile!,
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
              content: Text('Produk berhasil ditambahkan!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        print('Error adding product: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menambahkan produk: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Produk Baru')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Nama Produk
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Produk',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama produk tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Deskripsi Produk
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi Produk',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Deskripsi produk tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Harga Produk
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Harga',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Harga tidak boleh kosong';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Harga harus angka';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Stok Produk
                    TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(
                        labelText: 'Stok',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Stok tidak boleh kosong';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Stok harus angka';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Kategori Produk
                    _isCategoryLoading
                        ? const CircularProgressIndicator()
                        : DropdownButtonFormField<ProductCategory>(
                            decoration: const InputDecoration(
                              labelText: 'Kategori Produk (Opsional)',
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedCategory,
                            hint: const Text('Pilih Kategori'),
                            onChanged: (ProductCategory? newValue) {
                              setState(() {
                                _selectedCategory = newValue;
                              });
                            },
                            items: _categories.map((ProductCategory category) {
                              return DropdownMenuItem<ProductCategory>(
                                value: category,
                                child: Text(category.name),
                              );
                            }).toList(),
                          ),
                    const SizedBox(height: 16),

                    // Jumlah Diskon
                    TextFormField(
                      controller: _discountAmountController,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah Diskon (Opsional)',
                        border: OutlineInputBorder(),
                        hintText: 'Misal: 10000 atau 10',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            double.tryParse(value) == null) {
                          return 'Harus angka';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Tipe Diskon
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Tipe Diskon (Opsional)',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedDiscountType,
                      hint: const Text('Pilih Tipe Diskon'),
                      onChanged: (int? newValue) {
                        setState(() {
                          _selectedDiscountType = newValue;
                        });
                      },
                      items: const [
                        DropdownMenuItem<int>(
                          value: 1,
                          child: Text('Persentase'),
                        ),
                        DropdownMenuItem<int>(value: 2, child: Text('Nominal')),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tanggal Mulai Diskon
                    TextFormField(
                      controller: _discountStartController,
                      decoration: const InputDecoration(
                        labelText: 'Mulai Diskon (Opsional)',
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

                    // Tanggal Berakhir Diskon
                    TextFormField(
                      controller: _discountEndController,
                      decoration: const InputDecoration(
                        labelText: 'Berakhir Diskon (Opsional)',
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
                          final startDate = DateTime.parse(
                            _discountStartController.text,
                          );
                          final endDate = DateTime.parse(value);
                          if (endDate.isBefore(startDate)) {
                            return 'Tanggal berakhir harus setelah tanggal mulai';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Pemilihan Gambar
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Pilih Gambar Produk'),
                    ),
                    if (_imageFile != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Image.file(
                          _imageFile!,
                          height: 150,
                          width: 150,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text('Belum ada gambar dipilih.'),
                      ),
                    const SizedBox(height: 24),

                    // Tombol Submit
                    Center(
                      child: ElevatedButton(
                        onPressed: _submitProduct,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Tambah Produk',
                          style: TextStyle(fontSize: 18),
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
