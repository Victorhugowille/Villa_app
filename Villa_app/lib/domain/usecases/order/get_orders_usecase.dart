import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:villabistromobile/core/errors/failures.dart';
import 'package:villabistromobile/core/utils/usecase.dart';
import 'package:villabistromobile/domain/entities/order_entity.dart';
import 'package:villabistromobile/domain/repositories/order_repository.dart';

class GetOrdersUseCase extends UseCase<List<OrderEntity>, GetOrdersParams> {
  final OrderRepository repository;

  GetOrdersUseCase(this.repository);

  @override
  Future<Either<Failure, List<OrderEntity>>> call(GetOrdersParams params) {
    if (params.tableId != null) {
      return repository.getTableOrders(params.tableId!);
    }
    return repository.getOrders(params.companyId);
  }
}

class GetOrdersParams extends Equatable {
  final String companyId;
  final String? tableId;

  const GetOrdersParams({
    required this.companyId,
    this.tableId,
  });

  @override
  List<Object?> get props => [companyId, tableId];
}
