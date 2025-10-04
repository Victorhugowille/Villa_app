import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;
import 'package:villabistromobile/providers/navigation_provider.dart';
import 'package:villabistromobile/providers/printer_provider.dart';
import 'package:villabistromobile/providers/table_provider.dart';
import 'package:villabistromobile/screens/payment_screen.dart';
import 'package:villabistromobile/services/printing_service.dart';

class OrderListScreen extends StatefulWidget {
  final app_data.Table table;
  const OrderListScreen({super.key, required this.table});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  late Future<List<app_data.Order>> _ordersFuture;
  final PrintingService _printingService = PrintingService();

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _ordersFuture = Provider.of<TableProvider>(context, listen: false)
          .getOrdersForTable(widget.table.id);
    });
  }

  void _deleteOrder(String orderId) async {
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

  void _triggerPrintReceipt(List<app_data.Order> loadedOrders) async {
    if (loadedOrders.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nenhum pedido para imprimir.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    final totalAmount =
        loadedOrders.fold(0.0, (sum, order) => sum + order.total);
    final printerProvider = Provider.of<PrinterProvider>(context, listen: false);

    try {
      await _printingService.printReceiptPdf(
        orders: loadedOrders,
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

  void _registerActions(List<app_data.Order> loadedOrders) {
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    navProvider.setScreenActions([
      if (loadedOrders.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.print),
          tooltip: 'Imprimir Conferência',
          onPressed: () => _triggerPrintReceipt(loadedOrders),
        )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return FutureBuilder<List<app_data.Order>>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        if (isDesktop && snapshot.hasData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _registerActions(snapshot.data ?? []);
          });
        }

        Widget bodyContent;

        if (snapshot.connectionState == ConnectionState.waiting) {
          bodyContent = Center(
              child: CircularProgressIndicator(color: theme.primaryColor));
        } else if (snapshot.hasError) {
          bodyContent = Center(
              child: Text('Erro ao carregar pedidos: ${snapshot.error}'));
        } else {
          final loadedOrders = snapshot.data ?? [];

          if (loadedOrders.isEmpty) {
            bodyContent = Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('Nenhum pedido ativo para esta mesa.',
                      style: TextStyle(fontSize: 16)),
                ],
              ),
            );
          } else {
            final totalAmount =
                loadedOrders.fold(0.0, (sum, order) => sum + order.total);
            bodyContent = Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadOrders,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: loadedOrders.length,
                      itemBuilder: (ctx, index) {
                        final order = loadedOrders[index];
                        return _buildOrderCard(order, theme);
                      },
                    ),
                  ),
                ),
                _buildFooter(totalAmount, loadedOrders, navProvider, theme),
              ],
            );
          }
        }

        if (isDesktop) {
          return bodyContent;
        } else {
          return Scaffold(
            appBar: AppBar(
              title: Text('Pedidos - Mesa ${widget.table.tableNumber}'),
              actions: [
                if (snapshot.hasData && snapshot.data!.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.print),
                    tooltip: 'Imprimir Conferência',
                    onPressed: () => _triggerPrintReceipt(snapshot.data!),
                  )
              ],
            ),
            body: bodyContent,
          );
        }
      },
    );
  }

  Widget _buildOrderCard(app_data.Order order, ThemeData theme) {
    final String orderIdDisplay =
        order.id.length > 8 ? order.id.substring(0, 8) : order.id;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            title: Text(
              'Pedido #$orderIdDisplay',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle:
                Text(DateFormat('dd/MM/yyyy HH:mm').format(order.timestamp)),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
              onPressed: () => _deleteOrder(order.id),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: order.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                              child: Text(
                                  '${item.quantity}x ${item.product.name}')),
                          Text(
                              'R\$ ${(item.product.price * item.quantity).toStringAsFixed(2)}'),
                        ],
                      ),
                      if (item.selectedAdicionais.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: item.selectedAdicionais.map((itemAd) {
                              final ad = itemAd.adicional;
                              return Text(
                                "+ ${itemAd.quantity}x ${ad.name} (+ R\$ ${(ad.price * itemAd.quantity).toStringAsFixed(2)})",
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54),
                              );
                            }).toList(),
                          ),
                        )
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Subtotal do Pedido: ',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  'R\$ ${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(double totalAmount, List<app_data.Order> loadedOrders,
      NavigationProvider navProvider, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 252, 251, 251).withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total da Mesa:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              Text(
                'R\$ ${totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.payment),
              label: const Text('FECHAR CONTA'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: totalAmount > 0
                  ? () {
                      navProvider.navigateTo(
                        context,
                        PaymentScreen(
                          table: widget.table,
                          totalAmount: totalAmount,
                          orders: loadedOrders,
                        ),
                        'Pagamento - Mesa ${widget.table.tableNumber}',
                      );
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}