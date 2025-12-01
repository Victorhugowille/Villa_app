import 'package:villabistromobile/domain/entities/base_entity.dart';

class UserEntity extends BaseEntity {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final bool isActive;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.isActive,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, email, name, phone, isActive, createdAt];
}
