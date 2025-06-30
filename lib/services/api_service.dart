import 'dart:convert';
import 'package:coffee_app/models/order.dart';
import 'package:coffee_app/models/product.dart';
import 'package:coffee_app/models/cart.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../helper/general_helper.dart';

class ApiService {
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Accept': 'application/json'},
      body: {'email': email, 'password': password},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body)['data'];
      final token = data['token'];
      final role = data['role'];
      final email = data['email'];
      final name = data['name'];

      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setInt('role', role);
        await prefs.setString('email', email);
        await prefs.setString('name', name);

        return true;
      }
    }
    return false;
  }

  Future<bool> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      },
    );

    return response.statusCode == 200;
  }

  Future<bool> logout() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: headers,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      return response.statusCode == 200;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      return false;
    }
  }

  // Home API
  Future<List<Product>> fetchProducts({String? name, int? categoryId}) async {
    final headers = await _getAuthHeaders();
    final params = <String, dynamic>{};

    if (name != null) params['name'] = name;
    if (categoryId != null) params['category'] = categoryId;

    final uri = Uri.parse(
      '$baseUrl/user/product',
    ).replace(queryParameters: params);

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List products = jsonData['data'];
        return products.map((p) => Product.fromJson(p)).toList();
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<Product>> fetchPromotedProducts() async {
    final headers = await _getAuthHeaders();

    final uri = Uri.parse(
      '$baseUrl/user/product',
    ).replace(queryParameters: {'promoted': '1'});

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['data'] is List) {
          return (jsonData['data'] as List)
              .map((p) => Product.fromJson(p))
              .toList();
        } else {
          throw Exception('Format data tidak valid');
        }
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> fetchProductDetail(int productId) async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/user/product/$productId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return jsonData; // ini berisi key: status, data
    } else {
      throw Exception('Gagal memuat detail produk: ${response.statusCode}');
    }
  }

  Future<List<Cart>> fetchCart() async {
    final headers = await _getAuthHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/user/cart'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List cartData = json.decode(response.body)['cart'];
      return cartData.map((c) => Cart.fromJson(c)).toList();
    } else {
      throw Exception('Failed to load cart: ${response.statusCode}');
    }
  }

  Future<void> addToCart(int productId, int quantity) async {
    final headers = await _getAuthHeaders();

    final response = await http.post(
      Uri.parse('$baseUrl/user/cart/add'),
      headers: headers,
      body: jsonEncode({'product_id': productId, 'quantity': quantity}),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      final message = body['message'] ?? 'Unknown error';
      throw Exception('Gagal menambahkan ke keranjang: $message');
    }
  }

  Future<bool> removeCart(int cartId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/user/cart/remove/$cartId'),
      headers: await _getAuthHeaders(),
    );
    return response.statusCode == 200;
  }

  Future<bool> removeMultipleCartItems(List<int> cartIds) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/user/cart/delete-multiple'),
        body: json.encode({'ids': cartIds}),
        headers: {
          ...await _getAuthHeaders(),
          'Content-Type': 'application/json', // Tambahkan content type
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to delete multiple cart items: $e');
    }
  }

  Future<bool> clearCart() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/user/cart/clear'),
      headers: await _getAuthHeaders(),
    );
    return response.statusCode == 200;
  }

  Future<bool> updateCartQuantity(int cartId, int quantity) async {
    final headers = await _getAuthHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/user/cart/update/$cartId'),
      headers: headers,
      body: json.encode({'quantity': quantity}),
    );

    return response.statusCode == 200;
  }

  Future<List<Order>> getOrders() async {
    final headers = await _getAuthHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/user/order'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List orders = jsonData['data']['data']; // karena paginated

      return orders.map((e) => Order.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch orders: ${response.statusCode}');
    }
  }

  Future<String?> createOrder() async {
    final headers = await _getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/user/order'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return jsonData['redirect_url'];
    } else {
      throw Exception('Failed to create order: ${response.statusCode}');
    }
  }

  Future<String?> repayOrder(int orderId) async {
    final headers = await _getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/user/order/repay/$orderId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return jsonData['redirect_url'];
    } else {
      throw Exception('Gagal memulai ulang pembayaran: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> submitReview({
    required int productId,
    required int rating,
    required String review,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/user/review'),
        headers: headers,
        body: json.encode({
          'product_id': productId,
          'rating': rating,
          'review': review,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to submit review: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error submitting review: $e');
    }
  }

  Future<Map<String, dynamic>> updateReview({
    required int reviewId,
    required int rating,
    required String review,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/user/review/$reviewId'),
        headers: headers,
        body: json.encode({'rating': rating, 'review': review}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to update review');
      }
    } catch (e) {
      throw Exception('Error updating review: $e');
    }
  }

  Future<void> deleteReview(int reviewId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/user/review/$reviewId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete review');
      }
    } catch (e) {
      throw Exception('Error deleting review: $e');
    }
  }
}
