import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:villabistromobile/core/errors/failures.dart';
import 'package:villabistromobile/core/utils/usecase.dart';
import 'package:villabistromobile/domain/entities/product_entity.dart';
import 'package:villabistromobile/domain/repositories/product_repository.dart';

class GetProductsUseCase extends UseCase<List<ProductEntity>, GetProductsParams> {
  final ProductRepository repository;

  GetProductsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ProductEntity>>> call(GetProductsParams params) {
    return repository.getProducts(params.companyId, params.categoryId);
  }
}

class GetProductsParams extends Equatable {
  final String companyId;
  final String? categoryId;

  const GetProductsParams({
    required this.companyId,
    this.categoryId,
  });

  @override
  List<Object?> get props => [companyId, categoryId];
}
