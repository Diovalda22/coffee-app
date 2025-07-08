import 'dart:async';
import 'package:coffee_app/screens/user/cart_screen.dart';
import 'package:coffee_app/screens/user/order_screen.dart';
import 'package:coffee_app/screens/user/product_detail_screen.dart';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/product.dart';
import '../../models/product_category.dart';
import '../../helper/general_helper.dart';
import 'package:intl/intl.dart';
import 'package:coffee_app/screens/user/edit_profile_screen.dart';
import 'package:another_flushbar/flushbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final api = ApiService();
  bool isLoading = true;
  List<Product> promotedProducts = [];
  List<Product> allProducts = [];
  List<Product> filteredProducts = [];
  Map<String, List<Product>> groupedProducts = {};
  TextEditingController searchController = TextEditingController();

  int _selectedIndex = 0;

  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;
  late Timer _bannerTimer;

  final List<String> banners = [
    'assets/images/banner1.jpg',
    'assets/images/banner2.jpg',
    'assets/images/banner3.jpg',
  ];

  @override
  void initState() {
    super.initState();
    loadProducts();
    _initBannerSlider();
  }

  void _initBannerSlider() {
    _pageController.addListener(() {
      int newPage = _pageController.page?.round() ?? 0;
      if (newPage != _currentPage) {
        setState(() {
          _currentPage = newPage;
        });
      }
    });

    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_pageController.hasClients && mounted) {
        int nextPage = (_currentPage + 1) % banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bannerTimer.cancel();
    super.dispose();
  }

  Future<void> loadProducts() async {
    setState(() => isLoading = true);
    try {
      final fetchedPromoted = await api.fetchPromotedProducts();
      final grouped = await api.fetchGroupedProducts();
      setState(() {
        promotedProducts = fetchedPromoted;
        groupedProducts = grouped;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      Flushbar(
        message: 'Gagal memuat produk: $e',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        flushbarPosition: FlushbarPosition.TOP,
        borderRadius: BorderRadius.circular(8),
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(15),
      ).show(context);
    }
  }

  void filterProducts(String query) {
    setState(() {
      filteredProducts = allProducts.where((product) {
        final nameLower = product.name.toLowerCase();
        final queryLower = query.toLowerCase();
        return nameLower.contains(queryLower);
      }).toList();
    });
  }

  void _onItemTapped(int index) {
    if (index == 4) {
      _showLogoutConfirmation();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _performLogout() async {
    try {
      await api.logout();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      Flushbar(
        message: 'Error saat logout: $e',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        flushbarPosition: FlushbarPosition.TOP,
        borderRadius: BorderRadius.circular(8),
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(15),
      ).show(context);
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCarousel() {
    return SizedBox(
      height: 150,
      child: PageView.builder(
        controller: _pageController,
        itemCount: banners.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: AssetImage(banners[index]),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final isOutOfStock = product.stock <= 0;

    return SizedBox(
      width: 160,
      height: 240, // Height menyesuaikan isi (tanpa tombol)
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isOutOfStock
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(
                        productId: product.id,
                        onReviewSubmitted: () {
                          // Reload products when review is submitted
                          loadProducts();
                        },
                      ),
                    ),
                  );
                },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image with Overlay
                Stack(
                  children: [
                    Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product.imageUrl.startsWith('http')
                              ? product.imageUrl
                              : '$baseImageUrl${product.imageUrl}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 30),
                        ),
                      ),
                    ),
                    if (product.isPromoted == 1)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade700,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Best Seller',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    // <<<<< Diperbaiki: penulisan `if` setelah Container ditutup
                    if (isOutOfStock)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'STOK HABIS',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // Product Name
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Stock Information
                Text(
                  'Stok: ${product.stock}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isOutOfStock ? Colors.red : Colors.grey[600],
                    fontWeight: isOutOfStock
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),

                const SizedBox(height: 4),

                // Rating and Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Rating
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          product.averageRating?.toStringAsFixed(1) ?? '0.0',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),

                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (product.isDiscountActive)
                          Text(
                            'Rp${NumberFormat("#,###").format(product.price)}',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              fontSize: 10,
                            ),
                          ),
                        Text(
                          'Rp${NumberFormat("#,###").format(product.finalPrice ?? product.price)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: product.isDiscountActive
                                ? Colors.red[700]
                                : const Color(0xFF5D4037),
                          ),
                        ),
                        if (product.discountStart != null &&
                            product.discountEnd != null)
                          Text(
                            product.isDiscountExpired
                                ? 'Diskon expired'
                                : '${DateFormat('dd MMM').format(DateTime.parse(product.discountStart!))} - ${DateFormat('dd MMM').format(DateTime.parse(product.discountEnd!))}',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Product> products) {
    if (products.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4E342E),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 240, // Sesuaikan dengan tinggi kartu
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _buildProductCard(products[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHomeContent() {
    final isSearching = searchController.text.isNotEmpty;
    // Untuk pencarian, flatten semua produk dari grouped
    final allGroupedProducts = groupedProducts.values.expand((x) => x).toList();
    final filtered = isSearching
        ? allGroupedProducts
              .where(
                (product) => product.name.toLowerCase().contains(
                  searchController.text.toLowerCase(),
                ),
              )
              .toList()
        : null;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildBannerCarousel(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Cari produk kopi...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF8D6E63),
                      ),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverList(
              delegate: SliverChildListDelegate([
                if (isSearching)
                  filtered == null || filtered.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tidak ada produk yang ditemukan',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Coba kata kunci lain',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : _buildSection('Hasil Pencarian', filtered)
                else
                  Column(
                    children: [
                      _buildSection('Produk Unggulan', promotedProducts),
                      if ((groupedProducts['Minuman'] ?? []).isNotEmpty)
                        _buildSection('Minuman', groupedProducts['Minuman']!),
                      if ((groupedProducts['Makanan Utama'] ?? []).isNotEmpty)
                        _buildSection(
                          'Makanan Utama',
                          groupedProducts['Makanan Utama']!,
                        ),
                      if ((groupedProducts['Roti'] ?? []).isNotEmpty)
                        _buildSection('Roti', groupedProducts['Roti']!),
                      if ((groupedProducts['Makanan Ringan'] ?? []).isNotEmpty)
                        _buildSection(
                          'Makanan Ringan',
                          groupedProducts['Makanan Ringan']!,
                        ),
                    ],
                  ),
                const SizedBox(height: 16),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return RefreshIndicator(
          onRefresh: loadProducts,
          child: _buildHomeContent(),
        );
      case 1:
        return const CartScreen();
      case 2:
        return const OrderScreen();
      case 3:
        return const EditProfileScreen();
      default:
        return const Center(child: Text('Unknown'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3E5),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Pygmy Owl Coffee',
          style: TextStyle(
            fontFamily: 'Pacifico',
            fontSize: 24,
            color: Color(0xFF3E2723),
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFF3E0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF3E2723)),
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF4E342E),
        unselectedItemColor: Colors.brown[300],
        backgroundColor: const Color(0xFFFFF3E0),
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        elevation: 4,
        items: [
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: _selectedIndex == 0
                  ? BoxDecoration(
                      color: const Color(0xFF4E342E),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: Icon(
                Icons.local_cafe_outlined,
                color: _selectedIndex == 0 ? Colors.white : Colors.brown[300],
              ),
            ),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: _selectedIndex == 1
                  ? BoxDecoration(
                      color: const Color(0xFF4E342E),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: Icon(
                Icons.shopping_cart_outlined,
                color: _selectedIndex == 1 ? Colors.white : Colors.brown[300],
              ),
            ),
            label: 'Keranjang',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: _selectedIndex == 2
                  ? BoxDecoration(
                      color: const Color(0xFF4E342E),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: Icon(
                Icons.receipt_long_outlined,
                color: _selectedIndex == 2 ? Colors.white : Colors.brown[300],
              ),
            ),
            label: 'Pesanan',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: _selectedIndex == 3
                  ? BoxDecoration(
                      color: const Color(0xFF4E342E),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: Icon(
                Icons.person_outline,
                color: _selectedIndex == 3 ? Colors.white : Colors.brown[300],
              ),
            ),
            label: 'Profil',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: _selectedIndex == 4
                  ? BoxDecoration(
                      color: const Color(0xFF4E342E),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: Icon(
                Icons.logout,
                color: _selectedIndex == 4 ? Colors.white : Colors.brown[300],
              ),
            ),
            label: 'Keluar',
          ),
        ],
      ),
    );
  }
}
