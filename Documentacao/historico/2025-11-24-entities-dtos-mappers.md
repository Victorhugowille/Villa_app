# 🌟 Documentação Completa do Projeto VillaBistrô

**Autor:** Victor Hugo Wille
**Data da Consolidação:** 24/11/2025
**Foco:** Visão abrangente da arquitetura, decisões e funcionalidades implementadas no sistema de gestão VillaBistrô (Villa\_app).

---

## 1. Visão Estratégica e Metadados

| Chave | Valor |
| :--- | :--- |
| **Objetivo** | Otimizar a gestão de restaurantes, integrando atendimento (Garçom), produção (KDS) e financeiro (Caixa). |
| **Pilar Central** | Sincronização de dados em tempo real (Realtime) entre múltiplos dispositivos. |
| **Identidade Visual**| Dark Mode sofisticado: Verde Escuro (`#1E392A`), Creme (`#F0E6D1`) e Dourado (`#D4A373`). |
| **Regra de Ouro (Código)**| Resposta do código completa, na pasta correta, sem explicações teóricas. |

## 2. Stack Tecnológico

| Camada | Tecnologia | Decisão Chave |
| :--- | :--- | :--- |
| **Frontend** | Flutter/Dart | Multiplataforma (Mobile/Desktop) com código único. |
| **Backend** | Supabase (PostgreSQL) | Escolhido por ser um BaaS com banco de dados relacional e capacidade Realtime. |
| **Estado** | Provider (MultiProvider) | Gerenciamento de estado leve, com injeção de dependência e hierarquia clara. |
| **Segurança** | RLS (Row Level Security) | Essencial para o modelo Multi-tenant, garantindo isolamento de dados por `company_id`. |

---

## 3. Arquitetura de Software (Agentes)

O projeto adota uma arquitetura baseada em **Agentes (Providers)**, que separam o Estado da Lógica de Negócios e da UI.

| Agente (Provider) | Arquivo | Funções Chave |
| :--- | :--- | :--- |
| **Auth Agent** | `auth_provider.dart` | Gerencia Login, Logout e extrai o `company_id` do metadado do usuário para filtros RLS. |
| **Table Agent** | `table_provider.dart` | Gerencia o "chão de loja": `fetchAndSetTables`, `placeOrder`, `closeAccount`, Pagamentos Parciais. |
| **Product Agent** | `product_provider.dart` | Gerencia o Cardápio: CRUD de Produtos, Upload de Imagens (Storage), Deleção e Duplicação em Cascata. |
| **KDS Agent** | `kds_provider.dart` | Monitor da Cozinha: Escuta pedidos em tempo real e gerencia o ciclo de vida (`production` ➡️ `ready`). |
| **Printer Agent** | `printer_provider.dart` | Roteamento Inteligente: Agrupa itens por categoria e envia a impressão para o destino correto (Cozinha/Bar). |
| **Bot Agent** | `bot_provider.dart` | Envio de Notificações (ex: Pedido saiu para entrega) via Edge Functions do Supabase. |

---

## 4. Funcionalidades Críticas e Implementação

### 4.1. Lógica Multi-Tenant e RLS
* **Decisão:** Cada tabela relevante possui a coluna `company_id`.
* **RLS (docs/database/02\_rls\_policies.sql):** Políticas de acesso criadas para forçar que o `company_id` da linha seja igual ao `company_id` do usuário logado em todas as operações (`SELECT`, `INSERT`, `UPDATE`).

### 4.2. Sincronização e Triggers
* **Realtime (KDS):** Utiliza `RealtimeChannel` para que o `KdsProvider` atualize a lista de pedidos em milissegundos quando um garçom envia um pedido.
* **Triggers (docs/database/03\_fix\_table\_status.sql):** Uma função SQL garante que o `status` da mesa seja sincronizado automaticamente: se há pedidos ativos, a mesa é `ocupada`; se todos são `finalizado`, a mesa é `livre`. Isso reduz o código Dart e aumenta a robustez.

### 4.3. Pedidos Complexos e Cálculo
* A classe `CartItem` foi projetada para calcular o `totalPrice` corretamente, incluindo a soma dos **Adicionais** antes de multiplicar pela quantidade do produto.
* A classe `Order` consegue lidar com a serialização de dados aninhados (`CartItemAdicional` em JSONB) para o Supabase.

### 4.4. Rotas e UX
* O `NavigationProvider` foi implementado para gerenciar a pilha de telas, adaptando a navegação entre a barra lateral (Desktop) e o empilhamento tradicional (Mobile).
* Rotas críticas (`/home`, `/login`) garantem a experiência de primeira execução sem permitir que o usuário volte para telas de introdução.

## 5. Próximos Passos (Backlog)

* **Finalizar Integração Bot:** Implementar a lógica completa do lado do Supabase Edge Function para o envio da mensagem.
* **Relatórios (Excel):** Refinar o `ReportProvider` para permitir filtros avançados e gerar planilhas financeiras mais complexas.
* **Teste de Carga:** Simular múltiplos garçons fazendo pedidos simultaneamente para validar a estabilidade do Realtime e dos Triggers.

---

## 6. Documentação do Projeto (docs/)

A documentação é mantida em uma pasta dedicada para garantir a rastreabilidade e facilitar a colaboração.

| Arquivo/Pasta | Conteúdo | Finalidade |
| :--- | :--- | :--- |
| `AGENTS.md` | Detalhes sobre a responsabilidade de cada Provider. | Documentação do Código (Para Devs). |
| `PRD.md` | Visão e Requisitos de Produto (Personas e Fluxos). | Visão de Negócio (Para Gestores). |
| `database/` | Scripts SQL (Schema, RLS, Triggers) para backup e setup do Supabase. | Backup e Infraestrutura. |
| `contracts/` | JSONs de exemplo para dados (Mock de Pedidos, Produtos). | Testes de Front-end (UI/Dev). |