// lib/screens/print/print_model_screen.dart
import 'package:flutter/material.dart';
import 'package:villabistromobile/screens/print/kitchen_printer_screen.dart';
import 'package:villabistromobile/screens/print/print_model_conferencia_screen.dart';
import 'package:villabistromobile/screens/print/print_model_cupom_cliente_screen.dart';
import 'package:villabistromobile/screens/print/print_model_destinos_screen.dart';
import 'package:villabistromobile/screens/print/print_model_pedido_cozinha_screen.dart';

class PrinterModelScreen extends StatelessWidget {
  const PrinterModelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Definimos as abas e seu conteúdo correspondente.
    final tabs = [
      const Tab(icon: Icon(Icons.print), text: 'Destinos'),
      const Tab(icon: Icon(Icons.dvr), text: 'Estação'),
      const Tab(icon: Icon(Icons.receipt), text: 'Conferência'),
      const Tab(icon: Icon(Icons.receipt_long), text: 'Cupom Cliente'),
      const Tab(icon: Icon(Icons.kitchen), text: 'Pedido Cozinha'),
    ];

    final tabViews = [
      const CategoryPrinterSettingsTab(),
      const KitchenPrinterScreen(),
      const ConferencePrinterSettingsTab(),
      const ReceiptLayoutEditorTab(),
      const KitchenLayoutEditorTab(),
    ];

    // MUDANÇA PRINCIPAL:
    // O widget agora retorna APENAS o controlador de abas e seu conteúdo.
    // Ele não contém Scaffold, AppBar ou a lógica de 'isDesktop'.
    // Isso o torna um "widget de conteúdo" reutilizável.
    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          // A barra de abas fica no topo do conteúdo.
          Container(
            // Adiciona uma cor de fundo para consistência visual.
            color: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
            child: TabBar(
              isScrollable: true, // Permite rolar as abas em telas menores.
              tabs: tabs,
            ),
          ),
          // A área de visualização das abas preenche o resto do espaço.
          Expanded(
            child: TabBarView(children: tabViews),
          ),
        ],
      ),
    );
  }
}