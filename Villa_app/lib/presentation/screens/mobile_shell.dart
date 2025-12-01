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

    // --- CORREÇÃO AQUI ---
    // 1. Pega a largura total da tela
    final double screenWidth = MediaQuery.of(context).size.width;

    // 2. Define a largura do drawer.
    // O padrão do Flutter é (largura_da_tela - 56).
    // Vamos definir como 75% da tela.
    // Altere para 0.5 se quiser exatamente a metade.
    final double drawerWidth = screenWidth * 0.75;
    // --- FIM DA CORREÇÃO ---

    return Scaffold(
      appBar: const CustomAppBar(),

      // O menu "hambúrguer" (Drawer)
      drawer: Drawer(
        // --- CORREÇÃO AQUI ---
        // 3. Aplica a largura customizada ao Drawer
        width: drawerWidth,
        // --- FIM DA CORREÇÃO ---
        
        child: SideMenu(), // Reutiliza o mesmo SideMenu!
      ),

      // O corpo da tela
      body: navProvider.currentScreen,
    );
  }
}