// lib/widgets/custom_app_bar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/providers/navigation_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();

    return AppBar(
      // Botão de voltar que só aparece se houver histórico
      leading: navProvider.canPop
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => navProvider.pop(),
              tooltip: 'Voltar',
            )
          : null, // Sem botão se for a primeira tela
      title: Text(navProvider.currentTitle),
      centerTitle: true,
      actions: [
        // Botão para voltar para a tela inicial
        // Ações dinâmicas da tela atual
        ...navProvider.currentActions,
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}