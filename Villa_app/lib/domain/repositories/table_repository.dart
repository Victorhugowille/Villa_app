import 'package:dartz/dartz.dart';
import 'package:villabistromobile/core/errors/failures.dart';
import 'package:villabistromobile/domain/entities/table_entity.dart';

abstract class TableRepository {
  /// Obtém todas as mesas de uma empresa
  Future<Either<Failure, List<TableEntity>>> getTables(String companyId);

  /// Obtém uma mesa por ID
  Future<Either<Failure, TableEntity>> getTableById(String tableId);

  /// Cria uma nova mesa
  Future<Either<Failure, TableEntity>> createTable(TableEntity table);

  /// Atualiza uma mesa
  Future<Either<Failure, TableEntity>> updateTable(TableEntity table);

  /// Delete uma mesa
  Future<Either<Failure, void>> deleteTable(String tableId);

  /// Atualiza o status da mesa
  Future<Either<Failure, void>> updateTableStatus(String tableId, String status);

  /// Obtém mesas disponíveis
  Future<Either<Failure, List<TableEntity>>> getAvailableTables(String companyId);
}
