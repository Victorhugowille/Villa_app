import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:villabistromobile/core/errors/failures.dart';
import 'package:villabistromobile/core/utils/usecase.dart';
import 'package:villabistromobile/domain/entities/table_entity.dart';
import 'package:villabistromobile/domain/repositories/table_repository.dart';

class GetTablesUseCase extends UseCase<List<TableEntity>, GetTablesParams> {
  final TableRepository repository;

  GetTablesUseCase(this.repository);

  @override
  Future<Either<Failure, List<TableEntity>>> call(GetTablesParams params) {
    return repository.getTables(params.companyId);
  }
}

class GetTablesParams extends Equatable {
  final String companyId;

  const GetTablesParams({required this.companyId});

  @override
  List<Object?> get props => [companyId];
}
