# 🧠 Histórico e Estratégia de Prompts - VillaBistrô

Este documento fornece um resumo executivo da engenharia de prompts utilizada no desenvolvimento do **VillaBistrô Mobile**. O objetivo desta pasta não é registrar cada conversa, mas sim destacar os **momentos decisivos** que definiram a arquitetura, as regras de negócio e o padrão de qualidade do código.

> ⚠️ **Nota Importante:** Os arquivos nesta pasta representam uma **amostra selecionada** dos melhores prompts e soluções. Eles não constituem o histórico completo de chat, mas servem como referência para manter a consistência do desenvolvimento em sessões futuras.

---

## 📅 Linha do Tempo e Foco de Desenvolvimento

### **Setembro 2025: A Fundação**
*Foco: Arquitetura, Banco de Dados e Segurança.*

Nesta fase, os prompts foram direcionados para estabelecer as bases sólidas do sistema.
* **08/09:** Definição da Arquitetura de Pastas (MVVM simplificado com `Provider`) para garantir escalabilidade.
* **11/09:** Estabelecimento da **"Regra de Ouro"**: Códigos completos, sem fragmentos, com foco na solução prática.
* **15/09:** Implementação da lógica **Multi-tenant** (Auth), garantindo que dados de diferentes restaurantes nunca se misturem.
* **20/09:** Mapeamento Objeto-Relacional (ORM Manual), transformando tabelas SQL em Classes Dart (`Order`, `Product`).

### **Outubro 2025: Identidade e Expansão**
*Foco: UX/UI, Correções Críticas e Novas Integrações.*

Nesta fase, o foco mudou para a experiência do usuário e funcionalidades complexas.
* **05/10:** Definição do **Design System** (Verde Deep, Creme e Dourado), abandonando o padrão Material Blue.
* **13/10:** Reforço das diretrizes de qualidade de código para evitar explicações teóricas desnecessárias.
* **23/10:** Inovação com a arquitetura do **Bot de WhatsApp**, integrando Flutter com Supabase Edge Functions.
* **28/10:** Resolução de lógica complexa de negócios (Cálculo de adicionais no carrinho e fechamento de conta).

---

## 💡 A "Assinatura" do Prompt VillaBistrô

Para obter os melhores resultados neste projeto, identificamos que os prompts devem seguir este padrão estrutural:

1.  **Contexto Imediato:** "Estou no arquivo `table_provider.dart`..."
2.  **Objetivo Claro:** "Preciso que a mesa mude de cor quando o pagamento for parcial."
3.  **Restrição Técnica:** "Use Supabase Realtime, não use setState local."
4.  **Formato de Saída:** "Me mande o código inteiro corrigido, sem explicações teóricas."

### Exemplo de Prompt Ideal:
> "Crie a função `closeAccount` no `TableProvider`. Ela deve somar o total da `transaction`, atualizar o status da mesa no Supabase para 'livre' e limpar a lista local. O banco de dados já tem RLS ativo. Me mande o arquivo `table_provider.dart` atualizado."

---

## 🚀 Como usar esta documentação?

1.  **Para novos desenvolvedores:** Leiam os prompts de **Setembro** para entender a arquitetura.
2.  **Para novas funcionalidades:** Consultem os prompts de **Outubro** para ver como integramos serviços externos (Bots/Impressoras).
3.  **Para a IA:** Ao iniciar uma nova sessão, você pode "alimentar" a IA com o arquivo `11-09-2025.md` para que ela entenda imediatamente o estilo de código esperado.