# Clean Architecture - Guia Completo de Implementação

## 📊 Status Atual

### ✅ CONCLUÍDO - Domain Layer
- Entities (8 classes)
- Repositories abstratos (6 interfaces)
- Use Cases (16 casos de uso)
- Estrutura de DI preparada
- Barrel exports

### ⏳ PRÓXIMA FASE - Data Layer
- Models (estendem Entities)
- Remote Data Sources
- Repository Implementations
- Mappers (Entity ↔ Model)

### ⏳ FASE 3 - Presentation Layer Refatorada
- State Management baseado em Use Cases
- Providers refatorados
- Telas atualizadas

### ⏳ FASE 4 - Main.dart Refatorado
- DI completamente funcional
- Providers com Use Cases
- Estrutura escalável

---

## 🚀 Próximas Etapas Detalhadas

### FASE 2: Data Layer

#### 2.1 - Criar Models

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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'phone': phone,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
  };

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

#### 2.2 - Criar Data Sources

```dart
// lib/data/datasources/remote/user_remote_datasource.dart
abstract class UserRemoteDataSource {
  Future<UserModel> getCurrentUser();
  Future<UserModel> getUserById(String userId);
  Future<UserModel> login(String email, String password);
  Future<void> logout();
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final SupabaseClient supabase;

  UserRemoteDataSourceImpl(this.supabase);

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final user = await supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');
      
      final userData = await supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .single();
        
      return UserModel.fromJson(userData);
    } catch (e) {
      throw ServerException('Failed to get current user');
    }
  }
  
  // Implementar outros métodos...
}
```

#### 2.3 - Criar Repository Implementations

```dart
// lib/data/repositories/user_repository_impl.dart
import 'package:dartz/dartz.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;
  final UserLocalDataSource localDataSource;

  UserRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      await localDataSource.cacheUser(user);
      return Right(user.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }

  // Implementar outros métodos...
}
```

#### 2.4 - Estrutura de Data Layer

```
lib/data/
├── datasources/
│   ├── remote/
│   │   ├── user_remote_datasource.dart
│   │   ├── product_remote_datasource.dart
│   │   ├── category_remote_datasource.dart
│   │   └── ... outros
│   └── local/
│       ├── user_local_datasource.dart
│       └── ... outros
├── models/
│   ├── user_model.dart
│   ├── product_model.dart
│   ├── category_model.dart
│   └── ... outros
├── repositories/
│   ├── user_repository_impl.dart
│   ├── product_repository_impl.dart
│   ├── category_repository_impl.dart
│   └── ... outros
├── mappers/
│   ├── user_mapper.dart
│   ├── product_mapper.dart
│   └── ... outros
└── data_barrel.dart
```

### FASE 3: Refatorar Presentation Layer

#### 3.1 - Exemplo de Provider Refatorado

```dart
// lib/presentation/providers/auth_provider_clean.dart
class AuthProvider extends ChangeNotifier {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;

  UserEntity? _currentUser;
  bool _isLoading = false;
  String? _error;

  AuthProvider({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
  });

  // Getters
  UserEntity? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  // Login
  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await loginUseCase(
      LoginParams(email: email, password: password),
    );

    result.fold(
      (failure) {
        _error = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (user) {
        _currentUser = user;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
    );
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    final result = await logoutUseCase(NoParams());

    result.fold(
      (failure) {
        _error = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (_) {
        _currentUser = null;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
    );
  }

  // Get Current User
  Future<void> getCurrentUser() async {
    _isLoading = true;
    notifyListeners();

    final result = await getCurrentUserUseCase(NoParams());

    result.fold(
      (failure) {
        _error = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (user) {
        _currentUser = user;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
    );
  }
}
```

#### 3.2 - Setup no DI

```dart
// Em lib/core/di/injection_container_clean.dart
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

  // ============ PROVIDERS ============
  getIt.registerSingleton<AuthProvider>(
    AuthProvider(
      loginUseCase: getIt<LoginUseCase>(),
      logoutUseCase: getIt<LogoutUseCase>(),
      getCurrentUserUseCase: getIt<GetCurrentUserUseCase>(),
    ),
  );
}
```

---

## 📋 Checklist de Implementação

### Data Layer
- [ ] UserModel + UserRemoteDataSource + UserRepositoryImpl
- [ ] ProductModel + ProductRemoteDataSource + ProductRepositoryImpl
- [ ] CategoryModel + CategoryRemoteDataSource + CategoryRepositoryImpl
- [ ] CompanyModel + CompanyRemoteDataSource + CompanyRepositoryImpl
- [ ] TableModel + TableRemoteDataSource + TableRepositoryImpl
- [ ] OrderModel + OrderRemoteDataSource + OrderRepositoryImpl
- [ ] Testes unitários para repositories

### Presentation Layer
- [ ] Refatorar AuthProvider com Use Cases
- [ ] Refatorar ProductProvider com Use Cases
- [ ] Refatorar CategoryProvider com Use Cases
- [ ] Refatorar CompanyProvider com Use Cases
- [ ] Refatorar TableProvider com Use Cases
- [ ] Refatorar OrderProvider com Use Cases
- [ ] Atualizar telas para usar novos providers

### Integração
- [ ] Setup completo do DI
- [ ] Testar fluxo de login
- [ ] Testar carregamento de produtos
- [ ] Testar carregamento de categorias
- [ ] Testar criação de pedidos

### Otimizações Futuras
- [ ] Implementar Riverpod para estado
- [ ] Implementar BLoC Pattern
- [ ] Adicionar caching local
- [ ] Implementar offline-first
- [ ] Testes de integração

---

## 💡 Dicas

1. **Sempre use Either<Failure, T>** para retorno de métodos
2. **Mappers** separam Models de Entities
3. **Use Cases** encapsulam lógica de negócio
4. **Providers** gerenciam estado da UI
5. **Data Sources** falam com APIs externas
6. **Teste isoladamente** cada camada

---

## 🔗 Referências

- `DOMAIN_LAYER_GUIDE.md` - Guia completo do domain
- `DOMAIN_REFACTOR_SUMMARY.md` - Resumo do que foi feito
- `lib/main_clean_architecture.dart` - Exemplo de main refatorado
- `lib/core/di/injection_container_clean.dart` - Setup de DI

---

## ❓ Dúvidas Comuns

**P: Quando começar a refatorar?**
R: Depois de completar toda a Data Layer. Use o checklist acima.

**P: Preciso apagar os providers antigos?**
R: Gradualmente. Migre feature por feature, não tudo de uma vez.

**P: Como testar Use Cases?**
R: Mock o repository e teste o resultado com Either.

**P: Riverpod é melhor que Provider?**
R: Sim, mas Provider funciona bem. Migre depois quando estável.

---

Boa sorte! 🚀
