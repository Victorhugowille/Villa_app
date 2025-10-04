import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;
import 'package:villabistromobile/providers/cart_provider.dart';
import 'package:villabistromobile/providers/navigation_provider.dart';
import 'package:villabistromobile/providers/table_provider.dart';

class CartScreen extends StatelessWidget {
  final app_data.Table table;
  const CartScreen({super.key, required this.table});

  Future<void> _placeOrder(BuildContext context) async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    final tableProvider = Provider.of<TableProvider>(context, listen: false);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    if (cart.items.isEmpty) return;

    try {
      await tableProvider.placeOrder(
        tableId: table.id,
        items: cart.items,
      );
      cart.clearCart();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pedido realizado para a Mesa ${table.tableNumber}.'),
          backgroundColor: Colors.green,
        ),
      );

      if (isDesktop) {
        navProvider.popToHome();
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao realizar pedido: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);

    Widget emptyCartView = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.remove_shopping_cart_outlined,
              size: 80, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          Text(
            'Seu carrinho está vazio.',
            style: TextStyle(
                color: theme.colorScheme.onBackground.withOpacity(0.7),
                fontSize: 18),
          ),
        ],
      ),
    );

    Widget listContent = ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: cart.items.length,
      itemBuilder: (ctx, i) {
        final cartItem = cart.items[i];
        return Dismissible(
          key: ValueKey(cartItem.cartItemId),
          background: Container(
            color: Colors.red.withOpacity(0.8),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white, size: 30),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            Provider.of<CartProvider>(context, listen: false)
                .removeItem(cartItem.cartItemId);
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(cartItem.product.imageUrl ??
                      'https://placehold.co/100x100/e2e8f0/e2e8f0?text=Img'),
                  onBackgroundImageError: (_, __) {},
                ),
                title: Text(cartItem.product.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...cartItem.selectedAdicionais.map(
                      (itemAd) => Text(
                        "+ ${itemAd.quantity}x ${itemAd.adicional.name}",
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total do item: R\$ ${cartItem.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.red),
                      onPressed: () =>
                          cart.decreaseQuantity(cartItem.cartItemId),
                    ),
                    Text(
                      '${cartItem.quantity}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline,
                          color: theme.primaryColor),
                      onPressed: () =>
                          cart.increaseQuantity(cartItem.cartItemId),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    Widget bodyContent = cart.items.isEmpty ? emptyCartView : listContent;

    if (isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navProvider.setScreenActions([
          if (cart.items.isNotEmpty) ...[
            const Text('Total:', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Chip(
              label: Text(
                'R\$ ${cart.totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold),
              ),
              backgroundColor: theme.primaryColor,
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Fazer Pedido'),
              onPressed: () => _placeOrder(context),
            ),
            const SizedBox(width: 8),
          ]
        ]);
      });

      return bodyContent;
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Carrinho'),
        ),
        body: bodyContent,
        bottomNavigationBar: cart.items.isEmpty
            ? null
            : BottomAppBar(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total', style: TextStyle(fontSize: 16)),
                          Text(
                            'R\$ ${cart.totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => _placeOrder(context),
                        child: const Text('FAZER PEDIDO'),
                      )
                    ],
                  ),
                ),
              ),
      );
    }
  }
}