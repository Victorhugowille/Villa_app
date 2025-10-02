// lib/screens/responsive_layout.dart
import 'package:flutter/material.dart';
import 'package:villabistromobile/screens/main_screen.dart';
import 'package:villabistromobile/screens/table_selection_screen.dart';

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > 800) {
      return const MainScreen();
    } else {
      return const TableSelectionScreen();
    }
  }
}