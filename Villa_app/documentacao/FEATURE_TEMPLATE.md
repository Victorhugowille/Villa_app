# 📋 TEMPLATE - Criando Nova Feature

Use este template para criar uma nova feature rapidamente. Substitua `[FEATURE_NAME]` pelo nome real.

---

## 1️⃣ Entity (Domain Layer)

**Arquivo:** `lib/domain/entities/[feature_name]_entity.dart`

```dart
import 'package:villabistromobile/domain/entities/base_entity.dart';

class [FeatureName]Entity extends BaseEntity {
  final String id;
  final String name;
  // TODO: Adicionar mais propriedades

  const [FeatureName]Entity({
    required this.id,
    required this.name,
    // TODO: Adicionar construtores
  });

  @override
  List<Object?> get props => [id, name];
}
```

---

## 2️⃣ Model (Data Layer)

**Arquivo:** `lib/data/models/[feature_name]_model.dart`

```dart
import 'package:equatable/equatable.dart';

class [FeatureName]Model extends Equatable {
  final String id;
  final String name;
  // TODO: Adicionar mais propriedades

  const [FeatureName]Model({
    required this.id,
    required this.name,
    // TODO: Adicionar construtores
  });

  factory [FeatureName]Model.fromJson(Map<String, dynamic> json) {
    return [FeatureName]Model(
      id: json['id'] as String,
      name: json['name'] as String,
      // TODO: Mapear mais propriedades
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      // TODO: Serializar mais propriedades
    };
  }

  @override
  List<Object?> get props => [id, name];
}
```

---

## 3️⃣ Repository Interface (Domain Layer)

**Arquivo:** `lib/domain/repositories/[feature_name]_repository.dart`

```dart
import 'package:dartz/dartz.dart';
import 'package:villabistromobile/core/errors/failures.dart';
import 'package:villabistromobile/domain/entities/[feature_name]_entity.dart';

abstract class [FeatureName]Repository {
  Future<Either<Failure, List<[FeatureName]Entity>>> getAll();
  Future<Either<Failure, [FeatureName]Entity>> getById(String id);
  Future<Either<Failure, [FeatureName]Entity>> create([FeatureName]Entity entity);
  Future<Either<Failure, [FeatureName]Entity>> update([FeatureName]Entity entity);
  Future<Either<Failure, void>> delete(String id);
}
```

---

## 4️⃣ Remote DataSource (Data Layer)

**Arquivo:** `lib/data/datasources/[feature_name]_remote_datasource.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:villabistromobile/data/models/[feature_name]_model.dart';

abstract class [FeatureName]RemoteDataSource {
  Future<List<[FeatureName]Model>> getAll();
  Future<[FeatureName]Model> getById(String id);
  Future<[FeatureName]Model> create([FeatureName]Model model);
  Future<[FeatureName]Model> update([FeatureName]Model model);
  Future<void> delete(String id);
}

class [FeatureName]RemoteDataSourceImpl implements [FeatureName]RemoteDataSource {
  final SupabaseClient supabaseClient;

  [FeatureName]RemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<[FeatureName]Model>> getAll() async {
    try {
      final response = await supabaseClient
          .from('[feature_table_name]')
          .select()
          .withConverter((json) => json is List
              ? json
                  .map((item) => [FeatureName]Model.fromJson(item))
                  .toList()
              : [[FeatureName]Model.fromJson(json)]);

      return response as List<[FeatureName]Model>;
    } catch (e) {
      throw Exception('Failed to get all: $e');
    }
  }

  @override
  Future<[FeatureName]Model> getById(String id) async {
    try {
      final response = await supabaseClient
          .from('[feature_table_name]')
          .select()
          .eq('id', id)
          .single()
          .withConverter((json) => [FeatureName]Model.fromJson(json));

      return response as [FeatureName]Model;
    } catch (e) {
      throw Exception('Failed to get by id: $e');
    }
  }

  @override
  Future<[FeatureName]Model> create([FeatureName]Model model) async {
    try {
      final response = await supabaseClient
          .from('[feature_table_name]')
          .insert(model.toJson())
          .select()
          .single()
          .withConverter((json) => [FeatureName]Model.fromJson(json));

      return response as [FeatureName]Model;
    } catch (e) {
      throw Exception('Failed to create: $e');
    }
  }

  @override
  Future<[FeatureName]Model> update([FeatureName]Model model) async {
    try {
      final response = await supabaseClient
          .from('[feature_table_name]')
          .update(model.toJson())
          .eq('id', model.id)
          .select()
          .single()
          .withConverter((json) => [FeatureName]Model.fromJson(json));

      return response as [FeatureName]Model;
    } catch (e) {
      throw Exception('Failed to update: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await supabaseClient.from('[feature_table_name]').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete: $e');
    }
  }
}
```

---

## 5️⃣ Repository Implementation (Data Layer)

**Arquivo:** `lib/data/repositories/[feature_name]_repository_impl.dart`

```dart
import 'package:dartz/dartz.dart';
import 'package:villabistromobile/core/errors/failures.dart';
import 'package:villabistromobile/data/datasources/[feature_name]_remote_datasource.dart';
import 'package:villabistromobile/domain/entities/[feature_name]_entity.dart';
import 'package:villabistromobile/domain/repositories/[feature_name]_repository.dart';

class [FeatureName]RepositoryImpl implements [FeatureName]Repository {
  final [FeatureName]RemoteDataSource remoteDataSource;

  [FeatureName]RepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<[FeatureName]Entity>>> getAll() async {
    try {
      final models = await remoteDataSource.getAll();
      return Right(models as List<[FeatureName]Entity>);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, [FeatureName]Entity>> getById(String id) async {
    try {
      final model = await remoteDataSource.getById(id);
      return Right(model as [FeatureName]Entity);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, [FeatureName]Entity>> create(
      [FeatureName]Entity entity) async {
    try {
      final model = await remoteDataSource.create(entity as [FeatureName]Model);
      return Right(model as [FeatureName]Entity);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, [FeatureName]Entity>> update(
      [FeatureName]Entity entity) async {
    try {
      final model = await remoteDataSource.update(entity as [FeatureName]Model);
      return Right(model as [FeatureName]Entity);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    try {
      await remoteDataSource.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
```

---

## 6️⃣ UseCases (Domain Layer)

**Arquivo:** `lib/domain/usecases/[feature_name]/get_all_[feature_name]_usecase.dart`

```dart
import 'package:dartz/dartz.dart';
import 'package:villabistromobile/core/errors/failures.dart';
import 'package:villabistromobile/core/utils/usecase.dart';
import 'package:villabistromobile/domain/entities/[feature_name]_entity.dart';
import 'package:villabistromobile/domain/repositories/[feature_name]_repository.dart';

class GetAll[FeatureName]UseCase
    extends UseCase<List<[FeatureName]Entity>, NoParams> {
  final [FeatureName]Repository repository;

  GetAll[FeatureName]UseCase(this.repository);

  @override
  Future<Either<Failure, List<[FeatureName]Entity>>> call(NoParams params) {
    return repository.getAll();
  }
}
```

**Arquivo:** `lib/domain/usecases/[feature_name]/get_[feature_name]_by_id_usecase.dart`

```dart
import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import 'package:villabistromobile/core/errors/failures.dart';
import 'package:villabistromobile/core/utils/usecase.dart';
import 'package:villabistromobile/domain/entities/[feature_name]_entity.dart';
import 'package:villabistromobile/domain/repositories/[feature_name]_repository.dart';

class Get[FeatureName]ByIdUseCase
    extends UseCase<[FeatureName]Entity, Get[FeatureName]ByIdParams> {
  final [FeatureName]Repository repository;

  Get[FeatureName]ByIdUseCase(this.repository);

  @override
  Future<Either<Failure, [FeatureName]Entity>> call(
      Get[FeatureName]ByIdParams params) {
    return repository.getById(params.id);
  }
}

class Get[FeatureName]ByIdParams extends Equatable {
  final String id;

  const Get[FeatureName]ByIdParams({required this.id});

  @override
  List<Object?> get props => [id];
}
```

---

## 7️⃣ Provider (Presentation Layer)

**Arquivo:** `lib/presentation/providers/[feature_name]_provider.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:villabistromobile/core/utils/usecase.dart';
import 'package:villabistromobile/domain/entities/[feature_name]_entity.dart';
import 'package:villabistromobile/domain/usecases/[feature_name]/get_all_[feature_name]_usecase.dart';
import 'package:villabistromobile/domain/usecases/[feature_name]/get_[feature_name]_by_id_usecase.dart';

class [FeatureName]Provider extends ChangeNotifier {
  final GetAll[FeatureName]UseCase getAll[FeatureName]UseCase;
  final Get[FeatureName]ByIdUseCase get[FeatureName]ByIdUseCase;

  List<[FeatureName]Entity>? _items;
  [FeatureName]Entity? _selectedItem;
  bool _isLoading = false;
  String? _error;

  [FeatureName]Provider({
    required this.getAll[FeatureName]UseCase,
    required this.get[FeatureName]ByIdUseCase,
  });

  List<[FeatureName]Entity>? get items => _items;
  [FeatureName]Entity? get selectedItem => _selectedItem;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await getAll[FeatureName]UseCase(NoParams());
    result.fold(
      (failure) {
        _error = failure.message;
        _items = null;
      },
      (items) {
        _items = items;
        _error = null;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadById(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result =
        await get[FeatureName]ByIdUseCase(Get[FeatureName]ByIdParams(id: id));
    result.fold(
      (failure) {
        _error = failure.message;
        _selectedItem = null;
      },
      (item) {
        _selectedItem = item;
        _error = null;
      },
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

## 8️⃣ Registrar no Service Locator

**Arquivo:** `lib/core/di/injection_container.dart` (ADICIONAR)

```dart
// Adicione isto dentro de setupServiceLocator()

// [FEATURE_NAME] Datasources
getIt.registerSingleton<[FeatureName]RemoteDataSource>(
  [FeatureName]RemoteDataSourceImpl(
    supabaseClient: Supabase.instance.client,
  ),
);

// [FEATURE_NAME] Repositories
getIt.registerSingleton<[FeatureName]Repository>(
  [FeatureName]RepositoryImpl(
    remoteDataSource: getIt<[FeatureName]RemoteDataSource>(),
  ),
);

// [FEATURE_NAME] UseCases
getIt.registerSingleton<GetAll[FeatureName]UseCase>(
  GetAll[FeatureName]UseCase(getIt<[FeatureName]Repository>()),
);
getIt.registerSingleton<Get[FeatureName]ByIdUseCase>(
  Get[FeatureName]ByIdUseCase(getIt<[FeatureName]Repository>()),
);

// [FEATURE_NAME] Providers
getIt.registerSingleton<[FeatureName]Provider>(
  [FeatureName]Provider(
    getAll[FeatureName]UseCase: getIt<GetAll[FeatureName]UseCase>(),
    get[FeatureName]ByIdUseCase: getIt<Get[FeatureName]ByIdUseCase>(),
  ),
);
```

---

## 9️⃣ Usar na Page

**Arquivo:** `lib/presentation/pages/[feature_name]/[feature_name]_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/core/di/injection_container.dart';
import 'package:villabistromobile/presentation/providers/[feature_name]_provider.dart';

class [FeatureName]Page extends StatelessWidget {
  const [FeatureName]Page({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<[FeatureName]Provider>(
      create: (_) => getIt<[FeatureName]Provider>()..loadAll(),
      child: Scaffold(
        appBar: AppBar(title: const Text('[Feature Name]')),
        body: Consumer<[FeatureName]Provider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null) {
              return Center(
                child: Text('Erro: ${provider.error}'),
              );
            }

            if (provider.items?.isEmpty ?? true) {
              return const Center(child: Text('Nenhum item encontrado'));
            }

            return ListView.builder(
              itemCount: provider.items?.length ?? 0,
              itemBuilder: (context, index) {
                final item = provider.items![index];
                return ListTile(
                  title: Text(item.name),
                  // TODO: Adicionar mais detalhes
                );
              },
            );
          },
        ),
      ),
    );
  }
}
```

---

## ✅ Checklist de Implementação

- [ ] Entity criada
- [ ] Model criada com fromJson/toJson
- [ ] Repository interface criada
- [ ] DataSource criada e implementada
- [ ] Repository implementation criada
- [ ] UseCases criadas
- [ ] Provider criado
- [ ] Service Locator atualizado
- [ ] Imports corretos em todos os arquivos
- [ ] `flutter analyze` sem erros
- [ ] Compilação OK
- [ ] Funcionalidade testada

---

## 📝 Dicas

1. **Nomenclatura:** Use PascalCase para classes, snake_case para arquivos
2. **Imports:** Use `package:` imports, nunca relative imports
3. **Parametros:** Sempre use named parameters com `required`
4. **Tipos:** Nunca use `dynamic`, sempre declare tipos explícitos
5. **Errors:** Use `Left(Failure(...))` nunca `throw Exception`

---

Pronto! Agora você tem um template para criar qualquer nova feature rapidamente.
