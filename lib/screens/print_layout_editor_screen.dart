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

class PrintLayoutEditorScreen extends StatefulWidget {
  const PrintLayoutEditorScreen({super.key});

  @override
  State<PrintLayoutEditorScreen> createState() =>
      _PrintLayoutEditorScreenState();
}

class _PrintLayoutEditorScreenState extends State<PrintLayoutEditorScreen> {
  late PrintTemplateSettings _currentSettings;
  late TextEditingController _footerController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final providerSettings =
        Provider.of<PrinterProvider>(context, listen: false).templateSettings;
    _currentSettings =
        PrintTemplateSettings.fromJson(json.decode(json.encode(providerSettings.toJson())));
    _footerController = TextEditingController(text: _currentSettings.footerText);
  }

  @override
  void dispose() {
    _footerController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _autoSaveSettings() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      Provider.of<PrinterProvider>(context, listen: false)
          .saveTemplateSettings(_currentSettings);
    });
  }

  void _resetToDefaults() {
    setState(() {
      _currentSettings = PrintTemplateSettings.defaults();
      _footerController.text = _currentSettings.footerText;
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
    final mockItems = [
      app_data.CartItem(
        product: app_data.Product(id: 1, name: 'Produto Exemplo 1', price: 10.0, categoryId: 1, categoryName: 'Bebidas', displayOrder: 1, isSoldOut: false),
        quantity: 2,
      ),
      app_data.CartItem(
        product: app_data.Product(id: 2, name: 'Produto Exemplo 2', price: 15.0, categoryId: 1, categoryName: 'Bebidas', displayOrder: 2, isSoldOut: false),
        quantity: 1,
      ),
    ];

    final doc = pw.Document();
    final settings = _currentSettings;

    doc.addPage(
      pw.Page(
        pageFormat: format.copyWith(
            marginLeft: 1.5 * PdfPageFormat.mm,
            marginRight: 1.5 * PdfPageFormat.mm,
            marginTop: 2 * PdfPageFormat.mm,
            marginBottom: 2 * PdfPageFormat.mm,
        ),
        orientation: pw.PageOrientation.portrait,
        build: (context) {
          return pw.Column(
            children: [
              pw.Container(
                width: double.infinity,
                alignment: _getAlignment(settings.headerStyle.alignment),
                child: pw.Text('VillaBistrô',
                    style: _getTextStyle(settings.headerStyle)),
              ),
              pw.SizedBox(height: 5),
              pw.Center(child: pw.Text('----------------------------------')),
              pw.SizedBox(height: 5),
              pw.Container(
                width: double.infinity,
                alignment: _getAlignment(settings.tableStyle.alignment),
                child: pw.Text('MESA XX',
                    style: _getTextStyle(settings.tableStyle)),
              ),
              pw.SizedBox(height: 5),
              pw.Container(
                width: double.infinity,
                alignment: _getAlignment(settings.orderInfoStyle.alignment),
                child: pw.Text(
                  'Pedido #999 - ${DateFormat('HH:mm').format(DateTime.now())}',
                  style: _getTextStyle(settings.orderInfoStyle),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Center(child: pw.Text('----------------------------------')),
              pw.SizedBox(height: 5),
              for (final item in mockItems)
                pw.Container(
                  width: double.infinity,
                  alignment: _getAlignment(settings.itemStyle.alignment),
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Text(
                    '(${item.quantity}) ${item.product.name}',
                    style: _getTextStyle(settings.itemStyle),
                  ),
                ),
              if (settings.footerText.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 10),
                  child: pw.Container(
                    width: double.infinity,
                    alignment: _getAlignment(settings.footerStyle.alignment),
                    child: pw.Text(settings.footerText, style: _getTextStyle(settings.footerStyle)),
                  ),
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
        title: 'Layout da Impressão (Cozinha)',
        actions: [
          if (!isWideScreen)
            IconButton(
              icon: const Icon(Icons.preview_outlined),
              tooltip: 'Visualizar',
              onPressed: () async {
                final format = const PdfPageFormat(
                  57 * PdfPageFormat.mm, 
                  250 * PdfPageFormat.mm,
                  marginLeft: 1.5 * PdfPageFormat.mm,
                  marginRight: 1.5 * PdfPageFormat.mm,
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
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.black),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Card(
                    elevation: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: PdfPreview(
                        build: (format) => _generatePreviewPdfBytes(
                          format.copyWith(width: 58 * PdfPageFormat.mm)
                        ),
                        canChangeOrientation: false,
                        canChangePageFormat: false,
                        canDebug: false,
                        scrollViewDecoration: BoxDecoration(
                          color: Colors.grey[200],
                        ),
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
          _buildStyleEditor('Número da Mesa', _currentSettings.tableStyle, (newStyle) {
            setState(() => _currentSettings = _currentSettings.copyWith(tableStyle: newStyle));
            _autoSaveSettings();
          }),
          _buildStyleEditor('Informações do Pedido', _currentSettings.orderInfoStyle, (newStyle) {
            setState(() => _currentSettings = _currentSettings.copyWith(orderInfoStyle: newStyle));
            _autoSaveSettings();
          }),
          _buildStyleEditor('Itens do Pedido', _currentSettings.itemStyle, (newStyle) {
            setState(() => _currentSettings = _currentSettings.copyWith(itemStyle: newStyle));
            _autoSaveSettings();
          }),
          _buildTextAndStyleEditor('Rodapé', _footerController, (newStyle) {
            setState(() => _currentSettings = _currentSettings.copyWith(footerStyle: newStyle));
            _autoSaveSettings();
          }, _currentSettings.footerStyle),
        ],
      ),
    );
  }

  Widget _buildTextAndStyleEditor(String title, TextEditingController controller, ValueChanged<PrintStyle> onStyleChanged, PrintStyle style) {
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
              onChanged: (value) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(footerText: value);
                });
                _autoSaveSettings();
              },
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
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () => onUpdate(style.copyWith(
                          fontSize: (style.fontSize - 1).clamp(6.0, 30.0))),
                    ),
                    Text(style.fontSize.toStringAsFixed(0)),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => onUpdate(style.copyWith(
                          fontSize: (style.fontSize + 1).clamp(6.0, 30.0))),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Negrito'),
                Switch(
                  value: style.isBold,
                  onChanged: (isBold) =>
                      onUpdate(style.copyWith(isBold: isBold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Alinhamento'),
            const SizedBox(height: 8),
            SegmentedButton<pw.CrossAxisAlignment>(
              segments: const [
                ButtonSegment(
                    value: pw.CrossAxisAlignment.start,
                    icon: Icon(Icons.format_align_left),
                    label: Text('Esq.')),
                ButtonSegment(
                    value: pw.CrossAxisAlignment.center,
                    icon: Icon(Icons.format_align_center),
                    label: Text('Centro')),
                ButtonSegment(
                    value: pw.CrossAxisAlignment.end,
                    icon: Icon(Icons.format_align_right),
                    label: Text('Dir.')),
              ],
              selected: {style.alignment},
              onSelectionChanged: (newSelection) =>
                  onUpdate(style.copyWith(alignment: newSelection.first)),
              style: ButtonStyle(
                padding: MaterialStateProperty.all<EdgeInsets>(
                  const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
      ],
    );
  }
}

extension on PrintTemplateSettings {
  PrintTemplateSettings copyWith({
    PrintStyle? headerStyle,
    PrintStyle? tableStyle,
    PrintStyle? orderInfoStyle,
    PrintStyle? itemStyle,
    String? footerText,
    PrintStyle? footerStyle,
  }) {
    return PrintTemplateSettings(
      headerStyle: headerStyle ?? this.headerStyle,
      tableStyle: tableStyle ?? this.tableStyle,
      orderInfoStyle: orderInfoStyle ?? this.orderInfoStyle,
      itemStyle: itemStyle ?? this.itemStyle,
      footerText: footerText ?? this.footerText,
      footerStyle: footerStyle ?? this.footerStyle,
    );
  }
}