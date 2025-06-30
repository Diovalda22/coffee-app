import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';
import '../../services/api_service.dart';
import 'payment_screen.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({Key? key}) : super(key: key);

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final ApiService api = ApiService();
  List<Order> orders = [];
  bool isLoading = true;
  final Map<int, bool> _expandedStates = {};
  final DateFormat dateFormat = DateFormat('dd MMM yyyy, HH:mm');
  final NumberFormat currencyFormat = NumberFormat('#,###');

  // Warna yang digunakan
  final Color primaryColor = const Color(0xFF6F4E37);
  final Color backgroundColor = const Color(0xFFF8F3E5);
  final Color accentColor = const Color(0xFFDAB894);
  final Color darkAccent = const Color(0xFF5A3921);

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => isLoading = true);
    try {
      final response = await api.getOrders();
      setState(() {
        orders = response..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        for (int i = 0; i < orders.length; i++) {
          _expandedStates[i] = false;
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackbar('Gagal memuat pesanan: ${e.toString()}');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Map<String, dynamic> config = {
      'color': Colors.grey.shade100,
      'textColor': Colors.grey.shade800,
      'icon': Icons.help_outline,
      'text': status,
    };

    switch (status.toLowerCase()) {
      case 'pending':
        config = {
          'color': Colors.orange.shade100,
          'textColor': Colors.orange.shade800,
          'icon': Icons.pending,
          'text': 'Menunggu Pembayaran',
        };
        break;
      case 'paid':
        config = {
          'color': Colors.green.shade100,
          'textColor': Colors.green.shade800,
          'icon': Icons.check_circle,
          'text': 'Telah Dibayar',
        };
        break;
      case 'processing':
        config = {
          'color': Colors.blue.shade100,
          'textColor': Colors.blue.shade800,
          'icon': Icons.autorenew,
          'text': 'Sedang Diproses',
        };
        break;
      case 'cancelled':
        config = {
          'color': Colors.red.shade100,
          'textColor': Colors.red.shade800,
          'icon': Icons.cancel,
          'text': 'Dibatalkan',
        };
        break;
    }

    return Chip(
      avatar: Icon(config['icon'], size: 18, color: config['textColor']),
      label: Text(
        config['text'],
        style: TextStyle(
          color: config['textColor'],
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
      backgroundColor: config['color'],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: config['color'].withOpacity(0.3)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.coffee_outlined,
            size: 80,
            color: primaryColor.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'Belum Ada Pesanan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Pesanan Anda akan muncul di sini',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchOrders,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Muat Ulang',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Order order, int index) {
    final isCancelled = order.deletedAt != null;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(
              () => _expandedStates[index] = !_expandedStates[index]!,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pesanan #${order.id}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: darkAccent,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildStatusChip(order.paymentStatus),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(order.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Rp${currencyFormat.format(order.totalPrice)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${order.details.length} item${order.details.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (_expandedStates[index] == true) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    'DETAIL PESANAN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Order items
                  ...order.details.map(
                    (detail) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.coffee,
                                color: primaryColor.withOpacity(0.7),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  detail.product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${detail.quantity} × Rp${currencyFormat.format(detail.price)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Rp${currencyFormat.format(detail.price * detail.quantity)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Order summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Pesanan:'),
                      Text(
                        'Rp${currencyFormat.format(order.totalPrice)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Metode Pembayaran:'),
                      Text(
                        order.paymentMethod ?? '-',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),

                  // Payment button for pending orders
                  if (order.paymentStatus == 'pending' && !isCancelled) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _handlePayment(order),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Bayar Sekarang',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Expand/collapse indicator
          Center(
            child: Icon(
              _expandedStates[index] == true
                  ? Icons.expand_less
                  : Icons.expand_more,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _handlePayment(Order order) async {
    try {
      final redirectUrl = await api.repayOrder(order.id);
      if (redirectUrl != null && mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentScreen(paymentUrl: redirectUrl),
          ),
        );

        if (result == 'paid') {
          _fetchOrders();
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Gagal memproses pembayaran: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Pesanan Saya'),
        backgroundColor: backgroundColor,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchOrders),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _fetchOrders,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) =>
                      _buildOrderItem(orders[index], index),
                ),
              ),
            ),
    );
  }
}
