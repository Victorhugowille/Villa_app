import 'package:dartz/dartz.dart';
import 'package:villabistromobile/core/errors/failures.dart';
import 'package:villabistromobile/core/utils/usecase.dart';
import 'package:villabistromobile/domain/entities/user_entity.dart';
import 'package:villabistromobile/domain/repositories/user_repository.dart';

class GetCurrentUserUseCase extends UseCase<UserEntity, NoParams> {
  final UserRepository repository;

  GetCurrentUserUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) {
    return repository.getCurrentUser();
  }
}
