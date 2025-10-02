// lib/screens/category_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;
import 'package:villabistromobile/providers/cart_provider.dart';
import 'package:villabistromobile/providers/navigation_provider.dart';
import 'package:villabistromobile/providers/product_provider.dart';
import 'package:villabistromobile/screens/cart_screen.dart';
import 'package:villabistromobile/screens/product_selection_screen.dart';

class CategoryScreen extends StatelessWidget {
  final app_data.Table table;
  const CategoryScreen({super.key, required this.table});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);

    int crossAxisCount;
    if (screenWidth > 1200) {
      crossAxisCount = 5;
    } else if (screenWidth > 800) {
      crossAxisCount = 4;
    } else if (screenWidth > 600) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 2;
    }

    Widget bodyContent = Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        if (productProvider.categories.isEmpty) {
          // Garante que os dados sejam buscados se não estiverem disponíveis
          productProvider.fetchData();
        }
        if (productProvider.isLoading && productProvider.categories.isEmpty) {
          return Center(
              child: CircularProgressIndicator(color: theme.primaryColor));
        }

        final categories = productProvider.categories;

        return RefreshIndicator(
          onRefresh: () => productProvider.fetchData(),
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final category = categories[index];
              final productsInCategory = productProvider.products
                  .where((p) => p.categoryId == category.id)
                  .toList();

              return GestureDetector(
                onTap: () {
                  navProvider.navigateTo(
                    context,
                    ProductSelectionScreen(
                      table: table,
                      category: category,
                      products: productsInCategory,
                    ),
                    category.name,
                  );
                },
                child: Card(
                  color: theme.primaryColor,
                  elevation: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_pizza, // Ícone de exemplo, troque se tiver um na sua Categoria
                        size: 50,
                        color: theme.colorScheme.onPrimary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        category.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    List<Widget> appBarActions = [
      Consumer<CartProvider>(
        builder: (_, cart, ch) => Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined, size: 28),
              onPressed: () {
                navProvider.navigateTo(context, CartScreen(table: table),
                    'Carrinho - Mesa ${table.tableNumber}');
              },
            ),
            if (cart.totalItemsQuantity > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '${cart.totalItemsQuantity}',
                    style:
                        const TextStyle(color: Colors.white, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    ];

    if (isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navProvider.setScreenActions(appBarActions);
      });
      return bodyContent;
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(navProvider.currentTitle),
          actions: appBarActions,
        ),
        body: bodyContent,
      );
    }
  }
}