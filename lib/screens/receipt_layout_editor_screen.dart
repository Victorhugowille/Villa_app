// lib/screens/receipt_layout_editor_screen.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;
import 'package:villabistromobile/models/print_style_settings.dart';
import 'package:villabistromobile/providers/estabelecimento_provider.dart';
import 'package:villabistromobile/providers/printer_provider.dart';
import 'package:villabistromobile/services/printing_service.dart';
import 'package:villabistromobile/widgets/custom_app_bar.dart';

class ReceiptLayoutEditorScreen extends StatefulWidget {
  const ReceiptLayoutEditorScreen({super.key});

  @override
  State<ReceiptLayoutEditorScreen> createState() =>
      _ReceiptLayoutEditorScreenState();
}

class _ReceiptLayoutEditorScreenState extends State<ReceiptLayoutEditorScreen> {
  late TextEditingController _subtitleController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _finalMessageController;
  Timer? _debounce;
  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    _subtitleController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _finalMessageController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      final settings =
          Provider.of<PrinterProvider>(context, listen: false).receiptTemplateSettings;
      _subtitleController.text = settings.subtitleText;
      _addressController.text = settings.addressText;
      _phoneController.text = settings.phoneText;
      _finalMessageController.text = settings.finalMessageText;
      _isInit = false;
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _subtitleController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _finalMessageController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _autoSaveSettings(ReceiptTemplateSettings settings) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      Provider.of<PrinterProvider>(context, listen: false)
          .saveReceiptTemplateSettings(settings);
    });
  }

  void _resetToDefaults() {
    final newSettings = ReceiptTemplateSettings.defaults();
    Provider.of<PrinterProvider>(context, listen: false)
        .saveReceiptTemplateSettings(newSettings);
    _subtitleController.text = newSettings.subtitleText;
    _addressController.text = newSettings.addressText;
    _phoneController.text = newSettings.phoneText;
    _finalMessageController.text = newSettings.finalMessageText;
  }

  void _useEstabelecimentoData() {
    final estabelecimento =
        Provider.of<EstabelecimentoProvider>(context, listen: false)
            .estabelecimento;
    if (estabelecimento != null) {
      final settings = Provider.of<PrinterProvider>(context, listen: false)
          .receiptTemplateSettings;

      final newSubtitle = 'CNPJ: ${estabelecimento.cnpj}';
      final newAddress =
          '${estabelecimento.rua}, ${estabelecimento.numero}, ${estabelecimento.bairro}, ${estabelecimento.cidade}-${estabelecimento.estado}';
      final newPhone = 'Telefone: ${estabelecimento.telefone}';

      _subtitleController.text = newSubtitle;
      _addressController.text = newAddress;
      _phoneController.text = newPhone;

      final newSettings = settings.copyWith(
          subtitleText: newSubtitle,
          addressText: newAddress,
          phoneText: newPhone);
      Provider.of<PrinterProvider>(context, listen: false)
          .saveReceiptTemplateSettings(newSettings);

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dados do estabelecimento aplicados!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Nenhum dado de estabelecimento encontrado para aplicar.')));
    }
  }

  Future<Uint8List> _generatePreviewPdfBytes(
      ReceiptTemplateSettings settings) async {
    final printingService = PrintingService();
    final estabelecimentoProvider =
        Provider.of<EstabelecimentoProvider>(context, listen: false);
    return printingService.getReceiptPdfBytes(
      orders: [
        app_data.Order(
          id: '1',
          items: [
            app_data.CartItem(
                product: app_data.Product(
                    id: '1',
                    name: 'Produto Exemplo 1',
                    price: 10.0,
                    categoryId: '1',
                    categoryName: 'Bebidas',
                    displayOrder: 1,
                    isSoldOut: false),
                quantity: 2),
          ],
          timestamp: DateTime.now(),
          status: 'completed',
          type: 'mesa',
        )
      ],
      tableNumber: 'XX',
      totalAmount: 20.0,
      settings: settings,
      companyName: estabelecimentoProvider.estabelecimento?.nomeFantasia ?? 'Nome da Empresa',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PrinterProvider>(
      builder: (context, printerProvider, child) {
        final settings = printerProvider.receiptTemplateSettings;
        return Scaffold(
          appBar: CustomAppBar(
            actions: [
              IconButton(
                icon: const Icon(Icons.preview_outlined),
                tooltip: 'Visualizar',
                onPressed: () async {
                  final pdfBytes = await _generatePreviewPdfBytes(settings);
                  await Printing.layoutPdf(
                      onLayout: (format) async => pdfBytes);
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Redefinir Padrão',
                onPressed: _resetToDefaults,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.storefront),
                  label: const Text('Usar Dados do Estabelecimento'),
                  onPressed: _useEstabelecimentoData,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _subtitleController,
                          decoration: const InputDecoration(
                              labelText: 'Subtítulo (CNPJ)'),
                          onChanged: (value) => _autoSaveSettings(
                              settings.copyWith(subtitleText: value)),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _addressController,
                          decoration:
                              const InputDecoration(labelText: 'Endereço'),
                          onChanged: (value) => _autoSaveSettings(
                              settings.copyWith(addressText: value)),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _phoneController,
                          decoration:
                              const InputDecoration(labelText: 'Telefone'),
                          onChanged: (value) => _autoSaveSettings(
                              settings.copyWith(phoneText: value)),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _finalMessageController,
                          decoration: const InputDecoration(
                              labelText: 'Mensagem Final'),
                          onChanged: (value) => _autoSaveSettings(
                              settings.copyWith(finalMessageText: value)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}