// lib/screens/responsive_layout.dart
import 'package:flutter/material.dart';
import 'desktop_shell.dart';
import 'mobile_shell.dart';

/// Layout responsivo que alterna entre Mobile e Desktop
/// 
/// **Arquitetura de Navegação:**
/// - MOBILE (< 800px): Usa MobileShell com AppBar + Drawer + NavProvider
/// - DESKTOP (>= 800px): Usa DesktopShell com Sidebar fixo + AppBar + NavProvider
/// 
/// **Problema Resolvido:**
/// Anteriormente havia duplicação de AppBar no mobile porque as telas internas
/// tinham seu próprio Scaffold com AppBar. Agora, _ScreenBodyWrapper remove
/// o AppBar das telas internas mantendo apenas o da Shell.
/// 
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({super.key});

  @override
  Widget build(BuildContext context) {
    // Usar LayoutBuilder nos dá as restrições exatas de largura
    // no momento em que o widget é construído. É a forma mais
    // confiável de lidar com redimensionamento de janelas.
    return LayoutBuilder(
      builder: (context, constraints) {
        // Usamos constraints.maxWidth em vez de MediaQuery
        final double screenWidth = constraints.maxWidth;

        if (screenWidth >= 800) {
          // Se for tela grande, usa o DesktopShell (com sidebar fixo)
          return const DesktopShell();
        } else {
          // Se for tela pequena (celular ou janela pequena), usa o MobileShell
          return const MobileShell();
        }
      },
    );
  }
}