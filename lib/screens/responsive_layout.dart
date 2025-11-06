// lib/screens/responsive_layout.dart
import 'package:flutter/material.dart';
import 'package:villabistromobile/screens/desktop_shell.dart';
import 'package:villabistromobile/screens/mobile_shell.dart';

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

        if (screenWidth > 800) {
          // Se for tela grande, usa o DesktopShell (com menu lateral fixo)
          return const DesktopShell();
        } else {
          // Se for tela pequena (celular ou janela pequena), usa o MobileShell
          return const MobileShell();
        }
      },
    );
  }
}