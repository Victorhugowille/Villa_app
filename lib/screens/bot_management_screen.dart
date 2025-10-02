// lib/screens/bot_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/providers/bot_provider.dart';
import 'package:villabistromobile/widgets/side_menu.dart';

class BotManagementScreen extends StatelessWidget {
  const BotManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    Widget bodyContent = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Consumer<BotProvider>(
        builder: (context, botProvider, child) {
          return SwitchListTile(
            title: const Text('Ativar Robô de Atendimento'),
            subtitle: Text(
              botProvider.isBotActive
                  ? 'O robô responderá automaticamente às mensagens.'
                  : 'O robô está desativado. As mensagens precisarão de resposta manual.',
            ),
            value: botProvider.isBotActive,
            onChanged: (bool value) {
              botProvider.toggleBotStatus(value);
            },
          );
        },
      ),
    );

    if (isDesktop) {
      return bodyContent;
    } else {
      return Scaffold(
        drawer: const SideMenu(),
        appBar: AppBar(
          title: const Text('Gerenciamento do Robô'),
        ),
        body: bodyContent,
      );
    }
  }
}