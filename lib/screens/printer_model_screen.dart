// lib/screens/printer_model_screen.dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/data/app_data.dart';
import 'package:villabistromobile/models/print_style_settings.dart';
import 'package:villabistromobile/providers/estabelecimento_provider.dart';
import 'package:villabistromobile/providers/printer_provider.dart';
import 'package:villabistromobile/providers/product_provider.dart';
import 'package:villabistromobile/services/printing_service.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:villabistromobile/data/app_data.dart' as app_data;

class PrinterModelScreen extends StatelessWidget {
  const PrinterModelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.print), text: 'Impressoras'),
              Tab(icon: Icon(Icons.receipt_long), text: 'Cupom Cliente'),
              Tab(icon: Icon(Icons.kitchen), text: 'Pedido Cozinha'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _CategoryPrinterSettingsTab(),
            _ReceiptLayoutEditorTab(),
            _KitchenLayoutEditorTab(),
          ],
        ),
      ),
    );
  }
}

// ABA 1: CONFIGURAÇÃO DE IMPRESSORAS POR CATEGORIA
class _CategoryPrinterSettingsTab extends StatefulWidget {
  const _CategoryPrinterSettingsTab();

  @override
  State<_CategoryPrinterSettingsTab> createState() =>
      _CategoryPrinterSettingsTabState();
}

class _CategoryPrinterSettingsTabState
    extends State<_CategoryPrinterSettingsTab> {
  List<Printer> _printers = [];
  late Map<int, Map<String, String>> _currentSettings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final loadedPrinters = await Printing.listPrinters();
      final uniquePrintersByName = <String, Printer>{};
      for (final printer in loadedPrinters) {
        uniquePrintersByName.putIfAbsent(printer.name, () => printer);
      }
      final uniquePrinters = uniquePrintersByName.values.toList();

      if (mounted) {
        final providerSettings =
            Provider.of<PrinterProvider>(context, listen: false)
                .categoryPrinterSettings;

        setState(() {
          _printers = uniquePrinters;
          _currentSettings = Map<int, Map<String, String>>.from(providerSettings
              .map((key, value) =>
                  MapEntry(key, Map<String, String>.from(value))));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao carregar impressoras: $e')));
      }
    }
  }

  void _saveSettings() {
    final printerProvider =
        Provider.of<PrinterProvider>(context, listen: false);
    printerProvider.saveSettings(_currentSettings);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Configurações de impressora salvas!'),
      backgroundColor: Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final categories = Provider.of<ProductProvider>(context).categories;

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final Category category = categories[index];
                    final settings = _currentSettings[category.id] ?? {};
                    final String? selectedPrinterName =
                        _printers.any((p) => p.name == settings['name'])
                            ? settings['name']
                            : null;
                    final selectedSize = settings['size'] ?? '58';

                    final dropdownItems = _printers.map((Printer printer) {
                      return DropdownMenuItem<String>(
                        value: printer.name,
                        child:
                            Text(printer.name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList();

                    dropdownItems.insert(
                        0,
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Nenhuma',
                              style: TextStyle(fontStyle: FontStyle.italic)),
                        ));

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(category.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Impressora:'),
                                DropdownButton<String?>(
                                  value: selectedPrinterName,
                                  items: dropdownItems,
                                  onChanged: (String? newPrinterName) {
                                    setState(() {
                                      if (newPrinterName != null) {
                                        _currentSettings[category.id] = {
                                          'name': newPrinterName,
                                          'size': selectedSize,
                                        };
                                      } else {
                                        _currentSettings.remove(category.id);
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Tamanho do Papel:'),
                                SegmentedButton<String>(
                                  segments: const [
                                    ButtonSegment(
                                        value: '58', label: Text('58mm')),
                                    ButtonSegment(
                                        value: '80', label: Text('80mm')),
                                  ],
                                  selected: {selectedSize},
                                  onSelectionChanged:
                                      (Set<String> newSelection) {
                                    setState(() {
                                      final newSize = newSelection.first;
                                      if (selectedPrinterName != null) {
                                        _currentSettings[category.id] = {
                                          'name': selectedPrinterName,
                                          'size': newSize,
                                        };
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Salvar Configurações'),
                  ),
                ),
              ),
            ],
          );
  }
}

// ABA 2: EDITOR DE LAYOUT DO CUPOM DE CONFERÊNCIA
class _ReceiptLayoutEditorTab extends StatefulWidget {
  const _ReceiptLayoutEditorTab();

  @override
  State<_ReceiptLayoutEditorTab> createState() =>
      __ReceiptLayoutEditorTabState();
}

class __ReceiptLayoutEditorTabState extends State<_ReceiptLayoutEditorTab> {
  Timer? _debounce;

  @override
  void dispose() {
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

  Future<Uint8List> _generatePreviewPdfBytes(
      ReceiptTemplateSettings settings) async {
    final printingService = PrintingService();
    final estabelecimentoProvider =
        Provider.of<EstabelecimentoProvider>(context, listen: false);
    return printingService.getReceiptPdfBytes(
      orders: [
        app_data.Order(
          id: 1,
          items: [
            app_data.CartItem(
                product: app_data.Product(
                    id: 1,
                    name: 'Produto Exemplo 1',
                    price: 10.0,
                    categoryId: 1,
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
      companyName:
          estabelecimentoProvider.estabelecimento?.nomeFantasia ?? 'Nome da Empresa',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 800;
    return Consumer<PrinterProvider>(
      builder: (context, printerProvider, child) {
        final settings = printerProvider.receiptTemplateSettings;
        return isWideScreen
            ? Row(
                children: [
                  Expanded(flex: 2, child: _buildControlsPanel(settings)),
                  const VerticalDivider(width: 1),
                  Expanded(
                    flex: 1,
                    child: Container(
                      color: Colors.blueGrey.shade50,
                      padding: const EdgeInsets.all(16.0),
                      child: PdfPreview(
                        build: (format) => _generatePreviewPdfBytes(settings),
                        canChangeOrientation: false,
                        canChangePageFormat: false,
                        canDebug: false,
                      ),
                    ),
                  ),
                ],
              )
            : _buildControlsPanel(settings);
      },
    );
  }

  Widget _buildControlsPanel(ReceiptTemplateSettings settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildLogoEditor(settings),
          _buildInfoEditor(settings),
          _buildStyleEditor(
            'Itens do Pedido',
            settings.itemStyle,
            (newStyle) =>
                _autoSaveSettings(settings.copyWith(itemStyle: newStyle)),
          ),
          _buildStyleEditor(
            'Texto do Total',
            settings.totalStyle,
            (newStyle) =>
                _autoSaveSettings(settings.copyWith(totalStyle: newStyle)),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoEditor(ReceiptTemplateSettings settings) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Logo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => Provider.of<PrinterProvider>(context, listen: false).pickAndSaveLogo(),
                icon: const Icon(Icons.image),
                label: const Text('Selecionar Imagem do Logo'),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Altura do Logo na Impressão'),
            Slider(
              value: settings.logoHeight,
              min: 20,
              max: 100,
              divisions: 8,
              label: settings.logoHeight.round().toString(),
              onChanged: (value) {
                Provider.of<PrinterProvider>(context, listen: false).updateLogoHeight(value);
              },
              onChangeEnd: (value) {
                _autoSaveSettings(settings.copyWith(logoHeight: value));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoEditor(ReceiptTemplateSettings settings) {
    final estabelecimento = Provider.of<EstabelecimentoProvider>(context, listen: false).estabelecimento;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Dados do Estabelecimento',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (estabelecimento != null)
                  Tooltip(
                    message: 'Preencher com os dados cadastrados',
                    child: IconButton(
                      icon: const Icon(Icons.storefront),
                      onPressed: () {
                        final newSettings = settings.copyWith(
                          subtitleText: 'CNPJ: ${estabelecimento.cnpj}',
                          addressText: '${estabelecimento.rua}, ${estabelecimento.numero}, ${estabelecimento.bairro}',
                          phoneText: 'Tel: ${estabelecimento.telefone}',
                        );
                        Provider.of<PrinterProvider>(context, listen: false).saveReceiptTemplateSettings(newSettings);
                      },
                    ),
                  ),
              ],
            ),
            const Divider(),
            _buildTextAndStyleEditor(
              'CNPJ',
              settings.subtitleText,
              (newText) => _autoSaveSettings(settings.copyWith(subtitleText: newText)),
              settings.subtitleStyle,
              (newStyle) => _autoSaveSettings(settings.copyWith(subtitleStyle: newStyle)),
            ),
            _buildTextAndStyleEditor(
              'Endereço',
              settings.addressText,
              (newText) => _autoSaveSettings(settings.copyWith(addressText: newText)),
              settings.addressStyle,
              (newStyle) => _autoSaveSettings(settings.copyWith(addressStyle: newStyle)),
            ),
            _buildTextAndStyleEditor(
              'Telefone',
              settings.phoneText,
              (newText) => _autoSaveSettings(settings.copyWith(phoneText: newText)),
              settings.phoneStyle,
              (newStyle) => _autoSaveSettings(settings.copyWith(phoneStyle: newStyle)),
            ),
            _buildTextAndStyleEditor(
              'Mensagem Final',
              settings.finalMessageText,
              (newText) => _autoSaveSettings(settings.copyWith(finalMessageText: newText)),
              settings.finalMessageStyle,
              (newStyle) => _autoSaveSettings(settings.copyWith(finalMessageStyle: newStyle)),
            ),
          ],
        ),
      ),
    );
  }
}

// ABA 3: EDITOR DE LAYOUT DO PEDIDO DA COZINHA
class _KitchenLayoutEditorTab extends StatefulWidget {
  const _KitchenLayoutEditorTab();

  @override
  State<_KitchenLayoutEditorTab> createState() =>
      __KitchenLayoutEditorTabState();
}

class __KitchenLayoutEditorTabState extends State<_KitchenLayoutEditorTab> {
  Timer? _debounce;
  late TextEditingController _footerController;

  @override
  void initState() {
    super.initState();
    final settings =
        Provider.of<PrinterProvider>(context, listen: false).templateSettings;
    _footerController = TextEditingController(text: settings.footerText);
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = Provider.of<PrinterProvider>(context).templateSettings;
    if (_footerController.text != settings.footerText) {
      _footerController.text = settings.footerText;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _footerController.dispose();
    super.dispose();
  }

  void _autoSaveSettings(PrintTemplateSettings settings) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      Provider.of<PrinterProvider>(context, listen: false)
          .saveTemplateSettings(settings);
    });
  }

  Future<Uint8List> _generatePreviewPdfBytes(
      PrintTemplateSettings settings) async {
    final printingService = PrintingService();
    return printingService.getKitchenOrderPdfBytes(
      items: [
        app_data.CartItem(product: app_data.Product(id: 1, name: 'Produto Exemplo 1', price: 10.0, categoryId: 1, categoryName: 'Bebidas', displayOrder: 1, isSoldOut: false), quantity: 2),
        app_data.CartItem(product: app_data.Product(id: 2, name: 'Produto Exemplo 2', price: 15.0, categoryId: 1, categoryName: 'Bebidas', displayOrder: 2, isSoldOut: false), quantity: 1),
      ],
      tableNumber: 'XX',
      orderId: 999,
      paperSize: '58',
      templateSettings: settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 800;
    return Consumer<PrinterProvider>(
      builder: (context, printerProvider, child) {
        final settings = printerProvider.templateSettings;
        return isWideScreen
            ? Row(
                children: [
                  Expanded(flex: 2, child: _buildControlsPanel(settings)),
                  const VerticalDivider(width: 1),
                  Expanded(
                    flex: 1,
                    child: Container(
                      color: Colors.blueGrey.shade50,
                      padding: const EdgeInsets.all(16.0),
                      child: PdfPreview(
                        build: (format) => _generatePreviewPdfBytes(settings),
                        canChangeOrientation: false,
                        canChangePageFormat: false,
                        canDebug: false,
                      ),
                    ),
                  ),
                ],
              )
            : _buildControlsPanel(settings);
      },
    );
  }

  Widget _buildControlsPanel(PrintTemplateSettings settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildLogoEditor(settings),
          _buildStyleEditor(
              'Número da Mesa',
              settings.tableStyle,
              (newStyle) =>
                  _autoSaveSettings(settings.copyWith(tableStyle: newStyle))),
          _buildStyleEditor(
              'Informações (Nº Pedido e Hora)',
              settings.orderInfoStyle,
              (newStyle) => _autoSaveSettings(
                  settings.copyWith(orderInfoStyle: newStyle))),
          _buildStyleEditor(
              'Itens do Pedido',
              settings.itemStyle,
              (newStyle) =>
                  _autoSaveSettings(settings.copyWith(itemStyle: newStyle))),
          _buildTextAndStyleEditor(
              'Texto de Rodapé',
              settings.footerText, // Use direct value here
              (newText) =>
                  _autoSaveSettings(settings.copyWith(footerText: newText)),
              settings.footerStyle,
              (newStyle) =>
                  _autoSaveSettings(settings.copyWith(footerStyle: newStyle))),
        ],
      ),
    );
  }

  Widget _buildLogoEditor(PrintTemplateSettings settings) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Logo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => Provider.of<PrinterProvider>(context, listen: false).pickAndSaveLogo(),
                icon: const Icon(Icons.image),
                label: const Text('Selecionar Imagem do Logo'),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Altura do Logo na Impressão'),
            Slider(
              value: settings.logoHeight,
              min: 20,
              max: 100,
              divisions: 8,
              label: settings.logoHeight.round().toString(),
              onChanged: (value) {
                Provider.of<PrinterProvider>(context, listen: false).updateLogoHeight(value);
              },
              onChangeEnd: (value) {
                _autoSaveSettings(settings.copyWith(logoHeight: value));
              },
            ),
          ],
        ),
      ),
    );
  }
}

// WIDGETS GENÉRICOS UTILIZADOS PELAS ABAS DE EDIÇÃO

Widget _buildTextAndStyleEditor(
  String title,
  String initialValue,
  ValueChanged<String> onTextChanged,
  PrintStyle style,
  ValueChanged<PrintStyle> onStyleChanged,
) {
  // Using a key ensures the controller is re-created when the initialValue changes.
  final controller = TextEditingController(text: initialValue);

  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: title,
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onChanged: onTextChanged,
        ),
        const SizedBox(height: 8),
        _buildStyleControls(style, onStyleChanged),
        const SizedBox(height: 8),
        const Divider(),
      ],
    ),
  );
}

Widget _buildStyleEditor(
    String title, PrintStyle style, ValueChanged<PrintStyle> onUpdate) {
  return Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(),
          _buildStyleControls(style, onUpdate),
        ],
      ),
    ),
  );
}

Widget _buildStyleControls(
    PrintStyle style, ValueChanged<PrintStyle> onUpdate) {
  return Column(
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
      SwitchListTile(
        title: const Text('Negrito'),
        value: style.isBold,
        onChanged: (isBold) => onUpdate(style.copyWith(isBold: isBold)),
        dense: true,
        contentPadding: EdgeInsets.zero,
      ),
      const SizedBox(height: 8),
      const Text('Alinhamento'),
      const SizedBox(height: 8),
      SegmentedButton<pw.CrossAxisAlignment>(
        segments: const [
          ButtonSegment(
              value: pw.CrossAxisAlignment.start,
              icon: Icon(Icons.format_align_left)),
          ButtonSegment(
              value: pw.CrossAxisAlignment.center,
              icon: Icon(Icons.format_align_center)),
          ButtonSegment(
              value: pw.CrossAxisAlignment.end,
              icon: Icon(Icons.format_align_right)),
        ],
        selected: {style.alignment},
        onSelectionChanged: (newSelection) =>
            onUpdate(style.copyWith(alignment: newSelection.first)),
      ),
    ],
  );
}