# 📋 REORGANIZAÇÃO - Models, Screens e Providers

Seu projeto tem uma estrutura legada. Vamos reorganizar para Clean Architecture mantendo compatibilidade.

---

## 📊 SITUAÇÃO ATUAL

### Models Existentes (12 arquivos)
```
lib/models/
├── adicionais_models.dart
├── app_data.dart
├── cart_models.dart
├── category_models.dart
├── company_models.dart
├── delivery_order_models.dart
├── print_style_settings.dart
├── product_models.dart
├── report_models.dart
├── spreadsheet_models.dart
├── table_models.dart
└── transaction_models.dart
```

### Screens Existentes (23 arquivos em múltiplas pastas)
```
lib/screens/
├── bot_management_screen.dart
├── cart_screen.dart
├── category_screen.dart
├── configuracao/
├── desktop_shell.dart
├── edit_profile_screen.dart
├── google_sheets_screen.dart
├── kds_screen.dart
├── login/
├── management/
├── mobile_shell.dart
├── onboarding_screen.dart
├── order_list_screen.dart
├── payment_screen.dart
├── print/
├── product_selection_screen.dart
├── receipt_layout_editor_screen.dart
├── responsive_layout.dart
├── splash_screen.dart
├── table_selection_screen.dart
├── transactions_report_screen.dart
├── view_order_screen.dart
└── whatsapp_screen.dart
```

### Providers Existentes (13 arquivos)
```
lib/providers/
├── auth_provider.dart
├── bot_provider.dart
├── cart_provider.dart
├── company_provider.dart
├── kds_provider.dart
├── navigation_provider.dart
├── printer_provider.dart
├── product_provider.dart
├── report_provider.dart
├── sound_provider.dart
├── table_provider.dart
├── theme_provider.dart
└── transaction_provider.dart
```

---

## 🎯 ESTRUTURA NOVA (Clean Architecture)

### Onde Ir Cada Coisa

```
MODELS
├─ Entidades de Domínio                → lib/domain/entities/
│  ├─ category_models.dart          → category_entity.dart
│  ├─ product_models.dart           → product_entity.dart
│  ├─ company_models.dart           → company_entity.dart
│  ├─ table_models.dart             → table_entity.dart
│  ├─ cart_models.dart              → cart_entity.dart
│  ├─ delivery_order_models.dart    → delivery_order_entity.dart
│  ├─ transaction_models.dart       → transaction_entity.dart
│  ├─ report_models.dart            → report_entity.dart
│  └─ adicionais_models.dart        → adicionais_entity.dart
│
├─ DTOs (Data Transfer Objects)      → lib/data/models/
│  ├─ category_model.dart           (com fromJson/toJson)
│  ├─ product_model.dart
│  ├─ company_model.dart
│  ├─ table_model.dart
│  ├─ cart_model.dart
│  ├─ delivery_order_model.dart
│  ├─ transaction_model.dart
│  ├─ report_model.dart
│  └─ adicionais_model.dart
│
└─ Configuração                       → lib/core/utils/
   ├─ print_style_settings.dart
   ├─ app_data.dart
   └─ spreadsheet_models.dart

SCREENS (Manter estrutura + referenciar providers corretos)
├─ lib/presentation/pages/
│  ├─ auth/
│  │  └─ login/ (de lib/screens/login/)
│  ├─ products/
│  │  └─ category_screen.dart
│  │  └─ product_selection_screen.dart
│  ├─ orders/
│  │  ├─ order_list_screen.dart
│  │  └─ view_order_screen.dart
│  ├─ tables/
│  │  └─ table_selection_screen.dart
│  ├─ transactions/
│  │  └─ transactions_report_screen.dart
│  ├─ cart/
│  │  ├─ cart_screen.dart
│  │  └─ payment_screen.dart
│  ├─ management/
│  │  ├─ desktop_shell.dart
│  │  ├─ mobile_shell.dart
│  │  ├─ bot_management_screen.dart
│  │  ├─ kds_screen.dart
│  │  └─ google_sheets_screen.dart
│  ├─ common/
│  │  ├─ responsive_layout.dart
│  │  ├─ splash_screen.dart
│  │  ├─ onboarding_screen.dart
│  │  ├─ edit_profile_screen.dart
│  │  ├─ receipt_layout_editor_screen.dart
│  │  └─ whatsapp_screen.dart
│  └─ configuracao/
│     └─ (arquivos de configuração)
│
└─ Manter pasta lib/screens/ para backward compatibility
   (gradualmente migrar para lib/presentation/pages/)

PROVIDERS
├─ Permanecer em                      → lib/presentation/providers/
│  ├─ auth_provider.dart
│  ├─ cart_provider.dart
│  ├─ category_provider.dart
│  ├─ company_provider.dart
│  ├─ product_provider.dart
│  ├─ table_provider.dart
│  ├─ order_provider.dart             (novo, baseado em delivery_order)
│  ├─ transaction_provider.dart
│  ├─ report_provider.dart
│  ├─ kds_provider.dart
│  ├─ printer_provider.dart
│  ├─ theme_provider.dart
│  ├─ sound_provider.dart
│  ├─ navigation_provider.dart
│  ├─ bot_provider.dart
│  └─ utils_provider.dart             (para configurações diversas)
│
└─ Manter pasta lib/providers/ para backward compatibility
   (gradualmente migrar para lib/presentation/providers/)
```

---

## 🚀 PLANO DE IMPLEMENTAÇÃO (Gradual)

### FASE 1: Backward Compatibility (HOJE - 30 min)
✅ Manter tudo onde está
✅ Só documentar o novo local ideal
✅ Sem quebrar código existente

### FASE 2: Criar Estrutura Nova (Próximos dias)
- [ ] Criar entities em `lib/domain/entities/`
- [ ] Criar models em `lib/data/models/`
- [ ] Criar pages em `lib/presentation/pages/`

### FASE 3: Migração Gradual (Próximas semanas)
- [ ] Refatorar providers um por um
- [ ] Mover imports gradualmente
- [ ] Testar cada mudança

### FASE 4: Limpeza (Futuro)
- [ ] Remover duplicatas
- [ ] Deletar pastas antigas (se necessário)
- [ ] Documentar finalmente

---

## 📝 RECOMENDAÇÃO IMEDIATA

### Você PODE fazer agora (SEM quebrar nada):

**1. Criar Entities em Domain Layer**

Para cada model existente, criar uma entity:

```dart
// Exemplo: lib/domain/entities/product_entity.dart
import 'package:villabistromobile/domain/entities/base_entity.dart';

class ProductEntity extends BaseEntity {
  final String id;
  final String name;
  final double price;
  final String? image;
  
  const ProductEntity({
    required this.id,
    required this.name,
    required this.price,
    this.image,
  });

  @override
  List<Object?> get props => [id, name, price, image];
}
```

**2. Criar Models em Data Layer (com serialização)**

```dart
// Exemplo: lib/data/models/product_model.dart
import 'package:equatable/equatable.dart';

class ProductModel extends Equatable {
  final String id;
  final String name;
  final double price;
  final String? image;
  
  const ProductModel({
    required this.id,
    required this.name,
    required this.price,
    this.image,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      image: json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'image': image,
  };

  @override
  List<Object?> get props => [id, name, price, image];
}
```

**3. Criar Providers em Presentation Layer**

Seu `product_provider.dart` pode:
- Continuar onde está (`lib/providers/`)
- OU ser copiado para `lib/presentation/providers/`
- Ambos funcionam no começo

---

## 📊 MAPEAMENTO DE CONVERSÃO

### Models → Entities + DTOs

| Arquivo Atual | Entity Para Criar | Model Para Criar |
|---------------|-------------------|------------------|
| `category_models.dart` | `category_entity.dart` | `category_model.dart` |
| `product_models.dart` | `product_entity.dart` | `product_model.dart` |
| `company_models.dart` | `company_entity.dart` | `company_model.dart` |
| `table_models.dart` | `table_entity.dart` | `table_model.dart` |
| `cart_models.dart` | `cart_entity.dart` | `cart_model.dart` |
| `delivery_order_models.dart` | `delivery_order_entity.dart` | `delivery_order_model.dart` |
| `transaction_models.dart` | `transaction_entity.dart` | `transaction_model.dart` |
| `report_models.dart` | `report_entity.dart` | `report_model.dart` |
| `adicionais_models.dart` | `adicionais_entity.dart` | `adicionais_model.dart` |
| `print_style_settings.dart` | - | Mover para `core/utils/` |
| `app_data.dart` | - | Mover para `core/utils/` |
| `spreadsheet_models.dart` | - | Mover para `core/utils/` |

### Screens → Presentation Pages

| Pasta Atual | Novo Local |
|-------------|-----------|
| `lib/screens/login/` | `lib/presentation/pages/auth/` |
| `lib/screens/product_selection_screen.dart` | `lib/presentation/pages/products/` |
| `lib/screens/category_screen.dart` | `lib/presentation/pages/products/` |
| `lib/screens/cart_screen.dart` | `lib/presentation/pages/cart/` |
| `lib/screens/payment_screen.dart` | `lib/presentation/pages/cart/` |
| `lib/screens/order_list_screen.dart` | `lib/presentation/pages/orders/` |
| `lib/screens/view_order_screen.dart` | `lib/presentation/pages/orders/` |
| `lib/screens/table_selection_screen.dart` | `lib/presentation/pages/tables/` |
| `lib/screens/transactions_report_screen.dart` | `lib/presentation/pages/reports/` |
| `lib/screens/kds_screen.dart` | `lib/presentation/pages/management/` |
| `lib/screens/bot_management_screen.dart` | `lib/presentation/pages/management/` |
| `lib/screens/responsive_layout.dart` | `lib/presentation/pages/common/` |
| etc. | etc. |

### Providers → Presentation Providers

| Arquivo Atual | Novo Local |
|---------------|-----------|
| `lib/providers/*.dart` | `lib/presentation/providers/*.dart` |

**Nota:** Manter `lib/providers/` para backward compatibility

---

## ✅ AÇÃO RECOMENDADA AGORA

### Opção A: Gradual e Segura (Recomendado)
1. ✅ Manter tudo onde está por enquanto
2. ✅ Documentar o novo local ideal (feito!)
3. ✅ Começar com Nova Feature (Auth) seguindo Clean Architecture
4. ⏳ Depois, migrar features antigas uma por uma

### Opção B: Agressiva (Risco alto)
1. ❌ Mover tudo de uma vez
2. ❌ Muito risco de quebrar código
3. ❌ Não recomendado

### Opção C: Híbrida (Recomendado para Você)
1. ✅ Copiar models como Entities em `domain/entities/`
2. ✅ Criar DTOs em `data/models/` (sem serialização complexa)
3. ✅ Deixar screens e providers onde estão
4. ⏳ Migrar gradualmente conforme refatora cada feature

---

## 📌 PRÓXIMOS PASSOS

### 1. Você CONTINUA Usando Tudo Como Está ✅
- Screens em `lib/screens/` → Funciona
- Models em `lib/models/` → Funciona
- Providers em `lib/providers/` → Funciona

### 2. Você CRIA Novos em Clean Architecture
- Entities em `lib/domain/entities/`
- Models em `lib/data/models/`
- Pages em `lib/presentation/pages/`
- Providers em `lib/presentation/providers/`

### 3. Você MIGRA Gradualmente
- Uma feature por vez
- Sem pressa
- Testando sempre

### 4. No Futuro (Meses)
- Tudo estará em Clean Architecture
- Pastas antigas serão deletadas
- Código muito mais organizado

---

## 🎯 CONCLUSÃO

**Seus screens, models e providers ESTÃO NO LUGAR CERTO:**
- ✅ Eles funcionam perfeitamente onde estão
- ✅ Não precisa mover nada agora
- ✅ Pode deixar como está indefinidamente

**O novo local é apenas ideal para:**
- 🎯 Novas features
- 🎯 Código futuro
- 🎯 Melhor organização de longo prazo

**Estratégia recomendada:**
1. ✅ Deixa tudo como está (funciona!)
2. 🎯 Comece com features novas em Clean Architecture
3. ⏳ Migre features antigas conforme refatora
4. 📊 No fim, tudo estará bem organizado

---

**Status:** ✅ **TUDO FUNCIONANDO**  
**Próximo Passo:** Começar a refatorar primeiro Feature (Auth)  
**Cronograma:** Sem pressa - migração gradual

Tudo certo! 🚀
