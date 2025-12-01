# 🎯 VillaBistro - Roadmap Clean Architecture

## 📌 Situação Atual

**Status: FASE 1/4 ✅ CONCLUÍDO**

O projeto foi refatorado para seguir **Clean Architecture** principles. Toda a camada Domain foi implementada com sucesso.

---

## ✅ O que foi feito

### Domain Layer (100% Completo)

#### Entities (8)
- ✅ UserEntity
- ✅ ProductEntity
- ✅ CategoryEntity
- ✅ CompanyEntity (NOVO)
- ✅ TableEntity (NOVO)
- ✅ OrderEntity (NOVO)
- ✅ CartItemEntity (NOVO)
- ✅ BaseEntity

#### Repositories Abstratos (6)
- ✅ UserRepository (refatorado)
- ✅ ProductRepository (refatorado)
- ✅ CategoryRepository (NOVO)
- ✅ CompanyRepository (NOVO)
- ✅ TableRepository (NOVO)
- ✅ OrderRepository (NOVO)

#### Use Cases (16)
**Auth (4)**
- ✅ LoginUseCase
- ✅ LogoutUseCase
- ✅ GetCurrentUserUseCase
- ✅ GetUserByIdUseCase

**Product (2)**
- ✅ GetProductsUseCase
- ✅ GetProductByIdUseCase

**Category (1)**
- ✅ GetCategoriesUseCase

**Company (2)**
- ✅ GetCurrentCompanyUseCase
- ✅ GetCompaniesUseCase

**Table (1)**
- ✅ GetTablesUseCase

**Order (2)**
- ✅ CreateOrderUseCase
- ✅ GetOrdersUseCase

**Result: 16 Use Cases** bem estruturados

#### Infraestrutura
- ✅ Core.errors.failures.dart (Failure hierarchy)
- ✅ Core.utils.usecase.dart (UseCase base)
- ✅ DI container preparado
- ✅ Barrel exports

#### Documentação
- ✅ DOMAIN_LAYER_GUIDE.md
- ✅ DOMAIN_REFACTOR_SUMMARY.md
- ✅ CLEAN_ARCHITECTURE_IMPLEMENTATION_GUIDE.md
- ✅ CLEAN_ARCHITECTURE_VISUAL.md
- ✅ Este arquivo (Roadmap)

---

## ⏳ Próximas Fases

### FASE 2: Data Layer (Estimado: 3-4 semanas)

#### O que fazer:

1. **Models (6 classes)**
   - UserModel extends UserEntity
   - ProductModel extends ProductEntity
   - CategoryModel extends CategoryEntity
   - CompanyModel extends CompanyEntity
   - TableModel extends TableEntity
   - OrderModel extends OrderEntity

2. **Remote Data Sources (6 classes)**
   - UserRemoteDataSource + Impl
   - ProductRemoteDataSource + Impl
   - CategoryRemoteDataSource + Impl
   - CompanyRemoteDataSource + Impl
   - TableRemoteDataSource + Impl
   - OrderRemoteDataSource + Impl

3. **Local Data Sources (opcional, para cache)**
   - UserLocalDataSource + Impl
   - ProductLocalDataSource + Impl
   - Etc...

4. **Repository Implementations (6 classes)**
   - UserRepositoryImpl
   - ProductRepositoryImpl
   - CategoryRepositoryImpl
   - CompanyRepositoryImpl
   - TableRepositoryImpl
   - OrderRepositoryImpl

5. **Mappers (6 classes)**
   - UserMapper
   - ProductMapper
   - CategoryMapper
   - CompanyMapper
   - TableMapper
   - OrderMapper

6. **Exceptions/Errors**
   - ServerException
   - NetworkException
   - CacheException
   - ParsingException

#### Estrutura
```
lib/data/
├── models/
│   ├── user_model.dart
│   ├── product_model.dart
│   ├── category_model.dart
│   ├── company_model.dart
│   ├── table_model.dart
│   └── order_model.dart
├── datasources/
│   ├── remote/
│   │   └── [6 datasources]
│   └── local/
│       └── [opcional]
├── repositories/
│   └── [6 repository implementations]
├── mappers/
│   └── [6 mappers]
└── data_barrel.dart
```

---

### FASE 3: Presentation Layer Refatoração (Estimado: 2-3 semanas)

#### O que fazer:

1. **Refatorar Providers com Use Cases**
   - AuthProvider (usar LoginUseCase, GetCurrentUserUseCase)
   - ProductProvider (usar GetProductsUseCase)
   - CategoryProvider (usar GetCategoriesUseCase)
   - CompanyProvider (usar GetCompaniesUseCase, GetCurrentCompanyUseCase)
   - TableProvider (usar GetTablesUseCase)
   - OrderProvider (usar CreateOrderUseCase, GetOrdersUseCase)
   - Etc...

2. **Atualizar Telas**
   - LoginScreen → usar AuthProvider refatorado
   - HomeScreen → usar ProductProvider refatorado
   - Etc...

3. **Novo padrão de Provider**
   ```dart
   class AuthProvider extends ChangeNotifier {
     final LoginUseCase loginUseCase;
     final LogoutUseCase logoutUseCase;
     final GetCurrentUserUseCase getCurrentUserUseCase;
     
     AuthProvider({
       required this.loginUseCase,
       required this.logoutUseCase,
       required this.getCurrentUserUseCase,
     });
     
     Future<void> login(email, password) async {
       final result = await loginUseCase(...);
       result.fold((failure) => error, (user) => update);
     }
   }
   ```

---

### FASE 4: Integração Final (Estimado: 1 semana)

#### O que fazer:

1. **Completar DI (injection_container_clean.dart)**
   - Registrar todos os repositories
   - Registrar todos os use cases
   - Registrar todos os providers

2. **Refatorar main.dart**
   - Usar novo DI
   - Providers com Use Cases
   - Estrutura limpa

3. **Testes**
   - Testes unitários para Use Cases
   - Testes de integração para repositories
   - Testes de widget para telas

4. **Removar código antigo**
   - Deletar providers antigos (gradualmente)
   - Limpar imports
   - Atualizar documentação

---

## 📊 Timeline Visual

```
HOJE ├─ FASE 1 ─┤ FASE 2 ─────────────────┤ FASE 3 ─────────┤ FASE 4 ──┤ LAUNCH
     |          | Domain: 100%             | Data: 100%      | Refactor |
     | Domain   | Data Layer              | Presentation    | Final   |
     | Complete | (Models, DS, Repos)     | (Providers)     | Testing |
     |          |                         |                 |         |
     └──────────└─────────────────────────└─────────────────└─────────┘
     Semana 1   Semana 2-5                Semana 6-7        Semana 8
```

---

## 🎓 Como Contribuir com Cada Fase

### FASE 2 (Data Layer)

1. **Para cada feature (ex: User)**:
   ```
   a) Criar UserModel
      - Estende UserEntity
      - Adiciona fromJson()
      - Adiciona toJson()
      - Adiciona toEntity()
   
   b) Criar UserRemoteDataSource
      - Interface com métodos CRUD
      - Implementação com Supabase
      
   c) Criar UserRepositoryImpl
      - Implementa UserRepository
      - Usa UserRemoteDataSource
      - Trata erros com Either
      
   d) Criar UserMapper
      - Converte UserModel ↔ UserEntity
   
   e) Testar com testes unitários
   ```

2. **Template para Model**:
   ```dart
   class UserModel extends UserEntity {
     const UserModel({...});
     
     factory UserModel.fromJson(Map<String, dynamic> json) {
       return UserModel(...);
     }
     
     Map<String, dynamic> toJson() => {...};
     
     UserEntity toEntity() => UserEntity(...);
   }
   ```

### FASE 3 (Presentation)

1. **Para cada Provider refatorado**:
   ```
   a) Receber Use Cases no construtor
   b) Usar Either<Failure, Result> para tudo
   c) Implementar loading/error/success states
   d) Notificar listeners com notifyListeners()
   e) Usar padrão fold() do dartz
   ```

2. **Exemplo**:
   ```dart
   class AuthProvider extends ChangeNotifier {
     final LoginUseCase loginUseCase;
     UserEntity? _user;
     bool _isLoading = false;
     
     Future<void> login(email, password) async {
       _isLoading = true;
       notifyListeners();
       
       final result = await loginUseCase(
         LoginParams(email: email, password: password)
       );
       
       result.fold(
         (failure) => handleError(failure),
         (user) => handleSuccess(user),
       );
       
       _isLoading = false;
       notifyListeners();
     }
   }
   ```

---

## 📚 Documentação de Referência

| Documento | Propósito | Status |
|-----------|-----------|--------|
| DOMAIN_LAYER_GUIDE.md | Como usar Domain Layer | ✅ Pronto |
| DOMAIN_REFACTOR_SUMMARY.md | Resumo do que foi feito | ✅ Pronto |
| CLEAN_ARCHITECTURE_VISUAL.md | Visualização da arquitetura | ✅ Pronto |
| CLEAN_ARCHITECTURE_IMPLEMENTATION_GUIDE.md | Como implementar Data Layer | ✅ Pronto |
| Este arquivo | Roadmap executivo | ✅ Pronto |

---

## 🚀 Como Começar a Fase 2

### Passo 1: Preparar estrutura
```bash
cd lib/data
mkdir models datasources repositories mappers
```

### Passo 2: Começar com User
```dart
// lib/data/models/user_model.dart
import 'package:villabistromobile/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({...});
  
  factory UserModel.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }
  UserEntity toEntity() { ... }
}
```

### Passo 3: Criar User RemoteDataSource
```dart
// lib/data/datasources/remote/user_remote_datasource.dart
abstract class UserRemoteDataSource {
  Future<UserModel> getCurrentUser();
  Future<UserModel> login(String email, String password);
  ...
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final SupabaseClient supabase;
  UserRemoteDataSourceImpl(this.supabase);
  
  @override
  Future<UserModel> getCurrentUser() async {
    // Implementar com Supabase
  }
  ...
}
```

### Passo 4: Implementar UserRepository
```dart
// lib/data/repositories/user_repository_impl.dart
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;
  
  UserRepositoryImpl(this.remoteDataSource);
  
  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      return Right(user.toEntity());
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  ...
}
```

### Passo 5: Registrar no DI
```dart
// lib/core/di/injection_container_clean.dart
void setupServiceLocator() {
  // DataSources
  getIt.registerSingleton<UserRemoteDataSource>(
    UserRemoteDataSourceImpl(Supabase.instance.client)
  );
  
  // Repositories
  getIt.registerSingleton<UserRepository>(
    UserRepositoryImpl(getIt())
  );
  
  // UseCases (já feito na Fase 1)
  getIt.registerSingleton<LoginUseCase>(
    LoginUseCase(getIt())
  );
  ...
}
```

---

## ✨ Benefícios Esperados

### Curto Prazo (Fase 2-3)
- ✅ Código mais organizado e testável
- ✅ Fácil navegar entre camadas
- ✅ Menos bugs por separação clara

### Médio Prazo (Fase 4+)
- ✅ Onboarding de novos devs mais fácil
- ✅ Adicionar features é rápido
- ✅ Refatorações seguras com testes

### Longo Prazo
- ✅ Escalabilidade garantida
- ✅ Codebase sustentável
- ✅ Pronto para migration para Riverpod/BLoC

---

## 📋 Checklist Geral

- [x] FASE 1: Domain Layer (CONCLUÍDO)
- [ ] FASE 2: Data Layer (⏳ Próxima)
- [ ] FASE 3: Presentation Refactoring (⏳)
- [ ] FASE 4: Final Integration (⏳)
- [ ] Testes completos
- [ ] Deploy com nova arquitetura
- [ ] Documentação finalizada
- [ ] Time treinado

---

## ❓ Dúvidas Frequentes

**P: Posso começar a Fase 2 agora?**
R: Sim! A Fase 1 (Domain) está 100% completa. Você pode começar a implementar Models e DataSources.

**P: Preciso apagar os providers antigos?**
R: Não agora. Mantenha funcionando enquanto refatora. Migre feature por feature.

**P: Como testo Use Cases?**
R: Mock o repository e teste com Either. Ver exemplo em CLEAN_ARCHITECTURE_VISUAL.md

**P: Quando mudar para Riverpod?**
R: Depois que toda a arquitetura (Data + Domain) estiver estável. Riverpod é optional.

**P: Quanto tempo leva tudo?**
R: Estimado 6-8 semanas com 1 dev a tempo parcial. Pode ser mais rápido com mais pessoas.

---

## 🎉 Conclusão

Parabéns por começar essa jornada! Clean Architecture é um investimento inicial que se paga rápido.

**Próximo passo: Começar a Fase 2 - Data Layer**

Boa sorte! 🚀

---

*Última atualização: Novembro 28, 2025*
*Criado por: GitHub Copilot - Clean Architecture Specialist*
