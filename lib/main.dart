import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:villabistromobile/providers/cart_provider.dart';
import 'package:villabistromobile/providers/navigation_provider.dart';
import 'package:villabistromobile/providers/printer_provider.dart';
import 'package:villabistromobile/providers/product_provider.dart';
import 'package:villabistromobile/providers/table_provider.dart';
import 'package:villabistromobile/providers/transaction_provider.dart';
import 'package:villabistromobile/providers/theme_provider.dart';
import 'package:villabistromobile/providers/kds_provider.dart';
import 'package:villabistromobile/screens/splash_screen.dart';
import 'package:villabistromobile/screens/login/login_screen.dart';
import 'package:villabistromobile/screens/onboarding_screen.dart';
import 'package:villabistromobile/screens/responsive_layout.dart';
import 'package:villabistromobile/providers/report_provider.dart';
import 'package:villabistromobile/providers/saved_report_provider.dart';
import 'package:villabistromobile/providers/spreadsheet_provider.dart';
import 'package:villabistromobile/providers/bot_provider.dart';
import 'package:villabistromobile/providers/estabelecimento_provider.dart';
import 'package:villabistromobile/providers/company_provider.dart';
import 'package:villabistromobile/providers/auth_provider.dart';


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
        ChangeNotifierProvider(create: (context) => ProductProvider(context)),
        ChangeNotifierProvider(create: (context) => TransactionProvider()),
        ChangeNotifierProvider(create: (context) => PrinterProvider()),
        ChangeNotifierProvider(create: (context) => KdsProvider()),
        ChangeNotifierProvider(create: (context) => ReportProvider()),
        ChangeNotifierProvider(create: (context) => SavedReportProvider()),
        ChangeNotifierProvider(create: (context) => SpreadsheetProvider()),
        ChangeNotifierProvider(create: (context) => NavigationProvider()),
        ChangeNotifierProvider(create: (context) => BotProvider()),
        ChangeNotifierProvider(create: (context) => EstabelecimentoProvider()),
        ChangeNotifierProvider(create: (context) => CompanyProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
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