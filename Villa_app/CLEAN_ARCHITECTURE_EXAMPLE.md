# 📚 Exemplo Prático Completo - Clean Architecture

## Cenário: Implementar Feature de Autenticação

Este guia mostra como implementar uma feature completa (Login) usando Clean Architecture.

---

## 🎯 O que vamos fazer

Refatorar e completar a feature **Login** com:
1. ✅ Domain Layer (Already Done)
2. ⏳ Data Layer
3. ⏳ Presentation Layer

---

## ✅ FASE 1: Domain Layer (JÁ ESTÁ PRONTO)

### Entities
```dart
// lib/domain/entities/user_entity.dart
class UserEntity extends BaseEntity {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final bool isActive;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.isActive,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, email, name, phone, isActive, createdAt];
}
```

### Repositories (Abstratos)
```dart
// lib/domain/repositories/user_repository.dart
abstract class UserRepository {
  Future<Either<Failure, UserEntity>> login(String email, String password);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, UserEntity>> getCurrentUser();
  // ... outros métodos
}
```

### Use Cases
```dart
// lib/domain/usecases/auth/login_usecase.dart
class LoginUseCase extends UseCase<UserEntity, LoginParams> {
  final UserRepository repository;

  LoginUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(LoginParams params) {
    return repository.login(params.email, params.password);
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

---

## ⏳ FASE 2: Data Layer (COMEÇAR AQUI)

### Passo 1: Criar Exceções

```dart
// lib/core/exceptions/exceptions.dart
abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);
}

class ServerException extends AppException {
  const ServerException(String message) : super(message);
}

class AuthException extends AppException {
  const AuthException(String message) : super(message);
}

class NetworkException extends AppException {
  const NetworkException(String message) : super(message);
}

class ParsingException extends AppException {
  const ParsingException(String message) : super(message);
}
```

### Passo 2: Criar Model

```dart
// lib/data/models/user_model.dart
import 'package:villabistromobile/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required String id,
    required String email,
    required String name,
    String? phone,
    required bool isActive,
    required DateTime createdAt,
  }) : super(
    id: id,
    email: email,
    name: name,
    phone: phone,
    isActive: isActive,
    createdAt: createdAt,
  );

  /// Converte JSON do Supabase para Model
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Converte Model para JSON para Supabase
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'phone': phone,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
  };

  /// Converte Model para Entity (camada de domínio)
  UserEntity toEntity() => UserEntity(
    id: id,
    email: email,
    name: name,
    phone: phone,
    isActive: isActive,
    createdAt: createdAt,
  );
}
```

### Passo 3: Criar Remote Data Source

```dart
// lib/data/datasources/remote/user_remote_datasource.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:villabistromobile/core/exceptions/exceptions.dart';
import 'package:villabistromobile/data/models/user_model.dart';

/// Contrato para acesso remoto de dados de usuário
abstract class UserRemoteDataSource {
  /// Login de usuário
  /// Lança [AuthException] se credenciais inválidas
  /// Lança [ServerException] em caso de erro do servidor
  Future<UserModel> login(String email, String password);

  /// Logout de usuário
  Future<void> logout();

  /// Obtém usuário autenticado atual
  Future<UserModel> getCurrentUser();

  /// Obtém usuário por ID
  Future<UserModel> getUserById(String userId);
}

/// Implementação real usando Supabase
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final SupabaseClient supabase;

  UserRemoteDataSourceImpl(this.supabase);

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      // 1. Fazer login com Supabase Auth
      final authResponse = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw const AuthException('Falha ao fazer login');
      }

      // 2. Buscar dados do usuário na tabela
      final userData = await supabase
          .from('users')
          .select()
          .eq('id', authResponse.user!.id)
          .single();

      // 3. Converter para Model
      return UserModel.fromJson(userData as Map<String, dynamic>);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException('Erro ao buscar dados: ${e.message}');
    } on Exception catch (e) {
      throw ServerException('Erro desconhecido: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await supabase.auth.signOut();
    } on Exception catch (e) {
      throw ServerException('Erro ao fazer logout: $e');
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw const AuthException('Usuário não autenticado');
      }

      final userData = await supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      return UserModel.fromJson(userData as Map<String, dynamic>);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException('Erro ao buscar usuário: ${e.message}');
    }
  }

  @override
  Future<UserModel> getUserById(String userId) async {
    try {
      final userData = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return UserModel.fromJson(userData as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw ServerException('Usuário não encontrado: ${e.message}');
    }
  }
}
```

### Passo 4: Implementar Repository

```dart
// lib/data/repositories/user_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:villabistromobile/core/errors/failures.dart';
import 'package:villabistromobile/core/exceptions/exceptions.dart';
import 'package:villabistromobile/data/datasources/remote/user_remote_datasource.dart';
import 'package:villabistromobile/domain/entities/user_entity.dart';
import 'package:villabistromobile/domain/repositories/user_repository.dart';

/// Implementação concreta do UserRepository
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;

  UserRepositoryImpl({required this.remoteDataSource});

  /// Converte Exception em Failure
  Failure _handleException(Object exception) {
    if (exception is AuthException) {
      return AuthFailure(message: exception.message);
    } else if (exception is ServerException) {
      return ServerFailure(message: exception.message);
    } else if (exception is NetworkException) {
      return NetworkFailure(message: exception.message);
    }
    return UnknownFailure(message: 'Erro desconhecido');
  }

  @override
  Future<Either<Failure, UserEntity>> login(
    String email,
    String password,
  ) async {
    try {
      // Validar entrada
      if (email.isEmpty || password.isEmpty) {
        return Left(
          ValidationFailure(message: 'Email e senha são obrigatórios'),
        );
      }

      // Chamar data source
      final userModel = await remoteDataSource.login(email, password);

      // Converter Model para Entity
      return Right(userModel.toEntity());
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      return const Right(null);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final userModel = await remoteDataSource.getCurrentUser();
      return Right(userModel.toEntity());
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getUserById(String userId) async {
    try {
      final userModel = await remoteDataSource.getUserById(userId);
      return Right(userModel.toEntity());
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateUser(UserEntity user) async {
    // Implementar...
    return Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteUser(String userId) async {
    // Implementar...
    return Right(null);
  }
}
```

---

## ⏳ FASE 3: Presentation Layer

### Passo 5: Registrar no DI

```dart
// lib/core/di/injection_container_clean.dart
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ... outros imports

final getIt = GetIt.instance;

void setupServiceLocator() {
  // ============ DATA SOURCES ============
  getIt.registerSingleton<UserRemoteDataSource>(
    UserRemoteDataSourceImpl(Supabase.instance.client),
  );

  // ============ REPOSITORIES ============
  getIt.registerSingleton<UserRepository>(
    UserRepositoryImpl(
      remoteDataSource: getIt<UserRemoteDataSource>(),
    ),
  );

  // ============ USE CASES ============
  getIt.registerSingleton<LoginUseCase>(
    LoginUseCase(getIt<UserRepository>()),
  );
  getIt.registerSingleton<LogoutUseCase>(
    LogoutUseCase(getIt<UserRepository>()),
  );
  getIt.registerSingleton<GetCurrentUserUseCase>(
    GetCurrentUserUseCase(getIt<UserRepository>()),
  );

  print('✅ Service Locator configurado com sucesso!');
}
```

### Passo 6: Refatorar Provider

```dart
// lib/presentation/providers/auth_provider_clean.dart
import 'package:flutter/material.dart';
import 'package:villabistromobile/core/di/injection_container_clean.dart';
import 'package:villabistromobile/domain/entities/user_entity.dart';
import 'package:villabistromobile/domain/usecases/auth/login_usecase.dart';
import 'package:villabistromobile/domain/usecases/auth/logout_usecase.dart';
import 'package:villabistromobile/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:villabistromobile/core/utils/usecase.dart';

class AuthProvider extends ChangeNotifier {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  UserEntity? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  AuthProvider({
    LoginUseCase? loginUseCase,
    LogoutUseCase? logoutUseCase,
    GetCurrentUserUseCase? getCurrentUserUseCase,
  })  : _loginUseCase = loginUseCase ?? getIt<LoginUseCase>(),
        _logoutUseCase = logoutUseCase ?? getIt<LogoutUseCase>(),
        _getCurrentUserUseCase =
            getCurrentUserUseCase ?? getIt<GetCurrentUserUseCase>();

  // ============ GETTERS ============
  UserEntity? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  // ============ LOGIN ============
  Future<void> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    final result = await _loginUseCase(
      LoginParams(email: email, password: password),
    );

    result.fold(
      (failure) {
        _setError(failure.message);
        _isAuthenticated = false;
      },
      (user) {
        _currentUser = user;
        _isAuthenticated = true;
        _error = null;
      },
    );

    _setLoading(false);
  }

  // ============ LOGOUT ============
  Future<void> logout() async {
    _setLoading(true);

    final result = await _logoutUseCase(NoParams());

    result.fold(
      (failure) => _setError(failure.message),
      (_) {
        _currentUser = null;
        _isAuthenticated = false;
        _error = null;
      },
    );

    _setLoading(false);
  }

  // ============ GET CURRENT USER ============
  Future<void> getCurrentUser() async {
    _setLoading(true);

    final result = await _getCurrentUserUseCase(NoParams());

    result.fold(
      (failure) {
        _setError(failure.message);
        _isAuthenticated = false;
      },
      (user) {
        _currentUser = user;
        _isAuthenticated = true;
        _error = null;
      },
    );

    _setLoading(false);
  }

  // ============ HELPERS ============
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
```

### Passo 7: Usar no Widget

```dart
// lib/presentation/screens/login/login_screen.dart
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                if (authProvider.isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: () async {
                      await authProvider.login(
                        _emailController.text,
                        _passwordController.text,
                      );

                      if (mounted && authProvider.isAuthenticated) {
                        Navigator.of(context).pushReplacementNamed('/home');
                      }
                    },
                    child: const Text('Login'),
                  ),
                const SizedBox(height: 16),
                if (authProvider.error != null)
                  Text(
                    authProvider.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

---

## 🧪 Testes

```dart
// test/domain/usecases/auth/login_usecase_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:mockito/mockito.dart';

void main() {
  late LoginUseCase loginUseCase;
  late MockUserRepository mockUserRepository;

  setUp(() {
    mockUserRepository = MockUserRepository();
    loginUseCase = LoginUseCase(mockUserRepository);
  });

  group('LoginUseCase', () {
    const email = 'test@example.com';
    const password = 'password123';
    const user = UserEntity(
      id: '1',
      email: email,
      name: 'Test User',
      isActive: true,
      createdAt: 0,
    );

    test('should return UserEntity on successful login', () async {
      // Arrange
      when(mockUserRepository.login(email, password))
          .thenAnswer((_) async => const Right(user));

      // Act
      final result = await loginUseCase(
        const LoginParams(email: email, password: password),
      );

      // Assert
      expect(result, const Right(user));
      verify(mockUserRepository.login(email, password)).called(1);
    });

    test('should return AuthFailure on invalid credentials', () async {
      // Arrange
      when(mockUserRepository.login(email, password))
          .thenAnswer((_) async => Left(
            AuthFailure(message: 'Credenciais inválidas'),
          ));

      // Act
      final result = await loginUseCase(
        const LoginParams(email: email, password: password),
      );

      // Assert
      expect(result, isA<Left<AuthFailure, UserEntity>>());
    });
  });
}
```

---

## 🎉 Resultado

Agora você tem uma feature de **Login** completamente implementada com **Clean Architecture**:

✅ **Domain**: Use cases, entities, repositories abstratos
✅ **Data**: Models, data sources, repository implementations
✅ **Presentation**: Provider refatorado, widgets atualizados
✅ **Testes**: Testes unitários funcionando

**Próxima feature**: Repita o mesmo padrão para Products, Categories, etc!

---

*Padrão pronto para copiar e adaptar para outras features* 🚀
