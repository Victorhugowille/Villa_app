# Villa_app - Gestão Inteligente de Restaurantes

**Autor:** Victor Hugo Wille

**Tech Stack:** Flutter • Supabase • Realtime • Thermal Printing

**Villa_app** é um ecossistema completo de gestão para bares e restaurantes que integra o atendimento no salão (garçons), a produção na cozinha (KDS/Impressão) e a gestão administrativa em uma única experiência fluida e sincronizada em tempo real.

## 📌 Visão Geral

O objetivo do Villa_app é eliminar o caos operacional de um restaurante, garantindo que:
* **Pedidos** fluam da mesa para a cozinha instantaneamente.
* **Impressão** seja roteada automaticamente para as estações corretas (Bar vs Cozinha).
* **Pagamentos** sejam flexíveis (parciais ou totais) e seguros.
* **Dados** sejam sincronizados em tempo real entre múltiplos dispositivos via Supabase.

## 👤 Personas Principais

1.  **O Garçom Ágil:** Precisa lançar pedidos rapidamente na mesa, adicionar observações e fechar contas parciais sem travar o sistema.
2.  **A Cozinha Sincronizada:** Precisa receber pedidos claros (via Tela KDS ou Impressora Térmica) organizados por ordem de chegada.
3.  **O Gestor:** Precisa de relatórios de faturamento e controle total do cardápio e estoque.

## 🚀 Fluxo de Execução

* **Splash Screen:** Carregamento inicial, verificação de sessão (Auth) e pré-carregamento de temas.
* **Onboarding:** Apresentação das funcionalidades e identidade da marca.
* **Login/Auth:** Autenticação segura via E-mail/Senha com suporte a múltiplos inquilinos (Company ID) para isolamento de dados.
* **Seleção de Mesas (Home):** Visualização gráfica do status das mesas (Livre, Ocupada, Pagamento Parcial).
* **Lançamento de Pedidos:** Catálogo visual, seleção de adicionais obrigatórios/opcionais e envio para produção.

## 🎨 Identidade Visual

Baseada na sofisticação e conforto de um bistrô moderno, utilizando `ThemeProvider` para gerenciar a consistência.

* **Primary (Background):** `#1E392A` (Deep Green)
* **Foreground (Texto/Ícones):** `#F0E6D1` (Cream)
* **Accent (Destaques):** `#D4A373` (Gold/Bronze)
* **Estados de Mesa:**
    * 🔴 **Vermelho:** Ocupada
    * 🟠 **Amber:** Pagamento Parcial (Atenção)
    * 🟢 **Verde/Tema:** Livre

## ⚙️ Requisitos Funcionais (RF)

* **Gestão de Mesas:** Abrir mesa, adicionar itens, fechar conta total e realizar pagamentos parciais por item.
* **Roteamento de Impressão:** O sistema decide se o item vai para a impressora do "Bar" ou da "Cozinha" baseado na categoria do produto (ex: Bebidas -> Bar).
* **KDS (Kitchen Display System):** Monitor interativo que substitui ou complementa o papel, com estados "Em Produção" -> "Pronto" -> "Entregue".
* **Cardápio Dinâmico:** Produtos com imagens (Supabase Storage), categorias e grupos de adicionais.
* **Relatórios:** Geração de planilhas Excel `.xlsx` com histórico de transações por período.

## 🔧 Requisitos Não Funcionais (RNF)

* **Arquitetura:** Clean Architecture simplificada com `Provider` para gerência de estado e injeção de dependência.
* **Backend as a Service:** Supabase para Auth, Database (PostgreSQL) e Storage (Imagens).
* **Offline/Realtime:** Uso de WebSockets (`supabase_flutter`) para atualizações instantâneas de pedidos entre garçons e cozinha.
* **Impressão:** Integração direta via pacote `printing` e comandos ESC/POS para impressoras térmicas de rede.

## 💾 Dados & Persistência (Supabase)

Estrutura relacional simplificada:

| Tabela | Descrição |
| :--- | :--- |
| `mesas` | Status atual e número da mesa. |
| `pedidos` | Cabeçalho do pedido, status (`awaiting_print`, `production`, `ready`) e vínculo com mesa. |
| `itens_pedido` | Detalhes do item, quantidade e JSON de adicionais selecionados. |
| `transacoes` | Registro financeiro imutável gerado após o fechamento de conta. |
| `delivery_info` | Dados sensíveis de entrega (LGPD compliant). |
| `company` | Configurações do inquilino (Multi-tenant). |

## 🛣️ Roteamento

* `/` : Splash Screen (Decisor de fluxo)
* `/onboarding` : Introdução ao App
* `/login` : Tela de Autenticação
* `/home` : Shell Responsivo (Seleção de Mesas e Menu Principal)

## ✅ Checklist de Conformidade

- [x] Autenticação Multi-tenant (Company ID isolado)
- [x] Impressão automática e roteada por categoria
- [x] Sincronização em tempo real (Garçom lança -> KDS recebe)
- [x] Tratamento de Pagamento Parcial (Mesa fica Amber)
- [x] Geração de Relatórios em Excel
- [x] Upload e Cache de Imagens de Produtos
- [x] Edição de Perfil e Empresa

## 🧪 Testes Manuais (QA)

1.  **Fluxo do Pedido:** Abrir Mesa -> Adicionar Produto com Adicional -> Enviar. Verificar se apareceu no KDS e se a impressão ocorreu.
2.  **Sincronia:** Abrir o app em dois dispositivos. Modificar uma mesa em um e verificar se o status atualiza no outro instantaneamente.
3.  **Financeiro:** Realizar um pagamento parcial de 50% em uma mesa e verificar se o status muda visualmente para Amber e se o saldo restante está correto na conta final.

## 📁 Estrutura de Agentes (Providers)

O sistema utiliza uma arquitetura baseada em "Agentes" de negócio (ver `AGENTS.md`):
* **Printer Agent:** Escuta novos pedidos e gerencia filas de impressão.
* **Table Agent:** Gerencia o ciclo de vida do atendimento e ocupação.
* **Inventory Agent:** Cuida do CRUD complexo de produtos e categorias.
* **KDS Agent:** Controla o fluxo de produção na cozinha.

## 🔗 Links Úteis

* [Documentação Supabase Flutter](https://supabase.com/docs/guides/getting-started/tutorials/with-flutter)
* [Pacote Printing](https://pub.dev/packages/printing)
