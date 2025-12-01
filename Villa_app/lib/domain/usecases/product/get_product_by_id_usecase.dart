import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:villabistromobile/core/errors/failures.dart';
import 'package:villabistromobile/core/utils/usecase.dart';
import 'package:villabistromobile/domain/entities/product_entity.dart';
import 'package:villabistromobile/domain/repositories/product_repository.dart';

class GetProductByIdUseCase extends UseCase<ProductEntity, GetProductByIdParams> {
  final ProductRepository repository;

  GetProductByIdUseCase(this.repository);

  @override
  Future<Either<Failure, ProductEntity>> call(GetProductByIdParams params) {
    return repository.getProductById(params.productId);
  }
}

class GetProductByIdParams extends Equatable {
  final String productId;

  const GetProductByIdParams({required this.productId});

  @override
  List<Object?> get props => [productId];
}
