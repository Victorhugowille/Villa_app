import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/models/print_style_settings.dart';
import 'package:villabistromobile/providers/printer_provider.dart';
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
  late TextEditingController _subtitleController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _finalMessageController;
  Timer? _debounce;

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
    _debounce?.cancel();
    super.dispose();
  }

  void _autoSaveSettings() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      Provider.of<PrinterProvider>(context, listen: false).saveReceiptTemplateSettings(_currentSettings);
    });
  }

  void _resetToDefaults() {
    setState(() {
      _currentSettings = ReceiptTemplateSettings.defaults();
      _subtitleController.text = _currentSettings.subtitleText;
      _addressController.text = _currentSettings.addressText;
      _phoneController.text = _currentSettings.phoneText;
      _finalMessageController.text = _currentSettings.finalMessageText;
    });
    _autoSaveSettings();
  }
  
  pw.Alignment _getAlignment(pw.CrossAxisAlignment crossAxisAlignment) {
    switch (crossAxisAlignment) {
      case pw.CrossAxisAlignment.start:
        return pw.Alignment.centerLeft;
      case pw.CrossAxisAlignment.center:
        return pw.Alignment.center;
      case pw.CrossAxisAlignment.end:
        return pw.Alignment.centerRight;
      default:
        return pw.Alignment.centerLeft;
    }
  }

  pw.TextStyle _getTextStyle(PrintStyle style) {
    return pw.TextStyle(
      fontWeight: style.isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontSize: style.fontSize,
    );
  }

  Future<Uint8List> _generatePreviewPdfBytes(PdfPageFormat format) async {
    final mockOrder = app_data.Order(
      id: 1,
      status: 'closed',
      timestamp: DateTime.now(),
      items: [
         app_data.CartItem(product: app_data.Product(id: 1, name: 'Produto Exemplo 1', price: 10.0, categoryId: 1, categoryName: 'Bebidas', displayOrder: 1, isSoldOut: false), quantity: 2),
         app_data.CartItem(product: app_data.Product(id: 2, name: 'Produto Exemplo 2', price: 15.0, categoryId: 1, categoryName: 'Bebidas', displayOrder: 2, isSoldOut: false), quantity: 1),
      ]
    );
    
    final doc = pw.Document();
    final settings = _currentSettings;

    doc.addPage(
      pw.Page(
        pageFormat: format.copyWith(
            marginLeft: 2 * PdfPageFormat.mm,
            marginRight: 2 * PdfPageFormat.mm,
            marginTop: 2 * PdfPageFormat.mm,
            marginBottom: 2 * PdfPageFormat.mm
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                alignment: _getAlignment(settings.headerStyle.alignment),
                child: pw.Text('VILLA BISTRO', style: _getTextStyle(settings.headerStyle)),
              ),
              if (settings.subtitleText.isNotEmpty)
                pw.Container(
                  width: double.infinity,
                  alignment: _getAlignment(settings.subtitleStyle.alignment),
                  child: pw.Text(settings.subtitleText, style: _getTextStyle(settings.subtitleStyle)),
                ),
               if (settings.addressText.isNotEmpty)
                pw.Container(
                  width: double.infinity,
                  alignment: _getAlignment(settings.addressStyle.alignment),
                  child: pw.Text(settings.addressText, style: _getTextStyle(settings.addressStyle)),
                ),
              if (settings.phoneText.isNotEmpty)
                pw.Container(
                  width: double.infinity,
                  alignment: _getAlignment(settings.phoneStyle.alignment),
                  child: pw.Text(settings.phoneText, style: _getTextStyle(settings.phoneStyle)),
                ),
              pw.SizedBox(height: 5),
              pw.Container(
                width: double.infinity,
                alignment: _getAlignment(settings.infoStyle.alignment),
                child: pw.Text('Conferência - Mesa XX', style: _getTextStyle(settings.infoStyle)),
              ),
              pw.Container(
                width: double.infinity,
                alignment: _getAlignment(settings.infoStyle.alignment),
                child: pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()), style: _getTextStyle(settings.infoStyle)),
              ),
              pw.Divider(height: 12),
              pw.Column(
                children: mockOrder.items.map((item) {
                  return pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          '${item.quantity}x ${item.product.name}',
                          style: _getTextStyle(settings.itemStyle),
                        ),
                      ),
                      pw.Text(
                        'R\$ ${(item.product.price * item.quantity).toStringAsFixed(2)}',
                        style: _getTextStyle(settings.itemStyle),
                      ),
                    ],
                  );
                }).toList(),
              ),
              pw.Divider(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total:',
                      style: _getTextStyle(settings.totalStyle)),
                  pw.Text('R\$ ${mockOrder.total.toStringAsFixed(2)}',
                      style: _getTextStyle(settings.totalStyle)),
                ],
              ),
              pw.SizedBox(height: 20),
              if (settings.finalMessageText.isNotEmpty)
                pw.Container(
                  width: double.infinity,
                  alignment: _getAlignment(settings.finalMessageStyle.alignment),
                  child: pw.Text(settings.finalMessageText, style: _getTextStyle(settings.finalMessageStyle)),
                ),
            ],
          );
        },
      ),
    );
    return doc.save();
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
                final format = const PdfPageFormat(
                  57 * PdfPageFormat.mm, 
                  250 * PdfPageFormat.mm,
                  marginLeft: 2 * PdfPageFormat.mm,
                  marginRight: 2 * PdfPageFormat.mm,
                  marginTop: 2 * PdfPageFormat.mm,
                  marginBottom: 2 * PdfPageFormat.mm,
                );
                final pdfBytes = await _generatePreviewPdfBytes(format);
                await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Redefinir Padrão',
            onPressed: _resetToDefaults,
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
          flex: 1,
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
                        build: (format) => _generatePreviewPdfBytes(format),
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
          _buildStyleEditor('Cabeçalho (Nome do Local)', _currentSettings.headerStyle, (newStyle) {
            setState(() => _currentSettings = _currentSettings.copyWith(headerStyle: newStyle));
            _autoSaveSettings();
          }),
          _buildTextAndStyleEditor('Subtítulo (CNPJ)', _subtitleController, (newText) {
            setState(()=> _currentSettings = _currentSettings.copyWith(subtitleText: newText));
            _autoSaveSettings();
          }, _currentSettings.subtitleStyle, (newStyle) {
            setState(() => _currentSettings = _currentSettings.copyWith(subtitleStyle: newStyle));
            _autoSaveSettings();
          }),
          _buildTextAndStyleEditor('Endereço', _addressController, (newText) {
            setState(()=> _currentSettings = _currentSettings.copyWith(addressText: newText));
            _autoSaveSettings();
          }, _currentSettings.addressStyle, (newStyle) {
            setState(() => _currentSettings = _currentSettings.copyWith(addressStyle: newStyle));
            _autoSaveSettings();
          }),
          _buildTextAndStyleEditor('Telefone', _phoneController, (newText) {
            setState(()=> _currentSettings = _currentSettings.copyWith(phoneText: newText));
            _autoSaveSettings();
          }, _currentSettings.phoneStyle, (newStyle) {
            setState(() => _currentSettings = _currentSettings.copyWith(phoneStyle: newStyle));
            _autoSaveSettings();
          }),
          _buildStyleEditor('Info (Mesa e Data)', _currentSettings.infoStyle, (newStyle) {
            setState(() => _currentSettings = _currentSettings.copyWith(infoStyle: newStyle));
            _autoSaveSettings();
          }),
          _buildStyleEditor('Itens', _currentSettings.itemStyle, (newStyle) {
            setState(() => _currentSettings = _currentSettings.copyWith(itemStyle: newStyle));
            _autoSaveSettings();
          }),
          _buildStyleEditor('Total', _currentSettings.totalStyle, (newStyle) {
            setState(() => _currentSettings = _currentSettings.copyWith(totalStyle: newStyle));
            _autoSaveSettings();
          }),
          _buildTextAndStyleEditor('Mensagem Final', _finalMessageController, (newText) {
            setState(()=> _currentSettings = _currentSettings.copyWith(finalMessageText: newText));
            _autoSaveSettings();
          }, _currentSettings.finalMessageStyle, (newStyle) {
            setState(() => _currentSettings = _currentSettings.copyWith(finalMessageStyle: newStyle));
            _autoSaveSettings();
          }),
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