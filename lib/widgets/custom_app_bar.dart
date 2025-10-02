// lib/widgets/custom_app_bar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/providers/navigation_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;

  const CustomAppBar({super.key, this.actions});

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return AppBar(
      // Damos uma cor sutil para separar do conteúdo
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 1,
      // Força o AppBar a não adicionar um botão de menu/voltar sozinho
      automaticallyImplyLeading: false,
      
      // Título volta a ficar na posição padrão
      title: Text(navProvider.currentTitle),

      // O botão de voltar customizado para o desktop
      leading: isDesktop && navProvider.canPop
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Voltar',
              onPressed: () => navProvider.pop(),
            )
          : null, // No mobile ou na primeira tela, não mostra nada
      
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}