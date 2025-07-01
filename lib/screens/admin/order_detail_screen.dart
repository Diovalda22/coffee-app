// lib/screens/order/order_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart'; // Sesuaikan path jika Order model Anda ada di tempat lain

class OrderDetailScreen extends StatelessWidget {
  final Order order; // Objek Order yang akan ditampilkan detailnya

  const OrderDetailScreen({super.key, required this.order});

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

  String formatRupiah(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    // Definisi warna yang konsisten dengan desain Anda sebelumnya
    const Color cardBackgroundColor = Colors.white;
    const Color cardShadowColor = Colors.black26;
    const double cardElevation = 6.0;
    const Color titleWrapperColor = Color(
      0xFF4E342E,
    ); // Warna header yang Anda gunakan

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detail Pesanan #${order.id}',
          style: const TextStyle(color: Colors.white), // Warna teks AppBar
        ),
        backgroundColor:
            titleWrapperColor, // Warna AppBar konsisten dengan header card
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // Warna ikon back button
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ringkasan Pesanan (Mirip dengan Card di Dashboard)
            Card(
              color: cardBackgroundColor,
              elevation: cardElevation,
              shadowColor: cardShadowColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Pesanan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: titleWrapperColor,
                      ),
                    ),
                    const Divider(height: 20),
                    _buildDetailRow('ID Pesanan:', '#${order.id}'),
                    _buildDetailRow(
                      'Status Pembayaran:',
                      _getReadableStatus(order.paymentStatus),
                      chipColor: _getStatusColor(order.paymentStatus),
                    ),
                    _buildDetailRow('Tanggal Pesanan:', order.formattedDate),
                    _buildDetailRow('Total Harga:', order.formattedPrice),
                    if (order.totalQuantity != null)
                      _buildDetailRow(
                        'Jumlah Item:',
                        order.totalQuantity.toString(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Informasi Pelanggan
            Card(
              color: cardBackgroundColor,
              elevation: cardElevation,
              shadowColor: cardShadowColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Pelanggan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: titleWrapperColor,
                      ),
                    ),
                    const Divider(height: 20),
                    _buildDetailRow(
                      'Nama Pelanggan:',
                      order.user?.name ?? 'Tidak Diketahui',
                    ),
                    _buildDetailRow(
                      'Email Pelanggan:',
                      order.user?.email ?? 'Tidak Tersedia',
                    ),

                    // Tambahkan detail user lainnya jika ada (misal alamat, nomor telepon)
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Detail Produk dalam Pesanan
            Card(
              color: cardBackgroundColor,
              elevation: cardElevation,
              shadowColor: cardShadowColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detail Produk',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: titleWrapperColor,
                      ),
                    ),
                    const Divider(height: 20),
                    if (order.details.isEmpty)
                      const Text('Tidak ada detail produk untuk pesanan ini.')
                    else
                      ...order.details.map((detail) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Anda bisa menambahkan Image.network jika product.image_url adalah URL lengkap
                              // atau Placeholder jika tidak ada gambar
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child:
                                    detail.product.imageUrl != null &&
                                        detail.product.imageUrl!.isNotEmpty
                                    ? Image.network(
                                        'https://example.com/storage/${detail.product.imageUrl}', // Ganti dengan BASE_URL gambar Anda
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(Icons.broken_image),
                                      )
                                    : const Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey,
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
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '${detail.quantity} x ${formatRupiah(detail.product.price.toDouble())}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      'Total: ${formatRupiah(detail.price.toDouble())}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? chipColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
          if (chipColor != null)
            Chip(
              label: Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ), // Teks chip hitam
              ),
              backgroundColor: chipColor,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            )
          else
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}
