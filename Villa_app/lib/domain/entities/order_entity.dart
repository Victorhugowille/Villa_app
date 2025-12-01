import 'package:equatable/equatable.dart';

enum OrderStatus { pending, confirmed, preparing, ready, served, completed, cancelled }

/// Entidade de domínio para Pedido
class OrderEntity extends Equatable {
  final String id;
  final String companyId;
  final String tableId;
  final String? userId;
  final List<OrderItemEntity> items;
  final double totalAmount;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? notes;

  const OrderEntity({
    required this.id,
    required this.companyId,
    required this.tableId,
    this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.notes,
  });

  /// Retorna uma cópia com campos alterados
  OrderEntity copyWith({
    String? id,
    String? companyId,
    String? tableId,
    String? userId,
    List<OrderItemEntity>? items,
    double? totalAmount,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
  }) {
    return OrderEntity(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      tableId: tableId ?? this.tableId,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    companyId,
    tableId,
    userId,
    items,
    totalAmount,
    status,
    createdAt,
    updatedAt,
    notes,
  ];
}

/// Item dentro de um Pedido
class OrderItemEntity extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? notes;

  const OrderItemEntity({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.notes,
  });

  /// Retorna uma cópia com campos alterados
  OrderItemEntity copyWith({
    String? id,
    String? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    String? notes,
  }) {
    return OrderItemEntity(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    productId,
    productName,
    quantity,
    unitPrice,
    totalPrice,
    notes,
  ];
}
