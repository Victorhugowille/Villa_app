/// Interface de repositório para a entidade Company.
///
/// O repositório define operações de acesso e sincronização de dados para a
/// entidade `Company`, separando a lógica de persistência (cache/local/remoto)
/// da lógica de negócio. Interfaces ajudam a tornar o código testável e
/// permitem trocar implementações facilmente (ex.: mock, local DAO, remote).
///
/// Dicas rápidas:
/// - Prefira implementar um fluxo: syncFromServer -> persist no cache -> listAll/loadFromCache.
/// - Mantenha logs (kDebugMode) nas implementações para depurar syncs e conversões.
/// - Métodos que retornam listas devem retornar coleções do tipo `List<Company>`.

import '../../../../data/models/app_data.dart';

/// Repositório abstrato para operações de leitura/sincronização da entidade Company.
abstract class CompanyRepository {
  /// Render inicial rápido a partir do cache local.
  ///
  /// Uso: deve retornar os dados já persistidos localmente (cache/DB) para mostrar
  /// uma UI responsiva antes de qualquer sincronização remota.
  Future<List<Company>> loadFromCache();

  /// Sincronização incremental (>= lastSync). Retorna quantos registros mudaram.
  ///
  /// Uso: buscar alterações no servidor desde o último `lastSync`, aplicar
  /// transformações necessárias, atualizar o cache local e retornar a quantidade
  /// de registros que foram adicionados/atualizados/removidos.
  Future<int> syncFromServer();

  /// Listagem completa (normalmente do cache após sync).
  ///
  /// Uso: retornar a lista completa de `Company` geralmente a partir do cache
  /// local. Implementações podem delegar para um DAO local.
  Future<List<Company>> listAll();

  /// Destaques (filtrados do cache por `featured`).
  ///
  /// Uso: retornar uma lista filtrada de empresas marcadas como destaque. A
  /// lógica de filtragem deve ser feita localmente (cache) para performance.
  Future<List<Company>> listFeatured();

  /// Opcional: busca direta por ID no cache.
  ///
  /// Uso: recuperar um `Company` do cache local por seu `id`. Retorna `null`
  /// caso não exista no cache.
  Future<Company?> getById(int id);
}

/*
// Exemplo de uso:
// final repo = MinhaImplementacaoDeCompanyRepository();
// final cached = await repo.loadFromCache();
// final changed = await repo.syncFromServer();
// final all = await repo.listAll();

// Dicas para implementação:
// - Crie um DAO local (ex.: using sqflite/hive) para armazenar o cache.
// - Crie um datasource remoto para conversar com a API/Supabase.
// - No syncFromServer, atualize o cache e retorne o número de registros
//   que sofreram mudanças (inserts/updates/deletes).
// - Para testes, implemente um mock do repositório que retorna dados fixos.

// Checklist rápido:
// - [ ] Implementar conversões robustas (fromMap/toMap) na entidade `Company`.
// - [ ] Garantir que `syncFromServer` trate erros de rede e persistência.
// - [ ] Evitar chamar setState após await sem verificar `mounted` na UI.
*/
