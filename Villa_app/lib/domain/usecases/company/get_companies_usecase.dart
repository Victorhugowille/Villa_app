import 'package:dartz/dartz.dart';
import 'package:villabistromobile/core/errors/failures.dart';
import 'package:villabistromobile/core/utils/usecase.dart';
import 'package:villabistromobile/domain/entities/company_entity.dart';
import 'package:villabistromobile/domain/repositories/company_repository.dart';

class GetCompaniesUseCase extends UseCase<List<CompanyEntity>, NoParams> {
  final CompanyRepository repository;

  GetCompaniesUseCase(this.repository);

  @override
  Future<Either<Failure, List<CompanyEntity>>> call(NoParams params) {
    return repository.getCompanies();
  }
}
