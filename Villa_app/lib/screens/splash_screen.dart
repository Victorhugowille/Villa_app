import 'package:flutter/material.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart'; // 1. Importar o pacote

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 2. Renomeei a função para mais clareza
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    // Espera por 3 segundos para mostrar a splash screen
    await Future.delayed(const Duration(seconds: 3));

    // 3. Solicitar a permissão da câmera
    await _requestCameraPermission();

    // Navega para a tela de onboarding
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/onboarding');
    }
  }

  // 4. Nova função para pedir a permissão
  Future<void> _requestCameraPermission() async {
    // Solicita a permissão. O pop-up do Android aparecerá aqui.
    await Permission.camera.request();
    
    // Neste ponto, você poderia verificar o status da permissão
    // (se foi concedida, negada, etc.) e tomar ações,
    // mas por enquanto, apenas solicitamos e continuamos.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'VillaBistrô',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(
              color: theme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}