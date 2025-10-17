import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
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

  Map<String, dynamic> _printerSettings = {};
  Map<String, dynamic> get printerSettings => _printerSettings;

  KitchenTemplateSettings _templateSettings = KitchenTemplateSettings.defaults();
  KitchenTemplateSettings get templateSettings => _templateSettings;

  ReceiptTemplateSettings _receiptTemplateSettings =
      ReceiptTemplateSettings.defaults();
  ReceiptTemplateSettings get receiptTemplateSettings => _receiptTemplateSettings;

  Printer? _conferencePrinter;
  Printer? get conferencePrinter => _conferencePrinter;

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
    final settingsString = prefs.getString('printerToCategorySettings');
    if (settingsString != null) {
      _printerSettings = Map<String, dynamic>.from(json.decode(settingsString));
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
    final conferencePrinterString = prefs.getString('conferencePrinter');
    if (conferencePrinterString != null) {
      final printerMap = json.decode(conferencePrinterString);
      _conferencePrinter = Printer(
        url: printerMap['url'],
        name: printerMap['name'],
        model: printerMap['model'],
        location: printerMap['location'],
        isDefault: printerMap['isDefault'] ?? false,
        isAvailable: printerMap['isAvailable'] ?? true,
      );
    }
    notifyListeners();
  }

  Future<void> savePrinterSettings(Map<String, dynamic> newSettings) async {
    _printerSettings = newSettings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('printerToCategorySettings', json.encode(newSettings));
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

  Future<void> saveConferencePrinter(Printer? printer) async {
    _conferencePrinter = printer;
    final prefs = await SharedPreferences.getInstance();
    if (printer == null) {
      await prefs.remove('conferencePrinter');
    } else {
      final printerMap = {
        'url': printer.url,
        'name': printer.name,
        'model': printer.model,
        'location': printer.location,
        'isDefault': printer.isDefault,
        'isAvailable': printer.isAvailable,
      };
      await prefs.setString('conferencePrinter', json.encode(printerMap));
    }
    notifyListeners();
    _addLog('Impressora de conferência salva: ${printer?.name ?? 'Nenhuma'}.');
  }

  Future<void> pickAndSaveLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final String fileName = path.basename(pickedFile.path);
        final String imagePath = path.join(directory.path, fileName);
        final newImageFile = await File(pickedFile.path).copy(imagePath);
        _templateSettings =
            _templateSettings.copyWith(logoPath: newImageFile.path);
        _receiptTemplateSettings =
            _receiptTemplateSettings.copyWith(logoPath: newImageFile.path);
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
    if (_isListening || companyId == null) return;
    _addLog('Iniciando monitoramento de impressão...');
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
      if (error != null) _addLog('ERRO DE IMPRESSÃO: ${error.toString()}');
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
    try {
      final order = await _fetchFullOrderDetails(orderId);
      _addLog('Novo pedido #${order.numeroPedido} para impressão.');
      await _routeAndPrintOrder(order, isNewOrder: true);
    } catch (e) {
      _addLog('ERRO ao buscar detalhes do pedido #$orderId: $e');
    }
  }

  Future<void> reprintOrder(app_data.Order orderToReprint) async {
    final orderId = orderToReprint.id;
    _addLog('REIMPRIMINDO pedido: #${orderToReprint.numeroPedido}');
    try {
      final order = await _fetchFullOrderDetails(orderId);
      await _routeAndPrintOrder(order);
    } catch (e) {
      _addLog('ERRO ao reimprimir pedido #${orderToReprint.numeroPedido}: $e');
    }
  }

  Future<app_data.Order> _fetchFullOrderDetails(String orderId) async {
    final orderDetails = await _supabase
        .from('pedidos')
        .select(
            '*, delivery(*), mesas(numero), itens_pedido(*, produtos(*, categorias(id, name)))')
        .eq('id', orderId)
        .single();
    return app_data.Order.fromJson(orderDetails);
  }

  Future<void> _routeAndPrintOrder(app_data.Order order,
      {bool isNewOrder = false}) async {
    String? findPrinterKeyForItem(app_data.CartItem item) {
      for (final printerName in _printerSettings.keys) {
        final settings = _printerSettings[printerName];
        final categoryIds = List<String>.from(settings['categories'] ?? []);
        if (categoryIds.contains(item.product.categoryId)) {
          final paperSize = settings['size'] ?? '58';
          return '$printerName|$paperSize';
        }
      }
      return null;
    }

    try {
      final groupedByPrinterKey =
          groupBy(order.items, findPrinterKeyForItem);

      if (groupedByPrinterKey.isEmpty) {
        _addLog(
            'Pedido #${order.numeroPedido}: Nenhum item corresponde a uma impressora configurada.');
      }

      for (final key in groupedByPrinterKey.keys) {
        if (key == null) {
          final unassignedItems = groupedByPrinterKey[key]!
              .map((e) => e.product.name)
              .join(', ');
          _addLog(
              'Pedido #${order.numeroPedido}: Itens sem impressora: $unassignedItems');
          continue;
        }

        final parts = key.split('|');
        final printerName = parts[0];
        final paperSize = parts[1];

        final itemsForPrinter = groupedByPrinterKey[key]!;
        final orderForPrinter = order.copyWith(items: itemsForPrinter);

        final printers = await Printing.listPrinters();
        final selectedPrinter =
            printers.firstWhereOrNull((p) => p.name == printerName);

        if (selectedPrinter != null) {
          await _printingService.printKitchenOrder(
            order: orderForPrinter,
            printer: selectedPrinter,
            paperSize: paperSize,
            templateSettings: _templateSettings,
          );
          _addLog('Pedido #${order.numeroPedido} enviado para: $printerName.');
        } else {
          _addLog(
              'Impressora "$printerName" não encontrada. Pedido #${order.numeroPedido} não impresso.');
        }
      }
    } catch (e) {
      _addLog('ERRO CRÍTICO no processo de impressão: $e');
    }

    if (isNewOrder) {
      try {
        await _supabase
            .from('pedidos')
            .update({'status': 'production'})
            .eq('id', order.id);
        _addLog('Pedido #${order.numeroPedido} atualizado para "Em Produção".');
      } catch (e) {
        _addLog(
            'ERRO ao atualizar o status do pedido #${order.numeroPedido}: $e');
      }
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