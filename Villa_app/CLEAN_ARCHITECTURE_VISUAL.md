# Clean Architecture - Visão Geral Visual

```
┌─────────────────────────────────────────────────────────────────┐
│                         FLUTTER APP                              │
│                      (VillaBistro Mobile)                        │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ PRESENTATION LAYER                                               │
│ ─────────────────────────────────────────────────────────────── │
│ - Screens/Pages (UI)                                             │
│ - Widgets                                                        │
│ - State Management (Provider, BLoC, Riverpod)                   │
│ - Controllers/ViewModels                                        │
│                                                                  │
│  LoginScreen → AuthProvider ← GetCurrentUserUseCase             │
│  ProductScreen → ProductProvider ← GetProductsUseCase           │
│  etc...                                                          │
└─────────────────────────────────────────────────────────────────┘
                              ↑
                   (UseCases + Repositories)
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ DOMAIN LAYER                                                     │
│ ─────────────────────────────────────────────────────────────── │
│ Entidades | Repositórios Abstratos | Use Cases                  │
│                                                                  │
│ ┌──────────────┐  ┌──────────────────────┐  ┌─────────────────┐ │
│ │   ENTITIES   │  │  REPOSITORIES (ABS)  │  │   USE CASES     │ │
│ ├──────────────┤  ├──────────────────────┤  ├─────────────────┤ │
│ │ UserEntity   │  │ UserRepository       │  │ LoginUseCase    │ │
│ │ ProductEntity│→→│ ProductRepository    │→→│ GetProductsUs...│ │
│ │ OrderEntity  │  │ OrderRepository      │  │ CreateOrderUs...│ │
│ │ TableEntity  │  │ etc...               │  │ etc...          │ │
│ │ etc...       │  │                      │  │                 │ │
│ └──────────────┘  └──────────────────────┘  └─────────────────┘ │
│                                                                  │
│  ✅ Sem dependências externas                                   │
│  ✅ Puramente lógica de negócio                                 │
│  ✅ Fácil de testar                                             │
│  ✅ Independente de framework                                   │
└─────────────────────────────────────────────────────────────────┘
                              ↑
              (Implementations + Data Sources)
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ DATA LAYER                                                       │
│ ─────────────────────────────────────────────────────────────── │
│ Models | Data Sources | Repository Implementations              │
│                                                                  │
│ ┌──────────────────┐  ┌─────────────────────┐  ┌─────────────┐ │
│ │     MODELS       │  │   DATA SOURCES      │  │ REPOSITORIES│ │
│ ├──────────────────┤  ├─────────────────────┤  ├─────────────┤ │
│ │ UserModel        │→→│ UserRemoteDataSource│→→│ UserRepoImpl  │ │
│ │ ProductModel     │  │ ProductRemoteDS     │  │ ProductRepo..│ │
│ │ OrderModel       │  │ UserLocalDataSource │  │ OrderRepoImpl │ │
│ │ etc...           │  │ etc...              │  │ etc...       │ │
│ │                  │  │                     │  │              │ │
│ │ (extends Entity) │  │ (CRUD operations)   │  │(implements   │ │
│ │ + fromJson()     │  │                     │  │Repository)   │ │
│ │ + toEntity()     │  │                     │  │              │ │
│ └──────────────────┘  └─────────────────────┘  └─────────────┘ │
│                                                                  │
│  ↓                                                               │
│  [Mappers: Model ↔ Entity]                                      │
│                                                                  │
│  ✅ Acesso a APIs                                               │
│  ✅ Acesso a cache local                                        │
│  ✅ Tratamento de erros                                         │
│  ✅ Conversão de dados                                          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
                   (External Services)
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ EXTERNAL LAYER                                                   │
│ ─────────────────────────────────────────────────────────────── │
│ Supabase API | Local Database | Cache | File System             │
│                                                                  │
│ [REST API] ← Supabase → [Auth] → [Database]                    │
│ [SharedPreferences] ← Cache Data                                │
│ [File System] ← Local Files                                    │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📊 Fluxo de Dados

```
┌─────────────────────────────────────────────────────────────────┐
│ EXEMPLO: Fazer Login                                             │
└─────────────────────────────────────────────────────────────────┘

1. UI (Apresentação)
   └─ User clica no botão Login
   
2. Presentation (Provider)
   └─ authProvider.login("email@test.com", "password")
   
3. Use Case
   └─ LoginUseCase(params).call()
   
4. Domain (Repositório Abstrato)
   └─ UserRepository.login(email, password)
      (Abstração - não sabe como funciona)
   
5. Data (Repositório Implementado)
   └─ UserRepositoryImpl.login()
      └─ chama UserRemoteDataSource.login()
      
6. Data Source (Acesso Externo)
   └─ UserRemoteDataSourceImpl.login()
      └─ await supabase.auth.signInWithPassword(...)
      
7. External (Supabase)
   └─ [Auth API] verifica credenciais
   └─ retorna User ou erro
   
8. Return Trip (volta tudo para cima com Either)
   ├─ Left(AuthFailure) ou
   └─ Right(UserEntity)
   
9. UI Atualiza
   └─ Navigator.push(home) ou mostra erro
```

---

## 🔄 Ciclo de Vida de um Use Case

```
┌──────────────────────────────────────────────────────────────┐
│ Use Case: GetCurrentUserUseCase                               │
└──────────────────────────────────────────────────────────────┘

class GetCurrentUserUseCase extends UseCase<UserEntity, NoParams> {
  final UserRepository repository;  // ← Abstração injetada
  
  GetCurrentUserUseCase(this.repository);
  
  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) {
    return repository.getCurrentUser();
  }
}

Execução:
1. Provider chama: await getCurrentUserUseCase(NoParams())
2. Use Case recebe NoParams (sem parâmetros específicos)
3. Use Case delega para repository.getCurrentUser()
4. Repository (abstrato) não faz nada - é interface!
5. Data Layer implementa a interface
6. Data Layer acessa Supabase
7. Resultado: Either<Failure, UserEntity>
   ├─ Left: ServerFailure("Erro ao carregar usuário")
   └─ Right: UserEntity(id: "123", name: "João", ...)
8. Provider recebe resultado e atualiza UI
```

---

## 🎯 Responsabilidades por Camada

```
┌─────────────────────────────────────────────────────────────────┐
│ PRESENTATION LAYER                                               │
├─────────────────────────────────────────────────────────────────┤
│ ✅ Mostrar dados na UI                                          │
│ ✅ Capturar inputs do usuário                                   │
│ ✅ Gerenciar estado local da tela                               │
│ ✅ Chamar Use Cases quando necessário                           │
│ ✅ Mostrar erros/sucessos para usuário                          │
│ ✅ Navegar entre telas                                          │
│ ❌ NÃO validar regras de negócio complexas                      │
│ ❌ NÃO acessar Supabase/API diretamente                         │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ DOMAIN LAYER                                                     │
├─────────────────────────────────────────────────────────────────┤
│ ✅ Definir lógica de negócio pura                               │
│ ✅ Encapsular casos de uso                                      │
│ ✅ Definir contratos (repositories abstratos)                   │
│ ✅ Ser independente de framework                                │
│ ✅ Ser testável sem mocks complexos                             │
│ ❌ NÃO conhecer detalhes técnicos                               │
│ ❌ NÃO depender de pacotes Flutter                              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ DATA LAYER                                                       │
├─────────────────────────────────────────────────────────────────┤
│ ✅ Implementar repositories abstratos                           │
│ ✅ Acessar APIs/Banco de dados                                  │
│ ✅ Fazer cache de dados                                         │
│ ✅ Converter dados (Models ↔ Entities)                          │
│ ✅ Tratar erros técnicos                                        │
│ ✅ Garantir offline-first (se aplicável)                        │
│ ❌ NÃO conter lógica de negócio                                 │
│ ❌ NÃO atualizar UI diretamente                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 💾 Estrutura de Arquivos Completa

```
lib/
├── main.dart                          # Entry point (atual)
├── main_clean_architecture.dart       # Entry point refatorado
│
├── core/
│   ├── di/
│   │   ├── injection_container.dart   # DI atual
│   │   └── injection_container_clean.dart # DI novo ✅
│   ├── errors/
│   │   └── failures.dart              # Hierarquia de erros ✅
│   └── utils/
│       └── usecase.dart               # Base de Use Cases ✅
│
├── domain/                            # ✅ COMPLETO
│   ├── entities/
│   │   ├── base_entity.dart
│   │   ├── user_entity.dart
│   │   ├── product_entity.dart
│   │   ├── category_entity.dart
│   │   ├── company_entity.dart        # NOVO
│   │   ├── table_entity.dart          # NOVO
│   │   ├── order_entity.dart          # NOVO
│   │   └── cart_item_entity.dart      # NOVO
│   ├── repositories/
│   │   ├── user_repository.dart       # Refatorado
│   │   ├── product_repository.dart    # Refatorado
│   │   ├── category_repository.dart   # NOVO
│   │   ├── company_repository.dart    # NOVO
│   │   ├── table_repository.dart      # NOVO
│   │   └── order_repository.dart      # NOVO
│   ├── usecases/
│   │   ├── auth/
│   │   │   ├── login_usecase.dart
│   │   │   ├── logout_usecase.dart
│   │   │   ├── get_current_user_usecase.dart
│   │   │   └── get_user_by_id_usecase.dart
│   │   ├── product/
│   │   │   ├── get_products_usecase.dart
│   │   │   └── get_product_by_id_usecase.dart
│   │   ├── category/
│   │   │   └── get_categories_usecase.dart
│   │   ├── company/
│   │   │   ├── get_current_company_usecase.dart
│   │   │   └── get_companies_usecase.dart
│   │   ├── table/
│   │   │   └── get_tables_usecase.dart
│   │   └── order/
│   │       ├── create_order_usecase.dart
│   │       └── get_orders_usecase.dart
│   └── domain_barrel.dart             # Exports ✅
│
├── data/                              # ⏳ PRÓXIMO
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── product_model.dart
│   │   └── ...
│   ├── datasources/
│   │   ├── remote/
│   │   │   ├── user_remote_datasource.dart
│   │   │   └── ...
│   │   └── local/
│   │       ├── user_local_datasource.dart
│   │       └── ...
│   ├── repositories/
│   │   ├── user_repository_impl.dart
│   │   └── ...
│   ├── mappers/
│   │   ├── user_mapper.dart
│   │   └── ...
│   └── data_barrel.dart
│
├── presentation/                      # ⏳ REFATORANDO
│   ├── providers/                     # Provider layer
│   │   ├── auth_provider.dart
│   │   ├── product_provider.dart
│   │   └── ...
│   ├── screens/
│   │   ├── login/
│   │   ├── home/
│   │   └── ...
│   └── widgets/
│       ├── custom_button.dart
│       └── ...
│
└── docs/                              # 📚 DOCUMENTAÇÃO
    ├── DOMAIN_LAYER_GUIDE.md          # ✅ Novo
    ├── DOMAIN_REFACTOR_SUMMARY.md     # ✅ Novo
    └── CLEAN_ARCHITECTURE_IMPLEMENTATION_GUIDE.md # ✅ Novo
```

---

## 🧪 Testando Use Cases

```dart
// test/domain/usecases/auth/login_usecase_test.dart

void main() {
  late LoginUseCase loginUseCase;
  late MockUserRepository mockUserRepository;

  setUp(() {
    mockUserRepository = MockUserRepository();
    loginUseCase = LoginUseCase(mockUserRepository);
  });

  group('LoginUseCase', () {
    test('should return UserEntity on successful login', () async {
      // Arrange
      const params = LoginParams(
        email: 'test@example.com',
        password: 'password123',
      );
      final user = UserEntity(
        id: '1',
        email: 'test@example.com',
        name: 'Test User',
        isActive: true,
        createdAt: DateTime.now(),
      );

      when(mockUserRepository.login('test@example.com', 'password123'))
        .thenAnswer((_) async => Right(user));

      // Act
      final result = await loginUseCase(params);

      // Assert
      expect(result, Right(user));
      verify(mockUserRepository.login('test@example.com', 'password123'))
        .called(1);
    });

    test('should return AuthFailure on failed login', () async {
      // Arrange
      const params = LoginParams(
        email: 'test@example.com',
        password: 'wrongpassword',
      );

      when(mockUserRepository.login('test@example.com', 'wrongpassword'))
        .thenAnswer((_) async => Left(
          AuthFailure(message: 'Invalid credentials'),
        ));

      // Act
      final result = await loginUseCase(params);

      // Assert
      expect(result, isA<Left>());
      expect(result.fold(id, id), isA<AuthFailure>());
    });
  });
}
```

---

## ✨ Resumo da Arquitetura

| Aspecto | Domain | Data | Presentation |
|---------|--------|------|--------------|
| Responsabilidade | Lógica de negócio | Acesso a dados | UI e Estado |
| Depende de | Nada | Domain | Domain + Data + UI |
| Testável | ✅ Facilmente | ✅ Com mocks | ✅ Com mocks |
| Independente | ✅ Sim | ❌ Precisa de Domain | ❌ Precisa de Data |
| Framework | ❌ Não | ✅ Supabase, etc | ✅ Flutter |

---

**Status: Domain Layer ✅ COMPLETO**
**Próximo: Data Layer ⏳ EM BREVE**
