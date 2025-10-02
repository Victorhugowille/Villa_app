// lib/screens/management/product_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/data/app_data.dart';
import 'package:villabistromobile/providers/navigation_provider.dart';
import 'package:villabistromobile/providers/product_provider.dart';
import 'package:villabistromobile/screens/management/product_edit_screen.dart';
import 'package:villabistromobile/widgets/product_details.dart';
import 'package:villabistromobile/widgets/product_list.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  Product? _selectedProduct;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    await Provider.of<ProductProvider>(context, listen: false).fetchData();
  }

  void _registerActions() {
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    final actions = [
      IconButton(
        icon: const Icon(Icons.add),
        tooltip: 'Adicionar Produto',
        onPressed: () {
          setState(() {
            _selectedProduct = null;
          });
          navProvider.navigateTo(
              context, const ProductEditScreen(), 'Adicionar Produto');
        },
      ),
    ];
    navProvider.setScreenActions(actions);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);

    if (isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _registerActions();
      });
      return Row(
        children: [
          SizedBox(
            width: 380,
            child: ProductList(
              selectedProduct: _selectedProduct,
              onProductSelected: (product) {
                setState(() {
                  _selectedProduct = product;
                });
              },
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: ProductDetails(
              product: _selectedProduct,
              key: ValueKey(_selectedProduct?.id),
            ),
          ),
        ],
      );
    }

    // Layout para Mobile
    Widget bodyContent = Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        if (productProvider.products.isEmpty && productProvider.isLoading) {
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

        if (groupedItems.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height / 3),
                const Center(child: Text('Nenhum produto encontrado.')),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshData,
          child: ListView.builder(
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
          ),
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Produtos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar Produto',
            onPressed: () {
              navProvider.navigateTo(
                  context, const ProductEditScreen(), 'Adicionar Produto');
            },
          ),
        ],
      ),
      body: bodyContent,
    );
  }
}