import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) => setState(() => _currentPage = page),
                children: [
                  _buildPage(theme: theme, imagePath: 'assets/images/onboarding1.png', title: 'Bem-vindo ao VillaBistrô', description: 'Gerencie suas mesas e pedidos de forma rápida e eficiente.'),
                  _buildPage(theme: theme, imagePath: 'assets/images/onboarding2.png', title: 'Controle Total', description: 'Acompanhe o status de cada mesa e o andamento dos pedidos em tempo real.'),
                  _buildPage(theme: theme, imagePath: 'assets/images/onboarding3.png', title: 'Tudo Pronto!', description: 'Vamos começar a otimizar o seu atendimento.'),
                ],
              ),
            ),
            _buildBottomControls(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(onPressed: () => Navigator.of(context).pushReplacementNamed('/login'), child: Text('PULAR', style: TextStyle(color: theme.colorScheme.onBackground))),
          Row(children: List.generate(3, (index) => _buildDot(index, theme))),
          ElevatedButton(
            onPressed: () {
              if (_currentPage == 2) {
                Navigator.of(context).pushReplacementNamed('/login');
              } else {
                _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: theme.colorScheme.onPrimary, shape: const CircleBorder(), padding: const EdgeInsets.all(16)),
            child: const Icon(Icons.arrow_forward_ios),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index, ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 5),
      height: 10,
      width: _currentPage == index ? 20 : 10,
      decoration: BoxDecoration(color: _currentPage == index ? theme.primaryColor : Colors.grey, borderRadius: BorderRadius.circular(5)),
    );
  }

  Widget _buildPage({required ThemeData theme, required String imagePath, required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, height: 250),
          const SizedBox(height: 40),
          Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onBackground)),
          const SizedBox(height: 16),
          Text(description, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: theme.colorScheme.onBackground.withOpacity(0.8))),
        ],
      ),
    );
  }
}