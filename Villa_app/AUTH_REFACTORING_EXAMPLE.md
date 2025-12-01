# EXEMPLO PRÁTICO: Refatoração da Feature de Autenticação

Este arquivo mostra passo a passo como refatorar a feature de autenticação do seu app.

## Estrutura Atual (a ser refatorada)

```
lib/
├── providers/
│   └── auth_provider.dart         ← REFATORAR
├── models/
│   └── (sem models específicos de auth)
└── screens/
    └── login/
        └── login_screen.dart
```

## Estrutura Nova (Clean Architecture)

```
lib/
├── domain/
│   ├── entities/
│   │   └── auth_entity.dart       ← Novo
│   ├── repositories/
│   │   └── auth_repository.dart   ← Novo (abstrata)
│   └── usecases/
│       ├── login_usecase.dart     ← Novo
│       ├── register_usecase.dart  ← Novo
│       └── logout_usecase.dart    ← Novo
│
├── data/
│   ├── models/
│   │   └── auth_model.dart        ← Novo
│   ├── datasources/
│   │   └── auth_remote_datasource.dart   ← Novo
│   └── repositories/
│       └── auth_repository_impl.dart     ← Novo
│
└── presentation/
    └── providers/
        └── auth_provider.dart     ← REFATORAR (simplificar)
```

---

## PASSO 1: Criar AuthEntity (Domain Layer)

**Arquivo: `lib/domain/entities/auth_entity.dart`**

```dart
import 'package:villabistromobile/domain/entities/base_entity.dart';

class AuthEntity extends BaseEntity {
  final String id;
  final String email;
  final String? token;
  final bool isAuthenticated;
  final DateTime? expiresAt;

  const AuthEntity({
    required this.id,
    required this.email,
    this.token,
    required this.isAuthenticated,
    this.expiresAt,
  });

  @override
  List<Object?> get props => [id, email, token, isAuthenticated, expiresAt];
}
```

---

## PASSO 2: Criar AuthModel (Data Layer)

**Arquivo: `lib/data/models/auth_model.dart`**

```dart
import 'package:equatable/equatable.dart';

class AuthModel extends Equatable {
  final String id;
  final String email;
  final String? token;
  final bool isAuthenticated;
  final DateTime? expiresAt;

  const AuthModel({
    required this.id,
    required this.email,
    this.token,
    required this.isAuthenticated,
    this.expiresAt,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      id: json['id'] as String,
      email: json['email'] as String,
      token: json['session']?['access_token'] as String?,
      isAuthenticated: json['session'] != null,
      expiresAt: json['session']?['expires_at'] != null
          ? DateTime.parse(json['session']['expires_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'token': token,
      'is_authenticated': isAuthenticated,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, email, token, isAuthenticated, expiresAt];
}
```

---

## PASSO 3: Criar AuthRepository (Domain Layer - Interface)

**Arquivo: `lib/domain/repositories/auth_repository.dart`**

```dart
import 'package:dartz/dartz.dart';
import 'package:villabistromobile/core/errors/failures.dart';
import 'package:villabistromobile/domain/entities/auth_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthEntity>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, AuthEntity>> register({
    required String email,
    required String password,
    required String name,
  });

  Future<Either<Failure, AuthEntity>> getCurrentAuth();

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, bool>> isAuthenticated();
}
```

---

## PASSO 4: Criar AuthRemoteDataSource (Data Layer)

**Arquivo: `lib/data/datasources/auth_remote_datasource.dart`**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:villabistromobile/data/models/auth_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthModel> login({
    required String email,
    required String password,
  });

  Future<AuthModel> register({
    required String email,
    required String password,
    required String name,
  });

  Future<AuthModel> getCurrentAuth();

  Future<void> logout();

  Future<bool> isAuthenticated();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;

  AuthRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<AuthModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return AuthModel.fromJson({
        'id': response.user?.id,
        'email': response.user?.email,
        'session': {
          'access_token': response.session?.accessToken,
          'expires_at': response.session?.expiresAt,
        }
      });
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  @override
  Future<AuthModel> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await supabaseClient.auth.signUpWithPassword(
        email: email,
        password: password,
      );

      // Atualizar perfil do usuário com o nome
      await supabaseClient
          .from('profiles')
          .insert({'id': response.user?.id, 'name': name});

      return AuthModel.fromJson({
        'id': response.user?.id,
        'email': response.user?.email,
        'session': {
          'access_token': response.session?.accessToken,
          'expires_at': response.session?.expiresAt,
        }
      });
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  @override
  Future<AuthModel> getCurrentAuth() async {
    final session = supabaseClient.auth.currentSession;
    final user = supabaseClient.auth.currentUser;

    if (user == null || session == null) {
      throw Exception('No authenticated user');
    }

    return AuthModel.fromJson({
      'id': user.id,
      'email': user.email,
      'session': {
        'access_token': session.accessToken,
        'expires_at': session.expiresAt,
      }
    });
  }

  @override
  Future<void> logout() async {
    try {
      await supabaseClient.auth.signOut();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final session = supabaseClient.auth.currentSession;
    return session != null;
  }
}
```

---

## PASSO 5: Implementar AuthRepository (Data Layer)

**Arquivo: `lib/data/repositories/auth_repository_impl.dart`**

```dart
import 'package:dartz/dartz.dart';
import 'package:villabistromobile/core/errors/failures.dart';
import 'package:villabistromobile/data/datasources/auth_remote_datasource.dart';
import 'package:villabistromobile/domain/entities/auth_entity.dart';
import 'package:villabistromobile/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, AuthEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final model = await remoteDataSource.login(
        email: email,
        password: password,
      );
      return Right(model as AuthEntity);
    } on Exception catch (e) {
      return Left(AuthenticationFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final model = await remoteDataSource.register(
        email: email,
        password: password,
        name: name,
      );
      return Right(model as AuthEntity);
    } on Exception catch (e) {
      return Left(AuthenticationFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> getCurrentAuth() async {
    try {
      final model = await remoteDataSource.getCurrentAuth();
      return Right(model as AuthEntity);
    } on Exception catch (e) {
      return Left(AuthenticationFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      return const Right(null);
    } on Exception catch (e) {
      return Left(AuthenticationFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    try {
      final isAuth = await remoteDataSource.isAuthenticated();
      return Right(isAuth);
    } on Exception catch (e) {
      return Left(AuthenticationFailure(e.toString()));
    }
  }
}
```

---

## PASSO 6: Criar UseCases (Domain Layer)

**Arquivo: `lib/domain/usecases/auth/login_usecase.dart`**

```dart
import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import 'package:villabistromobile/core/errors/failures.dart';
import 'package:villabistromobile/core/utils/usecase.dart';
import 'package:villabistromobile/domain/entities/auth_entity.dart';
import 'package:villabistromobile/domain/repositories/auth_repository.dart';

class LoginUseCase extends UseCase<AuthEntity, LoginParams> {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  @override
  Future<Either<Failure, AuthEntity>> call(LoginParams params) {
    return repository.login(
      email: params.email,
      password: params.password,
    );
  }
}

class LoginParams extends Equatable {
  final String email;
  final String password;

  const LoginParams({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}
```

**Arquivo: `lib/domain/usecases/auth/register_usecase.dart`**

```dart
import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import 'package:villabistromobile/core/errors/failures.dart';
import 'package:villabistromobile/core/utils/usecase.dart';
import 'package:villabistromobile/domain/entities/auth_entity.dart';
import 'package:villabistromobile/domain/repositories/auth_repository.dart';

class RegisterUseCase extends UseCase<AuthEntity, RegisterParams> {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  @override
  Future<Either<Failure, AuthEntity>> call(RegisterParams params) {
    return repository.register(
      email: params.email,
      password: params.password,
      name: params.name,
    );
  }
}

class RegisterParams extends Equatable {
  final String email;
  final String password;
  final String name;

  const RegisterParams({
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  List<Object?> get props => [email, password, name];
}
```

**Arquivo: `lib/domain/usecases/auth/logout_usecase.dart`**

```dart
import 'package:dartz/dartz.dart';
import 'package:villabistromobile/core/errors/failures.dart';
import 'package:villabistromobile/core/utils/usecase.dart';
import 'package:villabistromobile/domain/repositories/auth_repository.dart';

class LogoutUseCase extends UseCase<void, NoParams> {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.logout();
  }
}
```

---

## PASSO 7: Refatorar AuthProvider (Presentation Layer)

**Arquivo: `lib/presentation/providers/auth_provider.dart` (NOVO)**

```dart
import 'package:flutter/foundation.dart';
import 'package:villabistromobile/core/utils/usecase.dart';
import 'package:villabistromobile/domain/entities/auth_entity.dart';
import 'package:villabistromobile/domain/usecases/auth/login_usecase.dart';
import 'package:villabistromobile/domain/usecases/auth/register_usecase.dart';
import 'package:villabistromobile/domain/usecases/auth/logout_usecase.dart';

class AuthProvider extends ChangeNotifier {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;

  AuthEntity? _user;
  bool _isLoading = false;
  String? _error;

  AuthProvider({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
  });

  AuthEntity? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user?.isAuthenticated ?? false;

  Future<void> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await loginUseCase(
      LoginParams(email: email, password: password),
    );

    result.fold(
      (failure) {
        _error = failure.message;
        _user = null;
      },
      (auth) {
        _user = auth;
        _error = null;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await registerUseCase(
      RegisterParams(email: email, password: password, name: name),
    );

    result.fold(
      (failure) {
        _error = failure.message;
        _user = null;
      },
      (auth) {
        _user = auth;
        _error = null;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await logoutUseCase(NoParams());

    result.fold(
      (failure) => _error = failure.message,
      (_) => _user = null,
    );

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
```

---

## PASSO 8: Atualizar Service Locator

**Arquivo: `lib/core/di/injection_container.dart`**

```dart
// ... existing code ...

void setupServiceLocator() {
  // Datasources
  getIt.registerSingleton<AuthRemoteDataSource>(
    AuthRemoteDataSourceImpl(
      supabaseClient: Supabase.instance.client,
    ),
  );

  // Repositories
  getIt.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(
      remoteDataSource: getIt<AuthRemoteDataSource>(),
    ),
  );

  // Use Cases
  getIt.registerSingleton<LoginUseCase>(
    LoginUseCase(getIt<AuthRepository>()),
  );
  getIt.registerSingleton<RegisterUseCase>(
    RegisterUseCase(getIt<AuthRepository>()),
  );
  getIt.registerSingleton<LogoutUseCase>(
    LogoutUseCase(getIt<AuthRepository>()),
  );

  // Providers
  getIt.registerSingleton<AuthProvider>(
    AuthProvider(
      loginUseCase: getIt<LoginUseCase>(),
      registerUseCase: getIt<RegisterUseCase>(),
      logoutUseCase: getIt<LogoutUseCase>(),
    ),
  );
}
```

---

## PASSO 9: Usar na LoginScreen

**Arquivo: `lib/screens/login/login_screen.dart` (ANTES)**

```dart
// Antigo - misturado
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // authProvider tem muita lógica misturada
      },
    );
  }
}
```

**Arquivo: `lib/screens/login/login_screen.dart` (DEPOIS)**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/core/di/injection_container.dart';
import 'package:villabistromobile/presentation/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController emailController;
  late TextEditingController passwordController;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthProvider>(
      create: (_) => getIt<AuthProvider>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Login')),
        body: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (authProvider.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        authProvider.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ElevatedButton(
                    onPressed: authProvider.isLoading
                        ? null
                        : () {
                            authProvider.login(
                              email: emailController.text,
                              password: passwordController.text,
                            );
                          },
                    child: authProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Entrar'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
```

---

## ✅ Resumo dos Passos

1. ✅ Criar `AuthEntity` - Objeto de domínio
2. ✅ Criar `AuthModel` - DTO com serialização
3. ✅ Criar `AuthRepository` - Interface/contrato
4. ✅ Criar `AuthRemoteDataSource` - Acesso a dados (Supabase)
5. ✅ Criar `AuthRepositoryImpl` - Implementação do contrato
6. ✅ Criar `LoginUseCase`, `RegisterUseCase`, `LogoutUseCase` - Casos de uso
7. ✅ Refatorar `AuthProvider` - Provider simplificado
8. ✅ Registrar tudo no `injection_container.dart`
9. ✅ Usar `getIt<AuthProvider>()` na UI

---

## 🎯 Resultado Final

**Benefícios:**
- ✅ Código organizado em camadas
- ✅ Fácil de testar (cada camada independente)
- ✅ Lógica de negócio separada da UI
- ✅ Fácil manutenção e evolução
- ✅ Reutilizável em diferentes contextos

Agora você pode seguir este mesmo padrão para outras features!
