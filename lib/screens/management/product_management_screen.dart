import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/data/app_data.dart';
import 'package:villabistromobile/providers/navigation_provider.dart';
import 'package:villabistromobile/providers/product_provider.dart';
import 'package:villabistromobile/screens/management/product_edit_screen.dart';
import 'package:villabistromobile/widgets/custom_app_bar.dart';

class ProductManagementScreen extends StatelessWidget {
  const ProductManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Gerenciar Produtos',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar Produto',
            onPressed: () {
              navProvider.navigateTo(context, const ProductEditScreen(), 'Novo Produto');
            },
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          if (productProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final categories = productProvider.categories;
          final products = productProvider.products;
          final List<dynamic> groupedItems = [];

          for (var category in categories) {
            final productsInCategory =
                products.where((p) => p.categoryId == category.id).toList();
            if (productsInCategory.isNotEmpty) {
              groupedItems.add(category);
              groupedItems.addAll(productsInCategory);
            }
          }

          return ListView.builder(
            itemCount: groupedItems.length,
            itemBuilder: (ctx, index) {
              final item = groupedItems[index];

              if (item is Category) {
                return Container(
                  color: Theme.of(context).primaryColor.withAlpha(50),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                );
              }

              if (item is Product) {
                return Card(
                  margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: item.imageUrl != null
                          ? NetworkImage(item.imageUrl!)
                          : null,
                      child: item.imageUrl == null
                          ? const Icon(Icons.fastfood, color: Colors.grey)
                          : null,
                    ),
                    title: Text(item.name),
                    subtitle: Text('R\$ ${item.price.toStringAsFixed(2)}'),
                    trailing: item.isSoldOut
                        ? Text(
                            'Esgotado',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                    onTap: () {
                      navProvider.navigateTo(
                          context, ProductEditScreen(product: item), 'Editar Produto');
                    },
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}