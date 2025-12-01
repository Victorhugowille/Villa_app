/// Interface de repositório para a entidade Table.
///
/// O repositório define operações de acesso e sincronização de dados para a
/// entidade `Table`, separando a lógica de persistência (cache/local/remoto)
/// da lógica de negócio. Interfaces ajudam a tornar o código testável e
/// permitem trocar implementações facilmente (ex.: mock, local DAO, remote).
///
import '../../../../data/models/app_data.dart';

/// Repositório abstrato para operações de leitura/sincronização da entidade Table.
abstract class TableRepository {
  /// Render inicial rápido a partir do cache local.
  Future<List<Table>> loadFromCache();

  /// Sincronização incremental (>= lastSync). Retorna quantos registros mudaram.
  Future<int> syncFromServer();

  /// Listagem completa (normalmente do cache após sync).
  Future<List<Table>> listAll();

  /// Destaques (filtrados do cache por `featured`).
  Future<List<Table>> listFeatured();

  /// Opcional: busca direta por ID no cache.
  Future<Table?> getById(int id);
}

/*
Exemplo de uso e dicas em comentário:
final repo = MinhaImplementacaoDeTableRepository();
final lista = await repo.listAll();
*/
