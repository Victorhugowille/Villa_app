import 'package:flutter/material.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;

class ViewOrderScreen extends StatelessWidget {
  final app_data.Order order;
  final int tableNumber;

  const ViewOrderScreen({
    super.key,
    required this.order,
    required this.tableNumber,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Mesa $tableNumber - Pedido #${order.id}'),
        elevation: 0,
      ),
      bottomNavigationBar: BottomAppBar(
        color: theme.primaryColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL DO PEDIDO',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimary),
              ),
              Text(
                'R\$ ${order.total.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimary),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text(
              'Itens do Pedido #${order.id}',
              style: TextStyle(
                color: theme.colorScheme.onBackground,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(indent: 16, endIndent: 16, color: theme.primaryColor),
          Expanded(
            child: ListView.builder(
              itemCount: order.items.length,
              itemBuilder: (ctx, i) {
                final item = order.items[i];
                return ListTile(
                  title: Text(item.product.name, style: TextStyle(color: theme.colorScheme.onBackground)),
                  subtitle: Text('Qtd: ${item.quantity}', style: TextStyle(color: theme.colorScheme.onBackground.withOpacity(0.7))),
                  trailing: Text(
                    'R\$ ${(item.product.price * item.quantity).toStringAsFixed(2)}',
                    style: TextStyle(color: theme.primaryColor, fontSize: 16),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}