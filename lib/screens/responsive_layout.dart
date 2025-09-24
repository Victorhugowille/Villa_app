import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/providers/navigation_provider.dart';
import 'package:villabistromobile/providers/table_provider.dart';
import 'package:villabistromobile/screens/kitchen_printer_screen.dart';
import 'package:villabistromobile/screens/management_screen.dart';
import 'package:villabistromobile/screens/printer_model_screen.dart';
import 'package:villabistromobile/screens/table_selection_screen.dart';
import 'package:villabistromobile/screens/theme_management_screen.dart';
import 'package:villabistromobile/screens/transactions_report_screen.dart';
import 'package:villabistromobile/widgets/custom_app_bar.dart';

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                const SideMenu(),
                Expanded(
                  child: Consumer<NavigationProvider>(
                    builder: (context, navigationProvider, child) {
                      return navigationProvider.currentScreen;
                    },
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Seleção de Mesas'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () =>
                      Provider.of<TableProvider>(context, listen: false)
                          .fetchAndSetTables(),
                  tooltip: 'Atualizar Mesas',
                ),
              ],
            ),
            drawer: const SideMenu(),
            body: const TableSelectionScreen(),
          );
        }
      },
    );
  }
}

class TableSelectionScreenWithAppBar extends StatelessWidget {
  const TableSelectionScreenWithAppBar({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Selecionar Mesa',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                Provider.of<TableProvider>(context, listen: false)
                    .fetchAndSetTables(),
            tooltip: 'Atualizar Mesas',
          ),
        ],
      ),
      body: const TableSelectionScreen(),
    );
  }
}

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 4,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: const Text(
              'VillaBistrô',
              style: TextStyle(
                  color: Color.fromARGB(255, 8, 60, 10), fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.table_restaurant),
            title: const Text('Mesas'),
            onTap: () {
              final isDesktop = MediaQuery.of(context).size.width > 800;
              if (isDesktop) {
                Provider.of<NavigationProvider>(context, listen: false)
                    .push(const TableSelectionScreenWithAppBar());
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Movimentação'),
            onTap: () => NavigationProvider.navigateTo(
                context, const TransactionsReportScreen()),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.business_center),
            title: const Text('Gestão'),
            onTap: () =>
                NavigationProvider.navigateTo(context, const ManagementScreen()),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.style),
            title: const Text('Modelos de Impressão'),
            onTap: () =>
                NavigationProvider.navigateTo(context, const PrinterModelScreen()),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.print),
            title: const Text('Estação de Impressão'),
            onTap: () =>
                NavigationProvider.navigateTo(context, const KitchenPrinterScreen()),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.color_lens_outlined),
            title: const Text('Gestão de tema'),
            onTap: () =>
                NavigationProvider.navigateTo(context, const ThemeManagementScreen()),
          ),
        ],
      ),
    );
  }
}