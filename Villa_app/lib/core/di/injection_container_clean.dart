import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

/// Configura injeção de dependências para Clean Architecture
void setupServiceLocator() {
  // ============ REPOSITORIES ============
  // TODO: Adicionar implementações dos repositories na camada Data
  
  // Exemplo quando a camada Data estiver pronta:
  // getIt.registerSingleton<UserRepository>(
  //   UserRepositoryImpl(
  //     remoteDataSource: getIt(),
  //     localDataSource: getIt(),
  //   ),
  // );

  // ============ USE CASES ============
  
  // Auth UseCases
  // getIt.registerSingleton<LoginUseCase>(
  //   LoginUseCase(getIt<UserRepository>()),
  // );
  // getIt.registerSingleton<LogoutUseCase>(
  //   LogoutUseCase(getIt<UserRepository>()),
  // );
  // getIt.registerSingleton<GetCurrentUserUseCase>(
  //   GetCurrentUserUseCase(getIt<UserRepository>()),
  // );
  // getIt.registerSingleton<GetUserByIdUseCase>(
  //   GetUserByIdUseCase(getIt<UserRepository>()),
  // );

  // Product UseCases
  // getIt.registerSingleton<GetProductsUseCase>(
  //   GetProductsUseCase(getIt<ProductRepository>()),
  // );
  // getIt.registerSingleton<GetProductByIdUseCase>(
  //   GetProductByIdUseCase(getIt<ProductRepository>()),
  // );

  // Category UseCases
  // getIt.registerSingleton<GetCategoriesUseCase>(
  //   GetCategoriesUseCase(getIt<CategoryRepository>()),
  // );

  // Company UseCases
  // getIt.registerSingleton<GetCurrentCompanyUseCase>(
  //   GetCurrentCompanyUseCase(getIt<CompanyRepository>()),
  // );
  // getIt.registerSingleton<GetCompaniesUseCase>(
  //   GetCompaniesUseCase(getIt<CompanyRepository>()),
  // );

  // Table UseCases
  // getIt.registerSingleton<GetTablesUseCase>(
  //   GetTablesUseCase(getIt<TableRepository>()),
  // );

  // Order UseCases
  // getIt.registerSingleton<CreateOrderUseCase>(
  //   CreateOrderUseCase(getIt<OrderRepository>()),
  // );
  // getIt.registerSingleton<GetOrdersUseCase>(
  //   GetOrdersUseCase(getIt<OrderRepository>()),
  // );

  print('✅ Service Locator configurado com sucesso!');
}

/// Obter Use Case
T getUseCase<T extends Object>() {
  return getIt<T>();
}

/// Verificar se uma dependência está registrada
bool isRegistered<T extends Object>() {
  return getIt.isRegistered<T>();
}
