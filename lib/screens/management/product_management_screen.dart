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

      // Otimização: registrar as ações apenas uma vez na inicialização
      final isDesktop = MediaQuery.of(context).size.width > 800;
      if (isDesktop) {
        _registerActions();
      }
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

    Widget bodyContent = Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        if (productProvider.products.isEmpty && productProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final categories = productProvider.categories;

        if (categories.isEmpty) {
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
          child: ProductList(
            onProductSelected: (product) {
              navProvider.navigateTo(
                  context, ProductEditScreen(product: product), 'Editar Produto');
            },
          ),
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Produtos'),
      ),
      body: bodyContent,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          navProvider.navigateTo(
              context, const ProductEditScreen(), 'Novo Produto');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}