/// Interface de repositório para a entidade Order.
///
/// O repositório define operações de acesso e sincronização de dados para a
/// entidade `Order`, separando a lógica de persistência (cache/local/remoto)
/// da lógica de negócio. Interfaces ajudam a tornar o código testável e
/// permitem trocar implementações facilmente (ex.: mock, local DAO, remote).
///
import '../../../../data/models/app_data.dart';

/// Repositório abstrato para operações de leitura/sincronização da entidade Order.
abstract class OrderRepository {
  /// Render inicial rápido a partir do cache local.
  Future<List<Order>> loadFromCache();

  /// Sincronização incremental (>= lastSync). Retorna quantos registros mudaram.
  Future<int> syncFromServer();

  /// Listagem completa (normalmente do cache após sync).
  Future<List<Order>> listAll();

  /// Destaques (filtrados do cache por `featured`).
  Future<List<Order>> listFeatured();

  /// Opcional: busca direta por ID no cache.
  Future<Order?> getById(int id);
}

/*
Exemplo de uso e dicas em comentário:
final repo = MinhaImplementacaoDeOrderRepository();
final lista = await repo.listAll();
*/
