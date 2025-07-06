import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';
import 'package:coffee_app/widgets/product_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  final VoidCallback? onReviewSubmitted;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.onReviewSubmitted,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final api = ApiService();
  bool isLoading = true;
  Map<String, dynamic>? product;
  int _quantity = 1;
  final _scrollController = ScrollController();
  bool _showReviewForm = false;
  bool _isEditingReview = false;
  int _selectedRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  int? _currentUserId;
  Map<String, dynamic>? _userReview;

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
    fetchProductDetail();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    print('DEBUG: Retrieved user ID from SharedPreferences: $userId');
    setState(() {
      _currentUserId = userId;
    });
  }

  Future<void> fetchProductDetail() async {
    try {
      print(
        'DEBUG: Fetching product detail for product ID: ${widget.productId}',
      );
      final result = await api.fetchProductDetail(widget.productId);
      print('DEBUG: Product detail response received');
      setState(() {
        product = result['data'];
        isLoading = false;
      });
      print('DEBUG: Calling _findUserReview after data update');
      _findUserReview();
    } catch (e) {
      print('DEBUG: Error fetching product detail: $e');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat detail produk: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _findUserReview() {
    if (product != null &&
        _currentUserId != null &&
        product!['reviews'] != null) {
      final reviews = product!['reviews'] as List;
      print('DEBUG: Current user id: $_currentUserId');
      print('DEBUG: Reviews count: ${reviews.length}');

      try {
        _userReview = reviews.cast<Map<String, dynamic>>().firstWhere((review) {
          final reviewUserId = review['user_id'];
          print(
            'DEBUG: Review user_id: $reviewUserId, Current user_id: $_currentUserId',
          );
          return reviewUserId == _currentUserId;
        });
        print('DEBUG: User review found: $_userReview');
      } catch (e) {
        _userReview = null;
        print('DEBUG: User review not found - $e');
      }
    } else {
      print(
        'DEBUG: Cannot find user review - product: ${product != null}, currentUserId: $_currentUserId, reviews: ${product?['reviews'] != null}',
      );
    }
  }

  void _incrementQuantity() {
    setState(() => _quantity++);
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  void _toggleReviewForm() {
    setState(() {
      _showReviewForm = !_showReviewForm;
      _isEditingReview = false;
      if (_showReviewForm) {
        _selectedRating = 0;
        _reviewController.clear();
      }
    });
  }

  void _editReview() {
    if (_userReview != null) {
      setState(() {
        _showReviewForm = true;
        _isEditingReview = true;
        _selectedRating = _userReview!['rating'];
        _reviewController.text = _userReview!['review'];
      });
    }
  }

  Future<void> _deleteReview() async {
    if (_userReview == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Ulasan'),
        content: const Text('Apakah Anda yakin ingin menghapus ulasan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await api.deleteReview(_userReview!['id']);

        if (response['success'] == true) {
          await fetchProductDetail();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Ulasan berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );

          // Notify parent screen to reload
          if (mounted && widget.onReviewSubmitted != null) {
            widget.onReviewSubmitted!();
          }
        } else {
          throw Exception(response['message'] ?? 'Gagal menghapus ulasan');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap beri rating terlebih dahulu'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      Map<String, dynamic> response;

      if (_isEditingReview && _userReview != null) {
        // Update existing review
        print('DEBUG: Updating existing review with ID: ${_userReview!['id']}');
        response = await api.updateReview(
          reviewId: _userReview!['id'],
          rating: _selectedRating,
          review: _reviewController.text,
        );
      } else {
        // Submit new review
        print('DEBUG: Submitting new review for product: ${widget.productId}');
        response = await api.submitReview(
          productId: widget.productId,
          rating: _selectedRating,
          review: _reviewController.text,
        );
      }

      print('DEBUG: Review response: $response');

      if (response['success'] == true) {
        print('DEBUG: Review submitted successfully, refreshing data...');
        await fetchProductDetail();
        setState(() {
          _showReviewForm = false;
          _isEditingReview = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Ulasan berhasil disimpan'),
            backgroundColor: Colors.green,
          ),
        );

        // Notify parent screen to reload
        if (mounted && widget.onReviewSubmitted != null) {
          widget.onReviewSubmitted!();
        }
      } else {
        throw Exception(response['message'] ?? 'Gagal menyimpan ulasan');
      }
    } catch (e) {
      print('DEBUG: Error submitting review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildReviewActionButton() {
    if (_userReview != null) {
      // User has already reviewed - show edit and delete buttons
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton.icon(
            onPressed: _editReview,
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _deleteReview,
            icon: const Icon(Icons.delete, size: 16),
            label: const Text('Hapus'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      );
    } else {
      // User hasn't reviewed yet - show add review button
      return TextButton(
        onPressed: _toggleReviewForm,
        child: Text(
          _showReviewForm ? 'Batal' : 'Tambah Ulasan',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
      );
    }

    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Produk tidak ditemukan')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(product!['name']),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'product-image-${product!['id']}',
                  child: ProductImage(
                    imagePath: product!['image_url'],
                    height: 300,
                    width: double.infinity,
                    borderRadius: 0,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product!['category'] != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Chip(
                            label: Text(
                              product!['category'],
                              style: TextStyle(
                                color: colorScheme.onSecondaryContainer,
                              ),
                            ),
                            backgroundColor: colorScheme.secondaryContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      Text(
                        product!['name'],
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Price display with discount
                      if (product!['final_price'] != null &&
                          product!['final_price'] < product!['price'])
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Rp ${NumberFormat('#,###', 'id_ID').format(product!['final_price'])}',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'DISKON',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rp ${NumberFormat('#,###', 'id_ID').format(product!['price'])}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            if (product!['discount_start'] != null &&
                                product!['discount_end'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 12,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Diskon berlaku: ${DateFormat('dd MMM yyyy').format(DateTime.parse(product!['discount_start']))} - ${DateFormat('dd MMM yyyy').format(DateTime.parse(product!['discount_end']))}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: Colors.grey[600],
                                            fontSize: 11,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        )
                      else
                        Text(
                          'Rp ${NumberFormat('#,###', 'id_ID').format(product!['price'])}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        'Deskripsi',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product!['description'],
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),

                      // Review Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ulasan Produk',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _buildReviewActionButton(),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Review Form
                      if (_showReviewForm)
                        Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Berikan Rating',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: List.generate(5, (index) {
                                    return IconButton(
                                      icon: Icon(
                                        index < _selectedRating
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                        size: 32,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _selectedRating = index + 1;
                                        });
                                      },
                                    );
                                  }),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Tulis Ulasan',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _reviewController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Bagaimana pengalaman Anda dengan produk ini?',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _submitReview,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Kirim Ulasan'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      if (product!['reviews'].isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Belum ada ulasan untuk produk ini.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...List.generate(product!['reviews'].length, (index) {
                          final review = product!['reviews'][index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor:
                                            colorScheme.primaryContainer,
                                        child: Text(
                                          review['user'][0].toUpperCase(),
                                          style: TextStyle(
                                            color:
                                                colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          review['user'],
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                      Row(
                                        children: List.generate(5, (i) {
                                          return Icon(
                                            i < review['rating']
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: Colors.amber,
                                            size: 16,
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    review['review'],
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(
                                      DateTime.parse(review['created_at']),
                                    ),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _decrementQuantity,
                          splashRadius: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            _quantity.toString(),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _incrementQuantity,
                          splashRadius: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await api.addToCart(widget.productId, _quantity);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Produk berhasil ditambahkan ke keranjang',
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Tambah ke Keranjang'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
