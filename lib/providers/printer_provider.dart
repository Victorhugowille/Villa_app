import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;
import 'package:villabistromobile/models/print_style_settings.dart';
import 'package:villabistromobile/providers/auth_provider.dart';
import 'package:villabistromobile/services/printing_service.dart';

class PrinterProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PrintingService _printingService = PrintingService();
  AuthProvider? _authProvider;
  RealtimeChannel? _orderChannel;

  bool _isListening = false;
  bool get isListening => _isListening;

  Map<String, Map<String, String>> _categoryPrinterSettings = {};
  Map<String, Map<String, String>> get categoryPrinterSettings =>
      _categoryPrinterSettings;

  KitchenTemplateSettings _templateSettings = KitchenTemplateSettings.defaults();
  KitchenTemplateSettings get templateSettings => _templateSettings;

  ReceiptTemplateSettings _receiptTemplateSettings =
      ReceiptTemplateSettings.defaults();
  ReceiptTemplateSettings get receiptTemplateSettings => _receiptTemplateSettings;

  List<String> _logMessages = [];
  List<String> get logMessages => _logMessages;

  PrinterProvider(this._authProvider) {
    _loadSettings();
  }

  void updateAuthProvider(AuthProvider newAuthProvider) {
    final oldCompanyId = _authProvider?.companyId;
    _authProvider = newAuthProvider;
    final newCompanyId = newAuthProvider.companyId;

    if (newCompanyId != null && oldCompanyId == null) {
      startListening();
    } else if (newCompanyId != null && newCompanyId != oldCompanyId) {
      stopListening();
      startListening();
    }
  }

  String? _getCompanyId() {
    return _authProvider?.companyId;
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final settingsString = prefs.getString('categoryPrinterSettings');
    if (settingsString != null) {
      final decodedData = json.decode(settingsString) as Map<String, dynamic>;
      _categoryPrinterSettings = decodedData.map((key, value) {
        return MapEntry(key, Map<String, String>.from(value));
      });
    }

    final templateString = prefs.getString('kitchenTemplateSettings');
    if (templateString != null) {
      _templateSettings =
          KitchenTemplateSettings.fromJson(json.decode(templateString));
    }

    final receiptTemplateString = prefs.getString('receiptTemplateSettings');
    if (receiptTemplateString != null) {
      _receiptTemplateSettings =
          ReceiptTemplateSettings.fromJson(json.decode(receiptTemplateString));
    }

    notifyListeners();
  }

  Future<void> saveSettings(
      Map<String, Map<String, String>> newSettings) async {
    _categoryPrinterSettings = newSettings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('categoryPrinterSettings', json.encode(newSettings));
    notifyListeners();
    _addLog('Configurações de impressora salvas.');
  }

  Future<void> saveTemplateSettings(KitchenTemplateSettings newSettings) async {
    _templateSettings = newSettings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'kitchenTemplateSettings', json.encode(newSettings.toJson()));
    notifyListeners();
    _addLog('Layout de impressão da cozinha salvo.');
  }

  Future<void> saveReceiptTemplateSettings(
      ReceiptTemplateSettings newSettings) async {
    _receiptTemplateSettings = newSettings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'receiptTemplateSettings', json.encode(newSettings.toJson()));
    notifyListeners();
    _addLog('Layout de impressão de conferência salvo.');
  }

  Future<void> pickAndSaveLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final imagePath = '${directory.path}/custom_logo.png';

        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(await pickedFile.readAsBytes());

        _templateSettings = _templateSettings.copyWith(logoPath: imagePath);
        _receiptTemplateSettings =
            _receiptTemplateSettings.copyWith(logoPath: imagePath);

        await saveTemplateSettings(_templateSettings);
        await saveReceiptTemplateSettings(_receiptTemplateSettings);
        _addLog('Novo logo salvo com sucesso.');
      } catch (e) {
        _addLog('Erro ao salvar o logo: $e');
      }
    }
  }

  void updateLogoHeight(double newHeight) {
    _templateSettings = _templateSettings.copyWith(logoHeight: newHeight);
    _receiptTemplateSettings =
        _receiptTemplateSettings.copyWith(logoHeight: newHeight);
    notifyListeners();
  }

  void updateKitchenLogoAlignment(CrossAxisAlignment newAlignment) {
    _templateSettings = _templateSettings.copyWith(logoAlignment: newAlignment);
    saveTemplateSettings(_templateSettings);
  }

  void updateReceiptLogoAlignment(CrossAxisAlignment newAlignment) {
    _receiptTemplateSettings =
        _receiptTemplateSettings.copyWith(logoAlignment: newAlignment);
    saveReceiptTemplateSettings(_receiptTemplateSettings);
  }

  void startListening() {
    final companyId = _getCompanyId();
    if (_isListening || companyId == null) {
      _addLog('Não foi possível iniciar: Serviço já ativo ou sem ID de empresa.');
      return;
    }

    _addLog('Tentando iniciar monitoramento de impressão...');

    _orderChannel = _supabase.channel('public:pedidos:company_id=eq.$companyId');
    _orderChannel!
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'pedidos',
      callback: (payload) {
        if (payload.newRecord['status'] == 'awaiting_print') {
          _handleNewOrder(payload.newRecord);
        }
      },
    )
        .subscribe((status, [error]) {
      _addLog('Status da conexão de Impressão: $status');
      if (error != null) {
        _addLog('ERRO DE IMPRESSÃO: ${error.toString()}');
      }

      final newListeningStatus = (status == RealtimeSubscribeStatus.subscribed);
      if (_isListening != newListeningStatus) {
        _isListening = newListeningStatus;
        Future.microtask(notifyListeners);
      }
    });
  }

  void stopListening() {
    if (_orderChannel != null) {
      _supabase.removeChannel(_orderChannel!);
      _orderChannel = null;
    }
    _isListening = false;
    _addLog('Monitoramento de impressão parado.');
    notifyListeners();
  }

  Future<void> _handleNewOrder(Map<String, dynamic> newOrderData) async {
    if (newOrderData.isEmpty) return;

    final orderId = newOrderData['id'].toString();
    final orderIdDisplay =
        orderId.length > 8 ? orderId.substring(0, 8) : orderId;
    _addLog('Novo pedido para impressão: #$orderIdDisplay');

    try {
      final orderDetails = await _supabase
          .from('pedidos')
          .select(
              '*, mesa_id(numero), itens_pedido!inner(*, produtos!inner(*, categorias(id, name)))')
          .eq('id', orderId)
          .single();
      final tableNumber = orderDetails['mesa_id']['numero'].toString();
      final itemsData = orderDetails['itens_pedido'] as List;
      final orderItems =
          itemsData.map((item) => app_data.CartItem.fromJson(item)).toList();
      await _routeAndPrintOrder(orderItems, tableNumber, orderId);
    } catch (e) {
      _addLog('ERRO ao buscar detalhes do pedido #$orderIdDisplay: $e');
    }
  }

  Future<void> _routeAndPrintOrder(
      List<app_data.CartItem> items, String tableNumber, String orderId) async {
    final orderIdDisplay =
        orderId.length > 8 ? orderId.substring(0, 8) : orderId;
    try {
      final groupedBySettings = groupBy(items, (item) {
        return _categoryPrinterSettings[item.product.categoryId];
      });

      if (groupedBySettings.isEmpty) {
        _addLog('Pedido #$orderIdDisplay: Nenhum item para imprimir.');
      }

      for (final settings in groupedBySettings.keys) {
        if (settings == null || settings['name'] == null) {
          _addLog('Pedido #$orderIdDisplay: Itens sem impressora configurada.');
          continue;
        }

        final printerName = settings['name']!;
        final paperSize = settings['size'] ?? '58';
        final itemsForPrinter = groupedBySettings[settings]!;

        final printers = await Printing.listPrinters();
        final selectedPrinter =
            printers.firstWhereOrNull((p) => p.name == printerName);

        if (selectedPrinter != null) {
          await _printingService.printKitchenOrder(
            items: itemsForPrinter,
            tableNumber: tableNumber,
            orderId: orderId,
            printer: selectedPrinter,
            paperSize: paperSize,
            templateSettings: _templateSettings,
          );
          _addLog('Pedido #$orderIdDisplay enviado para: $printerName.');
        } else {
          _addLog(
              'Impressora "$printerName" não encontrada. Pedido #$orderIdDisplay não impresso.');
        }
      }
    } catch (e) {
      _addLog('ERRO CRÍTICO no processo de impressão: $e');
    }

    try {
      await _supabase
          .from('pedidos')
          .update({'status': 'production'}).eq('id', orderId);
      _addLog('Pedido #$orderIdDisplay atualizado para "Em Produção".');
    } catch (e) {
      _addLog('ERRO ao atualizar o status do pedido #$orderIdDisplay: $e');
    }
  }

  void _addLog(String message) {
    final timestamp = DateFormat('HH:mm:ss').format(DateTime.now());
    _logMessages.insert(0, '$timestamp - $message');
    if (_logMessages.length > 100) _logMessages.removeLast();
    Future.microtask(notifyListeners);
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}