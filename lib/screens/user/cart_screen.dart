import 'package:coffee_app/screens/user/payment_screen.dart';
import 'package:coffee_app/widgets/product_image.dart';
import 'package:flutter/material.dart';
import '../../models/cart.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final api = ApiService();
  List<Cart> carts = [];
  bool isLoading = true;
  bool isOrdering = false;
  Set<int> selectedItems = {};

  @override
  void initState() {
    super.initState();
    loadCart();
  }

  Future<void> loadCart() async {
    try {
      final data = await api.fetchCart();
      setState(() {
        carts = data;
        isLoading = false;
        selectedItems.clear(); 
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat keranjang: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> updateQuantity(int cartId, int newQty) async {
    final success = await api.updateCartQuantity(cartId, newQty);
    if (success) {
      loadCart();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memperbarui jumlah'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> removeCartItem(int cartId) async {
    final success = await api.removeCart(cartId);
    if (success) {
      loadCart();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menghapus item'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> removeSelectedItems() async {
    if (selectedItems.isEmpty) return;

    final confirmed = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text(
          'Yakin ingin menghapus ${selectedItems.length} item terpilih?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => isLoading = true);

        final itemsToDelete = selectedItems.toList();
        print('Items yang akan dihapus: $itemsToDelete'); 

        final success = await api.removeMultipleCartItems(itemsToDelete);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${itemsToDelete.length} item berhasil dihapus'),
              backgroundColor: Colors.redAccent,
            ),
          );
          await loadCart();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus item: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        print('Error saat menghapus: $e'); 
      } finally {
        setState(() {
          isLoading = false;
          selectedItems.clear();
        });
      }
    }
  }

  Future<void> clearCart() async {
    final confirmed = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Yakin ingin mengosongkan keranjang?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await api.clearCart();
      if (success) {
        loadCart();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengosongkan keranjang'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> createOrder() async {
    setState(() => isOrdering = true);
    try {
      final redirectUrl = await api.createOrder();
      if (redirectUrl != null && mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentScreen(paymentUrl: redirectUrl),
          ),
        );

        if (result == 'paid') {
          isLoading = true;
          loadCart();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isOrdering = false);
    }
  }

  void confirmOrder() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi Order"),
        content: const Text("Yakin ingin memesan semua item di keranjang?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              createOrder();
            },
            child: const Text("Order Sekarang"),
          ),
        ],
      ),
    );
  }

  Widget buildCartItem(Cart cart) {
    final isSelected = selectedItems.contains(cart.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      color: isSelected ? Colors.brown[50] : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            if (isSelected) {
              selectedItems.remove(cart.id);
            } else {
              selectedItems.add(cart.id);
            }
          });
        },
        onLongPress: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Aksi"),
              content: const Text("Apa yang ingin Anda lakukan?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    removeCartItem(cart.id);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Hapus"),
                ),
              ],
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (isSelected)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.check_circle, color: Colors.brown),
                ),
              ProductImage(imagePath: cart.product.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cart.product.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${NumberFormat('#,###', 'id_ID').format(cart.product.price)}',
                      style: const TextStyle(color: Colors.brown),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 20),
                        onPressed: cart.quantity > 1
                            ? () => updateQuantity(cart.id, cart.quantity - 1)
                            : null,
                      ),
                      Text(
                        '${cart.quantity}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        onPressed: () =>
                            updateQuantity(cart.id, cart.quantity + 1),
                      ),
                    ],
                  ),
                  Text(
                    'Total: Rp ${NumberFormat('#,###', 'id_ID').format(cart.product.price * cart.quantity)}',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  int get totalItems {
    return carts.fold(0, (sum, cart) => sum + cart.quantity);
  }

  double get totalPrice {
    return carts.fold(
      0,
      (sum, cart) => sum + (cart.product.price * cart.quantity),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3E5),
      appBar: AppBar(
        title: const Text('Keranjang'),
        backgroundColor: const Color(0xFFF8F3E5),
        foregroundColor: Colors.brown[900],
        actions: [
          if (carts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: clearCart,
              tooltip: 'Clear Cart',
            ),
        ],
      ),
      body: Column(
        children: [
          if (selectedItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.brown[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${selectedItems.length} item terpilih',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: removeSelectedItems,
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'Hapus',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : carts.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.remove_shopping_cart,
                            size: 100,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Keranjang kamu kosong!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Yuk temukan kopi favoritmu dan mulai belanja sekarang!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/home');
                            },
                            icon: const Icon(Icons.storefront_outlined),
                            label: const Text('Cari Produk'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown[600],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: loadCart,
                    child: ListView.builder(
                      itemCount: carts.length,
                      itemBuilder: (context, index) =>
                          buildCartItem(carts[index]),
                    ),
                  ),
          ),
          if (carts.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Items: $totalItems',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Total Harga: Rp ${NumberFormat('#,###', 'id_ID').format(totalPrice)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isOrdering ? null : confirmOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown[800],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: isOrdering
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.shopping_bag_outlined, size: 20),
                      label: const Text(
                        'Order Now',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
