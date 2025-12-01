// lib/screens/management/product_detail_screen.dart
import 'package:flutter/material.dart';
import '../../../data/models/app_data.dart' as app_data;
import '../../widgets/product_details.dart'; // Import com o novo nome

class ProductDetailScreen extends StatelessWidget {
  final app_data.Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return ProductDetails(product: product); // Usa o novo widget 'ProductDetails'
  }
}
