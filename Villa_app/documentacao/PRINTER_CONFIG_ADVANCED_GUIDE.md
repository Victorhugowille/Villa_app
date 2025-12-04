# 🖨️ Guia de Configuração Avançada de Impressora

## Visão Geral

A nova **Tela de Configuração Avançada de Impressora** (`PrinterConfigAdvancedScreen`) permite controlar completamente o estilo e layout da impressão de pedidos em seu estabelecimento.

## 📍 Como Acessar

1. **Via Menu Lateral**: Menu → "Config. Impressora" 
2. **Rota**: A tela aparece junto com o menu de navegação do app

## 🎯 Funcionalidades Principais

### 1. **Dados da Empresa** (Auto-população)

A tela carrega automaticamente os dados da sua empresa do banco de dados:

- **CNPJ/Documento**: Puxado direto da tabela `companies`
- **Endereço**: Montado a partir de (Rua, Número, Bairro, Cidade, Estado)
- **Telefone**: Obtido da coluna `telefone`

**Como usar**:
- Clique no botão **"Carregar"** para importar dados da empresa
- Os campos serão preenchidos automaticamente
- Você pode editar manualmente se necessário

```
┌─────────────────────────────────────┐
│     Dados da Empresa                │
│  ┌──────────────────────────────┐  │
│  │ [Carregar]                   │  │
│  │ CNPJ: 12.345.678/0001-99     │  │
│  │ End.: Rua, 123 - Bairro...   │  │
│  │ Tel.: (11) 9999-9999         │  │
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
```

### 2. **Estilos de Impressão** (Ajuste Completo)

Cada seção da impressão pode ser customizada:

#### **Cabeçalho (Nome da Empresa)**
- Tamanho da fonte: 6pt - 32pt
- Negrito: Sim/Não
- Alinhamento: Esquerda | Centro | Direita

#### **Informações do Pedido**
- Número, data, hora
- Mesmos controles de estilo

#### **Items do Pedido**
- Produtos, quantidades, preços
- Personalize o tamanho e negrito

#### **Observações**
- Notas dos clientes
- Formatação dedicada

#### **Informações de Entrega**
- Endereço, cliente
- Estilo específico para delivery

#### **Rodapé**
- Mensagem final customizável
- Espaçamento e formatação

---

## 🎨 Como Customizar um Estilo

### Exemplo: Deixar o Cabeçalho Maior

1. **Clique** na seção "Cabeçalho (Nome da Empresa)"
2. Você verá os controles:
   ```
   Tamanho da Fonte: [======●======] (16)
                        ou Digite: [16]
   
   ☑ Negrito
   
   Alinhamento: ◎ Esquerda ◎ Centro ● Direita
   
   Preview: Preview: Cabeçalho (Nome da Empresa)
   ```

3. **Ajuste o tamanho**: Arraste o slider ou digite um valor
4. **Ative negrito**: Marque a checkbox
5. **Escolha alinhamento**: Clique em um dos botões

### Valores Recomendados

| Seção | Tamanho | Negrito | Alinhamento |
|-------|---------|---------|-------------|
| **Cabeçalho** | 16-18 | Sim | Centro |
| **Pedido** | 10-11 | Não | Centro |
| **Items** | 10-11 | Não | Esquerda |
| **Observações** | 9-10 | Não | Esquerda |
| **Entrega** | 10-11 | Não | Esquerda |
| **Rodapé** | 10-11 | Não | Centro |

---

## 💾 Salvando suas Configurações

### Fluxo Completo

```
1. Carregue dados da empresa (ou edite manualmente)
   ↓
2. Customize cada seção de estilo
   ↓
3. Veja o preview em tempo real
   ↓
4. Clique "Salvar Configurações"
   ↓
5. Confirmação: "✅ Configurações salvas com sucesso!"
```

### O que é Salvo

- ✅ Dados de empresa (CNPJ, endereço, telefone)
- ✅ Tamanhos de fonte de cada seção
- ✅ Estados de negrito
- ✅ Alinhamentos de texto
- ✅ Texto do rodapé customizado

### Onde é Salvo

Os dados são persistidos em:
- **Local Storage** (arquivo JSON no dispositivo)
- **SharedPreferences** (para acesso rápido)

---

## 🔄 Fluxo de Dados

```
┌──────────────────────────────────────────────┐
│        Supabase (companies table)            │
│  - CNPJ, telefone, endereço, estado, etc.   │
└────────────────┬─────────────────────────────┘
                 │
                 │ CompanyProvider.currentCompany
                 ▼
┌──────────────────────────────────────────────┐
│   PrinterConfigAdvancedScreen (UI)           │
│   - Campo "Carregar" → Preenche formulário   │
│   - Usuario edita valores                    │
└────────────────┬─────────────────────────────┘
                 │
                 │ printerProvider.saveTemplateSettings()
                 │ printerProvider.saveReceiptTemplateSettings()
                 ▼
┌──────────────────────────────────────────────┐
│        SharedPreferences + JSON              │
│  - KitchenTemplateSettings (estilo cozinha)  │
│  - ReceiptTemplateSettings (estilo recibo)   │
└────────────────┬─────────────────────────────┘
                 │
                 │ PrinterProvider._templateSettings
                 │ PrinterProvider._receiptTemplateSettings
                 ▼
┌──────────────────────────────────────────────┐
│     PrintingService (ao imprimir)            │
│  - Lê configurações salvas                   │
│  - Aplica estilos ao PDF                     │
│  - Envia para impressora                     │
└──────────────────────────────────────────────┘
```

---

## 🛠️ Arquivos Modificados

### Nova Tela
- `lib/presentation/screens/print/printer_config_advanced_screen.dart`

### Atualizações
- `lib/presentation/widgets/side_menu.dart` (adicionado menu item)
- `lib/data/models/print_style_settings.dart` (métodos `copyWith` já existem)

### Estrutura da Tela

```dart
PrinterConfigAdvancedScreen
├── Seção: Dados da Empresa
│   ├── Campo CNPJ
│   ├── Campo Endereço
│   ├── Campo Telefone
│   └── Botão "Carregar"
│
├── Seção: Estilos de Impressão
│   ├── Cabeçalho
│   │   ├── Slider Tamanho (6-32pt)
│   │   ├── Checkbox Negrito
│   │   ├── Botões Alinhamento
│   │   └── Preview
│   │
│   ├── Informações do Pedido
│   │   ├── Slider Tamanho
│   │   ├── Checkbox Negrito
│   │   ├── Botões Alinhamento
│   │   └── Preview
│   │
│   ├── Items do Pedido
│   │   └── [Mesmos controles]
│   │
│   ├── Observações
│   │   └── [Mesmos controles]
│   │
│   ├── Entrega
│   │   └── [Mesmos controles]
│   │
│   └── Rodapé
│       └── [Mesmos controles]
│
├── Seção: Texto do Rodapé
│   └── Campo customizável (mensagem final)
│
└── Botão "Salvar Configurações"
```

---

## 📊 Exemplo: Personalizando Completamente

### Cenário: Impressora de Cozinha Profissional

**Objetivo**: Maximizar legibilidade para cozinha ruidosa

**Configuração**:

| Seção | Tamanho | Negrito | Alinhamento |
|-------|---------|---------|-------------|
| Cabeçalho | **20** | ✅ | Centro |
| Pedido | **12** | ❌ | Centro |
| Items | **14** | ✅ | Esquerda |
| Observações | **11** | ✅ | Esquerda |
| Entrega | **12** | ❌ | Esquerda |
| Rodapé | **11** | ❌ | Centro |

**Passos**:

1. Abra a tela "Config. Impressora"
2. Clique em "Cabeçalho" → Ajuste para 20pt, ative negrito, centro
3. Clique em "Informações do Pedido" → 12pt, desative negrito, centro
4. Clique em "Items do Pedido" → 14pt, ative negrito, esquerda
5. Continue com as demais seções
6. Clique "Salvar Configurações"
7. Teste uma impressão para validar

---

## ⚙️ Detalhes Técnicos

### Modelos de Dados

#### `PrintStyle`
```dart
class PrintStyle {
  final double fontSize;        // 6.0 - 32.0
  final bool isBold;            // true | false
  final CrossAxisAlignment alignment;  // start | center | end
  
  PrintStyle copyWith({...}) // Permite atualizações imutáveis
}
```

#### `KitchenTemplateSettings`
```dart
class KitchenTemplateSettings {
  final PrintStyle headerStyle;
  final PrintStyle orderInfoStyle;
  final PrintStyle itemStyle;
  final PrintStyle observationStyle;
  final PrintStyle deliveryInfoStyle;
  final String footerText;
  final PrintStyle footerStyle;
  // ... mais campos
}
```

#### `ReceiptTemplateSettings`
```dart
class ReceiptTemplateSettings {
  final PrintStyle headerStyle;
  final String subtitleText;      // CNPJ (carregado)
  final String addressText;        // Endereço (carregado)
  final String phoneText;          // Telefone (carregado)
  // ... mais campos
}
```

### Providers Envolvidos

```dart
// 1. CompanyProvider
final company = Provider.of<CompanyProvider>(context).currentCompany;
// Acesso: company.cnpj, company.telefone, company.rua, etc.

// 2. PrinterProvider
printerProvider.saveTemplateSettings(newSettings);
printerProvider.saveReceiptTemplateSettings(newSettings);
```

---

## 🐛 Troubleshooting

### "Nenhuma empresa carregada!" (ao clicar Carregar)
- **Causa**: `CompanyProvider.currentCompany` é null
- **Solução**: Certifique-se que fez login e que a empresa está associada à sua conta

### Estilos não aparecem na impressão
- **Causa**: Configurações não foram salvas
- **Solução**: Clique o botão "Salvar Configurações" após ajustar

### Preview não atualiza em tempo real
- **Causa**: Bug de UI (raro)
- **Solução**: Feche e reabra a seção do estilo

### Valores muito altos causam erro
- **Causa**: Fonte > 32pt causa problemas de renderização
- **Limite**: Máximo de 32pt para segurança

---

## 📱 Responsividade

A tela é **fully responsive**:

- **Mobile**: SingleChildScrollView com cards empilhados
- **Tablet**: Mesmo layout (otimizado para touch)
- **Desktop**: Cards em coluna com scroll

---

## ✨ Próximas Melhorias (Sugestões)

1. **Preview em PDF**: Mostra exatamente como ficará impresso
2. **Presets**: Salvar múltiplas configurações nomeadas (Cozinha, Recepção, etc.)
3. **Importar/Exportar**: Compartilhar configurações entre dispositivos
4. **Template Builder**: Editor visual drag-and-drop
5. **Print Test**: Botão para imprimir teste antes de salvar

---

## 📞 Contato / Dúvidas

Para dúvidas sobre a implementação, consulte:
- `PrinterProvider` (lógica de impressão)
- `PrintingService` (geração de PDF)
- `CompanyProvider` (dados da empresa)

---

**Última Atualização**: [Data]  
**Status**: ✅ Implementado e Testado
