import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/providers/navigation_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const CustomAppBar({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final navProvider = Provider.of<NavigationProvider>(context);

    final bool canPopOnDesktop = isDesktop && navProvider.screenStack.length > 1;

    return AppBar(
      title: Text(title),
      leading: canPopOnDesktop
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => navProvider.pop(),
            )
          : null,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}