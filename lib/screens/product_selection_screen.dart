import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;
import 'package:villabistromobile/providers/cart_provider.dart';
import 'package:villabistromobile/providers/navigation_provider.dart';
import 'package:villabistromobile/screens/cart_screen.dart';
import 'package:villabistromobile/widgets/custom_app_bar.dart';

class ProductSelectionScreen extends StatefulWidget {
  final app_data.Table table;
  final app_data.Category category;
  final List<app_data.Product> products;

  const ProductSelectionScreen({
    super.key,
    required this.table,
    required this.category,
    required this.products,
  });

  @override
  State<ProductSelectionScreen> createState() => _ProductSelectionScreenState();
}

class _ProductSelectionScreenState extends State<ProductSelectionScreen> {
  late Map<int, int> _selection;

  @override
  void initState() {
    super.initState();
    final cart = Provider.of<CartProvider>(context, listen: false);
    _selection = {
      for (var product in widget.products)
        product.id: cart.getItemQuantity(product.id)
    };
  }

  void _updateSelection(int productId, int quantity) {
    setState(() {
      _selection[productId] = quantity;
    });
  }

  int get _totalSelectedItems {
    return _selection.values.where((qty) => qty > 0).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    Widget content = ListView.builder(
      itemCount: widget.products.length,
      itemBuilder: (ctx, index) {
        final product = widget.products[index];
        final quantity = _selection[product.id] ?? 0;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: SizedBox(
                width: 60,
                height: 60,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    product.imageUrl ??
                        'https://placehold.co/100x100/e2e8f0/e2e8f0?text=Img',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.fastfood,
                        color: theme.primaryColor.withOpacity(0.5)),
                  ),
                ),
              ),
              title: Text(product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('R\$ ${product.price.toStringAsFixed(2)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline,
                        color: quantity > 0 ? Colors.red : Colors.grey),
                    onPressed: quantity > 0
                        ? () => _updateSelection(product.id, quantity - 1)
                        : null,
                  ),
                  Text(
                    '$quantity',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline,
                        color: theme.primaryColor, size: 28),
                    onPressed: () =>
                        _updateSelection(product.id, quantity + 1),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    FloatingActionButton? fab = _totalSelectedItems > 0
      ? FloatingActionButton.extended(
          onPressed: () {
            final cart = Provider.of<CartProvider>(context, listen: false);
            Provider.of<NavigationProvider>(context, listen: false);

            cart.addItemsFromSelection(_selection, widget.products);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '$_totalSelectedItems tipo(s) de item atualizado(s) no carrinho.'),
                backgroundColor: theme.primaryColor,
              ),
            );

         Provider.of<NavigationProvider>(context, listen: false).pop();          },
          icon: const Icon(Icons.shopping_cart_checkout),
          label: const Text('ATUALIZAR CARRINHO'),
        )
      : null;
    
    if (isDesktop) {
        return Stack(
          children: [
            content,
            if (fab != null)
            Positioned(
              bottom: 24,
              right: 24,
              child: fab,
            )
          ],
        );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.category.name,
        actions: [
          Consumer<CartProvider>(
            builder: (_, cart, ch) => Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined, size: 28),
                  onPressed: () {
                    final cartScreen = CartScreen(table: widget.table);
                    Provider.of<NavigationProvider>(context, listen: false).navigateTo(context, cartScreen, 'Carrinho - Mesa ${widget.table.tableNumber}');
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
        ],
      ),
      body: content,
      floatingActionButton: fab,
    );
  }
}