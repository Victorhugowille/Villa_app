import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // <--- 1. Importar
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// PROVIDERS
import 'providers/auth_provider.dart';
import 'providers/bot_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/company_provider.dart';
import 'providers/kds_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/printer_provider.dart';
import 'providers/product_provider.dart';
import 'providers/report_provider.dart';
import 'providers/table_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/transaction_provider.dart';

// SCREENS
import 'screens/login/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/responsive_layout.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // <--- 2. Carregar o arquivo .env
  await dotenv.load(fileName: ".env");

  // <--- 3. Usar as variáveis do dotenv
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  runApp(
    ChangeNotifierProvider.value(
      value: themeProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Providers Independentes
        ChangeNotifierProvider(create: (context) => NavigationProvider()),
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(create: (context) => ReportProvider()),
        ChangeNotifierProvider(create: (context) => BotProvider()),
        ChangeNotifierProvider(create: (context) => CompanyProvider()),

        // Provider Principal de Autenticação
        ChangeNotifierProvider(create: (context) => AuthProvider()),

        // Providers que DEPENDEM do AuthProvider
        ChangeNotifierProxyProvider<AuthProvider, PrinterProvider>(
          create: (context) => PrinterProvider(context.read<AuthProvider>()),
          update: (context, auth, previous) =>
              previous!..updateAuthProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ProductProvider>(
          create: (context) => ProductProvider(context.read<AuthProvider>()),
          update: (context, auth, previous) =>
              previous!..updateAuthProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, TableProvider>(
          create: (context) => TableProvider(context.read<AuthProvider>()),
          update: (context, auth, previous) =>
              previous!..updateAuthProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, TransactionProvider>(
          create: (context) =>
              TransactionProvider(context.read<AuthProvider>()),
          update: (context, auth, previous) =>
              previous!..updateAuthProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, KdsProvider>(
          create: (context) => KdsProvider(context.read<AuthProvider>()),
          update: (context, auth, previous) =>
              previous!..updateAuthProvider(auth),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Villa Bistro Mobile',
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
            home: const SplashScreen(),
            routes: {
              '/onboarding': (context) => const OnboardingScreen(),
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const ResponsiveLayout(),
            },
          );
        },
      ),
    );
  }
}