import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
              'Pesanan Terbaru',
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
    final orders = [
      {
        'id': '#ORD-001',
        'customer': 'John Doe',
        'date': '24 Jun',
        'amount': 'Rp1.250.000',
        'status': 'Diproses',
      },
      {
        'id': '#ORD-002',
        'customer': 'Jane Smith',
        'date': '23 Jun',
        'amount': 'Rp750.000',
        'status': 'Dikirim',
      },
      {
        'id': '#ORD-003',
        'customer': 'Robert Johnson',
        'date': '22 Jun',
        'amount': 'Rp2.100.000',
        'status': 'Selesai',
      },
    ];

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
            rows: orders.map((order) {
              return DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 80,
                      child: Text(
                        order['id']!,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 120,
                      child: Text(
                        order['customer']!,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(SizedBox(width: 60, child: Text(order['date']!))),
                  DataCell(SizedBox(width: 100, child: Text(order['amount']!))),
                  DataCell(
                    Chip(
                      label: Text(
                        order['status']!,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: _getStatusColor(order['status']!),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Diproses':
        return Colors.orange[100]!;
      case 'Dikirim':
        return Colors.blue[100]!;
      case 'Selesai':
        return Colors.green[100]!;
      default:
        return Colors.grey[100]!;
    }
  }
}
