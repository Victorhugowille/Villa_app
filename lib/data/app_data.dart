import 'package:flutter/material.dart';

class SavedReport {
  final int id;
  final String name;
  final DateTime createdAt;

  SavedReport({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory SavedReport.fromJson(Map<String, dynamic> json) {
    return SavedReport(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

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

class CartItem {
  final Product product;
  final int quantity;

  CartItem({required this.product, required this.quantity});

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['produtos']),
      quantity: json['quantidade'],
    );
  }

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
  final String type;
  final int? tableNumber;
  final int? tableId;

  Order({
    required this.id,
    required this.items,
    required this.timestamp,
    required this.status,
    required this.type,
    this.tableNumber,
    this.tableId,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var itemsList = <CartItem>[];
    if (json['itens_pedido'] != null) {
      itemsList = (json['itens_pedido'] as List)
          .map((itemJson) => CartItem.fromJson(itemJson))
          .toList();
    }
    
    return Order(
      id: json['id'],
      items: itemsList,
      timestamp: DateTime.parse(json['created_at']),
      status: json['status'] ?? 'production',
      type: json['type'] ?? 'mesa',
      tableNumber: (json['mesa_id'] is Map) ? json['mesa_id']['numero'] : null,
      tableId: (json['mesa_id'] is Map) ? json['mesa_id']['id'] : (json['mesa_id'] is int ? json['mesa_id'] : null),
    );
  }
  
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

class CustomSpreadsheet {
  final int? id;
  final String name;
  final List<List<String>> sheetData;
  final DateTime createdAt;

  CustomSpreadsheet({
    this.id,
    required this.name,
    required this.sheetData,
    required this.createdAt,
  });

  factory CustomSpreadsheet.fromJson(Map<String, dynamic> json) {
    List<List<String>> data = (json['sheet_data'] as List)
        .map((row) => (row as List).map((cell) => cell.toString()).toList())
        .toList();

    return CustomSpreadsheet(
      id: json['id'],
      name: json['name'],
      sheetData: data,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Estabelecimento {
  final String? id;
  final String nomeFantasia;
  final String cnpj;
  final String telefone;
  final String rua;
  final String numero;
  final String bairro;
  final String cidade;
  final String estado;

  Estabelecimento({
    this.id,
    required this.nomeFantasia,
    required this.cnpj,
    required this.telefone,
    required this.rua,
    required this.numero,
    required this.bairro,
    required this.cidade,
    required this.estado,
  });

  factory Estabelecimento.fromJson(Map<String, dynamic> json) {
    return Estabelecimento(
      id: json['id'],
      nomeFantasia: json['nome_fantasia'] ?? '',
      cnpj: json['cnpj'] ?? '',
      telefone: json['telefone'] ?? '',
      rua: json['rua'] ?? '',
      numero: json['numero'] ?? '',
      bairro: json['bairro'] ?? '',
      cidade: json['cidade'] ?? '',
      estado: json['estado'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nome_fantasia': nomeFantasia,
      'cnpj': cnpj,
      'telefone': telefone,
      'rua': rua,
      'numero': numero,
      'bairro': bairro,
      'cidade': cidade,
      'estado': estado,
    };
  }
}
class Adicional {
  final int id;
  final String name;
  final double price;

  Adicional({required this.id, required this.name, required this.price});

  factory Adicional.fromJson(Map<String, dynamic> json) {
    return Adicional(
      id: json['id'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
    );
  }
}