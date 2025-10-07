import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/data/app_data.dart';
import 'package:villabistromobile/providers/product_provider.dart';

class ProductList extends StatefulWidget {
  final Product? selectedProduct;
  final Function(Product) onProductSelected;

  const ProductList({
    super.key,
    this.selectedProduct,
    required this.onProductSelected,
  });

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  List<Product> _localProducts = [];
  bool _isSavingOrder = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncLocalList();
  }

  void _syncLocalList() {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    if (mounted) {
      setState(() {
        _localProducts = List<Product>.from(productProvider.products);
      });
    }
  }

  Future<void> _handleReorder(int oldIndex, int newIndex,
      List<Product> productsInCategory, Category category) async {
    if (_isSavingOrder) return;

    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);

    setState(() {
      _isSavingOrder = true;

      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final movedProduct = productsInCategory.removeAt(oldIndex);
      productsInCategory.insert(newIndex, movedProduct);

      final List<Product> updatedFullList = [];
      for (final cat in productProvider.categories) {
        if (cat.id == category.id) {
          updatedFullList.addAll(productsInCategory);
        } else {
          updatedFullList
              .addAll(_localProducts.where((p) => p.categoryId == cat.id));
        }
      }
      _localProducts = updatedFullList;
    });

    try {
      await productProvider.updateProductOrder(productsInCategory);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ordem salva com sucesso!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao salvar ordem: ${e.toString()}'),
          backgroundColor: Colors.red,
        ));
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
    final productProvider = context.watch<ProductProvider>();

    if (productProvider.products.length != _localProducts.length &&
        !_isSavingOrder) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncLocalList());
    }

    final categories = productProvider.categories;

    if (productProvider.isLoading && _localProducts.isEmpty) {
      return Center(
          child: CircularProgressIndicator(color: theme.primaryColor));
    }

    if (_localProducts.isEmpty) {
      return const Center(child: Text('Nenhum produto encontrado.'));
    }

    return Column(
      children: [
        if (_isSavingOrder)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: LinearProgressIndicator(),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: categories.length,
            itemBuilder: (ctx, index) {
              final category = categories[index];
              final productsInCategory = _localProducts
                  .where((p) => p.categoryId == category.id)
                  .toList();

              if (productsInCategory.isEmpty) {
                return const SizedBox.shrink();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      category.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                  ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: productsInCategory.length,
                    itemBuilder: (context, itemIndex) {
                      final item = productsInCategory[itemIndex];
                      final isSelected = widget.selectedProduct?.id == item.id;
                      return Card(
                        key: ValueKey(item.id),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        elevation: isSelected ? 8 : 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isSelected
                              ? BorderSide(color: theme.primaryColor, width: 2)
                              : BorderSide.none,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.only(
                              left: 16, top: 8, bottom: 8, right: 8),
                          leading: CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: item.imageUrl != null
                                ? NetworkImage(item.imageUrl!)
                                : null,
                            child: item.imageUrl == null
                                ? const Icon(Icons.fastfood,
                                    color: Colors.grey)
                                : null,
                          ),
                          title: Text(item.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle:
                              Text('R\$ ${item.price.toStringAsFixed(2)}'),
                          onTap: () => widget.onProductSelected(item),
                          tileColor: isSelected
                              ? theme.primaryColor.withOpacity(0.1)
                              : null,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.copy_outlined,
                                    color: Colors.blue),
                                tooltip: 'Duplicar Produto',
                                onPressed: () async {
                                  try {
                                    await Provider.of<ProductProvider>(context,
                                            listen: false)
                                        .duplicateProduct(item.id);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Produto duplicado com sucesso!'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Erro ao duplicar: ${e.toString()}'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                              ReorderableDragStartListener(
                                index: itemIndex,
                                child: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.drag_indicator,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    onReorder: (oldIndex, newIndex) {
                      _handleReorder(
                          oldIndex, newIndex, productsInCategory, category);
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}