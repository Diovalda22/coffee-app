import 'package:flutter/material.dart';
import '../../helper/general_helper.dart';

class ProductImage extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;
  final double borderRadius;

  const ProductImage({
    super.key,
    required this.imagePath,
    this.width = 60,
    this.height = 60,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final fullUrl = '$baseImageUrl$imagePath';

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        fullUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey, size: 30),
        ),
      ),
    );
  }
}
