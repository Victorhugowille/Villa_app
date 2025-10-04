import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:villabistromobile/models/print_style_settings.dart';
import 'package:villabistromobile/providers/navigation_provider.dart';
import 'package:villabistromobile/providers/printer_provider.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;
import 'package:villabistromobile/screens/kitchen_printer_screen.dart';
import 'package:villabistromobile/services/printing_service.dart';
import 'package:villabistromobile/widgets/custom_app_bar.dart';

class PrintLayoutEditorScreen extends StatefulWidget {
  const PrintLayoutEditorScreen({super.key});

  @override
  State<PrintLayoutEditorScreen> createState() =>
      _PrintLayoutEditorScreenState();
}

class _PrintLayoutEditorScreenState extends State<PrintLayoutEditorScreen> {
  late TextEditingController _footerController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final providerSettings =
        Provider.of<PrinterProvider>(context, listen: false).templateSettings;
    _footerController = TextEditingController(text: providerSettings.footerText);
  }

  @override
  void dispose() {
    _footerController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _autoSaveSettings(KitchenTemplateSettings settings) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      Provider.of<PrinterProvider>(context, listen: false)
          .saveTemplateSettings(settings);
    });
  }

  void _resetToDefaults() {
    final newSettings = KitchenTemplateSettings.defaults();
    Provider.of<PrinterProvider>(context, listen: false)
        .saveTemplateSettings(newSettings);
    _footerController.text = newSettings.footerText;
  }

  Widget _generatePreviewWidget(KitchenTemplateSettings settings) {
    final printingService = PrintingService();
    return printingService.buildKitchenOrderWidget(
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
        app_data.CartItem(
            product: app_data.Product(
                id: '2',
                name: 'Produto Exemplo 2',
                price: 15.0,
                categoryId: '1',
                categoryName: 'Bebidas',
                displayOrder: 2,
                isSoldOut: false),
            quantity: 1),
      ],
      tableNumber: 'XX',
      orderId: '999',
      templateSettings: settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Consumer<PrinterProvider>(
      builder: (context, printerProvider, child) {
        final currentSettings = printerProvider.templateSettings;

        return Scaffold(
          appBar: CustomAppBar(
            actions: [
              IconButton(
                icon: const Icon(Icons.print_outlined),
                tooltip: 'Ir para Estação de Impressão',
                onPressed: () {
                  Provider.of<NavigationProvider>(context, listen: false)
                      .navigateTo(
                    context,
                    const KitchenPrinterScreen(),
                    'Estação de Impressão',
                  );
                },
              ),
              if (!isWideScreen)
                IconButton(
                  icon: const Icon(Icons.preview_outlined),
                  tooltip: 'Visualizar',
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                              content: SizedBox(
                                width: 250,
                                child: _generatePreviewWidget(currentSettings),
                              ),
                            ));
                  },
                ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Redefinir Padrão',
                onPressed: _resetToDefaults,
              ),
            ],
          ),
          body: isWideScreen
              ? _buildWideLayout(currentSettings)
              : _buildNarrowLayout(currentSettings),
        );
      },
    );
  }

  Widget _buildWideLayout(KitchenTemplateSettings currentSettings) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: _buildControlsPanel(currentSettings),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.blueGrey.shade50,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Pré-visualização em Tempo Real',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.black),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 4,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    width: 280,
                    color: Colors.white,
                    child: _generatePreviewWidget(currentSettings),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(KitchenTemplateSettings currentSettings) {
    return _buildControlsPanel(currentSettings);
  }

  Widget _buildControlsPanel(KitchenTemplateSettings currentSettings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildLogoEditor(currentSettings),
          _buildStyleEditor(
              'Nome do Local (se não houver logo)', currentSettings.headerStyle,
              (newStyle) {
            _autoSaveSettings(currentSettings.copyWith(headerStyle: newStyle));
          }),
          _buildStyleEditor('Número da Mesa', currentSettings.tableStyle,
              (newStyle) {
            _autoSaveSettings(currentSettings.copyWith(tableStyle: newStyle));
          }),
          _buildStyleEditor(
              'Informações do Pedido', currentSettings.orderInfoStyle,
              (newStyle) {
            _autoSaveSettings(
                currentSettings.copyWith(orderInfoStyle: newStyle));
          }),
          _buildStyleEditor('Itens do Pedido', currentSettings.itemStyle,
              (newStyle) {
            _autoSaveSettings(currentSettings.copyWith(itemStyle: newStyle));
          }),
          _buildTextAndStyleEditor('Rodapé', _footerController, (newStyle) {
            _autoSaveSettings(currentSettings.copyWith(footerStyle: newStyle));
          }, currentSettings.footerStyle, (newText) {
            _autoSaveSettings(currentSettings.copyWith(footerText: newText));
          }),
        ],
      ),
    );
  }

  Widget _buildLogoEditor(KitchenTemplateSettings currentSettings) {
    final printerProvider =
        Provider.of<PrinterProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Logo da Impressão',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            const SizedBox(height: 8),
            Center(
              child: currentSettings.logoPath != null &&
                      currentSettings.logoPath!.isNotEmpty &&
                      File(currentSettings.logoPath!).existsSync()
                  ? Image.file(
                      File(currentSettings.logoPath!),
                      key: UniqueKey(), // Força a atualização da imagem
                      height: 80,
                      errorBuilder: (c, e, s) =>
                          const Icon(Icons.error, color: Colors.red),
                    )
                  : Image.asset('assets/images/logoVilla.jpg', height: 80),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  await printerProvider.pickAndSaveLogo();
                },
                child: const Text('Trocar Imagem'),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Altura do Logo na Impressão'),
            Slider(
              value: currentSettings.logoHeight,
              min: 20,
              max: 100,
              divisions: 8,
              label: currentSettings.logoHeight.round().toString(),
              onChanged: (double value) {
                printerProvider.updateLogoHeight(value);
              },
              onChangeEnd: (double value) {
                _autoSaveSettings(currentSettings.copyWith(logoHeight: value));
              },
            ),
            const SizedBox(height: 8),
            const Text('Alinhamento do Logo'),
            const SizedBox(height: 8),
            Center(
              child: SegmentedButton<CrossAxisAlignment>(
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
                selected: {currentSettings.logoAlignment},
                onSelectionChanged: (newSelection) {
                  printerProvider
                      .updateKitchenLogoAlignment(newSelection.first);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextAndStyleEditor(
      String title,
      TextEditingController controller,
      ValueChanged<PrintStyle> onStyleChanged,
      PrintStyle style,
      ValueChanged<String> onTextChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildStyleControls(onUpdate, style),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleControls(
      ValueChanged<PrintStyle> onUpdate, PrintStyle style) {
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
              onChanged: (isBold) => onUpdate(style.copyWith(isBold: isBold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Alinhamento'),
        const SizedBox(height: 8),
        SegmentedButton<CrossAxisAlignment>(
          segments: const [
            ButtonSegment(
                value: CrossAxisAlignment.start,
                icon: Icon(Icons.format_align_left),
                label: Text('Esq.')),
            ButtonSegment(
                value: CrossAxisAlignment.center,
                icon: Icon(Icons.format_align_center),
                label: Text('Centro')),
            ButtonSegment(
                value: CrossAxisAlignment.end,
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