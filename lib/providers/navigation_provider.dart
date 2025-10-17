import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:villabistromobile/screens/table_selection_screen.dart';

class NavigationProvider with ChangeNotifier {
  // Estado inicial
  Widget _currentScreen = const TableSelectionScreen();
  String _currentTitle = 'Seleção de Mesas';
  List<Widget> _currentActions = [];

  // Histórico para a navegação customizada do Desktop
  final List<Widget> _screenHistory = [const TableSelectionScreen()];
  final List<String> _titleHistory = ['Seleção de Mesas'];
  final List<List<Widget>> _actionsHistory = [[]];

  // Getters públicos
  Widget get currentScreen => _currentScreen;
  String get currentTitle => _currentTitle;
  List<Widget> get currentActions => _currentActions;

  bool get canPop => _screenHistory.length > 1;

  void navigateTo(BuildContext context, Widget screen, String title) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    if (isDesktop) {
      // No DESKTOP: Atualiza o estado e adiciona ao histórico customizado
      _currentScreen = screen;
      _currentTitle = title;
      _currentActions = []; // Limpa ações da tela anterior

      _screenHistory.add(screen);
      _titleHistory.add(title);
      _actionsHistory.add([]); // Adiciona um placeholder para as ações

      notifyListeners();
    } else {
      // ===================================================================
      // CORREÇÃO AQUI (PARA O CELULAR)
      // ===================================================================
      // Usamos Scaffold.maybeOf() para verificar se há um drawer de forma segura.
      final scaffoldState = Scaffold.maybeOf(context);
      if (scaffoldState != null && scaffoldState.isDrawerOpen) {
        Navigator.of(context).pop(); // Fecha o menu apenas se ele existir e estiver aberto
      }
      
      // A navegação continua como antes, empurrando a nova tela.
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => screen,
        ),
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