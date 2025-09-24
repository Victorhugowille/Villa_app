import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/screens/responsive_layout.dart';

class NavigationProvider with ChangeNotifier {
  final List<Widget> _screenStack = [const TableSelectionScreenWithAppBar()];

  List<Widget> get screenStack => _screenStack;
  Widget get currentScreen => _screenStack.last;

  void push(Widget screen) {
    _screenStack.add(screen);
    notifyListeners();
  }

  void pop() {
    if (_screenStack.length > 1) {
      _screenStack.removeLast();
      notifyListeners();
    }
  }

  void popToHome() {
    _screenStack.removeRange(1, _screenStack.length);
    notifyListeners();
  }

  static void navigateTo(BuildContext context, Widget screen) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    if (isDesktop) {
      Provider.of<NavigationProvider>(context, listen: false).push(screen);
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => screen));
    }
  }
}