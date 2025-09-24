import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;
import 'package:villabistromobile/providers/cart_provider.dart';
import 'package:villabistromobile/providers/navigation_provider.dart';
import 'package:villabistromobile/providers/table_provider.dart';
import 'package:villabistromobile/screens/category_screen.dart';
import 'package:villabistromobile/screens/order_list_screen.dart';
import 'package:villabistromobile/screens/payment_screen.dart';

class TableSelectionScreen extends StatelessWidget {
  const TableSelectionScreen({super.key});

  void _handleTableTap(BuildContext context, app_data.Table table) {
    Provider.of<CartProvider>(context, listen: false).clearCart();
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    if (table.isOccupied) {
      if (isDesktop) {
        _showDesktopOptions(context, table);
      } else {
        _showMobileOptions(context, table);
      }
    } else {
      NavigationProvider.navigateTo(context, CategoryScreen(table: table));
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
                  NavigationProvider.navigateTo(
                      context, OrderListScreen(table: table));
                },
              ),
              _buildOptionTile(
                context: ctx,
                icon: Icons.add_shopping_cart,
                title: 'Adicionar Itens',
                onTap: () {
                  NavigationProvider.navigateTo(
                      context, CategoryScreen(table: table));
                },
              ),
              _buildOptionTile(
                context: ctx,
                icon: Icons.delete_forever,
                title: 'Limpar Mesa',
                onTap: () => _confirmClearTable(context, table),
              ),
              _buildOptionTile(
                context: ctx,
                icon: Icons.payment,
                title: 'Fechar Conta',
                onTap: () {
                  NavigationProvider.navigateTo(
                      context, OrderListScreen(table: table));
                },
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
                NavigationProvider.navigateTo(
                    context, OrderListScreen(table: table));
              },
            ),
            _buildOptionTile(
              context: ctx,
              icon: Icons.add_shopping_cart,
              title: 'Fazer um novo pedido',
              onTap: () {
                NavigationProvider.navigateTo(
                    context, CategoryScreen(table: table));
              },
            ),
            _buildOptionTile(
              context: ctx,
              icon: Icons.delete_forever,
              title: 'Limpar Mesa',
              onTap: () => _confirmClearTable(context, table),
            ),
            _buildOptionTile(
              context: ctx,
              icon: Icons.payment,
              title: ' Fechar conta ',
              onTap: () {
                NavigationProvider.navigateTo(
                    context, OrderListScreen(table: table));
              },
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
        Navigator.pop(context);
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
            'Tem certeza que deseja limpar a mesa e apagar todos os pedidos abertos?'),
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

    return Consumer<TableProvider>(
      builder: (context, tableProvider, child) {
        if (tableProvider.isLoading) {
          return Center(
              child: CircularProgressIndicator(color: theme.primaryColor));
        }

        if (tableProvider.tables.isEmpty) {
          return const Center(child: Text('Nenhuma mesa cadastrada.'));
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
              final bool isOccupied = table.isOccupied;

              return Card(
                elevation: 4,
                color:
                    isOccupied ? Colors.red : theme.cardColor,
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
                          color: isOccupied
                              ? theme.colorScheme.onSecondary
                              : theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mesa ${table.tableNumber}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isOccupied
                                ? theme.colorScheme.onSecondary
                                : theme.colorScheme.onSurface,
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
  }
}