**PRD:** https://docs.google.com/document/d/140Q4w-iIxWAiZDNWOn1u2Vjr-wb6VXhzRYPcmXS_8Zg/edit?tab=t.0#heading=h.frwj0pcjxme9

# 📜 VillaBistrô: Documento de Arquitetura e Visão Abrangente

## 1. Visão Geral e Propósito do Projeto

O **VillaBistrô** é uma aplicação completa de gestão para o setor de restaurantes e serviços de alimentação. Seu principal objetivo é otimizar o fluxo de trabalho, desde a abertura de uma mesa (pelo Garçom) até o monitoramento do pedido (pela Cozinha) e a notificação do cliente (pelo Bot).

| Característica | Detalhe |
| :--- | :--- |
| **Nome do Projeto** | VillaBistrô (ou Villa\_app) |
| **Propósito** | Gestão de restaurantes, otimização de pedidos e fluxo de delivery/mesa. |
| **Público-Alvo** | Garçons (App Mobile), Caixas/Gestores (App Desktop/Tablet) e Clientes (Notificações). |
| **Identidade** | Aconchegante e sofisticada (paleta de tons de verde escuro, creme e dourado). |

---

## 2. Stack Tecnológico e Arquitetura

O projeto foi construído com uma combinação robusta de tecnologias modernas, focando em performance, escalabilidade e desenvolvimento ágil.

### 2.1. Tecnologias Principais

| Camada | Tecnologia | Propósito |
| :--- | :--- | :--- |
| **Front-end** | **Flutter / Dart** | Desenvolvimento multiplataforma (Mobile e Desktop) com um único código-base. |
| **Backend** | **Supabase** | Backend-as-a-Service (BaaS) com PostgreSQL, oferecendo Autenticação (Auth), Banco de Dados Relacional e Armazenamento (Storage). |
| **Estado** | **Provider** | Gerenciamento de estado leve, simples e direto. |

### 2.2. Arquitetura de Código (Flutter/Dart)

A arquitetura segue o padrão **MVVM simplificado (Modelo-Visão-ViewModel)**, organizado em pastas por responsabilidade.

| Pasta | Conteúdo e Responsabilidade |
| :--- | :--- |
| `lib/data/` | **Models:** Classes Dart para mapear as tabelas do Supabase (e.g., `Product`, `Order`, `Table`). |
| `lib/providers/` | **Agentes / ViewModels:** Lógica de Estado e Negócio (e.g., `AuthProvider`, `TableProvider`). |
| `lib/screens/` | **Vistas (UI):** Telas do aplicativo (e.g., `login/`, `home/`, `config/`). |

---

## 3. Identidade Visual e Tematização

O projeto utiliza uma paleta de cores escura e sofisticada, gerenciada pelo `ThemeProvider`.

| Constante | Cor | Código Hex | Uso |
| :--- | :--- | :--- | :--- |
| `kBackgroundColor` | Verde Escuro | `#1E392A` | Fundo principal e base do app. |
| `kForegroundColor` | Creme | `#F0E6D1` | Texto e elementos de primeiro plano. |
| `kAccentColor` | Dourado/Bronze | `#D4A373` | Botões, destaques e elementos interativos. |

**Manutenção de Código:** Foi utilizada a técnica de refatoração para substituir o padrão obsoleto de cores pela sintaxe moderna (`Color.fromRGBO(r, g, b, alpha)`).

---

## 4. Fluxo do Usuário e Navegação

O fluxo de navegação é controlado por **Rotas Nomeadas** e foi projetado para ser intuitivo.

### 4.1. Arquitetura de Rotas
* Foi adotado o padrão de **Rotas Nomeadas** para as telas essenciais: `/`, `/onboarding`, `/home`, `/login`.
* Foi implementado um **Fluxo Unidirecional** que impede o retorno do usuário para telas de introdução (Splash, Onboarding) após o login.

### 4.2. Jornada Crítica
1.  **Launch/Splash:** Decisão de rota baseada na sessão de autenticação.
2.  **Onboarding:** Uso de `PageView` para apresentação do app.
3.  **Home:** Acesso ao gerenciamento de mesas, que é a tela principal do Garçom.

---

## 5. Backend (Supabase) e Segurança

O uso do Supabase envolveu a implementação de práticas rigorosas de segurança e gestão de dados.

### 5.1. Segurança Multi-Tenant (Isolamento de Dados)
* **RLS (Row Level Security):** Ativado em todas as tabelas críticas.
* **Filtro:** O acesso é permitido somente se o `company_id` do usuário logado for igual ao `company_id` da linha na tabela.

### 5.2. Gestão de Imagens (Storage)
* As fotos dos produtos são salvas em **Supabase Buckets**.
* O principal desafio foi resolvido através da correta configuração das **Policies (Políticas)** de acesso do Storage, que funcionam como a "polícia" para permitir ou negar o upload e download de imagens por usuário.

### 5.3. Sincronização e Triggers
* **Realtime:** Utilizado para a atualização instantânea de pedidos no **KDS Agent**.
* **Triggers SQL:** Implementados para automatizar a manutenção do `status` da mesa no banco de dados (ex: se todos os pedidos estão `finalizado`, o status da mesa muda para `livre`).

---

## 6. Funcionalidades Operacionais (Lógica de Negócio)

### 6.1. Gestão de Estado (Agentes/Providers)
Os Providers são os agentes de inteligência:
* **`Table Agent`:** Responde pelas transações principais: `placeOrder`, `closeAccount`, e registra pagamentos parciais.
* **`Printer Agent`:** Define, via categorias de produto, para qual impressora enviar o ticket (Bar ou Cozinha).
* **`KDS Agent`:** Gerencia a fila de pedidos na tela da cozinha.

### 6.2. Pedidos e Cálculo
* A lógica de cálculo de preço (`totalPrice` no `CartItem`) inclui a iteração sobre a lista de **Adicionais** para somar corretamente os valores extras antes de computar o total.

### 6.3. Notificação Externa (Bot de WhatsApp)
* Foi arquitetada a integração de notificação de status de pedido via **Supabase Edge Functions** (serviço serverless), que se conecta a uma API de terceiros (como Z-API) para enviar mensagens via WhatsApp, mantendo as chaves de API seguras no backend.

---

## 7. Metodologia e Documentação

O projeto adota uma metodologia ágil, valorizando a documentação e a qualidade de código (Regra de Ouro).

* **Documentos Chave:** `PRD.md`, `AGENTS.md` (detalhando a responsabilidade dos Providers) e `SUPABASE_INTEGRATION_GUIDE.md` (guia passo-a-passo).
* **Organização:** Todos os documentos e scripts SQL de infraestrutura são mantidos nas pastas `docs/` para garantir a rastreabilidade e facilitar a evolução do projeto.