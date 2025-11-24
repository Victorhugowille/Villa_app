# AGENTS — System Providers & Logic Controllers

Este arquivo documenta os "Agentes" do sistema (implementados via `ChangeNotifier` Providers). Cada agente é responsável por um domínio específico da lógica de negócios, gerenciamento de estado e interação com serviços externos (Supabase, Impressoras, Arquivos).

---

## 🖨️ Agente de Impressão e Roteamento (Printer Agent)
[cite_start]**Arquivo:** `lib/providers/printer_provider.dart` [cite: 8]

Este agente é responsável por monitorar novos pedidos e roteá-los fisicamente para as impressoras corretas (Cozinha, Bar, etc.) baseando-se nas categorias dos produtos.

### Responsabilidades
1.  [cite_start]**Monitoramento em Tempo Real:** Escuta a tabela `pedidos` no Supabase por inserções com status `awaiting_print`[cite: 8].
2.  [cite_start]**Roteamento Inteligente:** Agrupa itens de um pedido com base na categoria e envia para a impressora configurada para aquela categoria (ex: Bebidas -> Impressora Bar; Comida -> Impressora Cozinha)[cite: 8].
3.  [cite_start]**Gerenciamento de Templates:** Aplica configurações de estilo (`KitchenTemplateSettings`, `ReceiptTemplateSettings`) para formatar o cupom[cite: 8].

### Comandos Chave
* [cite_start]`startListening()`: Inicia o websocket para escutar novos pedidos[cite: 8].
* [cite_start]`reprintOrder(order)`: Força o reenvio de um pedido já existente para as impressoras[cite: 8].
* [cite_start]`savePrinterSettings()`: Persiste o mapeamento de "Impressora <-> Categoria"[cite: 8].

**Observação:** Este agente requer uma conexão ativa com o Supabase Realtime e permissões de acesso à rede local para encontrar impressoras térmicas.

---

## 🍳 Agente de Controle de Cozinha (KDS Agent)
[cite_start]**Arquivo:** `lib/providers/kds_provider.dart` [cite: 6]

Este agente atua como o controlador do fluxo de produção. Ele transforma o aplicativo em um monitor de cozinha (Kitchen Display System), sincronizando o estado dos pedidos entre todos os dispositivos.

### Responsabilidades
1.  [cite_start]**Filtragem de Estação:** Filtra pedidos entre `Mesa` e `Delivery` ou exibe ambos[cite: 6].
2.  **Avanço de Status:** Gerencia a máquina de estados do pedido:
    * `production` ➡️ `ready` (Pronto)
    * [cite_start]`ready` ➡️ `completed` (Entregue/Finalizado)[cite: 6].
3.  [cite_start]**Sincronização:** Utiliza `RealtimeChannel` para atualizar a tela instantaneamente quando um pedido é criado ou modificado em outro terminal[cite: 6].

### Fluxo de Trabalho
1.  O agente carrega pedidos com status `awaiting_print`, `production` ou `ready`.
2.  Ao chamar `advanceOrder()`, ele atualiza o banco. [cite_start]Se for um pedido de mesa pronto sendo finalizado, ele redireciona para a tela de Pagamento[cite: 6].

---

## 🍽️ Agente de Gestão de Mesas (Floor Manager Agent)
[cite_start]**Arquivo:** `lib/providers/table_provider.dart` [cite: 4, 10]

Este agente gerencia o "chão de fábrica" do restaurante, controlando a ocupação das mesas, lançamentos de pedidos e fechamento de contas.

### Responsabilidades
1.  [cite_start]**Ciclo de Vida da Mesa:** Cria novas mesas (`addNextTable`), atualiza ocupação e libera mesas (`clearTable`)[cite: 10].
2.  [cite_start]**Processamento de Pedidos:** Método `placeOrder` insere o pedido mestre e seus itens (com adicionais) transacionalmente no Supabase[cite: 10].
3.  [cite_start]**Fechamento Financeiro:** O método `closeAccount` cria uma entrada na tabela `transacoes`, vincula os pedidos a essa transação e libera a mesa para o próximo cliente[cite: 10].
4.  [cite_start]**Pagamento Parcial:** Gerencia o estado local de pagamentos parciais (`registerPartialPayment`), permitindo que grupos paguem separadamente sem fechar a mesa inteira[cite: 10].

---

## 📦 Agente de Catálogo e Estoque (Inventory Agent)
[cite_start]**Arquivo:** `lib/providers/product_provider.dart` [cite: 9]

Responsável pela integridade dos dados do cardápio. Ele lida com a criação, edição e exclusão complexa de produtos e categorias.

### Responsabilidades
1.  [cite_start]**CRUD de Produtos:** Criação e edição de produtos, incluindo upload de imagens para o Supabase Storage[cite: 9].
2.  [cite_start]**Deleção em Cascata (`_deleteProductCascading`):** Garante que, ao deletar um produto, suas imagens no Storage e seus grupos de adicionais vinculados sejam removidos para não deixar lixo no banco[cite: 9].
3.  [cite_start]**Duplicação Inteligente:** Possui lógica para duplicar produtos, categorias e grupos de adicionais (`duplicateProduct`, `duplicateCategory`), criando cópias com sufixo "_copia(N)" e copiando fisicamente as imagens no Storage[cite: 9].

---

## 📊 Agente de Relatórios (Analytics Agent)
[cite_start]**Arquivo:** `lib/providers/report_provider.dart` [cite: 3]

Um agente utilitário focado em extração de dados para contabilidade e gestão.

### Responsabilidades
1.  [cite_start]**Extração de Dados:** Busca transações baseadas em intervalos de datas[cite: 3].
2.  [cite_start]**Geração de Arquivos:** Utiliza a biblioteca `excel` para compilar os dados em uma planilha `.xlsx` e salvá-la no armazenamento temporário do dispositivo para compartilhamento[cite: 3].

---

## 🔐 Agentes de Infraestrutura e Estado

Estes agentes fornecem a base para o funcionamento dos agentes de negócio acima.

| Agente | Arquivo | Função Principal |
| :--- | :--- | :--- |
| **Auth Agent** | [cite_start]`auth_provider.dart` [cite: 1] | [cite_start]Gerencia sessão do usuário, login/logout e identifica a `company_id` atual para isolamento de dados (Multi-tenant)[cite: 1]. |
| **Company Agent** | [cite_start]`company_provider.dart` [cite: 5] | [cite_start]Gerencia o perfil da empresa, configurações fiscais e dados do usuário logado[cite: 5]. |
| **Navigation Agent** | [cite_start]`navigation_provider.dart` [cite: 7] | [cite_start]Gerencia a pilha de telas customizada para o layout responsivo, histórico de navegação e ações da AppBar[cite: 7]. |
| **Cart Agent** | [cite_start]`cart_provider.dart` [cite: 2] | [cite_start]Mantém o estado temporário dos itens selecionados antes de serem efetivados como um Pedido na mesa[cite: 2]. |
| **Theme Agent** | [cite_start]`theme_provider.dart` [cite: 11] | [cite_start]Gerencia a aparência do app, alternando entre paletas pré-definidas ou temas customizados pelo usuário[cite: 11]. |
| **Transaction Agent**| [cite_start]`transaction_provider.dart` [cite: 12]| [cite_start]Focado em métricas financeiras, calcula receita total e receita por método de pagamento[cite: 12]. |

---

## 🚀 Exemplo de Fluxo de Interação entre Agentes

1.  **Cart Agent** acumula itens selecionados pelo usuário.
2.  **Table Agent** recebe os itens do Cart e executa `placeOrder()`, salvando no Supabase com status `awaiting_print`.
3.  **Printer Agent** detecta o novo pedido via Realtime, verifica as categorias dos itens e imprime nas impressoras correspondentes. Em seguida, atualiza o status para `production`.
4.  **KDS Agent** exibe o pedido na tela da cozinha. O cozinheiro marca como `ready`.
5.  **Table Agent** (via Garçom) vê o status `ready`, entrega o prato e posteriormente chama `closeAccount()`.
6.  **Transaction Agent** registra o valor financeiro.