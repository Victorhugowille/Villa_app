import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;
import 'package:villabistromobile/providers/kds_provider.dart';

class KdsScreen extends StatefulWidget {
  const KdsScreen({super.key});

  @override
  State<KdsScreen> createState() => _KdsScreenState();
}

class _KdsScreenState extends State<KdsScreen> {
  late KdsProvider _kdsProvider;

  @override
  void initState() {
    super.initState();
    _kdsProvider = Provider.of<KdsProvider>(context, listen: false);
    _kdsProvider.listenToOrders();
  }

  @override
  void dispose() {
    _kdsProvider.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Removido o Scaffold daqui! O ResponsiveLayout já o fornece.
    return Consumer<KdsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Row(
          children: [
            Expanded(
              // Adicionada uma Key explícita para evitar conflitos se houver reconstruções complexas
              child: OrderColumn(
                key: const ValueKey('production_column'), 
                title: 'Em produção',
                color: Colors.orange.shade700,
                orders: provider.productionOrders,
              ),
            ),
            Expanded(
              // Adicionada uma Key explícita
              child: OrderColumn(
                key: const ValueKey('ready_column'),
                title: 'Prontos para entrega',
                color: Colors.green.shade700,
                orders: provider.readyOrders,
              ),
            ),
          ],
        );
      },
    );
  }
}

class OrderColumn extends StatelessWidget {
  final String title;
  final Color color;
  final List<app_data.Order> orders;

  const OrderColumn({
    super.key, // Manter o super.key aqui
    required this.title,
    required this.color,
    required this.orders,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '${title.toUpperCase()} (${orders.length})',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: orders.isEmpty
                ? const Center(child: Text('Nenhum pedido no momento.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      // Chave única para cada OrderCard baseada no ID do pedido
                      return OrderCard(key: ValueKey(orders[index].id), order: orders[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final app_data.Order order;
  const OrderCard({super.key, required this.order}); // Manter o super.key aqui

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<KdsProvider>(context, listen: false);
    final minutesAgo = DateTime.now().difference(order.timestamp).inMinutes;

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.type == 'mesa'
                      ? 'MESA ${order.tableNumber}'
                      : 'DELIVERY',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'há $minutesAgo min',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const Divider(),
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Text('${item.quantity}x ${item.product.name}'),
            )),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => provider.advanceOrder(context, order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: order.status == 'production' ? Colors.blueAccent : Colors.green,
                ),
                child: Text(order.status == 'ready' && order.type == 'mesa' ? 'Receber Pagamento' : 'Avançar Pedido'),
              ),
            )
          ],
        ),
      ),
    );
  }
}