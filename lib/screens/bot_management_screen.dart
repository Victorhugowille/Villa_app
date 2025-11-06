import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/providers/bot_provider.dart';
// O import do 'side_menu.dart' não é mais necessário aqui
// import 'package:villabistromobile/widgets/side_menu.dart';

class BotManagementScreen extends StatelessWidget {
  const BotManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // final isDesktop = MediaQuery.of(context).size.width > 800; // Não é mais necessário

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

    // --- CORREÇÃO AQUI ---
    // Removemos o 'if (isDesktop)' e o 'Scaffold' extra.
    // Esta tela agora SEMPRE retorna apenas o 'bodyContent'.
    return bodyContent;
  }
}