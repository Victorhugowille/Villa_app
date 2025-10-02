// lib/providers/navigation_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:villabistromobile/screens/table_selection_screen.dart';

class NavigationProvider with ChangeNotifier {
  Widget _currentScreen = const TableSelectionScreen();
  String _currentTitle = 'Seleção de Mesas';
  List<Widget>? _currentActions;

  final List<Widget> _screenHistory = [const TableSelectionScreen()];
  final List<String> _titleHistory = ['Seleção de Mesas'];
  final List<List<Widget>?> _actionsHistory = [null];

  Widget get currentScreen => _currentScreen;
  String get currentTitle => _currentTitle;
  List<Widget>? get currentActions => _currentActions;
  bool get canPop => _screenHistory.length > 1;

  void navigateTo(BuildContext context, Widget screen, String title) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    if (isDesktop) {
      _currentScreen = screen;
      _currentTitle = title;
      _currentActions = null;

      _screenHistory.add(screen);
      _titleHistory.add(title);
      _actionsHistory.add(null);

      notifyListeners();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screen),
      );
    }
  }

  void pop() {
    if (canPop) {
      _screenHistory.removeLast();
      _titleHistory.removeLast();
      _actionsHistory.removeLast();

      _currentScreen = _screenHistory.last;
      _currentTitle = _titleHistory.last;
      _currentActions = _actionsHistory.last;
      notifyListeners();
    }
  }
  void popToHome() {
    if (canPop) {
      _screenHistory.clear();
      _titleHistory.clear();
      _actionsHistory.clear();

      _currentScreen = const TableSelectionScreen();
      _currentTitle = 'Seleção de Mesas';
      _currentActions = null;

      _screenHistory.add(_currentScreen);
      _titleHistory.add(_currentTitle);
      _actionsHistory.add(null);

      notifyListeners();
    }
  }

  void setScreen(Widget screen, String title) {
    _screenHistory.clear();
    _titleHistory.clear();
    _actionsHistory.clear();

    _currentScreen = screen;
    _currentTitle = title;
    _currentActions = null;

    _screenHistory.add(_currentScreen);
    _titleHistory.add(_currentTitle);
    _actionsHistory.add(null);

    notifyListeners();
  }

  void setScreenActions(List<Widget> actions) {
    if (listEquals(_currentActions, actions)) return;

    _currentActions = actions;
    if (_actionsHistory.isNotEmpty) {
      _actionsHistory[_actionsHistory.length - 1] = actions;
    }
    notifyListeners();
  }
}