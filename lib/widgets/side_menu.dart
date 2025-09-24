import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/providers/kds_provider.dart';
import 'package:villabistromobile/providers/navigation_provider.dart';
import 'package:villabistromobile/screens/kds_screen.dart';
import 'package:villabistromobile/screens/kitchen_printer_screen.dart';
import 'package:villabistromobile/screens/management_screen.dart';
import 'package:villabistromobile/screens/printer_model_screen.dart';
import 'package:villabistromobile/screens/table_selection_screen.dart';
import 'package:villabistromobile/screens/theme_management_screen.dart';
import 'package:villabistromobile/screens/transactions_report_screen.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  void _navigateTo(BuildContext context, Widget screen, String title) {
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    if (!isDesktop) {
      Navigator.pop(context);
    }
    navProvider.setScreen(screen, title);
  }

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
            onTap: () => _navigateTo(context, const TableSelectionScreen(), 'Seleção de Mesas'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.view_kanban_outlined),
            title: const Text('Painel de Pedidos (KDS)'),
            onTap: () => _navigateTo(context, 
              ChangeNotifierProvider(
                create: (_) => KdsProvider(),
                child: const KdsScreen(),
              ), 
            'Painel de Pedidos (KDS)'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Movimentação'),
            onTap: () => _navigateTo(context, const TransactionsReportScreen(), 'Relatório de Movimentação'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.business_center),
            title: const Text('Gestão'),
            onTap: () => _navigateTo(context, const ManagementScreen(), 'Gestão'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.style),
            title: const Text('Modelos de Impressão'),
            onTap: () => _navigateTo(context, const PrinterModelScreen(), 'Modelos de Impressão'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.print),
            title: const Text('Estação de Impressão'),
            onTap: () => _navigateTo(context, const KitchenPrinterScreen(), 'Estação de Impressão'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.color_lens_outlined),
            title: const Text('Gestão de tema'),
            onTap: () => _navigateTo(context, const ThemeManagementScreen(), 'Gestão de Tema'),
          ),
        ],
      ),
    );
  }
}