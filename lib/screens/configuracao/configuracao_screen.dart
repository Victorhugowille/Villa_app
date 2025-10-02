import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:villabistromobile/providers/company_provider.dart';
import 'package:villabistromobile/screens/configuracao/company_requests_screen.dart';
import 'package:villabistromobile/screens/configuracao/estabelecimento_screen.dart';
import 'package:villabistromobile/screens/configuracao/pending_requests_screen.dart';
import 'package:villabistromobile/widgets/side_menu.dart';

class ConfiguracaoScreen extends StatelessWidget {
  const ConfiguracaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final currentUserEmail = Supabase.instance.client.auth.currentUser?.email;

    Widget bodyContent = Consumer<CompanyProvider>(
      builder: (context, companyProvider, child) {
        return ListView(
          children: [
            const Divider(),
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Dados do Estabelecimento'),
              subtitle:
                  const Text('Atualize as informações do seu estabelecimento'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EstabelecimentoScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            if (companyProvider.role == 'owner')
              ListTile(
                leading: const Icon(Icons.person_add_alt_1),
                title: const Text('Solicitações de Acesso'),
                subtitle: const Text('Aprove ou reprove novos usuários'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PendingRequestsScreen(),
                    ),
                  );
                },
              ),
            if (companyProvider.role == 'owner') const Divider(),
            if (currentUserEmail == 'victorhugowille@gmail.com')
              ListTile(
                leading: const Icon(Icons.business_center),
                title: const Text('Gerenciar Novas Empresas'),
                subtitle: const Text('Aprovar ou recusar novas empresas no app'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CompanyRequestsScreen(),
                    ),
                  );
                },
              ),
            if (currentUserEmail == 'victorhugowille@gmail.com')
              const Divider(),
          ],
        );
      },
    );

    if (isDesktop) {
      return bodyContent;
    } else {
      return Scaffold(
        drawer: const SideMenu(),
        appBar: AppBar(
          title: const Text('Configurações'),
        ),
        body: bodyContent,
      );
    }
  }
}