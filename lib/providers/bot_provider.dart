import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BotProvider with ChangeNotifier {
  bool _isBotActive = false;
  static const String _botStatusKey = 'bot_status';

  bool get isBotActive => _isBotActive;

  BotProvider() {
    loadBotStatus();
  }

  Future<void> loadBotStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isBotActive = prefs.getBool(_botStatusKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleBotStatus(bool value) async {
    _isBotActive = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_botStatusKey, _isBotActive);
    notifyListeners();
  }
}