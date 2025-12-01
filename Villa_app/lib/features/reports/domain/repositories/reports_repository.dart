/// Interface de repositório para a entidade SavedReport.
///
/// O repositório define as operações de acesso e sincronização de dados
/// relacionadas a relatórios salvos (`SavedReport`). Ele separa a lógica de
/// persistência (cache/local/remoto) da lógica de negócio, permitindo trocar
/// implementações (mock, local DAO, remoto) e facilitando testes.
///
/// ⚠️ Dicas rápidas:
/// - Normalmente o fluxo é: `syncFromServer` -> persistir no cache -> `listAll`/`loadFromCache`.
/// - Ao implementar, mantenha logs (kDebugMode) para depurar sincronizações e conversões.
/// - Métodos assíncronos usados na UI devem respeitar `mounted` antes de chamar setState.

import '../../../../data/models/app_data.dart';

/// Repositório abstrato para operações de leitura/sincronização da entidade SavedReport.
abstract class ReportsRepository {
  /// Render inicial rápido a partir do cache local.
  ///
  /// Uso: retornar os relatórios já persistidos localmente (cache/DB) para
  /// mostrar uma UI responsiva antes de qualquer sincronização remota.
  Future<List<SavedReport>> loadFromCache();

  /// Sincronização incremental (>= lastSync). Retorna quantos registros mudaram.
  ///
  /// Uso: buscar alterações no servidor desde o último `lastSync`, aplicar
  /// transformações, atualizar o cache local e retornar quantos registros
  /// foram adicionados/atualizados/removidos.
  Future<int> syncFromServer();

  /// Listagem completa (normalmente do cache após sync).
  ///
  /// Uso: retornar a lista completa de `SavedReport`, geralmente a partir do cache.
  Future<List<SavedReport>> listAll();

  /// Destaques (filtrados do cache por `featured`).
  ///
  /// Uso: retornar uma lista filtrada de relatórios marcados como destaque.
  /// Se o modelo não suportar `featured`, a implementação pode retornar uma
  /// lista vazia ou aplicar outra lógica de destaque.
  Future<List<SavedReport>> listFeatured();

  /// Opcional: busca direta por ID no cache.
  ///
  /// Uso: recuperar um `SavedReport` do cache local por seu `id`. Retorna `null`
  /// caso não exista no cache.
  Future<SavedReport?> getById(int id);
}

/*
// Exemplo de uso:
// final repo = MinhaImplementacaoDeReportsRepository();
// final cached = await repo.loadFromCache();
// final changed = await repo.syncFromServer();
// final all = await repo.listAll();

// Dicas de implementação:
// - Implemente um DAO local (sqflite/hive) para armazenar os relatórios salvos.
// - Implemente um datasource remoto que exporte as mudanças desde `lastSync`.
// - No `syncFromServer`, atualize o cache e retorne o número de registros
//   que sofreram mudanças (inserts/updates/deletes).
// - Para testes, crie um mock do repositório que retorna dados fixos.

// Checklist rápido:
// - [ ] Verificar se `SavedReport` possui fromMap/toMap robustos.
// - [ ] Tratar erros de rede e persistência em `syncFromServer`.
// - [ ] Evitar chamar setState após await sem checar `mounted` na UI.
*/
