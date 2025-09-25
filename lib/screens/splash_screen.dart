import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    // Aguarda um momento para a splash screen ser visível
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Verifica se o Onboarding já foi visto
    final prefs = await SharedPreferences.getInstance();
    final bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

    // Verifica se há uma sessão de usuário ativa
    final session = Supabase.instance.client.auth.currentSession;

    if (!seenOnboarding) {
      // Se nunca viu o onboarding, vai para a tela de onboarding
      Navigator.of(context).pushReplacementNamed('/onboarding');
    } else if (session == null) {
      // Se já viu o onboarding mas não está logado, vai para o login
      Navigator.of(context).pushReplacementNamed('/login');
    } else {
      // Se já viu o onboarding e está logado, vai direto para a home
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Image.asset('assets/images/splash_unificado.png'),
      ),
    );
  }
}