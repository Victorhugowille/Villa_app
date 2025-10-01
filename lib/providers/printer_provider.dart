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
import 'package:villabistromobile/services/printing_service.dart';

class PrinterProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PrintingService _printingService = PrintingService();
  RealtimeChannel? _orderChannel;

  bool _isListening = false;
  bool get isListening => _isListening;

  Map<int, Map<String, String>> _categoryPrinterSettings = {};
  Map<int, Map<String, String>> get categoryPrinterSettings =>
      _categoryPrinterSettings;
      
  PrintTemplateSettings _templateSettings = PrintTemplateSettings.defaults();
  PrintTemplateSettings get templateSettings => _templateSettings;

  ReceiptTemplateSettings _receiptTemplateSettings = ReceiptTemplateSettings.defaults();
  ReceiptTemplateSettings get receiptTemplateSettings => _receiptTemplateSettings;

  List<String> _logMessages = [];
  List<String> get logMessages => _logMessages;

  PrinterProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    final settingsString = prefs.getString('categoryPrinterSettings');
    if (settingsString != null) {
      final decodedData = json.decode(settingsString) as Map<String, dynamic>;
      _categoryPrinterSettings = decodedData.map((key, value) {
        return MapEntry(int.parse(key), Map<String, String>.from(value));
      });
    }

    final templateString = prefs.getString('printTemplateSettings');
    if (templateString != null) {
      _templateSettings = PrintTemplateSettings.fromJson(json.decode(templateString));
    }

    final receiptTemplateString = prefs.getString('receiptTemplateSettings');
    if (receiptTemplateString != null) {
      _receiptTemplateSettings = ReceiptTemplateSettings.fromJson(json.decode(receiptTemplateString));
    }

    notifyListeners();
  }

  Future<void> saveSettings(Map<int, Map<String, String>> newSettings) async {
    _categoryPrinterSettings = newSettings;
    final prefs = await SharedPreferences.getInstance();
    final encodedData = _categoryPrinterSettings
        .map((key, value) => MapEntry(key.toString(), value));
    await prefs.setString('categoryPrinterSettings', json.encode(encodedData));
    notifyListeners();
    _addLog('Configurações de impressora salvas.');
  }

  Future<void> saveTemplateSettings(PrintTemplateSettings newSettings) async {
    _templateSettings = newSettings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('printTemplateSettings', json.encode(newSettings.toJson()));
    notifyListeners();
    _addLog('Layout de impressão da cozinha salvo.');
  }
  
  Future<void> saveReceiptTemplateSettings(ReceiptTemplateSettings newSettings) async {
    _receiptTemplateSettings = newSettings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('receiptTemplateSettings', json.encode(newSettings.toJson()));
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
        _receiptTemplateSettings = _receiptTemplateSettings.copyWith(logoPath: imagePath);

         _templateSettings = _templateSettings.copyWith(logoPath: imagePath);
        _receiptTemplateSettings = _receiptTemplateSettings.copyWith(logoPath: imagePath);

        await saveTemplateSettings(_templateSettings);
        await saveReceiptTemplateSettings(_receiptTemplateSettings);
        _addLog('Novo logo salvo com sucesso.');
      } catch (e) {
        _addLog('Erro ao salvar o logo: $e');
      }
    }
  }
  void updateLogoHeight(double newHeight) {
    if (_templateSettings.logoHeight != newHeight) {
      _templateSettings = _templateSettings.copyWith(logoHeight: newHeight);
      notifyListeners();
    }
    if (_receiptTemplateSettings.logoHeight != newHeight) {
      _receiptTemplateSettings = _receiptTemplateSettings.copyWith(logoHeight: newHeight);
      notifyListeners();
    }
  }

  void startListening() {
    if (_isListening) return;
    
    _orderChannel = _supabase.channel('public:pedidos');
    _orderChannel!.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'pedidos',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'status',
          value: 'awaiting_print', 
        ),
        callback: (payload) {
          _handleNewOrder(payload.newRecord);
        },
      ).subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          _isListening = true;
          _addLog('Monitoramento de novos pedidos iniciado.');
          notifyListeners();
        } else {
          _isListening = false;
          _addLog('Monitoramento parado. Status: $status');
          if (error != null) {
            _addLog('Erro de conexão: $error');
          }
          notifyListeners();
        }
    });
  }

  void stopListening() {
    if (_orderChannel != null) {
      _supabase.removeChannel(_orderChannel!);
      _orderChannel = null;
    }
    _isListening = false;
    _addLog('Monitoramento de pedidos parado.');
    notifyListeners();
  }

  Future<void> _handleNewOrder(Map<String, dynamic> newOrderData) async {
    if (newOrderData.isEmpty) return;

    final orderId = newOrderData['id'];
    _addLog('Novo pedido recebido: #$orderId');

    try {
      final orderDetails = await _supabase
          .from('pedidos')
          .select(
              '*, mesa_id(numero), itens_pedido(*, produtos(*, categorias(id, name)))')
          .eq('id', orderId)
          .single();
      final tableNumber = orderDetails['mesa_id']['numero'].toString();
      final itemsData = orderDetails['itens_pedido'] as List;
      final orderItems =
          itemsData.map((item) => app_data.CartItem.fromJson(item)).toList();
      await _routeAndPrintOrder(orderItems, tableNumber, orderId);
    } catch (e) {
      _addLog('Erro ao buscar detalhes do pedido #$orderId: $e');
    }
  }

  Future<void> _routeAndPrintOrder(
      List<app_data.CartItem> items, String tableNumber, int orderId) async {
    final groupedBySettings = groupBy(
        items, (item) => _categoryPrinterSettings[item.product.categoryId]);

    bool allPrintedSuccessfully = true;

    for (final settings in groupedBySettings.keys) {
      if (settings == null || settings['name'] == null) {
        _addLog(
            'Pedido #$orderId contém itens de categorias não configuradas.');
        continue;
      }

      final printerName = settings['name']!;
      final paperSize = settings['size'] ?? '58';
      final itemsForPrinter = groupedBySettings[settings]!;

      try {
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
          _addLog(
              'Pedido #$orderId enviado para a impressora: $printerName ($paperSize mm).');
        } else {
          _addLog(
              'Impressora "$printerName" não encontrada. Pedido #$orderId não impresso.');
          allPrintedSuccessfully = false;
        }
      } catch (e) {
        _addLog('Falha ao imprimir para $printerName: $e');
        allPrintedSuccessfully = false;
      }
    }
    
    if (allPrintedSuccessfully) {
      try {
        await _supabase.from('pedidos').update({'status': 'printed'}).eq('id', orderId);
        _addLog('Pedido #$orderId marcado como impresso no banco de dados.');
      } catch (e) {
        _addLog('Falha ao atualizar o status do pedido #$orderId: $e');
      }
    }
  }

  void _addLog(String message) {
    final timestamp = DateFormat('HH:mm:ss').format(DateTime.now());
    _logMessages.insert(0, '$timestamp - $message');
    if (_logMessages.length > 100) _logMessages.removeLast();
    notifyListeners();
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}