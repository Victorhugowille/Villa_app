# Clean Architecture - VillaBistro Mobile

## Estrutura de Pastas

```
lib/
├── core/                          # Camada de núcleo - Código compartilhado
│   ├── constants/                 # Constantes da aplicação
│   │   └── app_constants.dart
│   ├── di/                        # Dependency Injection
│   │   └── injection_container.dart
│   ├── errors/                    # Tratamento de erros
│   │   └── failures.dart
│   └── utils/                     # Utilities
│       ├── typedef.dart           # Type definitions (Either, Result)
│       └── usecase.dart           # Base UseCase class
│
├── data/                          # Camada de Dados
│   ├── datasources/               # Implementação de dados (APIs, DB)
│   │   └── user_remote_datasource.dart
│   ├── models/                    # Data Transfer Objects (DTOs)
│   │   └── user_model.dart
│   └── repositories/              # Implementação dos repositories
│       └── user_repository_impl.dart
│
├── domain/                        # Camada de Domínio (lógica de negócio)
│   ├── entities/                  # Objetos de domínio
│   │   ├── base_entity.dart
│   │   └── user_entity.dart
│   ├── repositories/              # Contratos (interfaces)
│   │   └── user_repository.dart
│   └── usecases/                  # Casos de uso
│       ├── get_current_user_usecase.dart
│       └── get_user_by_id_usecase.dart
│
├── presentation/                  # Camada de Apresentação (UI)
│   ├── pages/                     # Telas da aplicação
│   ├── providers/                 # State management (ChangeNotifier)
│   │   └── user_provider.dart
│   └── widgets/                   # Widgets reutilizáveis
│
└── main.dart                      # Entry point
```

## Fluxo de Dados

```
UI (Widget) 
  ↓
Provider (State Management) 
  ↓
UseCase (Regra de Negócio)
  ↓
Repository (Abstração de Dados)
  ↓
DataSource (Implementação - API/DB)
  ↓
Response/Entity
```

## Camadas Explicadas

### 1. **Core** - Código Compartilhado
- Erros e falhas comuns
- Utilitários e helpers
- Constantes da aplicação
- Injeção de dependência (GetIt)

### 2. **Data** - Camada de Dados
- **DataSources**: Implementam acesso aos dados (Supabase, APIs, cache)
- **Models**: DTOs com serialização JSON
- **Repositories**: Implementam contratos definidos no domínio

### 3. **Domain** - Lógica de Negócio
- **Entities**: Objetos de domínio (sem dependências)
- **Repositories**: Interfaces que definem contratos
- **UseCases**: Implementam um caso de uso da aplicação

### 4. **Presentation** - Interface do Usuário
- **Pages**: Telas da aplicação
- **Providers**: Gerenciam estado com ChangeNotifier
- **Widgets**: Componentes reutilizáveis

## Como Usar

### Criar uma Novo Feature

#### 1. Criar Entity (Domain Layer)
```dart
// lib/domain/entities/product_entity.dart
class ProductEntity extends BaseEntity {
  final String id;
  final String name;
  final double price;
  
  ProductEntity({
    required this.id,
    required this.name,
    required this.price,
  });
  
  @override
  List<Object?> get props => [id, name, price];
}
```

#### 2. Criar Model (Data Layer)
```dart
// lib/data/models/product_model.dart
class ProductModel {
  final String id;
  final String name;
  final double price;
  
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      price: json['price'].toDouble(),
    );
  }
  
  toJson() => {...}
}
```

#### 3. Criar Repository Interface (Domain Layer)
```dart
// lib/domain/repositories/product_repository.dart
abstract class ProductRepository {
  Future<Either<Failure, List<ProductEntity>>> getProducts();
}
```

#### 4. Criar DataSource (Data Layer)
```dart
// lib/data/datasources/product_remote_datasource.dart
abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts();
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  @override
  Future<List<ProductModel>> getProducts() async {
    // Implementar com Supabase
  }
}
```

#### 5. Implementar Repository (Data Layer)
```dart
// lib/data/repositories/product_repository_impl.dart
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  
  @override
  Future<Either<Failure, List<ProductEntity>>> getProducts() async {
    try {
      final models = await remoteDataSource.getProducts();
      return Right(models as List<ProductEntity>);
    } catch(e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
```

#### 6. Criar UseCase (Domain Layer)
```dart
// lib/domain/usecases/get_products_usecase.dart
class GetProductsUseCase extends UseCase<List<ProductEntity>, NoParams> {
  final ProductRepository repository;
  
  @override
  Future<Either<Failure, List<ProductEntity>>> call(NoParams params) {
    return repository.getProducts();
  }
}
```

#### 7. Criar Provider (Presentation Layer)
```dart
// lib/presentation/providers/product_provider.dart
class ProductProvider extends ChangeNotifier {
  final GetProductsUseCase getProductsUseCase;
  
  List<ProductEntity>? _products;
  bool _isLoading = false;
  String? _error;
  
  // ... getters e métodos
  
  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();
    
    final result = await getProductsUseCase(NoParams());
    result.fold(
      (failure) => _error = failure.message,
      (products) => _products = products,
    );
    
    _isLoading = false;
    notifyListeners();
  }
}
```

#### 8. Registrar no Service Locator
```dart
// lib/core/di/injection_container.dart
void setupServiceLocator() {
  // Datasources
  getIt.registerSingleton<ProductRemoteDataSource>(
    ProductRemoteDataSourceImpl(),
  );
  
  // Repositories
  getIt.registerSingleton<ProductRepository>(
    ProductRepositoryImpl(
      remoteDataSource: getIt<ProductRemoteDataSource>(),
    ),
  );
  
  // UseCases
  getIt.registerSingleton<GetProductsUseCase>(
    GetProductsUseCase(getIt<ProductRepository>()),
  );
  
  // Providers
  getIt.registerSingleton<ProductProvider>(
    ProductProvider(getProductsUseCase: getIt<GetProductsUseCase>()),
  );
}
```

#### 9. Usar na Widget (Presentation Layer)
```dart
// lib/presentation/pages/products_page.dart
class ProductsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProductProvider>(
      create: (_) => getIt<ProductProvider>()..loadProducts(),
      child: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) return CircularProgressIndicator();
          if (provider.error != null) return Text(provider.error!);
          
          return ListView(
            children: provider.products?.map((p) => 
              ListTile(title: Text(p.name))
            ).toList() ?? [],
          );
        },
      ),
    );
  }
}
```

## Tratamento de Erros

Use o sistema de `Failure` para tratamento de erros:

```dart
// Definir novo erro em core/errors/failures.dart
class CacheFailure extends Failure {
  const CacheFailure(String message) : super(message);
}

// Usar em datasources ou repositories
result.fold(
  (failure) {
    if (failure is CacheFailure) {
      // Handle cache error
    }
  },
  (success) {
    // Handle success
  },
);
```

## Benefícios da Clean Architecture

✅ **Independência de Framework** - Lógica não depende de Flutter
✅ **Testabilidade** - Fácil de testar cada camada
✅ **Escalabilidade** - Fácil adicionar novos features
✅ **Manutenibilidade** - Código organizado e bem definido
✅ **Reusabilidade** - Componentes podem ser reutilizados
✅ **Separação de Responsabilidades** - Cada camada tem um propósito

## Próximos Passos

1. ✅ Estrutura criada
2. ⏳ Mover models existentes para domain/entities
3. ⏳ Implementar DataSources com Supabase
4. ⏳ Refatorar providers existentes para UseCases
5. ⏳ Atualizar main.dart com setupServiceLocator()
6. ⏳ Migrar screens para nova estrutura

## Referências

- [Uncle Bob's Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Clean Architecture in Flutter](https://resocoder.com/flutter-clean-architecture)
