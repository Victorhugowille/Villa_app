import 'package:dartz/dartz.dart';
import 'package:villabistromobile/core/errors/failures.dart';
import 'package:villabistromobile/domain/entities/product_entity.dart';

/// Repository abstrato para Produtos - define contrato de métodos
abstract class ProductRepository {
  /// Obtém todos os produtos de uma empresa
  Future<Either<Failure, List<ProductEntity>>> getProducts(
    String companyId, [
    String? categoryId,
  ]);

  /// Obtém um produto por ID
  Future<Either<Failure, ProductEntity>> getProductById(String productId);

  /// Cria um novo produto
  Future<Either<Failure, ProductEntity>> createProduct(ProductEntity product);

  /// Atualiza um produto existente
  Future<Either<Failure, ProductEntity>> updateProduct(ProductEntity product);

  /// Deleta um produto
  Future<Either<Failure, void>> deleteProduct(String productId);
}
