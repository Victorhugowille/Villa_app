// lib/providers/sound_provider.dart
/*
import 'dart:io'; // Necessário para Platform.isWindows
import 'package:flutter/foundation.dart'; // Para ChangeNotifier e debugPrint
import 'package:shared_preferences/shared_preferences.dart';
import 'package:win32/win32.dart'; // Import necessário para MessageBeep

// Enum OrderType não é mais necessário se o som é o mesmo
// enum OrderType { mesa, delivery }

class SoundProvider with ChangeNotifier {
  // Não precisamos mais de AudioPlayer ou Soundpool

  bool _isSoundStation = false;
  bool _soundEnabled = true; // Flag para habilitar/desabilitar o som geral

  bool get isSoundStation => _isSoundStation;
  bool get soundEnabled => _soundEnabled;

  SoundProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Carrega apenas as flags relevantes
    final prefs = await SharedPreferences.getInstance();
    _isSoundStation = prefs.getBool('isSoundStation') ?? false;
    _soundEnabled = prefs.getBool('soundEnabled') ?? true; // Som habilitado por padrão
    notifyListeners();
  }

  // Simplificado: Salva apenas as flags
  Future<void> saveSettings({bool? isSoundStation, bool? soundEnabled}) async {
    final prefs = await SharedPreferences.getInstance();
    bool changed = false;
    if (isSoundStation != null && _isSoundStation != isSoundStation) {
      _isSoundStation = isSoundStation;
      await prefs.setBool('isSoundStation', _isSoundStation);
      changed = true;
    }
    if (soundEnabled != null && _soundEnabled != soundEnabled) {
      _soundEnabled = soundEnabled;
      await prefs.setBool('soundEnabled', _soundEnabled);
      changed = true;
    }
    if (changed) notifyListeners();
  }

  // Renomeado para refletir a mudança
  Future<void> setIsSoundStation(bool isStation) async {
    await saveSettings(isSoundStation: isStation);
  }

  // Nova função para habilitar/desabilitar o som
  Future<void> setSoundEnabled(bool enabled) async {
    await saveSettings(soundEnabled: enabled);
  }

  // ### FUNÇÃO playSoundForOrder ATUALIZADA PARA win32 ###
  Future<void> playSoundForOrder(/* OrderType type - Não é mais necessário */) async {
    // Verifica se é Windows, se está habilitado e se é a estação de som
    if (!Platform.isWindows || !_soundEnabled || !_isSoundStation) {
      debugPrint("SoundProvider: Som ignorado (Windows: ${Platform.isWindows}, Habilitado: $_soundEnabled, Estação: $_isSoundStation).");
      return;
    }

    try {
      debugPrint("SoundProvider: Tentando tocar som de notificação padrão do Windows...");
      // MB_OK é o tipo de som mais comum para notificações simples
      // Outras opções: MB_ICONINFORMATION, MB_ICONWARNING, MB_ICONERROR, MB_ICONQUESTION
      MessageBeep(MB_ICONINFORMATION);
      debugPrint("SoundProvider: Comando MessageBeep(MB_OK) enviado.");
    } catch (e) {
      // É muito raro MessageBeep falhar, mas adicionamos por segurança
      debugPrint("!!!! ERRO AO TOCAR SOM DO SISTEMA (MessageBeep) !!!!");
      debugPrint("SoundProvider: Falha ao enviar comando MessageBeep. Erro: $e");
      debugPrint("--- VERIFIQUE AS CONFIGURAÇÕES DE SOM DO WINDOWS ---");
    }
  }

  // ### FUNÇÃO playTestSound ATUALIZADA PARA win32 ###
  Future<void> playTestSound() async {
     if (!Platform.isWindows || !_soundEnabled || !_isSoundStation) {
      debugPrint("SoundProvider: Som de teste ignorado (Windows: ${Platform.isWindows}, Habilitado: $_soundEnabled, Estação: $_isSoundStation).");
      // Você pode mostrar um SnackBar aqui informando o motivo
      return;
    }

    // Não precisamos mais do soundPath

    try {
      debugPrint("SoundProvider: Tentando tocar som de teste padrão do Windows...");
      MessageBeep(MB_ICONINFORMATION);
      debugPrint("SoundProvider: Comando MessageBeep(MB_OK) (teste) enviado.");
    } catch (e) {
      debugPrint("!!!! ERRO AO TOCAR SOM DE TESTE (MessageBeep) !!!!");
      debugPrint("SoundProvider: Falha ao enviar comando MessageBeep. Erro: $e");
      debugPrint("--- VERIFIQUE AS CONFIGURAÇÕES DE SOM DO WINDOWS ---");
      // Mostrar um SnackBar de erro aqui seria útil
    }
  }

  // dispose() não é mais necessário para win32
}*/