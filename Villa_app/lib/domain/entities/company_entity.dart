import 'package:equatable/equatable.dart';

/// Entidade de domínio para Empresa
class CompanyEntity extends Equatable {
  final String id;
  final String name;
  final String? logo;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CompanyEntity({
    required this.id,
    required this.name,
    this.logo,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  /// Retorna uma cópia com campos alterados
  CompanyEntity copyWith({
    String? id,
    String? name,
    String? logo,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompanyEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      logo: logo ?? this.logo,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    logo,
    phone,
    address,
    city,
    state,
    zipCode,
    isActive,
    createdAt,
    updatedAt,
  ];
}
