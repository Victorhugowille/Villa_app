import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/app_data.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/product_provider.dart';
import 'category_edit_screen.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  List<Category> _localCategories = [];
  bool _isSavingOrder = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    await Provider.of<ProductProvider>(context, listen: false).fetchData();
    _syncLocalList();
  }

  void _syncLocalList() {
    if (!mounted) return;
    setState(() {
      _localCategories = List<Category>.from(
          Provider.of<ProductProvider>(context, listen: false).categories);
    });
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

  Future<void> _confirmDeleteCategory(Category category) async {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
            'Tem certeza que deseja apagar a categoria "${category.name}"? Todos os produtos dentro dela também serão apagados.'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () {
              Navigator.of(ctx).pop(false);
            },
          ),
          TextButton(
            child: Text('Apagar',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onPressed: () {
              Navigator.of(ctx).pop(true);
            },
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await productProvider.deleteCategory(category.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Categoria apagada com sucesso.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } catch (e) {
        _showErrorDialog(e.toString());
      }
    }
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

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (_isSavingOrder) return;

    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final Category item = _localCategories.removeAt(oldIndex);
      _localCategories.insert(newIndex, item);
      _isSavingOrder = true;
    });

    try {
      await Provider.of<ProductProvider>(context, listen: false)
          .updateCategoryOrder(_localCategories);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ordem salva com sucesso!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ));
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
        _syncLocalList();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingOrder = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    Widget bodyContent = Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        if (productProvider.isLoading && _localCategories.isEmpty) {
          return Center(
              child: CircularProgressIndicator(color: theme.primaryColor));
        }

        if (productProvider.categories.length != _localCategories.length &&
            !_isSavingOrder) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _syncLocalList();
          });
        }

        if (_localCategories.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  Center(child: Text("Nenhuma categoria encontrada."))
                ]),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshData,
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            itemCount: _localCategories.length,
            itemBuilder: (ctx, index) {
              final category = _localCategories[index];
              return Card(
                key: ValueKey(category.id),
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading:
                      Icon(category.icon, color: theme.primaryColor, size: 30),
                  title: Text(category.name,
                      style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Visível em: ${category.appType.label}',
                    style: TextStyle(color: theme.colorScheme.secondary),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.copy_outlined, color: Colors.blue),
                        tooltip: 'Duplicar',
                        onPressed: () async {
                          try {
                            await productProvider
                                .duplicateCategory(category.id);
                            if (mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                content: Text(
                                    'Categoria duplicada com sucesso!'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 1),
                              ));
                            }
                          } catch (e) {
                            _showErrorDialog(e.toString());
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        onPressed: () {
                          _confirmDeleteCategory(category);
                        },
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.drag_indicator),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    navProvider.navigateTo(
                        context,
                        CategoryEditScreen(category: category),
                        'Editar Categoria');
                  },
                ),
              );
            },
            onReorder: _onReorder,
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