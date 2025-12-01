import 'package:equatable/equatable.dart';

/// Entidade de domínio para Mesa
class TableEntity extends Equatable {
  final String id;
  final String number;
  final int capacity;
  final String companyId;
  final bool isAvailable;
  final String? status; // 'available', 'occupied', 'reserved'
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TableEntity({
    required this.id,
    required this.number,
    required this.capacity,
    required this.companyId,
    required this.isAvailable,
    this.status,
    required this.createdAt,
    this.updatedAt,
  });

  /// Retorna uma cópia com campos alterados
  TableEntity copyWith({
    String? id,
    String? number,
    int? capacity,
    String? companyId,
    bool? isAvailable,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TableEntity(
      id: id ?? this.id,
      number: number ?? this.number,
      capacity: capacity ?? this.capacity,
      companyId: companyId ?? this.companyId,
      isAvailable: isAvailable ?? this.isAvailable,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    number,
    capacity,
    companyId,
    isAvailable,
    status,
    createdAt,
    updatedAt,
  ];
}
