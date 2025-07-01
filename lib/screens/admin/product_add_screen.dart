import 'dart:io'; // Untuk File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Package untuk memilih gambar
import '../../services/api_service.dart';
import '../../models/product_category.dart'; // Import model kategori produk

class ProductAddScreen extends StatefulWidget {
  const ProductAddScreen({super.key});

  @override
  State<ProductAddScreen> createState() => _ProductAddScreenState();
}

class _ProductAddScreenState extends State<ProductAddScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  ProductCategory? _selectedCategory; // Untuk menyimpan kategori yang dipilih
  List<ProductCategory> _categories =
      []; // Daftar kategori yang dimuat dari API
  File? _imageFile; // Untuk menyimpan file gambar yang dipilih

  bool _isLoading = false; // Status loading untuk submit form
  bool _isCategoryLoading = true; // Status loading untuk kategori

  @override
  void initState() {
    super.initState();
    _fetchCategories(); // Muat kategori saat inisialisasi
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  // --- Ambil daftar kategori dari API ---
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
      print('Categories loaded successfully: ${_categories.length} items');
    } catch (e) {
      print('DEBUG: Error in _fetchCategories() from ProductAddScreen: $e');
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

  // --- Pilih gambar dari galeri ---
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

  // --- Submit form untuk menambah produk ---
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
          categoryId: _selectedCategory?.id, // Kirim ID kategori yang dipilih
          imageFile: _imageFile!, // Kirim file gambar
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Produk berhasil ditambahkan!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(
            context,
          ).pop(true); // Kembali ke layar sebelumnya dengan hasil sukses
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
                    // Input Nama Produk
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

                    // Input Deskripsi Produk
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

                    // Input Harga Produk
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

                    // Input Stok Produk
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

                    // Dropdown Kategori
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
