/// Interface de repositório para a entidade Product.
///
/// O repositório define operações de acesso e sincronização de dados para a
/// entidade `Product`, separando a lógica de persistência (cache/local/remoto)
/// da lógica de negócio. Interfaces ajudam a tornar o código testável e
/// permitem trocar implementações facilmente (ex.: mock, local DAO, remote).
///
import '../../../../data/models/app_data.dart';

/// Repositório abstrato para operações de leitura/sincronização da entidade Product.
abstract class ProductRepository {
  /// Render inicial rápido a partir do cache local.
  Future<List<Product>> loadFromCache();

  /// Sincronização incremental (>= lastSync). Retorna quantos registros mudaram.
  Future<int> syncFromServer();

  /// Listagem completa (normalmente do cache após sync).
  Future<List<Product>> listAll();

  /// Destaques (filtrados do cache por `featured`).
  Future<List<Product>> listFeatured();

  /// Opcional: busca direta por ID no cache.
  Future<Product?> getById(int id);
}

/*
Exemplo de uso e dicas em comentário (veja 14_providers_repository_prompt[1].md):
final repo = MinhaImplementacaoDeProductRepository();
final lista = await repo.listAll();
*/
