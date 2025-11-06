// lib/screens/desktop_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/providers/navigation_provider.dart';
import 'package:villabistromobile/widgets/custom_app_bar.dart';
import 'package:villabistromobile/widgets/side_menu.dart';

class DesktopShell extends StatelessWidget {
  const DesktopShell({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos context.watch para que a tela reconstrua quando a navegação mudar
    final navProvider = context.watch<NavigationProvider>();

    return Scaffold(
      body: Row(
        children: [
          // Menu Lateral Fixo
          const SizedBox(
            width: 280,
            child: SideMenu(),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          // Conteúdo Principal Dinâmico
          Expanded(
            child: Column(
              children: [
                // Nossa AppBar customizada que reage ao provider
                const CustomAppBar(),
                Expanded(
                  // A tela atual é exibida aqui
                  child: navProvider.currentScreen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}