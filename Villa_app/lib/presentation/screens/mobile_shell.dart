// lib/screens/mobile_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/side_menu.dart';

class MobileShell extends StatelessWidget {
  const MobileShell({super.key});

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();

    // Pega a largura total da tela
    final double screenWidth = MediaQuery.of(context).size.width;

    // Define a largura do drawer como 75% da tela
    final double drawerWidth = screenWidth * 0.75;

    return Scaffold(
      appBar: const CustomAppBar(),
      drawer: Drawer(
        width: drawerWidth,
        child: SideMenu(),
      ),
      // O corpo: renderiza a tela atual direto
      body: navProvider.currentScreen,
    );
  }
}