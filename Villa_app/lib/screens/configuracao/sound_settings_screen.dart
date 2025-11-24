/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/providers/sound_provider.dart';

class SoundSettingsScreen extends StatelessWidget {
  const SoundSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuração de Som'),
      ),
      body: Consumer<SoundProvider>(
        builder: (context, soundProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- SWITCH DA ESTAÇÃO DE SOM ---
              SwitchListTile(
                title: const Text('Ativar Estação de Som'),
                subtitle: const Text(
                    'Ative APENAS no computador principal onde o som deve tocar.'),
                value: soundProvider.isSoundStation,
                onChanged: (value) {
                  soundProvider.setIsSoundStation(value);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(value
                        ? 'Estação de som ATIVADA neste dispositivo.'
                        : 'Estação de som DESATIVADA neste dispositivo.'),
                    backgroundColor: value ? Colors.green : Colors.orange,
                  ));
                },
              ),
              const Divider(height: 20),

              // --- SWITCH PARA HABILITAR/DESABILITAR SOM ---
              SwitchListTile(
                title: const Text('Habilitar Som de Notificação'),
                subtitle: const Text(
                    'Toca o som padrão do Windows para novos pedidos.'),
                value: soundProvider.soundEnabled,
                onChanged: (value) {
                  soundProvider.setSoundEnabled(value);
                },
              ),
              const Divider(height: 20),

              // --- BOTÃO DE TESTE ---
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Testar Som'),
                  // Desabilita se o som estiver desabilitado ou não for estação
                  onPressed: soundProvider.soundEnabled && soundProvider.isSoundStation
                      ? () => soundProvider.playTestSound()
                      : null,
                ),
              ),
              const SizedBox(height: 30),

              // --- MENSAGEM BETA ---
              const Center(
                child: Text(
                  'Usando som de notificação padrão do Windows.\nVolume controlado pelo sistema operacional.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}*/