import 'package:flutter/material.dart';

/// Wrapper que remove o AppBar de uma tela em mobile
/// Mantém a AppBar em desktop via CustomAppBar no DesktopShell
class ResponsiveScreenWrapper extends StatelessWidget {
  final Widget child;
  final bool showAppBarOnMobile;

  const ResponsiveScreenWrapper({
    super.key,
    required this.child,
    this.showAppBarOnMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 800;
    
    // Se for mobile e não quiser mostrar AppBar, remove-o
    if (isMobile && !showAppBarOnMobile) {
      return _RemoveAppBar(child: child);
    }
    
    return child;
  }
}

/// Widget que remove o AppBar de um Scaffold
class _RemoveAppBar extends StatelessWidget {
  final Widget child;

  const _RemoveAppBar({required this.child});

  @override
  Widget build(BuildContext context) {
    // Se child for um Scaffold, remove o appBar
    if (child is Scaffold) {
      final scaffold = child as Scaffold;
      return Scaffold(
        body: scaffold.body,
        drawer: scaffold.drawer,
        floatingActionButton: scaffold.floatingActionButton,
        floatingActionButtonLocation: scaffold.floatingActionButtonLocation,
        bottomNavigationBar: scaffold.bottomNavigationBar,
        backgroundColor: scaffold.backgroundColor,
      );
    }
    
    return child;
  }
}
