# 🚀 QUICK START - Clean Architecture VillaBistro

## O que foi criado?

Sua aplicação foi refatorada para seguir **Clean Architecture**. Aqui estão os arquivos principais:

### 📚 Documentação
- 📖 `CLEAN_ARCHITECTURE_GUIDE.md` - Guia completo da arquitetura
- 📖 `MIGRATION_GUIDE.md` - Passos para migrar suas features
- 📖 `AUTH_REFACTORING_EXAMPLE.md` - Exemplo passo-a-passo

### 📁 Novas Pastas Criadas

```
lib/
├── core/               # Código compartilhado
│   ├── constants/      # Constantes
│   ├── di/             # Injeção de dependência
│   ├── errors/         # Tipos de erro
│   └── utils/          # Utilitários
│
├── data/               # Acesso a dados
│   ├── datasources/    # APIs, Databases
│   ├── models/         # DTOs
│   └── repositories/   # Implementações
│
├── domain/             # Lógica de negócio
│   ├── entities/       # Objetos de domínio
│   ├── repositories/   # Interfaces
│   └── usecases/       # Casos de uso
│
└── presentation/       # Interface do usuário
    ├── pages/          # Telas
    ├── providers/      # State management
    └── widgets/        # Componentes
```

---

## 🎯 Próximos Passos

### 1️⃣ Verificar se tudo está funcionando

```bash
cd "c:\projetos\VILLABISTRO\villamobile\Villa_app"
flutter pub get
flutter analyze  # Verificar erros
```

### 2️⃣ Escolher uma feature para começar

**Recomendado começar por uma feature menor:**
- Auth (Login/Register)
- Companies (Gerenciamento)
- Products (Produtos)

### 3️⃣ Seguir o padrão do exemplo

Veja `AUTH_REFACTORING_EXAMPLE.md` e repita os 9 passos para cada feature:

```
1. Criar Entity (domain/entities/)
2. Criar Model (data/models/)
3. Criar Repository Interface (domain/repositories/)
4. Criar DataSource (data/datasources/)
5. Implementar Repository (data/repositories/)
6. Criar UseCase(s) (domain/usecases/)
7. Refatorar Provider (presentation/providers/)
8. Registrar no Service Locator (core/di/)
9. Usar na UI
```

---

## 💻 Comandos Úteis

```bash
# Verificar análise estática
flutter analyze

# Verificar imports não utilizados
flutter analyze --no-preamble

# Limpar cache
flutter clean

# Rebuild
flutter pub get
flutter pub upgrade

# Testar (quando criar testes)
flutter test
```

---

## 📝 Checklist de Migração

Para cada feature, marque conforme progride:

### Feature: Auth
- [ ] Entity criada
- [ ] Model criada
- [ ] Repository interface criada
- [ ] DataSource criada
- [ ] Repository impl criada
- [ ] UseCase(s) criada
- [ ] Provider refatorado
- [ ] Registrado no Service Locator
- [ ] Testes: Compilação OK
- [ ] Testes: Funcionalidade OK

### Feature: Companies
- [ ] Entity criada
- [ ] Model criada
- [ ] Repository interface criada
- [ ] DataSource criada
- [ ] Repository impl criada
- [ ] UseCase(s) criada
- [ ] Provider refatorado
- [ ] Registrado no Service Locator
- [ ] Testes: Compilação OK
- [ ] Testes: Funcionalidade OK

### Feature: Products
- [ ] Entity criada
- [ ] Model criada
- [ ] Repository interface criada
- [ ] DataSource criada
- [ ] Repository impl criada
- [ ] UseCase(s) criada
- [ ] Provider refatorado
- [ ] Registrado no Service Locator
- [ ] Testes: Compilação OK
- [ ] Testes: Funcionalidade OK

---

## 🔍 Estrutura de Exemplo Criada

Veja os arquivos de exemplo já criados:

```
lib/domain/entities/user_entity.dart           ✅ Criado
lib/domain/repositories/user_repository.dart   ✅ Criado
lib/domain/usecases/get_current_user_usecase.dart  ✅ Criado
lib/domain/usecases/get_user_by_id_usecase.dart    ✅ Criado

lib/data/models/user_model.dart                ✅ Criado
lib/data/datasources/user_remote_datasource.dart  ✅ Criado
lib/data/repositories/user_repository_impl.dart   ✅ Criado

lib/presentation/providers/user_provider.dart      ✅ Criado

lib/core/errors/failures.dart                  ✅ Criado
lib/core/utils/typedef.dart                    ✅ Criado
lib/core/utils/usecase.dart                    ✅ Criado
lib/core/constants/app_constants.dart          ✅ Criado
lib/core/di/injection_container.dart           ✅ Criado (parcial)
```

---

## 🎓 Entender a Arquitetura

### Fluxo de Dados

```
UI Widget
    ↓ (usa)
Provider (ChangeNotifier)
    ↓ (chama)
UseCase (com lógica de negócio)
    ↓ (usa)
Repository (interface)
    ↓ (implementa)
Repository Impl (implementação concreta)
    ↓ (usa)
DataSource (acesso a dados)
    ↓ (chama)
Supabase / API / Database
    ↓ (retorna)
Model (DTO com serialização)
    ↓ (converte para)
Entity (objeto de domínio)
    ↓ (retorna para)
UI (atualiza a tela)
```

### Erros com Either

```dart
// Não faça assim (evitar)
throw Exception("Erro");

// Faça assim (Clean Architecture)
return Left(Failure("Erro"));
return Right(Data("Sucesso"));

// Na UI
result.fold(
  (failure) => mostrarErro(failure.message),
  (data) => processar(data),
);
```

---

## ❓ Dúvidas Comuns

**P: Por que Entity E Model?**
R: Entity é de domínio (sem dependências). Model é DTO com serialização JSON.

**P: Quando criar um novo UseCase?**
R: Um UseCase = um caso de uso. Ex: `GetProductsUseCase`, `CreateOrderUseCase`.

**P: O Provider ChangeNotifier é a forma correta?**
R: Sim, usamos Provider + ChangeNotifier. Riverpod é alternativa opcional.

**P: Como testar?**
R: Cada camada pode ser testada isoladamente:
```dart
// Testar UseCase
test('GetProductsUseCase deve retornar products', () async {
  when(mockRepository.getProducts())
      .thenAnswer((_) => Future.value(Right(products)));
  
  final result = await usecase(NoParams());
  
  expect(result, Right(products));
});
```

**P: Preciso fazer isso em todas as features?**
R: Sim! Garante consistência, testabilidade e manutenibilidade.

---

## 📞 Precisa de Ajuda?

1. **Releia** `AUTH_REFACTORING_EXAMPLE.md` com atenção
2. **Copie** a estrutura de User (já criada)
3. **Adapte** para sua feature
4. **Teste** a compilação: `flutter analyze`

---

## ✨ Próximas Melhorias Opcionais

- [ ] Adicionar Riverpod no lugar de Provider
- [ ] Criar testes unitários
- [ ] Adicionar logging
- [ ] Implementar cache local
- [ ] Adicionar retry logic
- [ ] Melhorar tratamento de erros

---

**Você está pronto! 🚀 Comece a refatorar sua primeira feature agora.**
