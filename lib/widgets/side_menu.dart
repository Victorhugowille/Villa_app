// lib/widgets/side_menu.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/providers/company_provider.dart';
import 'package:villabistromobile/providers/kds_provider.dart';
import 'package:villabistromobile/providers/navigation_provider.dart';
import 'package:villabistromobile/screens/bot_management_screen.dart';
import 'package:villabistromobile/screens/configuracao/configuracao_screen.dart';
import 'package:villabistromobile/screens/excel_generator_screen.dart';
import 'package:villabistromobile/screens/kds_screen.dart';
import 'package:villabistromobile/screens/management/management_screen.dart';
import 'package:villabistromobile/screens/printer_model_screen.dart';
import 'package:villabistromobile/screens/table_selection_screen.dart';
import 'package:villabistromobile/screens/transactions_report_screen.dart';
import 'package:villabistromobile/screens/whatsapp_screen.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  void _navigateTo(BuildContext context, Widget screen, String title) {
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    if (isDesktop) {
      navProvider.setScreen(screen, title);
    } else {
      Navigator.of(context).pop(); // Fecha o drawer
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => screen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyProvider = context.watch<CompanyProvider>();

    return Drawer(
      elevation: 4,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 20,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Text(
              companyProvider.companyName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.table_restaurant),
            title: const Text('Mesas'),
            onTap: () => _navigateTo(
                context, const TableSelectionScreen(), 'Seleção de Mesas'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.wechat),
            title: const Text('WhatsApp'),
            onTap: () =>
                _navigateTo(context, const WhatsAppWebScreen(), 'WhatsApp'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.view_kanban_outlined),
            title: const Text('Painel de Pedidos (KDS)'),
            onTap: () => _navigateTo(
              context,
              ChangeNotifierProvider(
                create: (_) => KdsProvider(),
                child: const KdsScreen(),
              ),
              'Painel de Pedidos (KDS)',
            ),
          ),
          const Divider(),
          if (companyProvider.role == 'owner') ...[
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Movimentação'),
              onTap: () => _navigateTo(context,
                  const TransactionsReportScreen(), 'Relatório de Movimentação'),
            ),
            const Divider(),
          ],
          ListTile(
            leading: const Icon(Icons.grid_on_outlined),
            title: const Text('Planilhas'),
            onTap: () =>
                _navigateTo(context, const ExcelGeneratorScreen(), 'Planilhas'),
          ),
          const Divider(),
          if (companyProvider.role == 'owner') ...[
            ListTile(
              leading: const Icon(Icons.business_center),
              title: const Text('Gestão'),
              onTap: () =>
                  _navigateTo(context, const ManagementScreen(), 'Gestão'),
            ),
            const Divider(),
          ],
          if (companyProvider.role == 'owner') ...[
            ListTile(
              leading: const Icon(Icons.smart_toy_outlined),
              title: const Text('Robô'),
              onTap: () => _navigateTo(
                  context, const BotManagementScreen(), 'Gerenciamento do Robô'),
            ),
            const Divider(),
          ],
          ListTile(
            leading: const Icon(Icons.print_rounded),
            title: const Text('Impressão'),
            onTap: () => _navigateTo(
                context, const PrinterModelScreen(), 'Modelos de Impressão'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configurações'),
            onTap: () => _navigateTo(
                context, const ConfiguracaoScreen(), 'Configurações'),
          ),
        ],
      ),
    );
  }
}