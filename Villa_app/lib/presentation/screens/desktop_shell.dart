// lib/screens/desktop_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/side_menu.dart';

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
                // AppBar customizada que reage ao provider
                const CustomAppBar(),
                Expanded(
                  // Remove AppBar da tela se existir
                  child: _ScreenBodyWrapper(
                    child: navProvider.currentScreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Remove o AppBar de um Scaffold interno para manter consistência
class _ScreenBodyWrapper extends StatelessWidget {
  final Widget child;

  const _ScreenBodyWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    // Se a tela é um Scaffold, extrai apenas o body
    if (child is Scaffold) {
      final scaffold = child as Scaffold;
      return Scaffold(
        body: scaffold.body ?? const SizedBox.shrink(),
        floatingActionButton: scaffold.floatingActionButton,
        floatingActionButtonLocation: scaffold.floatingActionButtonLocation,
        bottomNavigationBar: scaffold.bottomNavigationBar,
        backgroundColor: scaffold.backgroundColor,
      );
    }

    // Se não for Scaffold, renderiza normalmente
    return child;
  }
}