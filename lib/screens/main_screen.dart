// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/providers/navigation_provider.dart';
import 'package:villabistromobile/widgets/custom_app_bar.dart';
import 'package:villabistromobile/widgets/side_menu.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();

    return Scaffold(
      body: Row(
        children: [
          const SizedBox(
            width: 280,
            child: SideMenu(),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: Column(
              children: [
                CustomAppBar(
                  actions: navProvider.currentActions,
                ),
                Expanded(
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