// lib/models/dashboard_stats.dart
class DashboardStats {
  final int totalProducts;
  final int totalCategories;
  final int todayOrders;
  final dynamic monthlyIncome; // Tetap String karena format Rupiah dari API

  DashboardStats({
    required this.totalProducts,
    required this.totalCategories,
    required this.todayOrders,
    required this.monthlyIncome,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalProducts: json['total_products'] as int,
      totalCategories: json['total_categories'] as int,
      todayOrders: json['today_orders'] as int,
      monthlyIncome: json['monthly_income'], // Can be int or double
    );
  }
}
