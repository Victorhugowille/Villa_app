// lib/widgets/side_menu.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/providers/auth_provider.dart';
import 'package:villabistromobile/providers/company_provider.dart';
import 'package:villabistromobile/providers/navigation_provider.dart';
import 'package:villabistromobile/screens/bot_management_screen.dart';
import 'package:villabistromobile/screens/configuracao/configuracao_screen.dart';
import 'package:villabistromobile/screens/google_sheets_screen.dart';
import 'package:villabistromobile/screens/kds_screen.dart';
import 'package:villabistromobile/screens/management/management_screen.dart';
import 'package:villabistromobile/screens/print/printer_model_screen.dart';
import 'package:villabistromobile/screens/table_selection_screen.dart';
import 'package:villabistromobile/screens/transactions_report_screen.dart';
import 'package:villabistromobile/screens/whatsapp_screen.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final companyProvider = context.watch<CompanyProvider>();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Usamos listen: false aqui, pois só precisamos chamar a função
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);

    String roleText;
    switch (companyProvider.role) {
      case 'owner': roleText = 'Dono'; break;
      case 'employee': roleText = 'Funcionário'; break;
      default: roleText = 'Usuário';
    }

    return Drawer(
      elevation: 4,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 20, 20, 20),
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    companyProvider.companyName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    roleText,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.table_restaurant),
                  title: const Text('Mesas'),
                  onTap: () => navProvider.navigateTo(
                    context,
                    const TableSelectionScreen(),
                    'Seleção de Mesas',
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.wechat),
                  title: const Text('WhatsApp'),
                  onTap: () => navProvider.navigateTo(
                    context,
                    const WhatsAppWebScreen(),
                    'WhatsApp',
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.view_kanban_outlined),
                  title: const Text('Painel de Pedidos (KDS)'),
                  onTap: () => navProvider.navigateTo(
                    context,
                    const KdsScreen(),
                    'Painel de Pedidos (KDS)',
                  ),
                ),
                const Divider(),
                if (companyProvider.role == 'owner') ...[
                  ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: const Text('Movimentação'),
                    onTap: () => navProvider.navigateTo(
                      context,
                      const TransactionsReportScreen(),
                      'Relatório de Movimentação',
                    ),
                  ),
                  const Divider(),
                ],
                ListTile(
                  leading: const Icon(Icons.grid_on_outlined),
                  title: const Text('Planilhas'),
                  onTap: () => navProvider.navigateTo(
                    context,
                    const GoogleSheetsScreen(),
                    'Planilhas',
                  ),
                ),
                const Divider(),
                if (companyProvider.role == 'owner') ...[
                  ListTile(
                    leading: const Icon(Icons.business_center),
                    title: const Text('Gestão'),
                    onTap: () => navProvider.navigateTo(
                      context,
                      const ManagementScreen(),
                      'Gestão',
                    ),
                  ),
                  const Divider(),
                ],
                if (companyProvider.role == 'owner') ...[
                  ListTile(
                    leading: const Icon(Icons.smart_toy_outlined),
                    title: const Text('Robô'),
                    onTap: () => navProvider.navigateTo(
                      context,
                      const BotManagementScreen(),
                      'Gerenciamento do Robô',
                    ),
                  ),
                  const Divider(),
                ],
                ListTile(
                  leading: const Icon(Icons.print_rounded),
                  title: const Text('Impressão'),
                  onTap: () => navProvider.navigateTo(
                    context,
                    const PrinterModelScreen(),
                    'Modelos de Impressão',
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Configurações'),
                  onTap: () => navProvider.navigateTo(
                    context,
                    const ConfiguracaoScreen(),
                    'Configurações',
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: ListTile(
              leading: Icon(Icons.logout, color: Colors.red.shade400),
              title: Text(
                'Sair da Conta',
                style: TextStyle(color: Colors.red.shade400),
              ),
              onTap: () {
                authProvider.signOut();
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (route) => false);
              },
            ),
          ),
        ],
      ),
    );
  }
}