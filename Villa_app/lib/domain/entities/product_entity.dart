import 'package:equatable/equatable.dart';

/// Entidade de domínio pura - sem dependências externas
class ProductEntity extends Equatable {
  final String id;
  final String name;
  final double price;
  final String? categoryId;
  final String categoryName;
  final int displayOrder;
  final String? imageUrl;
  final bool isSoldOut;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    required this.categoryName,
    required this.displayOrder,
    this.imageUrl,
    required this.isSoldOut,
  });

  /// Retorna uma cópia com campos alterados
  ProductEntity copyWith({
    String? id,
    String? name,
    double? price,
    String? categoryId,
    String? categoryName,
    int? displayOrder,
    String? imageUrl,
    bool? isSoldOut,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      displayOrder: displayOrder ?? this.displayOrder,
      imageUrl: imageUrl ?? this.imageUrl,
      isSoldOut: isSoldOut ?? this.isSoldOut,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    price,
    categoryId,
    categoryName,
    displayOrder,
    imageUrl,
    isSoldOut,
  ];
}
