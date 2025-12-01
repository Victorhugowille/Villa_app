import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/app_data.dart' as app_data;
import '../providers/cart_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/table_provider.dart';
import '../providers/printer_provider.dart';
import 'category_screen.dart';
import 'order_list_screen.dart';
import '../services/printing_service.dart';
// import 'package:villabistromobile/widgets/side_menu.dart'; // Não é mais necessário

class TableSelectionScreen extends StatefulWidget {
  const TableSelectionScreen({super.key});

  @override
  State<TableSelectionScreen> createState() => _TableSelectionScreenState();
}

class _TableSelectionScreenState extends State<TableSelectionScreen> {
  final PrintingService _printingService = PrintingService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TableProvider>(context, listen: false).fetchAndSetTables();
    });
  }

  Color _getTableColor(app_data.Table table, ThemeData theme) {
    if (table.isPartiallyPaid) {
      return Colors.amber.shade700;
    }
    if (table.isOccupied) {
      return Colors.red.shade700;
    }
    return theme.cardColor;
  }

  Color _getForegroundColor(app_data.Table table, ThemeData theme) {
    if (table.isOccupied || table.isPartiallyPaid) {
      return Colors.white;
    }
    return theme.colorScheme.onSurface;
  }

  void _handleTableTap(BuildContext context, app_data.Table table) {
    Provider.of<CartProvider>(context, listen: false).clearCart();
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    if (table.isOccupied || table.isPartiallyPaid) {
      if (isDesktop) {
        _showDesktopOptions(context, table);
      } else {
        _showMobileOptions(context, table);
      }
    } else {
      Provider.of<NavigationProvider>(context, listen: false)
          .navigateTo(context, CategoryScreen(table: table), 'Nova Venda');
    }
  }

  // A função de impressão agora recebe a mesa como parâmetro
  void _triggerPrintReceipt(BuildContext context, app_data.Table table) async {
    final tableProvider = Provider.of<TableProvider>(context, listen: false);
    final printerProvider = Provider.of<PrinterProvider>(context, listen: false);

    // Busca os pedidos da mesa antes de tentar imprimir
    try {
      final loadedOrders = await tableProvider.getOrdersForTable(table.id);
      
      if (loadedOrders.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Nenhum pedido para imprimir nesta mesa.'),
              backgroundColor: Colors.orange),
        );
        return;
      }

      final totalAmount =
          loadedOrders.fold(0.0, (sum, order) => sum + order.total);
      final conferencePrinter = printerProvider.conferencePrinter;

      if (conferencePrinter == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Nenhuma impressora de conferência configurada!'),
              backgroundColor: Colors.red),
        );
        return;
      }

      await _printingService.directPrintReceiptPdf(
        orders: loadedOrders,
        tableNumber: table.tableNumber.toString(),
        totalAmount: totalAmount,
        settings: printerProvider.receiptTemplateSettings,
        printer: conferencePrinter,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Conferência enviada para a impressora!'),
            backgroundColor: Colors.green),
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

  void _showDesktopOptions(BuildContext context, app_data.Table table) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Opções da Mesa ${table.tableNumber}'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOptionTile(
                context: ctx,
                icon: Icons.visibility,
                title: 'Visualizar Pedidos',
                onTap: () {
                  Provider.of<NavigationProvider>(context, listen: false)
                      .navigateTo(context, OrderListScreen(table: table),
                          'Pedidos - Mesa ${table.tableNumber}');
                },
              ),
              _buildOptionTile(
                context: ctx,
                icon: Icons.add_shopping_cart,
                title: 'Adicionar Itens',
                onTap: () {
                  Provider.of<NavigationProvider>(context, listen: false)
                      .navigateTo(context, CategoryScreen(table: table),
                          'Adicionar Itens');
                },
              ),
              // Adicionando a opção de imprimir aqui
              _buildOptionTile(
                context: ctx,
                icon: Icons.print_outlined,
                title: 'Imprimir Conferência',
                onTap: () => _triggerPrintReceipt(context, table),
              ),
              _buildOptionTile(
                context: ctx,
                icon: Icons.delete_forever,
                title: 'Limpar Mesa',
                onTap: () => _confirmClearTable(context, table),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMobileOptions(BuildContext context, app_data.Table table) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOptionTile(
              context: ctx,
              icon: Icons.visibility,
              title: 'Visualizar Pedidos',
              onTap: () {
                Provider.of<NavigationProvider>(context, listen: false)
                    .navigateTo(context, OrderListScreen(table: table),
                        'Pedidos - Mesa ${table.tableNumber}');
              },
            ),
            _buildOptionTile(
              context: ctx,
              icon: Icons.add_shopping_cart,
              title: 'Fazer um novo pedido',
              onTap: () {
                Provider.of<NavigationProvider>(context, listen: false)
                    .navigateTo(
                        context, CategoryScreen(table: table), 'Nova Venda');
              },
            ),
            // Adicionando a opção de imprimir aqui
            _buildOptionTile(
              context: ctx,
              icon: Icons.print_outlined,
              title: 'Imprimir Conferência',
              onTap: () => _triggerPrintReceipt(context, table),
            ),
            _buildOptionTile(
              context: ctx,
              icon: Icons.delete_forever,
              title: 'Limpar Mesa',
              onTap: () => _confirmClearTable(context, table),
            ),
          ],
        ),
      ),
    );
  }

  ListTile _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context); // Fecha o modal/dialog
        onTap();
      },
    );
  }

  void _confirmClearTable(BuildContext context, app_data.Table table) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Confirmar Ação'),
        content: const Text(
            'Tem certeza que deseja limpar a mesa? Esta ação irá liberar a mesa e finalizar todos os pedidos em aberto.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await Provider.of<TableProvider>(context, listen: false)
                    .clearTable(table.id);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Erro ao limpar a mesa: ${e.toString()}')),
                  );
                }
              }
            },
            child:
                const Text('Limpar Mesa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    // final isDesktop = screenWidth > 800; // Não precisamos mais disso aqui

    int crossAxisCount;
    if (screenWidth > 1200) {
      crossAxisCount = 5;
    } else if (screenWidth > 800) {
      crossAxisCount = 4;
    } else if (screenWidth > 600) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 2;
    }

    Widget screenContent = Consumer<TableProvider>(
      builder: (context, tableProvider, child) {
        if (tableProvider.isLoading) {
          return Center(
              child: CircularProgressIndicator(color: theme.primaryColor));
        }

        if (tableProvider.tables.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => tableProvider.fetchAndSetTables(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: const Center(
                    child: Text('Nenhuma mesa cadastrada.'),
                  ),
                )
              ],
            ),
          );
        }

        final tables = tableProvider.tables;

        return RefreshIndicator(
          onRefresh: () => tableProvider.fetchAndSetTables(),
          child: GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1,
            ),
            itemCount: tables.length,
            itemBuilder: (context, index) {
              final app_data.Table table = tables[index];
              final Color backgroundColor = _getTableColor(table, theme);
              final Color foregroundColor = _getForegroundColor(table, theme);

              return Card(
                elevation: 4,
                color: backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () => _handleTableTap(context, table),
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.table_restaurant,
                          size: 40,
                          color: foregroundColor.withOpacity(0.8),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mesa ${table.tableNumber}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: foregroundColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    // --- CORREÇÃO AQUI ---
    // Removemos o 'if (isDesktop)' e o 'Scaffold' extra.
    // Esta tela agora SEMPRE retorna apenas o 'screenContent',
    // que será o 'body:' do MobileShell ou DesktopShell.
    return screenContent;
  }
}