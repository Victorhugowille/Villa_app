# Domain Layer - Camada de Domínio

## Visão Geral

A camada Domain é o coração da Clean Architecture. Ela contém:

- **Entities**: Modelos puros de domínio (sem dependências externas)
- **Repositories (abstratos)**: Contratos/interfaces que definem o que os dados precisam fazer
- **Use Cases**: Casos de uso da aplicação (lógica de negócio)

## Estrutura

```
lib/domain/
├── entities/           # Modelos puros de dados
│   ├── base_entity.dart
│   ├── user_entity.dart
│   ├── product_entity.dart
│   ├── category_entity.dart
│   ├── company_entity.dart
│   ├── table_entity.dart
│   ├── order_entity.dart
│   └── cart_item_entity.dart
│
├── repositories/       # Abstrações/Interfaces
│   ├── user_repository.dart
│   ├── product_repository.dart
│   ├── category_repository.dart
│   ├── company_repository.dart
│   ├── table_repository.dart
│   └── order_repository.dart
│
├── usecases/          # Casos de uso (lógica de negócio)
│   ├── auth/
│   │   ├── get_current_user_usecase.dart
│   │   ├── get_user_by_id_usecase.dart
│   │   ├── login_usecase.dart
│   │   └── logout_usecase.dart
│   ├── product/
│   │   ├── get_products_usecase.dart
│   │   └── get_product_by_id_usecase.dart
│   ├── category/
│   │   └── get_categories_usecase.dart
│   ├── company/
│   │   ├── get_current_company_usecase.dart
│   │   └── get_companies_usecase.dart
│   ├── table/
│   │   └── get_tables_usecase.dart
│   └── order/
│       ├── create_order_usecase.dart
│       └── get_orders_usecase.dart
│
└── domain_barrel.dart  # Exportações centralizadas
```

## Princípios

### 1. **Entities - Modelos Puros**
- Sem dependências externas
- Imutáveis (const constructors)
- Implementam Equatable para comparação
- Possuem copyWith() para atualização

```dart
class ProductEntity extends Equatable {
  final String id;
  final String name;
  // ...
  
  ProductEntity copyWith({String? name, ...}) {
    return ProductEntity(
      name: name ?? this.name,
      // ...
    );
  }
}
```

### 2. **Repositories - Abstrações**
- Definem contratos (interfaces)
- Retornam `Either<Failure, T>` para tratamento de erros
- Implementações ficam na camada Data
- Independem de detalhes técnicos

```dart
abstract class UserRepository {
  Future<Either<Failure, UserEntity>> login(String email, String password);
  Future<Either<Failure, UserEntity>> getCurrentUser();
  // ...
}
```

### 3. **Use Cases - Lógica de Negócio**
- Encapsulam um caso de uso único
- Recebem Params (Equatable)
- Retornam Either<Failure, ResultType>
- Reutilizáveis e testáveis

```dart
class GetCurrentUserUseCase extends UseCase<UserEntity, NoParams> {
  final UserRepository repository;
  
  GetCurrentUserUseCase(this.repository);
  
  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) {
    return repository.getCurrentUser();
  }
}
```

## Padrão Either

Usamos `dartz` para `Either<Failure, Success>`:
- **Left (Failure)**: Erro ocorreu
- **Right (Success)**: Operação bem-sucedida

```dart
// Na data layer (implementação):
Future<Either<Failure, UserEntity>> getCurrentUser() async {
  try {
    final user = await supabase.from('users').select().single();
    return Right(UserModel.fromJson(user).toEntity());
  } on Exception catch (e) {
    return Left(ServerFailure('Erro ao carregar usuário'));
  }
}

// Utilizando no presentation:
final result = await getCurrentUserUseCase(NoParams());
result.fold(
  (failure) => showError(failure.message),
  (user) => updateUI(user),
);
```

## Adicionando Novas Features

Para adicionar uma nova feature, siga este checklist:

1. **Entity**:
   ```dart
   // lib/domain/entities/my_entity.dart
   class MyEntity extends Equatable {
     final String id;
     // ... campos
   }
   ```

2. **Repository Abstrato**:
   ```dart
   // lib/domain/repositories/my_repository.dart
   abstract class MyRepository {
     Future<Either<Failure, MyEntity>> getMyData();
   }
   ```

3. **Use Cases**:
   ```dart
   // lib/domain/usecases/my_feature/get_my_data_usecase.dart
   class GetMyDataUseCase extends UseCase<MyEntity, NoParams> {
     final MyRepository repository;
     // ...
   }
   ```

4. **Data Layer** (próxima etapa):
   - Model (extends Entity)
   - Remote DataSource
   - Repository Implementation
   - Mapper (Entity ↔ Model)

5. **Presentation Layer** (próxima etapa):
   - Provider/State Management
   - Telas e Widgets

## Benefícios

✅ **Independência**: Domain não depende de framework Flutter
✅ **Testabilidade**: Fácil de fazer testes unitários
✅ **Manutenibilidade**: Mudanças em uma camada não afetam outras
✅ **Reutilização**: Use Cases podem ser usados em múltiplos contextos
✅ **Escalabilidade**: Fácil adicionar novas features sem quebrar código existente

## Próximos Passos

1. ✅ **Domain Layer** (CONCLUÍDO)
2. ⏳ Data Layer (Models, DataSources, Repository Implementations)
3. ⏳ Presentation Layer (State Management, Screens, Widgets)
4. ⏳ DI/Service Locator (GetIt com injeção automática)
5. ⏳ Main.dart (Refatorado com Clean Architecture)
