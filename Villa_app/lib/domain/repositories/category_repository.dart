import 'package:dartz/dartz.dart';
import 'package:villabistromobile/core/errors/failures.dart';
import 'package:villabistromobile/domain/entities/category_entity.dart';

abstract class CategoryRepository {
  /// Obtém todas as categorias de uma empresa
  Future<Either<Failure, List<CategoryEntity>>> getCategories(String companyId);

  /// Obtém uma categoria por ID
  Future<Either<Failure, CategoryEntity>> getCategoryById(String categoryId);

  /// Cria uma nova categoria
  Future<Either<Failure, CategoryEntity>> createCategory(CategoryEntity category);

  /// Atualiza uma categoria
  Future<Either<Failure, CategoryEntity>> updateCategory(CategoryEntity category);

  /// Delete uma categoria
  Future<Either<Failure, void>> deleteCategory(String categoryId);
}
