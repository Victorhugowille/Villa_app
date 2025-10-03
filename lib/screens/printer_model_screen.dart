// lib/screens/printer_model_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/data/app_data.dart';
import 'package:villabistromobile/models/print_style_settings.dart';
import 'package:villabistromobile/providers/estabelecimento_provider.dart';
import 'package:villabistromobile/providers/printer_provider.dart';
import 'package:villabistromobile/providers/product_provider.dart';
import 'package:villabistromobile/services/printing_service.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;
import 'package:villabistromobile/widgets/side_menu.dart';
import 'package:villabistromobile/screens/kitchen_printer_screen.dart';

class PrinterModelScreen extends StatelessWidget {
  const PrinterModelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    final tabs = [
      const Tab(icon: Icon(Icons.print), text: 'Destinos'),
      const Tab(icon: Icon(Icons.dvr), text: 'Estação'),
      const Tab(icon: Icon(Icons.receipt_long), text: 'Cupom Cliente'),
      const Tab(icon: Icon(Icons.kitchen), text: 'Pedido Cozinha'),
    ];

    final tabViews = [
      _CategoryPrinterSettingsTab(),
      const KitchenPrinterScreen(),
      _ReceiptLayoutEditorTab(),
      const _KitchenLayoutEditorTab(),
    ];

    if (isDesktop) {
      return DefaultTabController(
        length: tabs.length,
        child: Scaffold(
          appBar: TabBar(tabs: tabs),
          body: TabBarView(children: tabViews),
        ),
      );
    } else {
      return DefaultTabController(
        length: tabs.length,
        child: Scaffold(
          drawer: const SideMenu(),
          appBar: AppBar(
            title: const Text('Impressão'),
            bottom: TabBar(
              isScrollable: true,
              tabs: tabs.map((t) => Tab(text: (t.text ?? ''))).toList(),
            ),
          ),
          body: TabBarView(children: tabViews),
        ),
      );
    }
  }
}

class _CategoryPrinterSettingsTab extends StatefulWidget {
  const _CategoryPrinterSettingsTab();

  @override
  State<_CategoryPrinterSettingsTab> createState() =>
      _CategoryPrinterSettingsTabState();
}

class _CategoryPrinterSettingsTabState
    extends State<_CategoryPrinterSettingsTab> {
  List<Printer> _printers = [];
  late Map<String, Map<String, String>> _currentSettings;
  bool _isLoadingPrinters = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _isLoadingPrinters = true);
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
          _currentSettings = Map<String, Map<String, String>>.from(
              providerSettings.map((key, value) =>
                  MapEntry(key, Map<String, String>.from(value))));
          _isLoadingPrinters = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPrinters = false);
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
    final productProvider = Provider.of<ProductProvider>(context);
    final categories = productProvider.categories;

    if (_isLoadingPrinters || productProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (categories.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Nenhuma categoria encontrada.\n\nVá para Gestão > Produtos para cadastrar novas categorias.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
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
                  child: Text(printer.name, overflow: TextOverflow.ellipsis),
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
                              fontWeight: FontWeight.bold, fontSize: 16)),
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
                              ButtonSegment(value: '58', label: Text('58mm')),
                              ButtonSegment(value: '80', label: Text('80mm')),
                            ],
                            selected: {selectedSize},
                            onSelectionChanged: (Set<String> newSelection) {
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

  void _printTest(ReceiptTemplateSettings settings) async {
    final pdfBytes = await PrintingService().getReceiptPdfBytes(
      orders: [
        app_data.Order(
            id: 'teste-id',
            items: [
              app_data.CartItem(product: app_data.Product(id: '1', name: 'Produto Teste 1', price: 10.99, categoryId: 'cat1', categoryName: 'Exemplo', displayOrder: 1, isSoldOut: false), quantity: 2),
              app_data.CartItem(product: app_data.Product(id: '2', name: 'Produto Teste 2', price: 8.50, categoryId: 'cat1', categoryName: 'Exemplo', displayOrder: 2, isSoldOut: false), quantity: 1),
            ],
            timestamp: DateTime.now(),
            status: 'completed',
            type: 'mesa')
      ],
      tableNumber: '99',
      totalAmount: 30.48,
      settings: settings,
      companyName: Provider.of<EstabelecimentoProvider>(context, listen: false).estabelecimento?.nomeFantasia ?? 'Sua Empresa',
    );
    await Printing.layoutPdf(onLayout: (format) => pdfBytes);
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 800;
    return Consumer<PrinterProvider>(
      builder: (context, printerProvider, child) {
        final settings = printerProvider.receiptTemplateSettings;
        
        final previewWidget = PrintingService().buildReceiptWidget(
          orders: [
            app_data.Order(
                id: 'preview-id',
                items: [
                  app_data.CartItem(product: app_data.Product(id: '1', name: 'Produto Exemplo 1', price: 10.99, categoryId: 'cat1', categoryName: 'Exemplo', displayOrder: 1, isSoldOut: false), quantity: 2),
                  app_data.CartItem(product: app_data.Product(id: '2', name: 'Produto 2 com nome longo', price: 8.50, categoryId: 'cat1', categoryName: 'Exemplo', displayOrder: 2, isSoldOut: false), quantity: 1),
                ],
                timestamp: DateTime.now(),
                status: 'completed',
                type: 'mesa')
          ],
          tableNumber: 'XX',
          totalAmount: 20.49,
          settings: settings,
          companyName: Provider.of<EstabelecimentoProvider>(context, listen: false).estabelecimento?.nomeFantasia ?? 'Sua Empresa',
        );

        if (isWideScreen) {
          return Row(
            children: [
              Expanded(flex: 2, child: _buildControlsPanel(settings)),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 1,
                child: Container(
                  color: Colors.blueGrey.shade100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Card(
                        elevation: 4,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          width: 280,
                          color: Colors.white,
                          child: previewWidget,
                        ),
                      ),
                      const SizedBox(height: 16),
                      IconButton(
                        icon: const Icon(Icons.print_outlined),
                        iconSize: 40,
                        tooltip: 'Imprimir Teste',
                        onPressed: () => _printTest(settings),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        } else {
          return _buildControlsPanel(settings);
        }
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
          if (! (MediaQuery.of(context).size.width > 800))
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.print_outlined),
                label: const Text("Imprimir Teste"),
                onPressed: () => _printTest(settings),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
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
             if (settings.logoPath != null && settings.logoPath!.isNotEmpty && File(settings.logoPath!).existsSync())
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Image.file(
                    File(settings.logoPath!),
                    height: 80,
                    errorBuilder: (c, e, s) => const Icon(Icons.error, color: Colors.red, size: 40),
                  ),
                ),
              ),
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
              'Subtítulo (CNPJ)',
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

class _KitchenLayoutEditorTab extends StatefulWidget {
  const _KitchenLayoutEditorTab();

  @override
  State<_KitchenLayoutEditorTab> createState() =>
      __KitchenLayoutEditorTabState();
}

class __KitchenLayoutEditorTabState extends State<_KitchenLayoutEditorTab> {
  Timer? _debounce;
  
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _autoSaveSettings(PrintTemplateSettings settings) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      Provider.of<PrinterProvider>(context, listen: false)
          .saveTemplateSettings(settings);
    });
  }

  void _printTest(PrintTemplateSettings settings) async {
    final pdfBytes = await PrintingService().getKitchenOrderPdfBytes(
      items: [
        app_data.CartItem(product: app_data.Product(id: '1', name: 'Produto Teste 1', price: 10.0, categoryId: '1', categoryName: 'Bebidas', displayOrder: 1, isSoldOut: false), quantity: 2),
        app_data.CartItem(product: app_data.Product(id: '2', name: 'Produto Teste 2', price: 15.0, categoryId: '1', categoryName: 'Bebidas', displayOrder: 2, isSoldOut: false), quantity: 1),
      ],
      tableNumber: '99',
      orderId: 'teste-123',
      paperSize: '58', 
      templateSettings: settings,
    );
    await Printing.layoutPdf(onLayout: (format) => pdfBytes);
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 800;
    return Consumer<PrinterProvider>(
      builder: (context, printerProvider, child) {
        final settings = printerProvider.templateSettings;

        final previewWidget = PrintingService().buildKitchenOrderWidget(
          items: [
            app_data.CartItem(product: app_data.Product(id: '1', name: 'Produto Exemplo 1', price: 10.0, categoryId: '1', categoryName: 'Bebidas', displayOrder: 1, isSoldOut: false), quantity: 2),
            app_data.CartItem(product: app_data.Product(id: '2', name: 'Produto Exemplo 2', price: 15.0, categoryId: '1', categoryName: 'Bebidas', displayOrder: 2, isSoldOut: false), quantity: 1),
          ],
          tableNumber: 'XX',
          orderId: 'preview-123',
          templateSettings: settings,
        );
        
        if (isWideScreen) {
          return Row(
            children: [
              Expanded(flex: 2, child: _buildControlsPanel(settings)),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 1,
                child: Container(
                  color: Colors.blueGrey.shade100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Card(
                        elevation: 4,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          width: 280,
                          color: Colors.white,
                          child: previewWidget,
                        ),
                      ),
                      const SizedBox(height: 16),
                      IconButton(
                        icon: const Icon(Icons.print_outlined),
                        iconSize: 40,
                        tooltip: 'Imprimir Teste',
                        onPressed: () => _printTest(settings),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        } else {
          return _buildControlsPanel(settings);
        }
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
              settings.footerText, 
              (newText) =>
                  _autoSaveSettings(settings.copyWith(footerText: newText)),
              settings.footerStyle,
              (newStyle) =>
                  _autoSaveSettings(settings.copyWith(footerStyle: newStyle))),
          if (! (MediaQuery.of(context).size.width > 800))
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.print_outlined),
                label: const Text("Imprimir Teste"),
                onPressed: () => _printTest(settings),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
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
            if (settings.logoPath != null && settings.logoPath!.isNotEmpty && File(settings.logoPath!).existsSync())
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Image.file(
                    File(settings.logoPath!),
                    height: 80,
                    errorBuilder: (c, e, s) => const Icon(Icons.error, color: Colors.red, size: 40),
                  ),
                ),
              ),
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
                 _autoSaveSettings(settings.copyWith(logoHeight: value));
              },
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildTextAndStyleEditor(
  String title,
  String initialValue,
  ValueChanged<String> onTextChanged,
  PrintStyle style,
  ValueChanged<PrintStyle> onStyleChanged,
) {
  final controller = TextEditingController(text: initialValue);
  
  // Para evitar múltiplas atualizações, o listener do controller
  // só deve chamar o onTextChanged.
  // A UI reconstruirá e pegará o novo valor do controller.
  controller.addListener(() {
    onTextChanged(controller.text);
  });

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
      SegmentedButton<CrossAxisAlignment>(
        segments: const [
          ButtonSegment(
              value: CrossAxisAlignment.start,
              icon: Icon(Icons.format_align_left)),
          ButtonSegment(
              value: CrossAxisAlignment.center,
              icon: Icon(Icons.format_align_center)),
          ButtonSegment(
              value: CrossAxisAlignment.end,
              icon: Icon(Icons.format_align_right)),
        ],
        selected: {style.alignment},
        onSelectionChanged: (newSelection) =>
            onUpdate(style.copyWith(alignment: newSelection.first)),
      ),
    ],
  );
}