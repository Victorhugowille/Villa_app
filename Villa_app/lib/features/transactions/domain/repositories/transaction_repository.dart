/// Interface de repositório para a entidade Transaction.
///
/// O repositório define operações de acesso e sincronização de dados para a
/// entidade `Transaction`, separando a lógica de persistência (cache/local/remoto)
/// da lógica de negócio. Interfaces ajudam a tornar o código testável e
/// permitem trocar implementações facilmente (ex.: mock, local DAO, remote).
///
import '../../../../data/models/app_data.dart';

/// Repositório abstrato para operações de leitura/sincronização da entidade Transaction.
abstract class TransactionRepository {
  /// Render inicial rápido a partir do cache local.
  Future<List<Transaction>> loadFromCache();

  /// Sincronização incremental (>= lastSync). Retorna quantos registros mudaram.
  Future<int> syncFromServer();

  /// Listagem completa (normalmente do cache após sync).
  Future<List<Transaction>> listAll();

  /// Destaques (filtrados do cache por `featured`).
  Future<List<Transaction>> listFeatured();

  /// Opcional: busca direta por ID no cache.
  Future<Transaction?> getById(int id);
}

/*
Exemplo de uso e dicas em comentário:
final repo = MinhaImplementacaoDeTransactionRepository();
final lista = await repo.listAll();
*/
