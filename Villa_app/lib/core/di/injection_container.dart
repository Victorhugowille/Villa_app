import 'package:get_it/get_it.dart';
// import 'package:villabistromobile/data/datasources/user_remote_datasource.dart';
// import 'package:villabistromobile/data/repositories/user_repository_impl.dart';
// import 'package:villabistromobile/domain/repositories/user_repository.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  // ============ USER FEATURE ============
  // TODO: Uncomment when data layer is ready
  // Datasources
  // getIt.registerSingleton<UserRemoteDataSource>(
  //   UserRemoteDataSourceImpl(),
  // );

  // Repositories
  // getIt.registerSingleton<UserRepository>(
  //   UserRepositoryImpl(
  //     remoteDataSource: getIt<UserRemoteDataSource>(),
  //   ),
  // );

  // Use Cases
  // getIt.registerSingleton<GetCurrentUserUseCase>(
  //   GetCurrentUserUseCase(getIt<UserRepository>()),
  // );
  // getIt.registerSingleton<GetUserByIdUseCase>(
  //   GetUserByIdUseCase(getIt<UserRepository>()),
  // );

  // Providers
  // Note: UserProvider não existe ainda
  // Remover estas linhas quando a classe for criada
}
