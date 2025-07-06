import 'dart:convert';
import 'dart:io';
import 'package:coffee_app/models/order.dart';
import 'package:coffee_app/models/product.dart';
import 'package:coffee_app/models/cart.dart';
import 'package:coffee_app/models/product_category.dart';
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

  // Auth API
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
      final userId = data['id'];

      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setInt('role', role);
        await prefs.setString('email', email);
        await prefs.setString('name', name);
        await prefs.setInt('userId', userId);

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

  // User API
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

  Future<Map<String, List<Product>>> fetchGroupedProducts() async {
    final headers = await _getAuthHeaders();
    final uri = Uri.parse('$baseUrl/user/product/grouped');
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final Map<String, dynamic> data = jsonData['data'];
      final Map<String, List<Product>> result = {};
      data.forEach((key, value) {
        if (value is List) {
          result[key] = value.map((e) => Product.fromJson(e)).toList();
        }
      });
      return result;
    } else {
      throw Exception(
        'Failed to fetch grouped products: ${response.statusCode}',
      );
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
      return jsonData;
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
          'Content-Type': 'application/json',
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
      final List orders = jsonData['data']['data'];

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
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/user/order/repay/$orderId'),
        headers: headers,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return responseData['redirect_url'];
      } else if (response.statusCode == 400) {
        // Handle case where payment is already done
        throw Exception(
          responseData['message'] ?? 'Pembayaran sudah dilakukan',
        );
      } else {
        throw Exception(
          responseData['message'] ??
              'Gagal memulai ulang pembayaran: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Response tidak valid dari server');
      }
      throw Exception('Gagal memulai ulang pembayaran: $e');
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

  Future<Map<String, dynamic>> deleteReview(int reviewId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/user/review/$reviewId'),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Gagal menghapus review',
          'status_code': response.statusCode,
        };
      }
    } catch (e) {
      throw Exception('Error deleting review: $e');
    }
  }

  // Admin API
  Future<Map<String, dynamic>> getAdminStats() async {
    final headers = await _getAuthHeaders();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        _handleErrorResponse(response, 'getAdminStats');
        return {};
      }
    } catch (e) {
      throw Exception('Gagal memuat statistik admin: $e');
    }
  }

  // Admin Products API
  Future<List<Product>> fetchAdminProducts({
    String? name,
    int? categoryId,
  }) async {
    final headers = await _getAuthHeaders();
    final params = <String, String>{};

    if (name != null && name.isNotEmpty) params['name'] = name;
    if (categoryId != null) params['category'] = categoryId.toString();

    final uri = Uri.parse(
      '$baseUrl/admin/product',
    ).replace(queryParameters: params.isNotEmpty ? params : null);

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> productsJson = jsonData['data'];
        return productsJson.map((p) => Product.fromJson(p)).toList();
      } else {
        _handleErrorResponse(response, 'fetchAdminProducts');
        return [];
      }
    } catch (e) {
      throw Exception('Gagal memuat produk admin: $e');
    }
  }

  Future<Product> getProductById(int id) async {
    final headers = await _getAuthHeaders();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/product/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body)['data'];
        return Product.fromJson(jsonData);
      } else {
        _handleErrorResponse(response, 'getProductById');
        throw Exception('Gagal mengambil detail produk.');
      }
    } catch (e) {
      throw Exception('Gagal mengambil detail produk: $e');
    }
  }

  Future<void> createProduct({
    required String name,
    required String description,
    required int price,
    required int stock,
    int? categoryId,
    required File imageFile,
    int? discountAmount, // Diubah dari int ke double
    int? discountType,
    String? discountStart, // Diubah dari DateTime ke String
    String? discountEnd, // Diubah dari DateTime ke String
  }) async {
    final uri = Uri.parse('$baseUrl/admin/product');
    final request = http.MultipartRequest('POST', uri);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      print(
        'DEBUG: Token is null or empty. Cannot proceed with authenticated request.',
      );
      throw Exception('Autentikasi diperlukan. Silakan login kembali.');
    }

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    // Field utama
    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['price'] = price.toString();
    request.fields['stock'] = stock.toString();

    // Field opsional kategori
    if (categoryId != null) {
      request.fields['category_id'] = categoryId.toString();
    }

    // Field diskon
    if (discountAmount != null) {
      request.fields['discount_amount'] = discountAmount.toString();
    }

    if (discountType != null) {
      request.fields['discount_type'] = discountType.toString();
    }

    if (discountStart != null) {
      request.fields['discount_start'] = discountStart;
    }

    if (discountEnd != null) {
      request.fields['discount_end'] = discountEnd;
    }

    // Tambahkan file gambar
    request.files.add(
      await http.MultipartFile.fromPath(
        'image_url',
        imageFile.path,
        filename: imageFile.path.split('/').last,
      ),
    );

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Produk berhasil dibuat: $responseBody');
      } else {
        _handleErrorResponse(
          http.Response(
            responseBody,
            response.statusCode,
            headers: response.headers,
          ),
          'createProduct',
        );
      }
    } catch (e) {
      print('DEBUG: Caught exception in createProduct (ApiService): $e');
      throw Exception('Gagal menambahkan produk: $e');
    }
  }

  Future<void> updateProduct({
    required int id,
    required String name,
    required String description,
    required int price,
    required int stock,
    int? categoryId,
    File? imageFile,
    int? discountAmount,
    int? discountType,
    String? discountStart,
    String? discountEnd,
  }) async {
    final uri = Uri.parse('$baseUrl/admin/product/$id');
    final request = http.MultipartRequest('POST', uri);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('Token tidak valid. Silakan login kembali.');
    }

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    // Required fields
    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['price'] = price.toString();
    request.fields['stock'] = stock.toString();

    // Optional fields
    if (categoryId != null) {
      request.fields['category_id'] = categoryId.toString();
    }

    // Discount fields
    if (discountAmount != null) {
      request.fields['discount_amount'] = discountAmount.toString();
    }

    if (discountType != null) {
      request.fields['discount_type'] = discountType.toString();
    }

    if (discountStart != null && discountStart.isNotEmpty) {
      request.fields['discount_start'] = discountStart;
    }

    if (discountEnd != null && discountEnd.isNotEmpty) {
      request.fields['discount_end'] = discountEnd;
    }

    // Image file
    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'image_url',
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      );
    }

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Produk berhasil diperbarui: $responseBody');
      } else {
        _handleErrorResponse(
          http.Response(
            responseBody,
            response.statusCode,
            headers: response.headers,
          ),
          'updateProduct',
        );
        throw Exception('Gagal memperbarui produk: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating product: $e');
      throw Exception('Gagal memperbarui produk: $e');
    }
  }

  Future<void> deleteProduct(int productId) async {
    final headers = await _getAuthHeaders();
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/product/$productId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        _handleErrorResponse(response, 'deleteProduct');
      }
    } catch (e) {
      throw Exception('Gagal menghapus produk: $e');
    }
  }

  Future<Map<String, dynamic>> setPromoted(int productId) async {
    final headers = await _getAuthHeaders();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/product/promoted/$productId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        _handleErrorResponse(response, 'setPromoted');
        throw Exception('Gagal mengubah status promosi produk.');
      }
    } catch (e) {
      throw Exception('Gagal mengubah status promosi produk: $e');
    }
  }

  // Admin Categories API
  Future<List<ProductCategory>> fetchProductCategories() async {
    final headers = await _getAuthHeaders();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/category'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> categoriesJson = jsonData['data'];
        return categoriesJson.map((c) => ProductCategory.fromJson(c)).toList();
      } else {
        _handleErrorResponse(response, 'fetchProductCategories');
        return [];
      }
    } catch (e) {
      throw Exception('Gagal memuat kategori produk: $e');
    }
  }

  Future<ProductCategory> createProductCategory(String name) async {
    final headers = await _getAuthHeaders();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/category'),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: json.encode({'name': name}),
      );

      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        return ProductCategory.fromJson(jsonData['data']);
      } else {
        _handleErrorResponse(response, 'createProductCategory');
        throw Exception('Gagal membuat kategori.');
      }
    } catch (e) {
      throw Exception('Gagal menambahkan kategori: $e');
    }
  }

  Future<ProductCategory> updateProductCategory(int id, String name) async {
    final headers = await _getAuthHeaders();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/category/$id'),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: json.encode({'name': name}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = json.decode(response.body);
        return ProductCategory.fromJson(jsonData['data']);
      } else {
        _handleErrorResponse(response, 'updateProductCategory');
        throw Exception('Gagal memperbarui kategori.');
      }
    } catch (e) {
      throw Exception('Gagal memperbarui kategori: $e');
    }
  }

  Future<void> deleteProductCategory(int id) async {
    final headers = await _getAuthHeaders();
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/category/$id'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Kategori berhasil dihapus: $id');
      } else {
        _handleErrorResponse(response, 'deleteProductCategory');
        throw Exception('Gagal menghapus kategori.');
      }
    } catch (e) {
      throw Exception('Gagal menghapus kategori: $e');
    }
  }

  Future<List<Order>> fetchOrders() async {
    final headers = await _getAuthHeaders();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/order'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> ordersJson = jsonData['data'];
        return ordersJson.map((o) => Order.fromJson(o)).toList();
      } else {
        _handleErrorResponse(response, 'fetchOrders');
        return [];
      }
    } catch (e) {
      throw Exception('Gagal memuat daftar pesanan: $e');
    }
  }

  Future<List<Order>> fetchLatestOrders() async {
    final headers = await _getAuthHeaders();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/latestOrder'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> ordersJson = jsonData['data'];
        return ordersJson.map((o) => Order.fromJson(o)).toList();
      } else {
        _handleErrorResponse(response, 'fetchLatestOrders');
        return [];
      }
    } catch (e) {
      throw Exception('Gagal memuat pesanan terbaru: $e');
    }
  }

  void _handleErrorResponse(http.Response response, String endpoint) {
    String message = 'Terjadi kesalahan pada $endpoint: ${response.statusCode}';
    try {
      final body = json.decode(response.body);
      if (body is Map && body.containsKey('message')) {
        message = body['message'];
      } else if (body is Map && body.containsKey('error')) {
        message = body['error'];
      } else if (body is String && body.isNotEmpty) {
        message = body;
      }
    } catch (e) {}

    if (response.statusCode == 401) {
      throw Exception('Sesi berakhir atau tidak terautentikasi: $message');
    }
    throw Exception(message);
  }
}
