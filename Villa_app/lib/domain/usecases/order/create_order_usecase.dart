import 'package:dartz/dartz.dart';
import 'package:villabistromobile/core/errors/failures.dart';
import 'package:villabistromobile/core/utils/usecase.dart';
import 'package:villabistromobile/domain/entities/order_entity.dart';
import 'package:villabistromobile/domain/repositories/order_repository.dart';

class CreateOrderUseCase extends UseCase<OrderEntity, OrderEntity> {
  final OrderRepository repository;

  CreateOrderUseCase(this.repository);

  @override
  Future<Either<Failure, OrderEntity>> call(OrderEntity order) {
    return repository.createOrder(order);
  }
}
