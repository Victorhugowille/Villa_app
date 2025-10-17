import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:villabistromobile/providers/company_provider.dart';
import 'package:villabistromobile/providers/navigation_provider.dart';
import 'package:villabistromobile/screens/configuracao/company_requests_screen.dart';
import 'package:villabistromobile/screens/configuracao/company_screen.dart';
// ADICIONE ESTE IMPORT
import 'package:villabistromobile/screens/configuracao/destaques_site_screen.dart';
import 'package:villabistromobile/screens/configuracao/delivery_zones_screen.dart';
import 'package:villabistromobile/screens/configuracao/pending_requests_screen.dart';
import 'package:villabistromobile/screens/management/theme_management_screen.dart';
import 'package:villabistromobile/widgets/side_menu.dart';

class ConfiguracaoScreen extends StatelessWidget {
  const ConfiguracaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserEmail = Supabase.instance.client.auth.currentUser?.email;
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    
    final isDesktop = MediaQuery.of(context).size.width > 800;

    Widget bodyContent = Consumer<CompanyProvider>(
      builder: (context, companyProvider, child) {
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            const Divider(),
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Dados do Estabelecimento'),
              subtitle: const Text('Atualize as informações da sua empresa'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                navProvider.navigateTo(
                  context,
                  const CompanyScreen(),
                  'Dados do Estabelecimento',
                );
              },
            ),
            const Divider(),

            // ### NOVO ITEM ADICIONADO AQUI ###
            if (companyProvider.role == 'owner')
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Destaques do Site'),
                subtitle: const Text('Gerencie as imagens do carrossel'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  navProvider.navigateTo(
                    context,
                    const DestaquesSiteScreen(),
                    'Destaques do Site',
                  );
                },
              ),
            if (companyProvider.role == 'owner') const Divider(),
            // ### FIM DO NOVO ITEM ###

            if (companyProvider.role == 'owner')
              ListTile(
                leading: const Icon(Icons.map_outlined),
                title: const Text('Zonas de Entrega'),
                subtitle: const Text('Gerencie as áreas e taxas de delivery'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  navProvider.navigateTo(
                    context,
                    const DeliveryZonesScreen(),
                    'Zonas de Entrega',
                  );
                },
              ),
            if (companyProvider.role == 'owner') const Divider(),
            if (companyProvider.role == 'owner')
              ListTile(
                leading: const Icon(Icons.person_add_alt_1),
                title: const Text('Solicitações de Acesso'),
                subtitle: const Text('Aprove ou reprove novos usuários'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  navProvider.navigateTo(
                    context,
                    const PendingRequestsScreen(),
                    'Solicitações de Acesso',
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
                  navProvider.navigateTo(
                    context,
                    const CompanyRequestsScreen(),
                    'Gerenciar Novas Empresas',
                  );
                },
              ),
            if (currentUserEmail == 'victorhugowille@gmail.com') const Divider(),
            ListTile(
              leading: const Icon(Icons.color_lens),
              title: const Text('Aparência'),
              subtitle: const Text('Personalize as cores do seu app'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                navProvider.navigateTo(
                  context,
                  const ThemeManagementScreen(),
                  'Gestão de Temas',
                );
              },
            ),
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