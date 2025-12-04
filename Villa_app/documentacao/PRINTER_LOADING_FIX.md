# Fix: Impressora de Conferência Null no Delivery

## Problema Identificado

Quando um pedido **DELIVERY** chegava via Supabase Realtime, o sistema tentava usar `_conferencePrinter` mas encontrava **null**, mesmo que a impressora tivesse sido salva nas configurações.

### Root Cause

1. **Timing Issue**: O `PrinterProvider` era inicializado no construtor com `_loadSettings()` sendo chamado de forma **assíncrona sem await**.
2. **Realtime Channel**: O `startListening()` começava a ouvir pedidos **antes** que `_loadSettings()` terminasse de carregar as configurações do SharedPreferences.
3. **Race Condition**: Se um pedido DELIVERY chegasse antes do carregamento, `_conferencePrinter` estaria null.

## Solução Implementada

### 1. Rastreamento de Carregamento (`_settingsLoaded`)

Adicionado flag para rastrear se as configurações foram completamente carregadas:

```dart
bool _settingsLoaded = false;
bool get settingsLoaded => _settingsLoaded;
```

### 2. Método de Inicialização Separado

Criado `_initializeSettings()` para garantir ordem correta:

```dart
PrinterProvider(this._authProvider) {
  _initializeSettings();
}

Future<void> _initializeSettings() async {
  await _loadSettings();
  _settingsLoaded = true;
  _addLog('✅ Configurações de impressora carregadas e prontas para uso.');
}
```

### 3. Verificação em `startListening()`

Adicionada verificação para não iniciar monitoramento se configurações não carregaram:

```dart
void startListening() {
  final companyId = _getCompanyId();
  if (_isListening || companyId == null) return;
  
  if (!_settingsLoaded) {
    _addLog('⚠️ Aguardando carregamento das configurações...');
    return;
  }
  
  // ... continua normalmente
}
```

### 4. Verificação em `_routeAndPrintOrder()` (Delivery)

Adicionado fallback para aguardar configurações se necessário:

```dart
if (order.type == 'delivery') {
  _addLog('Pedido DELIVERY #${order.numeroPedido}: Buscando impressora de conferência...');
  _addLog('DEBUG: _settingsLoaded = $_settingsLoaded, _conferencePrinter = ${_conferencePrinter?.name ?? 'NULL'}');
  
  if (!_settingsLoaded) {
    _addLog('⚠️ DELIVERY #${order.numeroPedido}: Aguardando carregamento...');
    await Future.delayed(Duration(milliseconds: 500));
  }
  
  if (_conferencePrinter != null) {
    // ... imprime normalmente
  }
}
```

### 5. Logging Melhorado

Adicionados logs detalhados para debug:
- ✅ Quando impressora de conferência é carregada com sucesso
- ⚠️ Quando nenhuma impressora foi configurada
- 🔴 Quando delivery falha por impressora null
- 📝 DEBUG flags para rastrear estado das configurações

## Arquivo Modificado

- `lib/presentation/providers/printer_provider.dart`
  - Adicionado `bool _settingsLoaded`
  - Modificado construtor para chamar `_initializeSettings()`
  - Criado método `_initializeSettings()`
  - Adicionadas verificações em `startListening()`
  - Adicionados logs em `_routeAndPrintOrder()` para delivery

## Testes Recomendados

1. ✅ App inicia e carrega configurações de impressora
2. ✅ Mesa pedido roteia para impressora correta por categoria
3. ✅ Delivery pedido usa impressora de conferência
4. ✅ Ambos imprimem em papel 58mm (após fix anterior)
5. ✅ Logs mostram ordem correta: "Configurações carregadas" → "Iniciando monitoramento"

## Notas

- O carregamento assíncrono de SharedPreferences é normal no Flutter
- A solução aguarda 500ms como fallback se pedido chegar muito rápido
- Logs agora mostram exatamente quando cada etapa ocorre
- `_settingsLoaded` garante que não iniciamos listening antes de estar pronto
