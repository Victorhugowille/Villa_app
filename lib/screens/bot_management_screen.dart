import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/providers/bot_provider.dart';

class BotManagementScreen extends StatelessWidget {
  const BotManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
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
      ),
    );
  }
}