import 'package:flutter/material.dart';
import 'package:coffee_app/models/order.dart';
import 'package:coffee_app/services/api_service.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<Order>> _latestOrdersFuture;
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _latestOrdersFuture = _fetchLatestOrders();
  }

  Future<List<Order>> _fetchLatestOrders() async {
    try {
      final latestOrders = await apiService.fetchLatestOrders();
      return latestOrders;
    } catch (e) {
      print('Error fetching latest orders: $e');
      throw Exception('Gagal memuat pesanan terbaru: $e');
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
        return 'Tertunda';
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Ringkasan',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(context),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Pesanan Terbaru (5 Terakhir)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          _buildRecentOrders(context),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryRow(
              'Total Produk',
              '125',
              Icons.shopping_bag,
              Colors.blue,
            ),
            const Divider(height: 24),
            _buildSummaryRow(
              'Total Kategori',
              '8',
              Icons.category,
              Colors.green,
            ),
            const Divider(height: 24),
            _buildSummaryRow(
              'Pesanan Hari Ini',
              '24',
              Icons.receipt,
              Colors.orange,
            ),
            const Divider(height: 24),
            _buildSummaryRow(
              'Pendapatan',
              'Rp5.250.000',
              Icons.attach_money,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
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

  Widget _buildRecentOrders(BuildContext context) {
    return FutureBuilder<List<Order>>(
      future: _latestOrdersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        } else if (snapshot.hasError) {
          return Card(
            color: Colors.red[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
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
                        _latestOrdersFuture = _fetchLatestOrders();
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
          final latestOrders = snapshot.data!;
          if (latestOrders.isEmpty) {
            return const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text('Belum ada pesanan terbaru.')),
              ),
            );
          } else {
            return Card(
              child: SingleChildScrollView(
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
                        label: Text(
                          'ID',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
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
                    rows: latestOrders.map((order) {
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
                            SizedBox(
                              width: 100,
                              child: Text(order.formattedPrice),
                            ),
                          ),
                          DataCell(
                            Chip(
                              label: Text(
                                _getReadableStatus(order.paymentStatus),
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: _getStatusColor(
                                order.paymentStatus,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            );
          }
        } else {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('Tidak ada data pesanan terbaru.')),
            ),
          );
        }
      },
    );
  }
}
