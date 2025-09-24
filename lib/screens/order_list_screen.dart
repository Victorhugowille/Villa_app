import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;
import 'package:villabistromobile/providers/navigation_provider.dart';
import 'package:villabistromobile/providers/printer_provider.dart';
import 'package:villabistromobile/providers/table_provider.dart';
import 'package:villabistromobile/screens/payment_screen.dart';
import 'package:villabistromobile/services/printing_service.dart';
import 'package:villabistromobile/widgets/custom_app_bar.dart';

class OrderListScreen extends StatefulWidget {
  final app_data.Table table;
  const OrderListScreen({super.key, required this.table});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  late Future<List<app_data.Order>> _ordersFuture;
  List<app_data.Order> _loadedOrders = [];
  final PrintingService _printingService = PrintingService();

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    setState(() {
      _ordersFuture = Provider.of<TableProvider>(context, listen: false)
          .getOrdersForTable(widget.table.id);
    });
  }

  void _deleteOrder(int orderId) async {
    try {
      await Provider.of<TableProvider>(context, listen: false)
          .deleteOrder(orderId);
      _loadOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erro ao apagar pedido: ${e.toString()}'),
            backgroundColor: Colors.red),
      );
    }
  }

  double _calculateTotal(List<app_data.Order> orders) {
    return orders.fold(0.0, (sum, order) => sum + order.total);
  }

  void _triggerPrintReceipt() async {
    if (_loadedOrders.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nenhum pedido para imprimir.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    final totalAmount = _calculateTotal(_loadedOrders);
    final printerProvider = Provider.of<PrinterProvider>(context, listen: false);

    try {
      await _printingService.printReceiptPdf(
        orders: _loadedOrders,
        tableNumber: widget.table.tableNumber.toString(),
        totalAmount: totalAmount,
        settings: printerProvider.receiptTemplateSettings,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erro ao imprimir Conferência: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Pedidos - Mesa ${widget.table.tableNumber}',
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Imprimir Conferência',
            onPressed: _triggerPrintReceipt,
          )
        ],
      ),
      body: FutureBuilder<List<app_data.Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: theme.primaryColor));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          _loadedOrders = snapshot.data ?? [];

          final totalAmount = _calculateTotal(_loadedOrders);

          if (_loadedOrders.isEmpty) {
            return const Center(child: Text('Nenhum pedido para esta mesa.'));
          } else {
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _loadedOrders.length,
                    itemBuilder: (ctx, index) {
                      final order = _loadedOrders[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 6),
                        child: ExpansionTile(
                          title: Text(
                              'Pedido #${order.id} - ${DateFormat('HH:mm').format(order.timestamp)}'),
                          subtitle:
                              Text('Total: R\$ ${order.total.toStringAsFixed(2)}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () => _deleteOrder(order.id),
                          ),
                          children: order.items.map((item) {
                            return ListTile(
                              dense: true,
                              title:
                                  Text('${item.quantity}x ${item.product.name}'),
                              trailing: Text(
                                  'R\$ ${(item.product.price * item.quantity).toStringAsFixed(2)}'),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total da Mesa:',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onBackground)),
                      Text('R\$ ${totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: totalAmount > 0
                          ? () {
                              NavigationProvider.navigateTo(
                                context,
                                PaymentScreen(
                                  table: widget.table,
                                  totalAmount: totalAmount,
                                  orders: _loadedOrders,
                                ),
                              );
                            }
                          : null,
                      child: const Text('FECHAR CONTA'),
                    ),
                  ),
                )
              ],
            );
          }
        },
      ),
    );
  }
}