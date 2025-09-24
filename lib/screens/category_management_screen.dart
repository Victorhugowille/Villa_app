import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/providers/navigation_provider.dart';
import 'package:villabistromobile/providers/product_provider.dart';
import 'package:villabistromobile/screens/category_edit_screen.dart';
import 'package:villabistromobile/widgets/custom_app_bar.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Gerenciar Categorias',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: productProvider.isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : ListView.builder(
              itemCount: productProvider.categories.length,
              itemBuilder: (ctx, index) {
                final category = productProvider.categories[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: Icon(category.icon,
                        color: theme.primaryColor, size: 30),
                    title: Text(category.name,
                        style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold)),
                    trailing: IconButton(
                      icon:
                          const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        try {
                          await productProvider.deleteCategory(category.id);
                        } catch (e) {
                          _showErrorDialog(e.toString());
                        }
                      },
                    ),
                    onTap: () {
                      navProvider.navigateTo(
                          context, CategoryEditScreen(category: category), 'Editar Categoria');
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          navProvider.navigateTo(context, const CategoryEditScreen(), 'Nova Categoria');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}