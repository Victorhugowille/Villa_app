import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/providers/navigation_provider.dart';
import 'package:villabistromobile/widgets/side_menu.dart';

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;
        final navProvider = Provider.of<NavigationProvider>(context);

        if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                const SideMenu(),
                Expanded(
                  child: Column(
                    children: [
                      AppBar(
                        title: Text(navProvider.currentTitle),
                        automaticallyImplyLeading: false,
                      ),
                      Expanded(
                        child: navProvider.currentScreen,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          // Layout para Mobile
          return Scaffold(
            appBar: AppBar(
              title: Text(navProvider.currentTitle),
            ),
            drawer: const SideMenu(),
            body: navProvider.currentScreen,
          );
        }
      },
    );
  }
}