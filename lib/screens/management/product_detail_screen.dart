// lib/screens/management/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:villabistromobile/data/app_data.dart';
import 'package:villabistromobile/widgets/product_details.dart'; // Import com o novo nome

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return ProductDetails(product: product); // Usa o novo widget 'ProductDetails'
  }
}
