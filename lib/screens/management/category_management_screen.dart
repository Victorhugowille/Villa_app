// lib/screens/management/category_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/providers/navigation_provider.dart';
import 'package:villabistromobile/providers/product_provider.dart';
import 'package:villabistromobile/screens/management/category_edit_screen.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
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

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('Ok'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  void _registerActions() {
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    navProvider.setScreenActions([
      IconButton(
        icon: const Icon(Icons.add),
        tooltip: 'Nova Categoria',
        onPressed: () {
          navProvider.navigateTo(
              context, const CategoryEditScreen(), 'Nova Categoria');
        },
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    Widget bodyContent = Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        if (productProvider.isLoading && productProvider.categories.isEmpty) {
          return Center(
              child: CircularProgressIndicator(color: theme.primaryColor));
        }
        if (productProvider.categories.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [Center(child: Text("Nenhuma categoria encontrada."))]
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _refreshData,
          child: ListView.builder(
            itemCount: productProvider.categories.length,
            itemBuilder: (ctx, index) {
              final category = productProvider.categories[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading:
                      Icon(category.icon, color: theme.primaryColor, size: 30),
                  title: Text(category.name,
                      style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      try {
                        await productProvider.deleteCategory(category.id);
                      } catch (e) {
                        _showErrorDialog(e.toString());
                      }
                    },
                  ),
                  onTap: () {
                    navProvider.navigateTo(context,
                        CategoryEditScreen(category: category), 'Editar Categoria');
                  },
                ),
              );
            },
          ),
        );
      },
    );

    if (isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _registerActions();
      });
      return bodyContent;
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Gerenciar Categorias'),
        ),
        body: bodyContent,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            navProvider.navigateTo(
                context, const CategoryEditScreen(), 'Nova Categoria');
          },
          child: const Icon(Icons.add),
        ),
      );
    }
  }
}