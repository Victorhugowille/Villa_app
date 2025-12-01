import 'package:equatable/equatable.dart';

/// Item do Carrinho
class CartItemEntity extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final String? notes;

  const CartItemEntity({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.notes,
  });

  /// Calcula o preço total do item
  double get totalPrice => unitPrice * quantity;

  /// Retorna uma cópia com campos alterados
  CartItemEntity copyWith({
    String? id,
    String? productId,
    String? productName,
    double? unitPrice,
    int? quantity,
    String? notes,
  }) {
    return CartItemEntity(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    productId,
    productName,
    unitPrice,
    quantity,
    notes,
  ];
}
