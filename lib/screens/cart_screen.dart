import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;
import 'package:villabistromobile/providers/cart_provider.dart';
import 'package:villabistromobile/providers/navigation_provider.dart';
import 'package:villabistromobile/providers/table_provider.dart';

class CartScreen extends StatelessWidget {
  final app_data.Table table;
  const CartScreen({super.key, required this.table});

  void _showItemObservationDialog(
      BuildContext context, app_data.CartItem cartItem) {
    final controller = TextEditingController(text: cartItem.observacao);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Observação para ${cartItem.product.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
              labelText: 'Ex: Sem cebola, ponto da carne, etc.'),
          onSubmitted: (_) =>
              _submitObservation(context, cartItem.id, controller.text),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
              onPressed: () =>
                  _submitObservation(context, cartItem.id, controller.text),
              child: const Text('Salvar')),
        ],
      ),
    );
  }

  void _submitObservation(
      BuildContext context, String cartItemId, String observation) {
    Provider.of<CartProvider>(context, listen: false)
        .updateItemObservation(cartItemId, observation);
    Navigator.pop(context);
  }

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
        orderObservation: cart.orderObservation,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrinho'),
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.remove_shopping_cart_outlined, size: 80, color: Colors.grey.shade600),
                  const SizedBox(height: 16),
                  const Text('Seu carrinho está vazio.', style: TextStyle(fontSize: 18)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: cart.items.length,
                    itemBuilder: (ctx, i) {
                      final cartItem = cart.items[i];
                      return Dismissible(
                        key: ValueKey(cartItem.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          cart.removeItem(cartItem.id);
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                title: Text(cartItem.product.name),
                                subtitle: Text(
                                    'Total: R\$ ${cartItem.totalPrice.toStringAsFixed(2)}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                        icon: const Icon(Icons.remove),
                                        onPressed: () =>
                                            cart.decreaseQuantity(cartItem.id)),
                                    Text('${cartItem.quantity}',
                                        style: const TextStyle(fontSize: 18)),
                                    IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: () =>
                                            cart.increaseQuantity(cartItem.id)),
                                  ],
                                ),
                              ),
                              if (cartItem.observacao != null &&
                                  cartItem.observacao!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 16, right: 16, bottom: 8),
                                  child: Text(
                                    'Obs: ${cartItem.observacao}',
                                    style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.black54),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                                child: TextButton.icon(
                                  icon: const Icon(Icons.edit_note, size: 20),
                                  label: Text(
                                      cartItem.observacao != null &&
                                              cartItem.observacao!.isNotEmpty
                                          ? 'Editar Observação'
                                          : 'Adicionar Observação'),
                                  onPressed: () =>
                                      _showItemObservationDialog(context, cartItem),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Observação Geral do Pedido',
                      hintText: 'Ex: Trazer todos os pratos juntos, etc.',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (text) {
                      cart.updateOrderObservation(text);
                    },
                  ),
                )
              ],
            ),
      bottomNavigationBar: cart.items.isEmpty
          ? null
          : BottomAppBar(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text('Total: R\$ ${cart.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
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