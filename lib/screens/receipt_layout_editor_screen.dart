import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/models/print_style_settings.dart';
import 'package:villabistromobile/providers/printer_provider.dart';
import 'package:villabistromobile/services/printing_service.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;
import 'package:villabistromobile/widgets/custom_app_bar.dart';

class ReceiptLayoutEditorScreen extends StatefulWidget {
  const ReceiptLayoutEditorScreen({super.key});

  @override
  State<ReceiptLayoutEditorScreen> createState() =>
      _ReceiptLayoutEditorScreenState();
}

class _ReceiptLayoutEditorScreenState extends State<ReceiptLayoutEditorScreen> {
  late ReceiptTemplateSettings _currentSettings;
  final PrintingService _printingService = PrintingService();
  late TextEditingController _subtitleController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _finalMessageController;

  @override
  void initState() {
    super.initState();
    final providerSettings = Provider.of<PrinterProvider>(context, listen: false).receiptTemplateSettings;
    _currentSettings = ReceiptTemplateSettings.fromJson(json.decode(json.encode(providerSettings.toJson())));
    _subtitleController = TextEditingController(text: _currentSettings.subtitleText);
    _addressController = TextEditingController(text: _currentSettings.addressText);
    _phoneController = TextEditingController(text: _currentSettings.phoneText);
    _finalMessageController = TextEditingController(text: _currentSettings.finalMessageText);
  }

  @override
  void dispose() {
    _subtitleController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _finalMessageController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    Provider.of<PrinterProvider>(context, listen: false).saveReceiptTemplateSettings(_currentSettings);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Layout salvo com sucesso!'),
      backgroundColor: Colors.green,
    ));
    Navigator.of(context).pop();
  }

  void _resetToDefaults() {
    setState(() {
      _currentSettings = ReceiptTemplateSettings.defaults();
      _subtitleController.text = _currentSettings.subtitleText;
      _addressController.text = _currentSettings.addressText;
      _phoneController.text = _currentSettings.phoneText;
      _finalMessageController.text = _currentSettings.finalMessageText;
    });
  }

  Future<Uint8List> _generatePreviewPdfBytes() async {
    final mockOrder = app_data.Order(
      id: 1,
      status: 'closed',
      timestamp: DateTime.now(),
      items: [
         app_data.CartItem(product: app_data.Product(id: 1, name: 'Produto Exemplo 1', price: 10.0, categoryId: 1, categoryName: 'Bebidas', displayOrder: 1, isSoldOut: false), quantity: 2),
         app_data.CartItem(product: app_data.Product(id: 2, name: 'Produto Exemplo 2', price: 15.0, categoryId: 1, categoryName: 'Bebidas', displayOrder: 2, isSoldOut: false), quantity: 1),
      ]
    );

    return await _printingService.getReceiptPdfBytes(
      orders: [mockOrder],
      tableNumber: 'XX',
      totalAmount: mockOrder.total,
      settings: _currentSettings,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Layout da Impressão (Conferência)',
        actions: [
          if (!isWideScreen)
            IconButton(
              icon: const Icon(Icons.preview_outlined),
              tooltip: 'Visualizar',
              onPressed: () async {
                final pdfBytes = await _generatePreviewPdfBytes();
                await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Redefinir Padrão',
            onPressed: _resetToDefaults,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Salvar',
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: isWideScreen ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildControlsPanel(),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.blueGrey.shade50,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pré-visualização em Tempo Real',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Card(
                    elevation: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: PdfPreview(
                        build: (format) => _generatePreviewPdfBytes(),
                        pageFormats: const {'58mm': PdfPageFormat(58 * PdfPageFormat.mm, 250 * PdfPageFormat.mm, marginAll: 2 * PdfPageFormat.mm)},
                        canChangeOrientation: false,
                        canChangePageFormat: false,
                        canDebug: false,
                        scrollViewDecoration: BoxDecoration(color: Colors.grey[200]),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildNarrowLayout() {
    return _buildControlsPanel();
  }

  Widget _buildControlsPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildStyleEditor('Cabeçalho (Nome do Local)', _currentSettings.headerStyle, (newStyle) => setState(() => _currentSettings = _currentSettings.copyWith(headerStyle: newStyle))),
          _buildTextAndStyleEditor('Subtítulo (CNPJ)', _subtitleController, (newText) => setState(()=> _currentSettings = _currentSettings.copyWith(subtitleText: newText)), _currentSettings.subtitleStyle, (newStyle) => setState(() => _currentSettings = _currentSettings.copyWith(subtitleStyle: newStyle))),
          _buildTextAndStyleEditor('Endereço', _addressController, (newText) => setState(()=> _currentSettings = _currentSettings.copyWith(addressText: newText)), _currentSettings.addressStyle, (newStyle) => setState(() => _currentSettings = _currentSettings.copyWith(addressStyle: newStyle))),
          _buildTextAndStyleEditor('Telefone', _phoneController, (newText) => setState(()=> _currentSettings = _currentSettings.copyWith(phoneText: newText)), _currentSettings.phoneStyle, (newStyle) => setState(() => _currentSettings = _currentSettings.copyWith(phoneStyle: newStyle))),
          _buildStyleEditor('Info (Mesa e Data)', _currentSettings.infoStyle, (newStyle) => setState(() => _currentSettings = _currentSettings.copyWith(infoStyle: newStyle))),
          _buildStyleEditor('Itens', _currentSettings.itemStyle, (newStyle) => setState(() => _currentSettings = _currentSettings.copyWith(itemStyle: newStyle))),
          _buildStyleEditor('Total', _currentSettings.totalStyle, (newStyle) => setState(() => _currentSettings = _currentSettings.copyWith(totalStyle: newStyle))),
          _buildTextAndStyleEditor('Mensagem Final', _finalMessageController, (newText) => setState(()=> _currentSettings = _currentSettings.copyWith(finalMessageText: newText)), _currentSettings.finalMessageStyle, (newStyle) => setState(() => _currentSettings = _currentSettings.copyWith(finalMessageStyle: newStyle))),
        ],
      ),
    );
  }

  Widget _buildTextAndStyleEditor(String title, TextEditingController controller, ValueChanged<String> onTextChanged, PrintStyle style, ValueChanged<PrintStyle> onStyleChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Texto'),
              onChanged: onTextChanged,
            ),
            const SizedBox(height: 16),
            _buildStyleControls(onStyleChanged, style),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleEditor(
      String title, PrintStyle style, ValueChanged<PrintStyle> onUpdate) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildStyleControls(onUpdate, style),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleControls(ValueChanged<PrintStyle> onUpdate, PrintStyle style) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tamanho da Fonte'),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.remove), onPressed: () => onUpdate(style.copyWith(fontSize: (style.fontSize - 1).clamp(6.0, 30.0)))),
                    Text(style.fontSize.toStringAsFixed(0)),
                    IconButton(icon: const Icon(Icons.add), onPressed: () => onUpdate(style.copyWith(fontSize: (style.fontSize + 1).clamp(6.0, 30.0)))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Negrito'),
                Switch(value: style.isBold, onChanged: (isBold) => onUpdate(style.copyWith(isBold: isBold))),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Alinhamento'),
            const SizedBox(height: 8),
            SegmentedButton<pw.CrossAxisAlignment>(
              segments: const [
                ButtonSegment(value: pw.CrossAxisAlignment.start, icon: Icon(Icons.format_align_left), label: Text('Esq.')),
                ButtonSegment(value: pw.CrossAxisAlignment.center, icon: Icon(Icons.format_align_center), label: Text('Centro')),
                ButtonSegment(value: pw.CrossAxisAlignment.end, icon: Icon(Icons.format_align_right), label: Text('Dir.')),
              ],
              selected: {style.alignment},
              onSelectionChanged: (newSelection) => onUpdate(style.copyWith(alignment: newSelection.first)),
              style: ButtonStyle(padding: MaterialStateProperty.all<EdgeInsets>(const EdgeInsets.symmetric(horizontal: 8))),
            ),
      ],
    );
  }
}


extension on ReceiptTemplateSettings {
  ReceiptTemplateSettings copyWith({
    PrintStyle? headerStyle,
    String? subtitleText,
    PrintStyle? subtitleStyle,
    String? addressText,
    PrintStyle? addressStyle,
    String? phoneText,
    PrintStyle? phoneStyle,
    PrintStyle? infoStyle,
    PrintStyle? itemStyle,
    PrintStyle? totalStyle,
    String? finalMessageText,
    PrintStyle? finalMessageStyle,
  }) {
    return ReceiptTemplateSettings(
      headerStyle: headerStyle ?? this.headerStyle,
      subtitleText: subtitleText ?? this.subtitleText,
      subtitleStyle: subtitleStyle ?? this.subtitleStyle,
      addressText: addressText ?? this.addressText,
      addressStyle: addressStyle ?? this.addressStyle,
      phoneText: phoneText ?? this.phoneText,
      phoneStyle: phoneStyle ?? this.phoneStyle,
      infoStyle: infoStyle ?? this.infoStyle,
      itemStyle: itemStyle ?? this.itemStyle,
      totalStyle: totalStyle ?? this.totalStyle,
      finalMessageText: finalMessageText ?? this.finalMessageText,
      finalMessageStyle: finalMessageStyle ?? this.finalMessageStyle,
    );
  }
}