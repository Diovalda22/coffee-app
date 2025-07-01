import 'dart:convert';

import 'package:coffee_app/helper/general_helper.dart';
import 'package:coffee_app/models/order.dart';
import 'package:coffee_app/models/product.dart';
import 'package:coffee_app/models/product_category.dart';
import 'package:coffee_app/screens/admin/order_detail_screen.dart';
import 'package:coffee_app/screens/admin/product_add_screen.dart';
import 'package:coffee_app/screens/admin/product_edit_screen.dart';
import 'package:coffee_app/services/api_service.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/dashboard_stats.dart';

void main() {
  runApp(const MaterialApp(home: AdminHomeScreen()));
}

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;
  final api = ApiService();

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ProductManagementScreen(),
    const CategoryManagementScreen(),
    const OrderManagementScreen(),
  ];

  Future<void> _performLogout() async {
    try {
      final success = await api.logout();
      if (mounted) {
        if (success) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logout berhasil (offline)')),
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal logout: $e')));
      }
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(context).pop();
              await Future.delayed(const Duration(milliseconds: 200));
              if (mounted) await _performLogout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();
  static const Color appScreenBackgroundColor = Color(0xFFDAB894);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appScreenBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header tetap
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20.0),
              ),
              child: Container(
                height: kToolbarHeight,
                color: const Color(0xFF4E342E),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Admin Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: _showLogoutConfirmation,
                    ),
                  ],
                ),
              ),
            ),

            // Konten dengan jarak dari header
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: IndexedStack(index: _currentIndex, children: _screens),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey, // Hubungkan key
        index: _currentIndex, // Index awal
        height: 60.0, // Tinggi navigation bar
        items: const <Widget>[
          Icon(Icons.dashboard, size: 30, color: Colors.white),
          Icon(Icons.shopping_bag, size: 30, color: Colors.white),
          Icon(Icons.category, size: 30, color: Colors.white),
          Icon(Icons.receipt, size: 30, color: Colors.white),
        ],
        color: const Color(0xFF4E342E), // Warna dasar navigation bar
        buttonBackgroundColor: const Color(
          0xFF4E342E,
        ), // Warna background tombol yang aktif
        backgroundColor: Colors
            .transparent, // Warna background di belakang curve (biasanya transparan agar terlihat konten di bawahnya)
        animationCurve: Curves.easeInOut, // Kurva animasi
        animationDuration: const Duration(milliseconds: 300), // Durasi animasi
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        // letCurvePaint: true, // Jika ingin curve di atas konten
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<DashboardStats> _dashboardStatsFuture;
  late Future<List<Order>> _recentOrdersFuture;
  final ApiService apiService = ApiService();

  // --- Palet Warna (agar konsisten) ---
  static const Color screenBackgroundColor = Color(0xFFF5F5DC); // Krem muda
  static const Color cardBackgroundColor = Colors.white; // Card putih
  static const Color cardShadowColor = Colors.black26; // Shadow Card
  static const double cardElevation = 6.0; // Elevasi Card
  static const Color titleWrapperColor = Color(
    0xFF4E342E,
  ); // Warna pembungkus judul

  @override
  void initState() {
    super.initState();
    _dashboardStatsFuture = _fetchDashboardStats();
    _recentOrdersFuture = _fetchRecentOrders();
  }

  Future<DashboardStats> _fetchDashboardStats() async {
    try {
      final Map<String, dynamic> data = await apiService.getAdminStats();
      return DashboardStats.fromJson(data);
    } catch (e) {
      print('Error fetching dashboard stats: $e');
      throw Exception('Failed to load dashboard data: $e');
    }
  }

  Future<List<Order>> _fetchRecentOrders() async {
    try {
      final allOrders = await apiService.fetchOrders();
      final now = DateTime.now();

      return allOrders.where((order) {
        if (order.orderDate == null) {
          return false;
        }
        try {
          final orderDateTime = DateTime.parse(order.orderDate!).toLocal();
          return orderDateTime.year == now.year &&
              orderDateTime.month == now.month &&
              orderDateTime.day == now.day;
        } catch (e) {
          print('DEBUG: Failed to parse order date "${order.orderDate}": $e');
          return false;
        }
      }).toList();
    } catch (e) {
      print('Error fetching recent orders: $e');
      throw Exception('Gagal memuat daftar pesanan: $e');
    }
  }

  String formatRupiah(String amount) {
    try {
      final double number = double.parse(amount);
      final formatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp',
        decimalDigits: 0,
      );
      return formatter.format(number);
    } catch (e) {
      return 'Rp' + amount;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green[100]!;
      case 'pending':
        return Colors.orange[100]!;
      case 'shipped':
        return Colors.blue[100]!;
      case 'delivered':
        return Colors.purple[100]!;
      case 'cancelled':
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  String _getReadableStatus(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Dibayar';
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'shipped':
        return 'Dikirim';
      case 'delivered':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Widget _buildSummaryRow(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 16)),
          ],
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildRecentOrders(BuildContext context, List<Order> orders) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width - 32,
        ),
        child: DataTable(
          columnSpacing: 20,
          dataRowHeight: 48,
          columns: const [
            DataColumn(
              label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text(
                'Pelanggan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Tanggal',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Jumlah',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: orders.map((order) {
            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 80,
                    child: Text(
                      '#${order.id}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 120,
                    child: Text(
                      order.user.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 80,
                    child: Text(order.formattedDate.split(',')[0]),
                  ),
                ),
                DataCell(
                  SizedBox(width: 100, child: Text(order.formattedPrice)),
                ),
                DataCell(
                  Chip(
                    label: Text(
                      _getReadableStatus(order.paymentStatus),
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: _getStatusColor(order.paymentStatus),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch, // Agar children mengisi lebar
        children: [
          // --- Bagian Header/Judul Ringkasan ---
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16, // Sesuaikan padding
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: titleWrapperColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Ringkasan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16), // Jarak antara judul dan card ringkasan
          // --- FutureBuilder untuk Ringkasan (DashboardStats) ---
          FutureBuilder<DashboardStats>(
            // <<< INI UNTUK RINGKASAN
            future: _dashboardStatsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Card(
                  color: cardBackgroundColor,
                  elevation: cardElevation,
                  shadowColor: cardShadowColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              } else if (snapshot.hasError) {
                return Card(
                  color: Colors.red[50],
                  elevation: cardElevation,
                  shadowColor: cardShadowColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error memuat ringkasan: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _dashboardStatsFuture = _fetchDashboardStats();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (snapshot.hasData) {
                final stats = snapshot.data!;
                return Card(
                  color: cardBackgroundColor,
                  elevation: cardElevation,
                  shadowColor: cardShadowColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildSummaryRow(
                          'Total Produk',
                          stats.totalProducts.toString(),
                          Icons.shopping_bag,
                          Colors.blue,
                        ),
                        const Divider(height: 24),
                        _buildSummaryRow(
                          'Total Kategori',
                          stats.totalCategories.toString(),
                          Icons.category,
                          Colors.green,
                        ),
                        const Divider(height: 24),
                        _buildSummaryRow(
                          'Pesanan Hari Ini',
                          stats.todayOrders.toString(),
                          Icons.receipt,
                          Colors.orange,
                        ),
                        const Divider(height: 24),
                        _buildSummaryRow(
                          'Pendapatan Bulanan',
                          formatRupiah(stats.monthlyIncome),
                          Icons.attach_money,
                          Colors.purple,
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return Card(
                  color: cardBackgroundColor,
                  elevation: cardElevation,
                  shadowColor: cardShadowColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text('Tidak ada data ringkasan.')),
                  ),
                );
              }
            },
          ),

          const SizedBox(
            height: 24,
          ), // Jarak antara ringkasan dan pesanan terbaru
          // --- Bagian Header/Judul Pesanan Terbaru ---
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16, // Sesuaikan padding
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: titleWrapperColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pesanan Terbaru',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 8,
          ), // Jarak antara judul dan card pesanan terbaru
          // --- FutureBuilder untuk Pesanan Terbaru (List<Order>) ---
          FutureBuilder<List<Order>>(
            // <<< INI UNTUK PESANAN TERBARU
            future: _recentOrdersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Card(
                  color: cardBackgroundColor,
                  elevation: cardElevation,
                  shadowColor: cardShadowColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              } else if (snapshot.hasError) {
                return Card(
                  color: Colors.red[50],
                  elevation: cardElevation,
                  shadowColor: cardShadowColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error memuat pesanan terbaru: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _recentOrdersFuture = _fetchRecentOrders();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (snapshot.hasData) {
                final ordersToday = snapshot.data!;
                if (ordersToday.isEmpty) {
                  return Card(
                    color: cardBackgroundColor,
                    elevation: cardElevation,
                    shadowColor: cardShadowColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text('Tidak ada pesanan hari ini.'),
                      ), // <<< PESAN INI
                    ),
                  );
                } else {
                  return Card(
                    color: cardBackgroundColor,
                    elevation: cardElevation,
                    shadowColor: cardShadowColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: _buildRecentOrders(context, ordersToday),
                  );
                }
              } else {
                return Card(
                  color: cardBackgroundColor,
                  elevation: cardElevation,
                  shadowColor: cardShadowColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text('Tidak ada data pesanan.')),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final ApiService apiService = ApiService();
  late Future<List<Product>> _productsFuture;
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProducts();
  }

  Future<List<Product>> _fetchProducts() async {
    try {
      // UBAH PANGGILAN METODE DI SINI
      final products = await apiService
          .fetchAdminProducts(); // Panggil metode untuk admin
      setState(() {
        _products = products;
        _isLoading = false;
      });
      return products;
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load products: $e')));
      }
      throw Exception('Failed to load products: $e');
    }
  }

  // Fungsi formatter untuk Rupiah
  String formatRupiah(int amount) {
    // Mengambil int karena product.price adalah int
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  Future<void> _navigateToEditProductScreen(Product product) async {
    // Navigator.push akan mengarahkan ke halaman baru
    // dan menunggu hasil (pop(true) jika update berhasil)
    final bool? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductEditScreen(product: product),
      ),
    );

    // Jika result adalah true (artinya produk berhasil diupdate dan kembali),
    // maka refresh daftar produk
    if (result == true) {
      _fetchProducts(); // Panggil ulang untuk memuat data terbaru
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daftar produk diperbarui.')),
        );
      }
    }
  }

  Future<void> _deleteProduct(int productId, String productName) async {
    // Show a confirmation dialog before deleting
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus Produk'),
          content: Text('Anda yakin ingin menghapus produk "$productName"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // User cancels
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true), // User confirms
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    // Proceed with deletion only if confirmed
    if (confirm == true) {
      // Show a temporary loading snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Menghapus produk "$productName"...')),
      );

      try {
        await apiService.deleteProduct(
          productId,
        ); // Call the API to delete the product

        // After successful deletion, refresh the product list
        await _fetchProducts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Produk "$productName" berhasil dihapus!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Error deleting product: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus produk "$productName": $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                // <-- Huruf 'C' besar di sini
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4E342E), // Warna pembungkus
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Manajemen Produk',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Tambah'),
                onPressed: () async {
                  final bool? result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ProductAddScreen(),
                    ),
                  );
                  // Jika produk berhasil ditambahkan (result adalah true), refresh daftar
                  if (result == true) {
                    _productsFuture =
                        _fetchProducts(); // Re-assign future to trigger refresh
                    // Tidak perlu setState di sini karena _fetchProducts sudah setState
                  }
                  // TODO: Implementasi navigasi ke halaman tambah produk
                  print('Tombol Tambah Produk ditekan');
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting ||
                    _isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  ); // Indikator loading
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  ); // Tampilkan pesan error
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Tidak ada produk tersedia.'),
                  ); // Data kosong
                } else {
                  // Data berhasil dimuat, tampilkan daftar produk
                  return ListView.builder(
                    itemCount: _products.length, // Gunakan _products.length
                    itemBuilder: (context, index) {
                      final product = _products[index]; // Ambil objek produk

                      // Pastikan baseImageUrl tersedia di scope ini (diimpor atau global)
                      // Misalnya, jika baseImageUrl didefinisikan dari flutter_dotenv
                      final String fullImageUrl =
                          '$baseImageUrl${product.imageUrl}';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            radius: 20,
                            // Tampilkan gambar atau placeholder jika URL kosong/null
                            backgroundImage: product.imageUrl.isNotEmpty
                                ? NetworkImage(fullImageUrl) as ImageProvider
                                : const AssetImage(
                                    'assets/placeholder.png',
                                  ), // Ganti dengan path gambar placeholder Anda
                            onBackgroundImageError: (exception, stackTrace) {
                              // Handle error saat gambar gagal dimuat
                              print(
                                'Error memuat gambar ${product.name}: $exception',
                              );
                              // Anda bisa menampilkan gambar placeholder di sini
                            },
                          ),
                          title: Text(
                            product.name, // Tampilkan nama produk
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          subtitle: Text(
                            formatRupiah(
                              product.price,
                            ), // Tampilkan harga dengan format Rupiah
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  // TODO: Implementasi edit produk
                                  _navigateToEditProductScreen(product);
                                  print('Edit Produk: ${product.name}');
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  _deleteProduct(product.id, product.name);
                                  // TODO: Implementasi delete produk
                                  print('Hapus Produk: ${product.name}');
                                  // Misalnya, panggil API delete, lalu refresh daftar produk
                                  // _deleteProduct(product.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final ApiService _apiService = ApiService();
  List<ProductCategory> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCategories(); // Muat kategori saat layar diinisialisasi
  }

  // --- Ambil daftar kategori dari API ---
  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final fetchedCategories = await _apiService.fetchProductCategories();
      setState(() {
        _categories = fetchedCategories;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      print('DEBUG: Error fetching categories: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat kategori: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- Tambah/Edit Kategori (Menggunakan Dialog) ---
  Future<void> _showCategoryFormDialog({
    ProductCategory? categoryToEdit,
  }) async {
    final TextEditingController nameController = TextEditingController(
      text: categoryToEdit?.name ?? '',
    );
    final bool isEditing = categoryToEdit != null;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Kategori' : 'Tambah Kategori Baru'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nama Kategori',
              hintText: 'Masukkan nama kategori',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text(isEditing ? 'Simpan' : 'Tambah'),
              onPressed: () async {
                final String name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nama kategori tidak boleh kosong'),
                    ),
                  );
                  return;
                }

                setState(() {
                  _isLoading = true; // Set loading saat submit
                });

                try {
                  if (isEditing) {
                    await _apiService.updateProductCategory(
                      categoryToEdit!.id,
                      name,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kategori berhasil diperbarui!'),
                        ),
                      );
                    }
                  } else {
                    await _apiService.createProductCategory(name);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kategori berhasil ditambahkan!'),
                        ),
                      );
                    }
                  }
                  if (mounted) Navigator.of(context).pop(); // Tutup dialog
                  _fetchCategories(); // Refresh daftar setelah operasi
                } catch (e) {
                  print('DEBUG: Error in category operation: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal: ${e.toString()}')),
                    );
                  }
                } finally {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- Hapus Kategori ---
  Future<void> _deleteCategory(int categoryId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Apakah Anda yakin ingin menghapus kategori ini?'),
                Text('Tindakan ini tidak dapat dibatalkan.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus'),
              onPressed: () async {
                setState(() {
                  _isLoading = true;
                });
                try {
                  await _apiService.deleteProductCategory(categoryId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Kategori berhasil dihapus!'),
                      ),
                    );
                  }
                  if (mounted) Navigator.of(context).pop(); // Tutup dialog
                  _fetchCategories(); // Refresh daftar
                } catch (e) {
                  print('DEBUG: Error deleting category: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menghapus: ${e.toString()}'),
                      ),
                    );
                  }
                } finally {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Manajemen Kategori',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Tambah'),
                onPressed: () =>
                    _showCategoryFormDialog(), // Panggil dialog untuk tambah
              ),
            ],
          ),
          const SizedBox(height: 16),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text('Error: $_error'))
              : _categories.isEmpty
              ? const Center(child: Text('Belum ada kategori.'))
              : Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 3.5,
                        ),
                    itemCount: _categories.length, // Gunakan data asli
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.category, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  category.name, // Tampilkan nama kategori
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              PopupMenuButton<String>(
                                iconSize: 18,
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showCategoryFormDialog(
                                      categoryToEdit: category,
                                    );
                                  } else if (value == 'delete') {
                                    _deleteCategory(category.id);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Hapus'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final ApiService _apiService = ApiService();
  List<Order> _allOrders = []; // Semua pesanan yang dimuat dari API
  List<Order> _filteredOrders = []; // Pesanan yang ditampilkan setelah filter
  bool _isLoading = true;
  String? _error;
  String _selectedStatusFilter = 'Semua'; // Status filter yang aktif

  final List<String> _statusFilters = [
    'Semua',
    'pending', // Ini harus cocok dengan nilai 'payment_status' di JSON Anda
    'paid',
    'shipped',
    'delivered',
    'cancelled', // Tambahkan status lain jika ada di backend Anda
  ];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  // --- Ambil daftar pesanan dari API ---
  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _allOrders = await _apiService.fetchOrders();
      _applyFilter(); // Terapkan filter awal setelah memuat semua pesanan
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      print('DEBUG: Error fetching orders: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat pesanan: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- Terapkan Filter ---
  void _applyFilter() {
    if (_selectedStatusFilter == 'Semua') {
      _filteredOrders = List.from(_allOrders);
    } else {
      _filteredOrders = _allOrders
          .where((order) => order.paymentStatus == _selectedStatusFilter)
          .toList();
    }
    setState(() {}); // Perbarui UI
  }

  // --- Helper untuk mendapatkan warna status ---
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      // Gunakan toLowerCase untuk perbandingan yang konsisten
      case 'paid':
        return Colors.green[100]!;
      case 'pending':
        return Colors.orange[100]!;
      case 'shipped':
        return Colors.blue[100]!;
      case 'delivered':
        return Colors.purple[100]!;
      case 'cancelled':
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  // Helper untuk mendapatkan teks status yang lebih mudah dibaca
  String _getReadableStatus(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Dibayar';
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'shipped':
        return 'Dikirim';
      case 'delivered':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Manajemen Pesanan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusFilters.map((status) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(
                      _getReadableStatus(status),
                      style: TextStyle(
                        // === Perubahan di sini ===
                        color:
                            _selectedStatusFilter ==
                                status // Jika chip terpilih
                            ? Colors
                                  .white // Teks putih
                            : Colors.black, // Teks hitam jika tidak terpilih
                      ),
                    ), // Tampilkan teks yang lebih ramah pengguna
                    selected: _selectedStatusFilter == status,
                    onSelected: (selected) {
                      setState(() {
                        // Logika untuk reset filter jika chip yang sama dipilih lagi
                        if (_selectedStatusFilter == status && !selected) {
                          _selectedStatusFilter =
                              'All'; // Misalnya, reset ke 'All'
                        } else {
                          _selectedStatusFilter = status;
                        }
                      });
                      _applyFilter(); // Terapkan filter saat chip dipilih
                    },
                    selectedColor: const Color(
                      0xFF4E342E,
                    ), // Warna chip saat dipilih
                    // Tambahkan backgroundColor untuk chip yang tidak dipilih
                    backgroundColor: Colors
                        .grey[200], // Warna background chip saat tidak dipilih
                    // Opsional: Untuk mengatur border jika tidak dipilih
                    // shape: StadiumBorder(side: BorderSide(color: Colors.grey[400]!)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text('Error: $_error'))
              : _filteredOrders.isEmpty
              ? const Center(
                  child: Text('Tidak ada pesanan yang sesuai filter ini.'),
                )
              : Expanded(
                  child: ListView.builder(
                    itemCount: _filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = _filteredOrders[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          // Tambahkan InkWell untuk tap (misal ke Order Detail)
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    OrderDetailScreen(order: order),
                              ),
                            );
                            print('Order tapped: ${order.id}');
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12, // Disesuaikan sedikit
                              vertical: 12, // Disesuaikan sedikit
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.receipt,
                                  size: 28,
                                ), // Ukuran ikon diperbesar
                                const SizedBox(
                                  width: 12,
                                ), // Jarak ikon diperbesar
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pesanan #${order.id}', // Gunakan Order ID asli
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize:
                                              16, // Ukuran teks diperbesar
                                        ),
                                      ),
                                      Text(
                                        'Pelanggan: ${order.user.name}', // Nama pelanggan
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        'Tanggal: ${order.formattedDate}', // Tanggal pesanan
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      // Tampilkan produk pertama dari detail sebagai contoh
                                      if (order.details.isNotEmpty)
                                        Text(
                                          'Produk: ${order.details[0].product.name} (${order.details[0].quantity}x)',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Chip(
                                      label: Text(
                                        _getReadableStatus(order.paymentStatus),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      backgroundColor: _getStatusColor(
                                        order.paymentStatus,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                    ),
                                    const SizedBox(height: 8), // Jarak
                                    Text(
                                      order.formattedPrice, // Total harga
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors
                                            .green, // Warna untuk total harga
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}

  // Color _getStatusColor(String status) {
  //   switch (status) {
  //     case 'Diproses':
  //       return Colors.orange[100]!;
  //     case 'Dikirim':
  //       return Colors.blue[100]!;
  //     case 'Selesai':
  //       return Colors.green[100]!;
  //     default:
  //       return Colors.grey[100]!;
  //   }
  // }

