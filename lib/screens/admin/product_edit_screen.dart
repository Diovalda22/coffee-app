// Path: lib/screens/product/product_edit_screen.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Untuk memilih gambar
import 'dart:io'; // Untuk tipe File

// Pastikan Anda mengimpor model dan service yang benar
import '../../helper/general_helper.dart';
import '../../models/product.dart'; // Import ProductModel
import '../../models/product_category.dart'; // Import ProductCategory
import '../../services/api_service.dart'; // Import ApiService Anda

class ProductEditScreen extends StatefulWidget {
  final Product product; // Menerima objek produk yang akan diedit dari layar sebelumnya

  const ProductEditScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  final _formKey = GlobalKey<FormState>(); // Kunci untuk validasi form
  final ApiService _apiService = ApiService(); // Instansi ApiService

  // Controllers untuk setiap input field, diinisialisasi di initState
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;

  // State untuk dropdown kategori
  ProductCategory? _selectedCategory;
  List<ProductCategory> _categories = [];
  bool _isCategoryLoading = true; // Status loading kategori

  // State untuk gambar
  File? _imageFile; // Menyimpan gambar baru yang dipilih dari galeri
  String? _currentImageUrl; // Menyimpan URL gambar yang sudah ada (dari produk yang diedit)

  bool _isLoading = false; // Status loading saat submit form

  @override
  void initState() {
    super.initState();
    // Inisialisasi controllers dengan data produk yang diterima
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController = TextEditingController(text: widget.product.description);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _stockController = TextEditingController(text: widget.product.stock.toString());

    // Set URL gambar yang sudah ada dari objek produk
    _currentImageUrl = widget.product.imageUrl;

    // Ambil daftar kategori dari API
    _fetchCategories();
  }

  @override
  void dispose() {
    // Pastikan untuk membuang controllers saat widget di-dispose untuk mencegah memory leaks
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  // --- Metode untuk mengambil daftar kategori dari API ---
  Future<void> _fetchCategories() async {
    setState(() {
      _isCategoryLoading = true;
    });
    try {
      final categories = await _apiService.fetchProductCategories();
      setState(() {
        _categories = categories;
        // Setelah kategori dimuat, coba set kategori yang terpilih berdasarkan produk
        if (widget.product.productCategoryId != null) {
          _selectedCategory = _categories.firstWhere(
            (cat) => cat.id == widget.product.productCategoryId,
            orElse: () => _categories.first, // Fallback jika tidak ditemukan
          );
        }
        _isCategoryLoading = false;
      });
      print('Categories loaded successfully for Edit Product: ${_categories.length} items');
    } catch (e) {
      print('DEBUG: Error fetching categories in ProductEditScreen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat kategori: $e')),
        );
      }
      setState(() {
        _isCategoryLoading = false;
      });
    }
  }

  // --- Metode untuk memilih gambar dari galeri ---
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Kompresi gambar untuk mengurangi ukuran file
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _currentImageUrl = null; // Hapus URL gambar lama agar tampilan mengarah ke gambar baru
      });
      print('DEBUG: New image picked for update. Path: ${_imageFile!.path}');
    } else {
      print('DEBUG: Image picking for update cancelled.');
    }
  }

  // --- Metode untuk submit form update produk ---
  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) {
      return; // Hentikan jika validasi form gagal
    }

    setState(() {
      _isLoading = true; // Set status loading
    });

    try {
      await _apiService.updateProduct(
        id: widget.product.id, // Kirim ID produk yang diedit
        name: _nameController.text,
        description: _descriptionController.text,
        price: int.parse(_priceController.text),
        stock: int.parse(_stockController.text),
        categoryId: _selectedCategory?.id, // Kirim ID kategori yang dipilih (bisa null)
        imageFile: _imageFile, // Kirim file gambar baru (bisa null jika tidak diganti)
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Kembali ke layar sebelumnya dengan sinyal sukses
      }
    } catch (e) {
      print('Error updating product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui produk: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false; // Nonaktifkan status loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Produk')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Tampilkan loading saat submit
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
                        ? const CircularProgressIndicator() // Tampilkan loading saat kategori dimuat
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
                            // Validator bisa ditambahkan jika kategori wajib
                            // validator: (value) {
                            //   if (value == null) {
                            //     return 'Kategori tidak boleh kosong';
                            //   }
                            //   return null;
                            // },
                          ),
                    const SizedBox(height: 16),

                    // Pemilihan dan Tampilan Gambar
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Pilih Gambar Baru'),
                    ),
                    const SizedBox(height: 8),
                    _imageFile != null // Jika ada gambar baru yang dipilih
                        ? Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Image.file(
                              _imageFile!,
                              height: 150,
                              width: 150,
                              fit: BoxFit.cover,
                            ),
                          )
                        : _currentImageUrl != null && _currentImageUrl!.isNotEmpty // Jika ada URL gambar lama
                            ? Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Image.network(
                                  // Asumsikan gambar disimpan di folder 'storage' di Laravel public
                                  // Sesuaikan URL ini jika lokasi gambar berbeda
                                  '${baseImageUrl}${_currentImageUrl!}',
                                  
                                  height: 150,
                                  width: 150,
                                  fit: BoxFit.cover,
                                  // Handle error jika gambar tidak bisa dimuat
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image, size: 100),
                                  // Optional: Tampilkan loading saat gambar diunduh
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                ),
                              )
                            : const Padding( // Jika tidak ada gambar sama sekali
                                padding: EdgeInsets.only(top: 8.0),
                                child: Text('Tidak ada gambar produk.'),
                              ),
                    const SizedBox(height: 24),

                    // Tombol Submit
                    Center(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateProduct, // Nonaktifkan tombol saat loading
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white) // Tampilkan loading di tombol
                            : const Text(
                                'Simpan Perubahan',
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