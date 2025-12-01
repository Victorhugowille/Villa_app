import 'package:dartz/dartz.dart';
import 'package:villabistromobile/core/errors/failures.dart';
import 'package:villabistromobile/domain/entities/company_entity.dart';

abstract class CompanyRepository {
  /// Obtém as empresas do usuário autenticado
  Future<Either<Failure, List<CompanyEntity>>> getCompanies();

  /// Obtém uma empresa por ID
  Future<Either<Failure, CompanyEntity>> getCompanyById(String companyId);

  /// Obtém a empresa atualmente selecionada
  Future<Either<Failure, CompanyEntity>> getCurrentCompany();

  /// Define a empresa atual
  Future<Either<Failure, void>> setCurrentCompany(String companyId);

  /// Cria uma nova empresa
  Future<Either<Failure, CompanyEntity>> createCompany(CompanyEntity company);

  /// Atualiza uma empresa
  Future<Either<Failure, CompanyEntity>> updateCompany(CompanyEntity company);

  /// Delete uma empresa
  Future<Either<Failure, void>> deleteCompany(String companyId);
}
