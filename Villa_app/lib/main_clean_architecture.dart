import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Core
import 'core/di/injection_container_clean.dart';
import 'presentation/providers/theme_provider.dart';

// Features - Providers (substituir com State Management moderno futuramente)
// Importante: Gradualmente migrar de Provider para gerenciar estado baseado em Use Cases
import 'presentation/providers/navigation_provider.dart';
import 'presentation/providers/cart_provider.dart';
import 'presentation/providers/report_provider.dart';
import 'presentation/providers/bot_provider.dart';
import 'presentation/providers/company_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/printer_provider.dart';
import 'presentation/providers/product_provider.dart';
import 'presentation/providers/table_provider.dart';
import 'presentation/providers/transaction_provider.dart';
import 'presentation/providers/kds_provider.dart';

// Screens
import 'presentation/screens/login/login_screen.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/screens/responsive_layout.dart';
import 'presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carregar arquivo .env
  await dotenv.load(fileName: ".env");

  // Inicializar Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Setup Service Locator (Dependency Injection) - Clean Architecture
  setupServiceLocator();

  // Carregar tema persistido
  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  runApp(
    ChangeNotifierProvider.value(
      value: themeProvider,
      child: const MyApp(),
    ),
  );
}

/// Widget principal da aplicação
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ============ PROVIDERS INDEPENDENTES ============
        // Estes providers não dependem de outros (podem ser refatorados futuramente)
        ChangeNotifierProvider(create: (context) => NavigationProvider()),
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(create: (context) => ReportProvider()),
        ChangeNotifierProvider(create: (context) => BotProvider()),
        ChangeNotifierProvider(create: (context) => CompanyProvider()),

        // ============ AUTH PROVIDER (PRINCIPAL) ============
        // Este é o provider core que gerencia autenticação
        ChangeNotifierProvider(create: (context) => AuthProvider()),

        // ============ PROVIDERS DEPENDENTES ============
        // Estes providers dependem do AuthProvider
        // Nota: Gradualmente migrar para UseCase-based architecture
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
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'VillaBistro',
            theme: themeProvider.getTheme,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('pt', 'BR'),
              Locale('en', 'US'),
            ],
            locale: const Locale('pt', 'BR'),
            home: _buildInitialRoute(),
          );
        },
      ),
    );
  }

  /// Determina a rota inicial baseada no estado de autenticação
  Widget _buildInitialRoute() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return const SplashScreen();
        }

        if (authProvider.isAuthenticated) {
          if (authProvider.hasCompany) {
            return const ResponsiveLayout();
          }
          return const OnboardingScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

// ============ NOTAS DE REFATORAÇÃO ============
//
// 1. DOMINIO (✅ COMPLETO)
//    - Entities bem definidas
//    - Repositories abstratos
//    - Use Cases implementados
//
// 2. DATA LAYER (⏳ PRÓXIMO)
//    - Implementar UserRepositoryImpl
//    - Implementar ProductRepositoryImpl
//    - Implementar CategoryRepositoryImpl
//    - Etc...
//
// 3. PRESENTATION LAYER (⏳ FUTURA)
//    - Refatorar Providers para usar Use Cases
//    - Exemplo:
//      
//      class AuthProvider extends ChangeNotifier {
//        final LoginUseCase loginUseCase;
//        final GetCurrentUserUseCase getCurrentUserUseCase;
//        
//        AuthProvider(this.loginUseCase, this.getCurrentUserUseCase);
//        
//        Future<void> login(String email, String password) async {
//          final result = await loginUseCase(
//            LoginParams(email: email, password: password)
//          );
//          
//          result.fold(
//            (failure) => _handleFailure(failure),
//            (user) => _handleSuccess(user),
//          );
//        }
//      }
//
// 4. ROTEIRO
//    - Fase 1: Domain + Data Layer (AGORA)
//    - Fase 2: Refatorar Providers com Use Cases
//    - Fase 3: Implementar novo State Management (Riverpod/Bloc)
//    - Fase 4: Remover todos os providers antigos
