# VillaBistrô - Gestão Inteligente de Restaurantes
**Prd:** https://docs.google.com/document/d/140Q4w-iIxWAiZDNWOn1u2Vjr-wb6VXhzRYPcmXS_8Zg/edit?tab=t.0#heading=h.frwj0pcjxme9
**Autor:** Victor Hugo Wille
**Tech Stack:** Flutter • Supabase • Realtime • Thermal Printing

[cite_start]O **VillaBistrô** é um ecossistema completo de gestão para o setor de restaurantes e serviços de alimentação[cite: 1, 2]. [cite_start]Seu principal objetivo é otimizar o fluxo de trabalho, desde a abertura da mesa até o monitoramento do pedido pela cozinha, garantindo sincronia em tempo real e integridade dos dados[cite: 1, 2].

## 📌 Visão Geral do Projeto

| Chave | Detalhe |
| :--- | :--- |
| **Propósito** | [cite_start]Otimizar a gestão de pedidos, fluxo de delivery e controle de mesas[cite: 1, 2]. |
| **Pilar Central** | [cite_start]Sincronização de dados em tempo real (Realtime) via Supabase[cite: 1, 2]. |
| **Público-Alvo** | [cite_start]Garçons (Mobile), Cozinha (KDS) e Gestores (Desktop/Caixa)[cite: 2]. |

## 🎨 Identidade Visual (Design)

[cite_start]A identidade visual é sofisticada e utiliza um esquema de cores de alto contraste, ideal para ambientes de baixa iluminação[cite: 2].

| Constante | Cor | Código Hex | Uso Principal |
| :--- | :--- | :--- | :--- |
| **Background** | Verde Escuro | `#1E392A` | [cite_start]Fundo principal do aplicativo[cite: 2]. |
| **Foreground** | Creme | `#F0E6D1` | [cite_start]Texto e elementos de leitura[cite: 2]. |
| **Accent** | Dourado/Bronze | `#D4A373` | [cite_start]Destaque, botões primários[cite: 2]. |
| **Status Red** | Vermelho | N/A | [cite_start]Indica Mesa Ocupada[cite: 2]. |
| **Status Amber** | Amarelo | N/A | [cite_start]Indica Pagamento Parcial[cite: 2]. |

## 🛠️ Stack Tecnológico e Arquitetura

[cite_start]O projeto utiliza o padrão **MVVM simplificado** com `Provider` e rotas nomeadas[cite: 2].

* [cite_start]**Front-end:** Flutter/Dart[cite: 1, 2].
* [cite_start]**Backend:** Supabase (PostgreSQL, Auth, Storage)[cite: 1, 2].
* [cite_start]**Arquitetura:** Baseada em **Agentes (Providers)** para isolar a lógica de negócio e o estado[cite: 2].

### Agentes de Serviço (Providers)

| Agente | Função Principal |
| :--- | :--- |
| **Table Agent** | [cite_start]Gerencia o ciclo de vida das mesas (`livre`, `ocupada`) e o fluxo de pagamento[cite: 2]. |
| **Printer Agent** | [cite_start]Roteamento de impressão de tickets por categoria (Cozinha vs Bar)[cite: 2]. |
| **KDS Agent** | [cite_start]Monitora pedidos em tempo real para a tela da cozinha[cite: 2]. |
| **Bot Agent** | [cite_start]Envia notificações (e.g., status de entrega) via Supabase Edge Functions[cite: 2]. |
| **Auth Agent** | [cite_start]Responsável por garantir o isolamento de dados por `company_id` (Multi-tenant)[cite: 2]. |

## 🎯 Funcionalidades Críticas

1.  [cite_start]**Gestão de Pedidos:** Suporte a Adicionais (extras/observações) e cálculo de preço complexo[cite: 2].
2.  [cite_start]**Sincronia Automática:** Uso de Triggers SQL para que a mesa mude para `ocupada` ou `livre` automaticamente após a inserção/finalização de pedidos[cite: 2].
3.  [cite_start]**Segurança de Dados:** RLS (Row Level Security) ativado em todas as tabelas para isolamento entre restaurantes[cite: 2].
4.  [cite_start]**Pagamento:** Suporte para Fechamento de Conta Total e gerenciamento de Pagamentos Parciais[cite: 2].

## 📑 Documentação do Projeto (docs/)

[cite_start]A documentação é organizada na pasta `docs/` para manter a rastreabilidade e a transparência[cite: 2].

* [cite_start]**`docs/database`:** Armazena os scripts SQL (`01_schema_dump.sql`, `02_rls_policies.sql`, `03_fix_table_status.sql`) como backup da infraestrutura[cite: 2].
* [cite_start]**`AGENTS.md`:** Detalha a responsabilidade de cada `Provider` no sistema[cite: 2].
* [cite_start]**`PRD.md`:** Contém a visão de requisitos de produto e o foco de negócio[cite: 2].

## 🏃 Como Rodar o Projeto

1.  **Configuração:** Certifique-se de que o `.env` esteja configurado com `SUPABASE_URL` e `SUPABASE_ANON_KEY`.
2.  **Dependências:** Execute `flutter pub get` na pasta raiz do projeto.
3.  **Execução:**
    ```bash
    flutter run -d windows # Para desenvolvimento em Desktop
    # ou
    flutter run # Para Mobile
    ```