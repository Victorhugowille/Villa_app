import 'package:dartz/dartz.dart';
import 'package:villabistromobile/core/errors/failures.dart';
import 'package:villabistromobile/domain/entities/user_entity.dart';

abstract class UserRepository {
  /// Realiza login do usuário
  Future<Either<Failure, UserEntity>> login(String email, String password);

  /// Realiza logout do usuário
  Future<Either<Failure, void>> logout();

  /// Obtém o usuário atualmente autenticado
  Future<Either<Failure, UserEntity>> getCurrentUser();

  /// Obtém um usuário por ID
  Future<Either<Failure, UserEntity>> getUserById(String userId);

  /// Atualiza um usuário
  Future<Either<Failure, void>> updateUser(UserEntity user);

  /// Delete um usuário
  Future<Either<Failure, void>> deleteUser(String userId);
}
