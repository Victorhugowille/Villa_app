import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';

/// Implementação do Repository - conecta DataSource com Repository abstrato
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDatasource remoteDatasource;

  ProductRepositoryImpl({required this.remoteDatasource});

  @override
  Future<Either<Failure, List<ProductEntity>>> getProducts(
    String companyId, [
    String? categoryId,
  ]) async {
    try {
      final products = await remoteDatasource.getProducts(companyId);
      // Converter models para entities
      final entities = products.map((p) => p.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(ServerFailure('Erro ao buscar produtos: $e'));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> getProductById(String productId) async {
    try {
      final product = await remoteDatasource.getProductById(productId);
      // Converter model para entity
      return Right(product.toEntity());
    } catch (e) {
      return Left(ServerFailure('Erro ao buscar produto: $e'));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> createProduct(
    ProductEntity product,
  ) async {
    try {
      // Converter entity para mapa para enviar ao datasource
      final productData = {
        'name': product.name,
        'price': product.price,
        'category_id': product.categoryId,
        'display_order': product.displayOrder,
        'image_url': product.imageUrl,
        'is_sold_out': product.isSoldOut,
      };
      final createdProduct = await remoteDatasource.createProduct(productData);
      // Converter model para entity
      return Right(createdProduct.toEntity());
    } catch (e) {
      return Left(ServerFailure('Erro ao criar produto: $e'));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> updateProduct(
    ProductEntity product,
  ) async {
    try {
      // Converter entity para mapa para enviar ao datasource
      final updates = {
        'name': product.name,
        'price': product.price,
        'category_id': product.categoryId,
        'display_order': product.displayOrder,
        'image_url': product.imageUrl,
        'is_sold_out': product.isSoldOut,
      };
      await remoteDatasource.updateProduct(product.id, updates);
      return Right(product);
    } catch (e) {
      return Left(ServerFailure('Erro ao atualizar produto: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String productId) async {
    try {
      await remoteDatasource.deleteProduct(productId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Erro ao deletar produto: $e'));
    }
  }
}
