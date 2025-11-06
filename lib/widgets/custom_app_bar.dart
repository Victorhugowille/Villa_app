import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/providers/company_provider.dart';
import 'package:villabistromobile/providers/navigation_provider.dart';
// 1. IMPORTE A NOVA TELA DE PERFIL
import 'package:villabistromobile/screens/edit_profile_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();

    return Consumer<CompanyProvider>(
      builder: (context, companyProvider, child) {
        final avatarUrl = companyProvider.avatarUrl;

        return AppBar(
          // --- CORREÇÃO AQUI ---
          // Adicionamos lógica para mostrar o botão de menu
          // quando não for possível "voltar".
          leading: navProvider.canPop
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => navProvider.pop(),
                  tooltip: 'Voltar',
                )
              : Builder(
                  builder: (context) {
                    // Usamos um Builder para pegar o context
                    // que está "abaixo" do Scaffold do MobileShell,
                    // permitindo que o .of(context) encontre o drawer.
                    return IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () {
                        // Comando para abrir o drawer
                        Scaffold.of(context).openDrawer();
                      },
                      tooltip: 'Menu',
                    );
                  },
                ),
          // --- FIM DA CORREÇÃO ---
          title: Text(navProvider.currentTitle),
          centerTitle: true,
          actions: [
            ...navProvider.currentActions,
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  backgroundImage:
                      (avatarUrl != null) ? NetworkImage(avatarUrl) : null,
                  child: (avatarUrl == null)
                      ? const Icon(Icons.person, size: 20)
                      : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}