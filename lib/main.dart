import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:villabistromobile/providers/cart_provider.dart';
import 'package:villabistromobile/providers/navigation_provider.dart'; // Importe o provider
import 'package:villabistromobile/providers/printer_provider.dart';
import 'package:villabistromobile/providers/product_provider.dart';
import 'package:villabistromobile/providers/table_provider.dart';
import 'package:villabistromobile/providers/transaction_provider.dart';
import 'package:villabistromobile/providers/theme_provider.dart';
import 'package:villabistromobile/screens/splash_screen.dart';
import 'package:villabistromobile/screens/login_screen.dart';
import 'package:villabistromobile/screens/onboarding_screen.dart';
import 'package:villabistromobile/screens/responsive_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://fhbxegpnztkzqxpkbgkx.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZoYnhlZ3BuenRrenF4cGtiZ2t4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgyODU4OTMsImV4cCI6MjA3Mzg2MTg5M30.SIEamzBeh_NcOIes-ULqU0RjGV1u3w8NCdgKTACoLjI',
  );

  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(create: (context) => TableProvider()),
        ChangeNotifierProvider(create: (context) => ProductProvider()),
        ChangeNotifierProvider(create: (context) => TransactionProvider()),
        ChangeNotifierProvider(create: (context) => PrinterProvider()),
        
        // ADICIONE ESTA LINHA FALTANTE
        ChangeNotifierProvider(create: (context) => NavigationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'VILLABISTROMOBILE',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.getTheme,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('pt', 'BR'),
          ],
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/onboarding': (context) => const OnboardingScreen(),
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const ResponsiveLayout(),
          },
        );
      },
    );
  }
}