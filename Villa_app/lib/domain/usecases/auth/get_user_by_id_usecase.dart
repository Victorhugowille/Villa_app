import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:villabistromobile/core/errors/failures.dart';
import 'package:villabistromobile/core/utils/usecase.dart';
import 'package:villabistromobile/domain/entities/user_entity.dart';
import 'package:villabistromobile/domain/repositories/user_repository.dart';

class GetUserByIdUseCase extends UseCase<UserEntity, GetUserByIdParams> {
  final UserRepository repository;

  GetUserByIdUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(GetUserByIdParams params) {
    return repository.getUserById(params.userId);
  }
}

class GetUserByIdParams extends Equatable {
  final String userId;

  const GetUserByIdParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}
