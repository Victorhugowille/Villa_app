import 'package:dartz/dartz.dart';
import 'package:villabistromobile/core/errors/failures.dart';
import 'package:villabistromobile/core/utils/usecase.dart';
import 'package:villabistromobile/domain/entities/company_entity.dart';
import 'package:villabistromobile/domain/repositories/company_repository.dart';

class GetCurrentCompanyUseCase extends UseCase<CompanyEntity, NoParams> {
  final CompanyRepository repository;

  GetCurrentCompanyUseCase(this.repository);

  @override
  Future<Either<Failure, CompanyEntity>> call(NoParams params) {
    return repository.getCurrentCompany();
  }
}
