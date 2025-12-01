import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:villabistromobile/core/errors/failures.dart';
import 'package:villabistromobile/core/utils/usecase.dart';
import 'package:villabistromobile/domain/entities/category_entity.dart';
import 'package:villabistromobile/domain/repositories/category_repository.dart';

class GetCategoriesUseCase extends UseCase<List<CategoryEntity>, GetCategoriesParams> {
  final CategoryRepository repository;

  GetCategoriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<CategoryEntity>>> call(GetCategoriesParams params) {
    return repository.getCategories(params.companyId);
  }
}

class GetCategoriesParams extends Equatable {
  final String companyId;

  const GetCategoriesParams({required this.companyId});

  @override
  List<Object?> get props => [companyId];
}
