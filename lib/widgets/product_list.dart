// lib/widgets/product_list.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/data/app_data.dart';
import 'package:villabistromobile/providers/product_provider.dart';

class ProductList extends StatelessWidget {
  final Product? selectedProduct;
  final Function(Product) onProductSelected;

  const ProductList({
    super.key,
    required this.selectedProduct,
    required this.onProductSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productProvider = context.watch<ProductProvider>();
    final products = productProvider.products;
    final categories = productProvider.categories;
    final List<dynamic> groupedItems = [];

    for (var category in categories) {
      final productsInCategory = products.where((p) => p.categoryId == category.id).toList();
      if (productsInCategory.isNotEmpty) {
        groupedItems.add(category);
        groupedItems.addAll(productsInCategory);
      }
    }

    if (productProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (groupedItems.isEmpty) {
      return const Center(child: Text('Nenhum produto encontrado.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: groupedItems.length,
      itemBuilder: (ctx, index) {
        final item = groupedItems[index];

        if (item is Category) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              item.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: theme.primaryColor,
              ),
            ),
          );
        }

        if (item is Product) {
          final isSelected = selectedProduct?.id == item.id;
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            elevation: isSelected ? 8 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isSelected
                  ? BorderSide(color: theme.primaryColor, width: 2)
                  : BorderSide.none,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: item.imageUrl != null ? NetworkImage(item.imageUrl!) : null,
                child: item.imageUrl == null ? const Icon(Icons.fastfood, color: Colors.grey) : null,
              ),
              title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('R\$ ${item.price.toStringAsFixed(2)}'),
              onTap: () => onProductSelected(item),
              tileColor: isSelected ? theme.primaryColor.withOpacity(0.1) : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}