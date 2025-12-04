# 🏗️ Refatoração para Clean Architecture

## ✅ O que foi feito

### 1. **Estrutura de Pastas Criada**
- ✅ `lib/core/` - Código compartilhado (errors, utils, DI, constants)
- ✅ `lib/data/` - Camada de dados (datasources, models, repositories)
- ✅ `lib/domain/` - Lógica de negócio (entities, repositories abstratas, usecases)
- ✅ `lib/presentation/` - Interface do usuário (pages, providers, widgets)

### 2. **Dependências Adicionadas**
```yaml
get_it: ^7.6.0       # Service Locator / Dependency Injection
dartz: ^0.10.1       # Either pattern para tratamento de erros
equatable: ^2.0.5    # Igualdade estrutural de objetos
```

### 3. **Arquivos Base Criados**
- ✅ `core/errors/failures.dart` - Tipos de erros
- ✅ `core/utils/typedef.dart` - Type aliases (ResultFuture, Result)
- ✅ `core/utils/usecase.dart` - Base UseCase
- ✅ `core/constants/app_constants.dart` - Constantes da app
- ✅ `core/di/injection_container.dart` - Service Locator setup

### 4. **Exemplo de Feature Criado (User)**
Veja a pasta `domain/usecases/` para entender o padrão:
- `domain/entities/user_entity.dart` - Entidade de usuário
- `domain/repositories/user_repository.dart` - Contrato do repository
- `domain/usecases/get_current_user_usecase.dart` - UseCase
- `data/models/user_model.dart` - DTO com serialização
- `data/datasources/user_remote_datasource.dart` - Acesso a dados
- `data/repositories/user_repository_impl.dart` - Implementação
- `presentation/providers/user_provider.dart` - Provider (ChangeNotifier)

### 5. **Documentação Completa**
📖 Veja `CLEAN_ARCHITECTURE_GUIDE.md` para tutorial completo

---

## 📋 Próximos Passos (TODO)

### 1. **Refatorar Features Existentes**

Para cada feature (auth, products, orders, etc), seguir este padrão:

```
Feature Name:
├── domain/
│   ├── entities/
│   ├── repositories/ (abstracts)
│   └── usecases/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/ (implementations)
└── presentation/
    ├── pages/
    ├── providers/
    └── widgets/
```

### 2. **Migrar Providers Existentes**

Seus providers atuais (`auth_provider.dart`, `product_provider.dart`, etc) precisam ser refatorados:

**Antes (atual):**
```dart
class ProductProvider extends ChangeNotifier {
  // Contém lógica de negócio misturada com UI
  List<Product> products = [];
  
  void loadProducts() {
    // Busca direto do Supabase
  }
}
```

**Depois (Clean Architecture):**
```dart
// 1. UseCase já contém a lógica
class GetProductsUseCase { }

// 2. Provider só gerencia estado da UI
class ProductProvider extends ChangeNotifier {
  final GetProductsUseCase getProductsUseCase;
  
  Future<void> loadProducts() async {
    final result = await getProductsUseCase(NoParams());
    result.fold(
      (failure) => _error = failure.message,
      (products) => _products = products,
    );
    notifyListeners();
  }
}
```

### 3. **Implementar DataSources com Supabase**

Todos os `*_remote_datasource.dart` precisam ser implementados com Supabase:

```dart
class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final SupabaseClient supabaseClient;
  
  ProductRemoteDataSourceImpl({required this.supabaseClient});
  
  @override
  Future<List<ProductModel>> getProducts() async {
    final response = await supabaseClient
        .from('products')
        .select()
        .withConverter((json) => ProductModel.fromJson(json));
    
    return response as List<ProductModel>;
  }
}
```

### 4. **Registrar no Service Locator**

Cada novo usecase precisa ser registrado em `core/di/injection_container.dart`:

```dart
void setupServiceLocator() {
  // ... existing code ...
  
  // NOVO FEATURE
  getIt.registerSingleton<ProductRemoteDataSource>(
    ProductRemoteDataSourceImpl(supabaseClient: Supabase.instance.client),
  );
  getIt.registerSingleton<ProductRepository>(
    ProductRepositoryImpl(remoteDataSource: getIt<ProductRemoteDataSource>()),
  );
  getIt.registerSingleton<GetProductsUseCase>(
    GetProductsUseCase(getIt<ProductRepository>()),
  );
  getIt.registerSingleton<ProductProvider>(
    ProductProvider(getProductsUseCase: getIt<GetProductsUseCase>()),
  );
}
```

### 5. **Usar na UI**

Quando usar na tela, sempre usar através do GetIt:

```dart
class ProductsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProductProvider>(
      create: (_) => getIt<ProductProvider>()..loadProducts(),
      child: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          // UI code aqui
        },
      ),
    );
  }
}
```

---

## 🎯 Ordem Sugerida de Migração

1. **Auth Feature** (Login, Register, etc)
2. **Companies Feature** (Gerenciamento de empresas)
3. **Products Feature** (Produtos e categorias)
4. **Orders Feature** (Pedidos)
5. **Tables Feature** (Mesas)
6. **Transactions Feature** (Transações/Vendas)
7. **Reports Feature** (Relatórios)

---

## 🔍 Como Verificar o Progresso

```bash
# Verificar se não há erros de compilação
flutter analyze

# Rodar testes (quando criados)
flutter test

# Build para verificar
flutter build apk
```

---

## 📚 Estrutura Completa Esperada

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart
│   ├── di/
│   │   └── injection_container.dart
│   ├── errors/
│   │   └── failures.dart
│   └── utils/
│       ├── typedef.dart
│       └── usecase.dart
│
├── data/
│   ├── datasources/
│   │   ├── auth_remote_datasource.dart
│   │   ├── company_remote_datasource.dart
│   │   ├── product_remote_datasource.dart
│   │   ├── order_remote_datasource.dart
│   │   └── ...
│   ├── models/
│   │   ├── auth_model.dart
│   │   ├── company_model.dart
│   │   ├── product_model.dart
│   │   └── ...
│   └── repositories/
│       ├── auth_repository_impl.dart
│       ├── company_repository_impl.dart
│       ├── product_repository_impl.dart
│       └── ...
│
├── domain/
│   ├── entities/
│   │   ├── base_entity.dart
│   │   ├── auth_entity.dart
│   │   ├── company_entity.dart
│   │   ├── product_entity.dart
│   │   └── ...
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── company_repository.dart
│   │   ├── product_repository.dart
│   │   └── ...
│   └── usecases/
│       ├── auth/
│       │   ├── login_usecase.dart
│       │   ├── register_usecase.dart
│       │   └── logout_usecase.dart
│       ├── companies/
│       │   └── get_companies_usecase.dart
│       └── ...
│
├── presentation/
│   ├── pages/
│   │   ├── auth/
│   │   │   ├── login_page.dart
│   │   │   └── register_page.dart
│   │   ├── companies/
│   │   ├── products/
│   │   ├── orders/
│   │   └── ...
│   ├── providers/
│   │   ├── auth_provider.dart (NOVO - refatorado)
│   │   ├── company_provider.dart (NOVO - refatorado)
│   │   ├── product_provider.dart (NOVO - refatorado)
│   │   └── ...
│   └── widgets/
│       ├── auth_widgets.dart
│       ├── common_widgets.dart
│       └── ...
│
└── main.dart (ATUALIZADO)
```

---

## 💡 Dicas Importantes

1. **Não misture camadas** - Data não pode depender de Presentation
2. **UseCase = Um caso de uso** - `GetProductsUseCase`, `CreateOrderUseCase`, etc
3. **Models vs Entities** - Models têm serialização JSON, Entities não
4. **Errors sempre Either** - Use `Either<Failure, Success>` não Exception
5. **Testabilidade** - Cada classe deve poder ser testada isoladamente

---

## ❓ Dúvidas?

Consulte:
- `CLEAN_ARCHITECTURE_GUIDE.md` - Guia completo com exemplos
- `lib/domain/usecases/` - Veja como está implementado UserUseCase
- `lib/presentation/providers/user_provider.dart` - Veja como usar UseCase no Provider

---

**Status**: 🚀 Pronto para começar a refatoração!
