# 🚀 Guia de Integração Supabase - VillaBistrô

Este documento define o roteiro para conectar o aplicativo VillaBistrô ao backend Supabase, garantindo sincronia em tempo real, segurança e integridade dos dados.

## ✅ Pré-requisitos
- [x] Projeto Supabase criado
- [x] URL e ANON_KEY obtidas
- [x] Arquivo `.env` criado na raiz com as credenciais
- [x] Dependências `supabase_flutter` e `flutter_dotenv` adicionadas ao `pubspec.yaml`

---

## 📋 Roteiro de Execução

### **ETAPA 1: SQL - Estrutura do Banco de Dados**

Acesse o **Supabase SQL Editor** e execute os scripts documentados na pasta `docs/database/` na seguinte ordem:

#### 1.1 - Estrutura Base (Schema)
Criação das tabelas essenciais (`mesas`, `pedidos`, `produtos`, etc).
```bash
Consulte: docs/database/01_schema_dump.sql