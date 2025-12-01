import 'package:dartz/dartz.dart';
import 'package:villabistromobile/core/errors/failures.dart';
import 'package:villabistromobile/domain/entities/order_entity.dart';

abstract class OrderRepository {
  /// Obtém todos os pedidos de uma empresa
  Future<Either<Failure, List<OrderEntity>>> getOrders(String companyId);

  /// Obtém pedidos de uma mesa
  Future<Either<Failure, List<OrderEntity>>> getTableOrders(String tableId);

  /// Obtém um pedido por ID
  Future<Either<Failure, OrderEntity>> getOrderById(String orderId);

  /// Cria um novo pedido
  Future<Either<Failure, OrderEntity>> createOrder(OrderEntity order);

  /// Atualiza um pedido
  Future<Either<Failure, OrderEntity>> updateOrder(OrderEntity order);

  /// Atualiza o status de um pedido
  Future<Either<Failure, void>> updateOrderStatus(
    String orderId,
    OrderStatus status,
  );

  /// Delete um pedido
  Future<Either<Failure, void>> deleteOrder(String orderId);
}
