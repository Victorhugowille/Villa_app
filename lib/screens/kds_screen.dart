import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;
import 'package:villabistromobile/providers/kds_provider.dart';
import 'package:villabistromobile/widgets/side_menu.dart';

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
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final kdsProvider = context.watch<KdsProvider>();

    Widget bodyContent = Column(
      children: [
        if (!isDesktop)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ToggleButtons(
              isSelected: [
                kdsProvider.filter == KdsFilter.all,
                kdsProvider.filter == KdsFilter.table,
                kdsProvider.filter == KdsFilter.delivery,
              ],
              onPressed: (index) {
                kdsProvider.setFilter(KdsFilter.values[index]);
              },
              borderRadius: BorderRadius.circular(8),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Todos'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Mesa'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Delivery'),
                ),
              ],
            ),
          ),
        Expanded(
          child: Consumer<KdsProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.productionOrders.isEmpty && provider.readyOrders.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: OrderColumn(
                      key: const ValueKey('production_column'),
                      title: 'Em produção',
                      color: Colors.orange.shade700,
                      orders: provider.productionOrders,
                    ),
                  ),
                  Expanded(
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
          ),
        ),
      ],
    );

    if (isDesktop) {
      return bodyContent;
    } else {
      return Scaffold(
        drawer: const SideMenu(),
        appBar: AppBar(
          title: const Text('Painel de Pedidos (KDS)'),
        ),
        body: bodyContent,
      );
    }
  }
}

class OrderColumn extends StatelessWidget {
  final String title;
  final Color color;
  final List<app_data.Order> orders;

  const OrderColumn({
    super.key,
    required this.title,
    required this.color,
    required this.orders,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
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
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: orders.isEmpty
                ? const Center(child: Text('Nenhum pedido no momento.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      return OrderCard(
                          key: ValueKey(orders[index].id),
                          order: orders[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class OrderCard extends StatefulWidget {
  final app_data.Order order;
  const OrderCard({super.key, required this.order});

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  Timer? _timer;
  late int _minutesAgo;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _minutesAgo =
            DateTime.now().difference(widget.order.timestamp).inMinutes;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _getTimeColor(int minutes) {
    if (minutes > 10) {
      return Colors.red.shade700;
    } else if (minutes > 5) {
      return Colors.orange.shade800;
    }
    return Colors.grey.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<KdsProvider>(context, listen: false);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.order.type == 'mesa'
                          ? Icons.deck_outlined
                          : Icons.delivery_dining_outlined,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.order.type == 'mesa' && widget.order.tableNumber != null
                          ? 'MESA ${widget.order.tableNumber}'
                          : 'DELIVERY',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  'há $_minutesAgo min',
                  style: TextStyle(
                      color: _getTimeColor(_minutesAgo),
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            ...widget.order.items.map((item) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${item.quantity}x ',
                          style: const TextStyle(fontWeight: FontWeight.bold)
                        ),
                        TextSpan(text: item.product.name),
                      ],
                    ),
                  ),
                ),
                if(item.selectedAdicionais.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 15, top: 2, bottom: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: item.selectedAdicionais.map((adicional) => 
                        Text(
                          '+ ${adicional.quantity}x ${adicional.adicional.name}',
                          style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255), fontSize: 13),
                        )
                      ).toList(),
                    ),
                  ),
              ],
            )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => provider.advanceOrder(context, widget.order),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: widget.order.status == 'production' || widget.order.status == 'awaiting_print'
                      ? Colors.blueAccent
                      : Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(widget.order.status == 'ready' &&
                        widget.order.type == 'mesa'
                    ? 'Receber Pagamento'
                    : 'Avançar Pedido'),
              ),
            )
          ],
        ),
      ),
    );
  }
}