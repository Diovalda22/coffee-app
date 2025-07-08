import 'package:flutter/material.dart';
import 'package:coffee_app/services/api_service.dart';
import 'dashboard_screen.dart';
import 'product_screen.dart';
import 'category_screen.dart';
import 'order_screen.dart';
import 'package:another_flushbar/flushbar.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;
  final ApiService _apiService = ApiService();

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ProductManagementScreen(),
    const CategoryManagementScreen(),
    const OrderManagementScreen(),
  ];

  Future<void> _handleLogout(BuildContext context) async {
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _apiService.logout();
        if (success) {
          Flushbar(
            message: 'Logout berhasil',
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
          ).show(context);
          // Navigate to login screen and remove all previous routes
          navigator.pushNamedAndRemoveUntil(
            '/login',
            (Route<dynamic> route) => false,
          );
        } else {
          Flushbar(
            message: 'Logout gagal, silahkan coba lagi',
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ).show(context);
        }
      } catch (e) {
        Flushbar(
          message: 'Error: ${e.toString()}',
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.orange,
        ).show(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: SafeArea(child: _screens[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Produk',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Kategori',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Pesanan'),
        ],
      ),
    );
  }
}
