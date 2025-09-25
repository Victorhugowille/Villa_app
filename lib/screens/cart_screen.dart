import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;
import 'package:villabistromobile/providers/cart_provider.dart';
import 'package:villabistromobile/providers/navigation_provider.dart';
import 'package:villabistromobile/providers/table_provider.dart';

class CartScreen extends StatelessWidget {
  final app_data.Table table;
  const CartScreen({super.key, required this.table});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        children: <Widget>[
          Expanded(
            child: cart.items.isEmpty
                ? Center(
                    child: Text(
                      'Seu carrinho está vazio.',
                      style: TextStyle(
                          color: theme.colorScheme.onBackground, fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (ctx, i) {
                      final cartItem = cart.items.values.toList()[i];
                      return Dismissible(
                        key: ValueKey(cartItem.product.id),
                        background: Container(
                          color: Colors.red.withOpacity(0.8),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          Provider.of<CartProvider>(context, listen: false)
                              .removeItem(cartItem.product.id);
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 30,
                                backgroundImage: NetworkImage(
                                    cartItem.product.imageUrl ??
                                        'https://placehold.co/100x100/e2e8f0/e2e8f0?text=Img'),
                                onBackgroundImageError: (_, __) {},
                                child: null,
                              ),
                              title: Text(cartItem.product.name),
                              subtitle: Text(
                                  'Total: R\$ ${(cartItem.product.price * cartItem.quantity).toStringAsFixed(2)}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.red),
                                    onPressed: () => cart
                                        .removeSingleItem(cartItem.product.id),
                                  ),
                                  Text(
                                    '${cartItem.quantity}',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.add_circle_outline,
                                        color: theme.primaryColor),
                                    onPressed: () =>
                                        cart.addItem(cartItem.product),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (cart.items.isNotEmpty)
            Card(
              elevation: 5,
              margin: const EdgeInsets.fromLTRB(15, 15, 15, 8),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text('Total', style: TextStyle(fontSize: 20)),
                    const Spacer(),
                    Chip(
                      label: Text(
                        'R\$ ${cart.totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: theme.primaryColor,
                    ),
                    TextButton(
                      child: Text('FAZER PEDIDO',
                          style: TextStyle(color: theme.primaryColor)),
                      onPressed: () async {
                        final navProvider = Provider.of<NavigationProvider>(context, listen: false);

                        await Provider.of<TableProvider>(context,
                                listen: false)
                            .placeOrder(
                          tableId: table.id,
                          items: cart.itemsAsList,
                        );
                        cart.clearCart();
                        
                        navProvider.popToHome();
                      },
                    )
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }
}