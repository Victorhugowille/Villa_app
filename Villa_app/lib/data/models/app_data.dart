import 'package:flutter/material.dart';

class Company {
  final String id;
  final String name;
  final String? logoUrl;
  final String? cnpj;
  final String? telefone;
  final String? rua;
  final String? numero;
  final String? bairro;
  final String? cidade;
  final String? estado;
  final String? zapiInstanceId;
  final String? zapiToken;
  final String? notificationEmail;
  final String? slug;
  final String status; // <-- CAMPO ADICIONADO
  final String? colorSite;
  final double? latitude;
  final double? longitude;

  Company({
    required this.id,
    required this.name,
    this.logoUrl,
    this.cnpj,
    this.telefone,
    this.rua,
    this.numero,
    this.bairro,
    this.cidade,
    this.estado,
    this.zapiInstanceId,
    this.zapiToken,
    this.notificationEmail,
    this.slug,
    required this.status, // <-- CAMPO ADICIONADO
    this.colorSite,
    this.latitude,
    this.longitude,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      logoUrl: json['logo_url'],
      cnpj: json['cnpj'],
      telefone: json['telefone'],
      rua: json['rua'],
      numero: json['numero'],
      bairro: json['bairro'],
      cidade: json['cidade'],
      estado: json['estado'],
      zapiInstanceId: json['zapi_instance_id'],
      zapiToken: json['zapi_token'],
      notificationEmail: json['notification_email'],
      slug: json['slug'],
      status: json['status'] ?? 'pending', // <-- CAMPO ADICIONADO
      colorSite: json['color_site'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo_url': logoUrl,
      'cnpj': cnpj,
      'telefone': telefone,
      'rua': rua,
      'numero': numero,
      'bairro': bairro,
      'cidade': cidade,
      'estado': estado,
      'latitude': latitude,
      'longitude': longitude,
      'status': status, // <-- CAMPO ADICIONADO
    };
  }
}

class DestaqueSite {
  final int id;
  final String companyId;
  final String imageUrl;
  final int slotNumber;

  DestaqueSite({
    required this.id,
    required this.companyId,
    required this.imageUrl,
    required this.slotNumber,
  });

  factory DestaqueSite.fromJson(Map<String, dynamic> json) {
    return DestaqueSite(
      id: json['id'],
      companyId: json['company_id'],
      imageUrl: json['image_url'],
      slotNumber: json['slot_number'],
    );
  }
}

class SavedReport {
  final String id;
  final String name;
  final DateTime createdAt;
  SavedReport({required this.id, required this.name, required this.createdAt});
  factory SavedReport.fromJson(Map<String, dynamic> json) {
    return SavedReport(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? 'Relatório Inválido',
        createdAt:
            DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now());
  }
}

class GrupoAdicional {
  final String id;
  final String name;
  final String produtoId;
  final String? imageUrl;
  List<Adicional> adicionais;
  final int displayOrder;
  final int minQuantity;
  final int? maxQuantity;

  GrupoAdicional(
      {required this.id,
      required this.name,
      required this.produtoId,
      this.imageUrl,
      this.adicionais = const [],
      required this.displayOrder,
      required this.minQuantity,
      this.maxQuantity});

  factory GrupoAdicional.fromJson(Map<String, dynamic> json) {
    List<Adicional> items = [];
    if (json['adicionais'] is List) {
      items = (json['adicionais'] as List)
          .map((item) => Adicional.fromJson(item))
          .toList();
      items.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    }
    return GrupoAdicional(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? 'Grupo Inválido',
        produtoId: json['produto_id']?.toString() ?? '',
        imageUrl: json['image_url'],
        adicionais: items,
        displayOrder: json['display_order'] ?? 0,
        minQuantity: json['min_quantity'] ?? 0,
        maxQuantity: json['max_quantity']);
  }
}

class Adicional {
  final String id;
  final String name;
  final double price;
  final String? grupoId;
  final String? imageUrl;
  final int displayOrder;

  Adicional(
      {required this.id,
      required this.name,
      required this.price,
      this.grupoId,
      this.imageUrl,
      required this.displayOrder});

  factory Adicional.fromJson(Map<String, dynamic> json) {
    return Adicional(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? 'Adicional Inválido',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        grupoId: json['grupo_id']?.toString(),
        imageUrl: json['image_url'],
        displayOrder: json['display_order'] ?? 0);
  }
}

// ==================================================
// ADICIONADO O ENUM QUE FALTAVA
// ==================================================
enum CategoryAppType {
  todos('Todos'),
  garcom('App Garçom'),
  delivery('App Delivery');

  final String label;
  const CategoryAppType(this.label);

  static CategoryAppType fromString(String? value) {
    return CategoryAppType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CategoryAppType.todos,
    );
  }
}
// ==================================================

class Category {
  final String id;
  final String name;
  final IconData icon;
  final int displayOrder;
  final CategoryAppType appType; // NOVO CAMPO

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.displayOrder,
    required this.appType, // NOVO CAMPO
  });

  factory Category.fromJson(Map<String, dynamic> jsonData) {
    return Category(
      id: jsonData['id']?.toString() ?? '',
      name: jsonData['name'] ?? 'Categoria Inválida',
      icon: IconData(jsonData['icon_code_point'] ?? 0xe1de,
          fontFamily: jsonData['icon_font_family']),
      displayOrder: jsonData['display_order'] ?? 0,
      appType: CategoryAppType.fromString(jsonData['app_type']), // NOVO CAMPO
    );
  }
}

class Product {
  final String id;
  final String name;
  final double price;
  final String? categoryId;
  final String categoryName;
  final int displayOrder;
  final String? imageUrl;
  final bool isSoldOut;

  Product(
      {required this.id,
      required this.name,
      required this.price,
      required this.categoryId,
      required this.categoryName,
      required this.displayOrder,
      this.imageUrl,
      required this.isSoldOut});

  factory Product.fromJson(Map<String, dynamic> jsonData) {
    return Product(
        id: jsonData['id']?.toString() ?? '',
        name: jsonData['name'] ?? 'Produto Inválido',
        price: (jsonData['price'] as num?)?.toDouble() ?? 0.0,
        categoryId: jsonData['category_id']?.toString(),
        categoryName: (jsonData['categorias'] is Map)
            ? jsonData['categorias']['name'] ?? 'Sem Categoria'
            : 'Sem Categoria',
        displayOrder: jsonData['display_order'] ?? 0,
        imageUrl: jsonData['image_url'],
        isSoldOut: jsonData['is_sold_out'] ?? false);
  }
}

class Table {
  final String id;
  final int tableNumber;
  bool isOccupied;
  bool isPartiallyPaid;

  Table({
    required this.id,
    required this.tableNumber,
    required this.isOccupied,
    this.isPartiallyPaid = false,
  });

  factory Table.fromJson(Map<String, dynamic> jsonData) {
    return Table(
      id: jsonData['id']?.toString() ?? '',
      tableNumber: jsonData['numero'] ?? 0,
      isOccupied: jsonData['status'] == 'ocupada',
      isPartiallyPaid: false,
    );
  }
}

class CartItemAdicional {
  final Adicional adicional;
  final int quantity;

  CartItemAdicional({required this.adicional, required this.quantity});

  factory CartItemAdicional.fromJson(Map<String, dynamic> json) {
    final adicionalJson = json['adicional'] as Map<String, dynamic>? ?? {};
    return CartItemAdicional(
      adicional: Adicional(
        id: adicionalJson['id']?.toString() ?? '',
        name: adicionalJson['name'] ?? 'Adicional Inválido',
        price: (adicionalJson['price'] as num?)?.toDouble() ?? 0.0,
        displayOrder: 0,
      ),
      quantity: json['quantity'] ?? 1,
    );
  }
}

class CartItem {
  final String id;
  final Product product;
  int quantity;
  List<CartItemAdicional> selectedAdicionais;
  String? observacao;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    this.selectedAdicionais = const [],
    this.observacao,
  });

  double get totalPrice {
    final double adicionaisPrice = selectedAdicionais.fold(
        0.0, (sum, item) => sum + (item.adicional.price * item.quantity));
    return (product.price + adicionaisPrice) * quantity;
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id']?.toString() ?? '',
      product: Product.fromJson(json['produtos'] ?? {}),
      quantity: json['quantidade'] ?? 0,
      selectedAdicionais: (json['adicionais_selecionados'] as List? ?? [])
          .map((item) => CartItemAdicional.fromJson(item))
          .toList(),
      observacao: json['observacao'],
    );
  }

  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    List<CartItemAdicional>? selectedAdicionais,
    String? observacao,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedAdicionais: selectedAdicionais ?? this.selectedAdicionais,
      observacao: observacao ?? this.observacao,
    );
  }
}

// **CLASSE ATUALIZADA**
class DeliveryInfo {
  final String id;
  final String pedidoId;
  final String nomeCliente;
  final String telefoneCliente;
  final String enderecoEntrega;
  final String? companyId;
  final String? locationLink; // NOVO CAMPO: Para o link do mapa

  DeliveryInfo({
    required this.id,
    required this.pedidoId,
    required this.nomeCliente,
    required this.telefoneCliente,
    required this.enderecoEntrega,
    this.companyId,
    this.locationLink, // NOVO CAMPO
  });

  factory DeliveryInfo.fromJson(Map<String, dynamic> json) {
    return DeliveryInfo(
      id: json['id']?.toString() ?? '',
      pedidoId: json['pedido_id']?.toString() ?? '',
      nomeCliente: json['nome_cliente'] ?? '',
      telefoneCliente: json['telefone_cliente'] ?? '',
      enderecoEntrega: json['endereco_entrega'] ?? '',
      companyId: json['company_id']?.toString(),
      locationLink: json['location_link'], // NOVO CAMPO
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pedido_id': int.tryParse(pedidoId) ?? 0,
      'nome_cliente': nomeCliente,
      'telefone_cliente': telefoneCliente,
      'endereco_entrega': enderecoEntrega,
      'company_id': companyId,
      'location_link': locationLink,
    };
  }
}

class Order {
  final String id;
  final int numeroPedido;
  final List<CartItem> items;
  final DateTime timestamp;
  final String status;
  final String type;
  final int? tableNumber;
  final String? tableId;
  final DeliveryInfo? deliveryInfo;
  final String? observacao;
  final double? deliveryFee;
  final Map<String, dynamic>? paymentInfo;

  Order({
    required this.id,
    required this.numeroPedido,
    required this.items,
    required this.timestamp,
    required this.status,
    required this.type,
    this.tableNumber,
    this.tableId,
    this.deliveryInfo,
    this.observacao,
    this.deliveryFee,
    this.paymentInfo,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var itemsList = <CartItem>[];
    if (json['itens_pedido'] is List) {
      itemsList = (json['itens_pedido'] as List)
          .map((itemJson) => CartItem.fromJson(itemJson))
          .toList();
    }

    int? tableNum;
    if (json['mesas'] is Map && json['mesas'] != null) {
      tableNum = (json['mesas']['numero'] as num?)?.toInt();
    } else if (json['table_number'] != null) {
      tableNum = (json['table_number'] as num?)?.toInt();
    }

    DeliveryInfo? deliveryData;
    final dynamic deliveryJson = json['delivery'];

    if (deliveryJson != null) {
      if (deliveryJson is List && deliveryJson.isNotEmpty) {
        final firstItem = deliveryJson.first;
        if (firstItem is Map<String, dynamic>) {
          deliveryData = DeliveryInfo.fromJson(firstItem);
        }
      } else if (deliveryJson is Map<String, dynamic>) {
        deliveryData = DeliveryInfo.fromJson(deliveryJson);
      }
    }

    return Order(
      id: json['id']?.toString() ?? '',
      numeroPedido: json['numero_pedido'] ?? 0,
      items: itemsList,
      timestamp:
          DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'production',
      type: json['type'] ?? 'mesa',
      tableNumber: tableNum,
      tableId: (json['mesas'] is Map)
          ? json['mesas']['id'].toString()
          : json['mesa_id']?.toString(),
      deliveryInfo: deliveryData,
      observacao: json['observacao'],
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble(),
      paymentInfo: json['payment_info'] as Map<String, dynamic>?,
    );
  }

  double get total => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  // **MÉTODO ADICIONADO AQUI**
  Order copyWith({
    String? id,
    int? numeroPedido,
    List<CartItem>? items,
    DateTime? timestamp,
    String? status,
    String? type,
    int? tableNumber,
    String? tableId,
    DeliveryInfo? deliveryInfo,
    String? observacao,
    double? deliveryFee,
    Map<String, dynamic>? paymentInfo,
  }) {
    return Order(
      id: id ?? this.id,
      numeroPedido: numeroPedido ?? this.numeroPedido,
      items: items ?? this.items,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      type: type ?? this.type,
      tableNumber: tableNumber ?? this.tableNumber,
      tableId: tableId ?? this.tableId,
      deliveryInfo: deliveryInfo ?? this.deliveryInfo,
      observacao: observacao ?? this.observacao,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      paymentInfo: paymentInfo ?? this.paymentInfo,
    );
  }
}

class Transaction {
  final String id;
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
      id: jsonData['id']?.toString() ?? '',
      tableNumber: jsonData['table_number'] ?? 0,
      totalAmount: (jsonData['total_amount'] as num?)?.toDouble() ?? 0.0,
      timestamp:
          DateTime.tryParse(jsonData['created_at'] ?? '') ?? DateTime.now(),
      paymentMethod: jsonData['payment_method'] ?? 'N/A',
      discount: (jsonData['discount'] as num?)?.toDouble() ?? 0.0,
      surcharge: (jsonData['surcharge'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CustomSpreadsheet {
  final String? id;
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
    List<List<String>> data = [];
    if (json['sheet_data'] is List) {
      data = (json['sheet_data'] as List)
          .map((row) => (row as List).map((cell) => cell.toString()).toList())
          .toList();
    }

    return CustomSpreadsheet(
      id: json['id'],
      name: json['name'] ?? '',
      sheetData: data,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}