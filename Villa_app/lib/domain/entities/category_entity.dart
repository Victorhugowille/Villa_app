import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Tipos de app suportados pela categoria
enum CategoryAppType { cardapio, ifood, dimer, all }

/// Entidade de domínio para Categoria
class CategoryEntity extends Equatable {
  final String id;
  final String name;
  final int iconCodePoint;
  final String? iconFontFamily;
  final int displayOrder;
  final CategoryAppType appType;
  final String companyId;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    this.iconFontFamily,
    required this.displayOrder,
    required this.appType,
    required this.companyId,
  });

  /// Converte codePoint para IconData
  IconData get icon => IconData(
    iconCodePoint,
    fontFamily: iconFontFamily ?? 'MaterialIcons',
  );

  /// Retorna uma cópia com campos alterados
  CategoryEntity copyWith({
    String? id,
    String? name,
    int? iconCodePoint,
    String? iconFontFamily,
    int? displayOrder,
    CategoryAppType? appType,
    String? companyId,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
      displayOrder: displayOrder ?? this.displayOrder,
      appType: appType ?? this.appType,
      companyId: companyId ?? this.companyId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    iconCodePoint,
    iconFontFamily,
    displayOrder,
    appType,
    companyId,
  ];
}
