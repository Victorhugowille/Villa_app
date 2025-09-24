import 'package:flutter/material.dart';

class Category {
  final int id;
  final String name;
  final IconData icon;

  Category({required this.id, required this.name, required this.icon});

  factory Category.fromJson(Map<String, dynamic> jsonData) {
    return Category(
      id: jsonData['id'],
      name: jsonData['name'],
      icon: IconData(
        jsonData['icon_code_point'],
        fontFamily: jsonData['icon_font_family'],
      ),
    );
  }
}

class Product {
  final int id;
  final String name;
  final double price;
  final int categoryId;
  final String categoryName;
  final int displayOrder;
  final String? imageUrl;
  final bool isSoldOut;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    required this.categoryName,
    required this.displayOrder,
    this.imageUrl,
    required this.isSoldOut,
  });

  factory Product.fromJson(Map<String, dynamic> jsonData) {
    return Product(
      id: jsonData['id'],
      name: jsonData['name'],
      price: (jsonData['price'] as num).toDouble(),
      categoryId: jsonData['category_id'],
      categoryName:
          (jsonData['categorias'] != null) ? jsonData['categorias']['name'] : 'Sem Categoria',
      displayOrder: jsonData['display_order'] ?? 0,
      imageUrl: jsonData['image_url'],
      isSoldOut: jsonData['is_sold_out'] ?? false,
    );
  }
}

class Table {
  final int id;
  final int tableNumber;
  final bool isOccupied;

  Table({
    required this.id,
    required this.tableNumber,
    required this.isOccupied,
  });

  factory Table.fromJson(Map<String, dynamic> jsonData) {
    return Table(
      id: jsonData['id'] ?? 0,
      tableNumber: jsonData['numero'] ?? 0,
      isOccupied: jsonData['status'] == 'ocupada',
    );
  }
}

// CLASSE ATUALIZADA
class CartItem {
  final Product product;
  final int quantity; // Alterado para final (imutável)

  CartItem({required this.product, required this.quantity});

  // CORREÇÃO: Adicionando o construtor 'fromJson' que estava faltando
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['produtos']),
      quantity: json['quantidade'],
    );
  }

  // MELHORIA: Adicionando o método 'copyWith'
  CartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}


class Order {
  final int id;
  final List<CartItem> items;
  final DateTime timestamp;
  final String status;

  Order({
    required this.id,
    required this.items,
    required this.timestamp,
    required this.status,
  });
  
  double get total =>
      items.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
}

class Transaction {
  final int id;
  final int tableNumber;
  final double totalAmount;
  final DateTime timestamp;
  final String paymentMethod;
  final double discount;
  final double surcharge;

  Transaction({
    required this.id,
    required this.tableNumber,
    required this.totalAmount,
    required this.timestamp,
    required this.paymentMethod,
    required this.discount,
    required this.surcharge,
  });

  factory Transaction.fromJson(Map<String, dynamic> jsonData) {
    return Transaction(
      id: jsonData['id'],
      tableNumber: jsonData['table_number'],
      totalAmount: (jsonData['total_amount'] as num).toDouble(),
      timestamp: DateTime.parse(jsonData['created_at']),
      paymentMethod: jsonData['payment_method'] ?? 'N/A',
      discount: (jsonData['discount'] as num?)?.toDouble() ?? 0.0,
      surcharge: (jsonData['surcharge'] as num?)?.toDouble() ?? 0.0,
    );
  }
}