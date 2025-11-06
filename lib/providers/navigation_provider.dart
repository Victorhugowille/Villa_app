import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:villabistromobile/screens/table_selection_screen.dart';

class NavigationProvider with ChangeNotifier {
  // Estado inicial
  Widget _currentScreen = const TableSelectionScreen();
  String _currentTitle = 'Seleção de Mesas';
  List<Widget> _currentActions = [];

  // Histórico para a navegação customizada
  final List<Widget> _screenHistory = [const TableSelectionScreen()];
  final List<String> _titleHistory = ['Seleção de Mesas'];
  final List<List<Widget>> _actionsHistory = [[]];

  // Getters públicos
  Widget get currentScreen => _currentScreen;
  String get currentTitle => _currentTitle;
  List<Widget> get currentActions => _currentActions;

  bool get canPop => _screenHistory.length > 1;

  // --- CORREÇÃO AQUI ---
  // Adicionamos um parâmetro opcional {bool isRootNavigation = false}
  void navigateTo(
    BuildContext context,
    Widget screen,
    String title, {
    bool isRootNavigation = false, // <-- NOVO PARÂMETRO
  }) {
    
    // 1. Fecha o drawer (só vai executar no Mobile)
    final scaffoldState = Scaffold.maybeOf(context);
    if (scaffoldState != null && scaffoldState.isDrawerOpen) {
      Navigator.of(context).pop(); // Fecha o menu
    }

    // 2. --- LÓGICA ATUALIZADA ---
    // Se for uma navegação "raiz" (vinda do Drawer),
    // limpamos o histórico.
    if (isRootNavigation) {
      _screenHistory.clear();
      _titleHistory.clear();
      _actionsHistory.clear();
    }

    // 3. Adiciona a nova tela ao histórico (que pode estar limpo ou não)
    _currentScreen = screen;
    _currentTitle = title;
    _currentActions = []; 

    _screenHistory.add(screen);
    _titleHistory.add(title);
    _actionsHistory.add([]);

    notifyListeners();
  }

  // O pop() continua igual.
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
      final homeScreen = _screenHistory.first;
      final homeTitle = _titleHistory.first;
      final homeActions = _actionsHistory.first;

      _screenHistory.clear();
      _titleHistory.clear();
      _actionsHistory.clear();

      _screenHistory.add(homeScreen);
      _titleHistory.add(homeTitle);
      _actionsHistory.add(homeActions);

      _currentScreen = homeScreen;
      _currentTitle = homeTitle;
      _currentActions = homeActions;
      
      notifyListeners();
    }
  }

  void setScreenActions(List<Widget> actions) {
    if (listEquals(_currentActions, actions)) return;

    _currentActions = actions;
    if (_actionsHistory.isNotEmpty) {
      _actionsHistory.last = actions;
    }
    notifyListeners();
  }
}