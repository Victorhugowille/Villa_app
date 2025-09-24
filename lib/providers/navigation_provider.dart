import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/screens/table_selection_screen.dart';

class NavigationProvider with ChangeNotifier {
  Widget _currentScreen = const TableSelectionScreen();
  String _currentTitle = 'Seleção de Mesas';
  final List<Widget> _screenHistory = [const TableSelectionScreen()];
  final List<String> _titleHistory = ['Seleção de Mesas'];

  Widget get currentScreen => _currentScreen;
  String get currentTitle => _currentTitle;
  bool get canPop => _screenHistory.length > 1;

  void navigateTo(BuildContext context, Widget screen, String title) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    if (isDesktop) {
      _currentScreen = screen;
      _currentTitle = title;
      _screenHistory.add(screen);
      _titleHistory.add(title);
      notifyListeners();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screen),
      );
    }
  }

  void pop(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    if (isDesktop) {
      if (canPop) {
        _screenHistory.removeLast();
        _titleHistory.removeLast();
        _currentScreen = _screenHistory.last;
        _currentTitle = _titleHistory.last;
        notifyListeners();
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  void popToHome() {
    if (_screenHistory.length > 1) {
      _screenHistory.removeRange(1, _screenHistory.length);
      _titleHistory.removeRange(1, _titleHistory.length);
      _currentScreen = _screenHistory.first;
      _currentTitle = _titleHistory.first;
      notifyListeners();
    }
  }

  void setScreen(Widget screen, String title) {
    _screenHistory.clear();
    _titleHistory.clear();
    
    _currentScreen = screen;
    _currentTitle = title;

    _screenHistory.add(_currentScreen);
    _titleHistory.add(_currentTitle);
    
    notifyListeners();
  }
}