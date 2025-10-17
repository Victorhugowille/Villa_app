import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;
import 'package:villabistromobile/models/print_style_settings.dart';
import 'package:villabistromobile/providers/printer_provider.dart';
import 'package:villabistromobile/services/printing_service.dart';
import 'package:villabistromobile/providers/company_provider.dart';
import 'package:villabistromobile/screens/print/print_layout_helpers.dart';

class ReceiptLayoutEditorTab extends StatefulWidget {
  const ReceiptLayoutEditorTab({super.key});

  @override
  State<ReceiptLayoutEditorTab> createState() => _ReceiptLayoutEditorTabState();
}

class _ReceiptLayoutEditorTabState extends State<ReceiptLayoutEditorTab> {
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
    final sampleDeliveryInfo = app_data.DeliveryInfo(
        id: 'preview-d-id',
        pedidoId: 'teste-123',
        nomeCliente: 'Cliente de Teste',
        telefoneCliente: '(99) 99999-9999',
        enderecoEntrega:
            'Rua de Teste, 123, Apto 404 - Bairro Exemplo, Cidade');

    final pdfBytes = await PrintingService().getReceiptPdfBytes(
      orders: [
        app_data.Order(
            id: 'teste-id',
            // CORREÇÃO AQUI
            numeroPedido: 99,
            items: [
              app_data.CartItem(
                  id: 'ci1',
                  product: app_data.Product(
                      id: '1',
                      name: 'Produto Teste 1',
                      price: 10.99,
                      categoryId: 'cat1',
                      categoryName: 'Exemplo',
                      displayOrder: 1,
                      isSoldOut: false),
                  quantity: 2,
                  selectedAdicionais: [
                    app_data.CartItemAdicional(
                        adicional: app_data.Adicional(
                            id: 'ad1',
                            name: 'Bacon Extra',
                            price: 3.0,
                            displayOrder: 1),
                        quantity: 1)
                  ]),
              app_data.CartItem(
                id: 'ci2',
                product: app_data.Product(
                    id: '2',
                    name: 'Produto Teste 2',
                    price: 8.50,
                    categoryId: 'cat1',
                    categoryName: 'Exemplo',
                    displayOrder: 2,
                    isSoldOut: false),
                quantity: 1,
              ),
            ],
            timestamp: DateTime.now(),
            status: 'completed',
            type: 'delivery')
      ],
      tableNumber: 'ENTREGA',
      totalAmount: 33.48, // Ajustado para (10.99 * 2) + 3.0 + 8.50
      settings: settings,
      deliveryInfo: sampleDeliveryInfo,
    );
    await Printing.layoutPdf(onLayout: (format) => pdfBytes);
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 800;
    return Consumer<PrinterProvider>(
      builder: (context, printerProvider, child) {
        final settings = printerProvider.receiptTemplateSettings;

        final sampleDeliveryInfo = app_data.DeliveryInfo(
            id: 'preview-d-id',
            pedidoId: 'preview-123',
            nomeCliente: 'Cliente Exemplo Delivery',
            telefoneCliente: '(45) 99999-8888',
            enderecoEntrega:
                'Rua das Flores, 123, Apto 101 - Centro, Cidade');

        final previewWidget = PrintingService().buildReceiptWidget(
            orders: [
              app_data.Order(
                  id: 'preview-id',
                  // CORREÇÃO AQUI
                  numeroPedido: 123,
                  items: [
                    app_data.CartItem(
                        id: 'pci1',
                        product: app_data.Product(
                            id: '1',
                            name: 'Produto Exemplo 1',
                            price: 10.99,
                            categoryId: 'cat1',
                            categoryName: 'Exemplo',
                            displayOrder: 1,
                            isSoldOut: false),
                        quantity: 2),
                    app_data.CartItem(
                        id: 'pci2',
                        product: app_data.Product(
                            id: '2',
                            name: 'Produto 2 com nome longo',
                            price: 8.50,
                            categoryId: 'cat1',
                            categoryName: 'Exemplo',
                            displayOrder: 2,
                            isSoldOut: false),
                        quantity: 1,
                        selectedAdicionais: [
                          app_data.CartItemAdicional(
                              adicional: app_data.Adicional(
                                  id: 'ad1',
                                  name: 'Molho Extra',
                                  price: 2.0,
                                  displayOrder: 1),
                              quantity: 2)
                        ]),
                  ],
                  timestamp: DateTime.now(),
                  status: 'completed',
                  type: 'delivery',
                  deliveryInfo: sampleDeliveryInfo)
            ],
            tableNumber: 'ENTREGA',
            totalAmount: 34.48, // (10.99*2) + 8.50 + (2.0*2)
            settings: settings,
            deliveryInfo: sampleDeliveryInfo);

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
          buildStyleEditor(
            'Informações do Delivery',
            settings.deliveryInfoStyle,
            (newStyle) =>
                _autoSaveSettings(settings.copyWith(deliveryInfoStyle: newStyle)),
          ),
          buildStyleEditor(
            'Itens do Pedido',
            settings.itemStyle,
            (newStyle) =>
                _autoSaveSettings(settings.copyWith(itemStyle: newStyle)),
          ),
          buildStyleEditor(
            'Texto do Total',
            settings.totalStyle,
            (newStyle) =>
                _autoSaveSettings(settings.copyWith(totalStyle: newStyle)),
          ),
          if (!(MediaQuery.of(context).size.width > 800))
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
            if (settings.logoPath != null &&
                settings.logoPath!.isNotEmpty &&
                File(settings.logoPath!).existsSync())
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Image.file(
                    File(settings.logoPath!),
                    key: UniqueKey(),
                    height: 80,
                    errorBuilder: (c, e, s) =>
                        const Icon(Icons.error, color: Colors.red, size: 40),
                  ),
                ),
              ),
            Center(
              child: ElevatedButton.icon(
                onPressed: () =>
                    Provider.of<PrinterProvider>(context, listen: false)
                        .pickAndSaveLogo(),
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
                Provider.of<PrinterProvider>(context, listen: false)
                    .updateLogoHeight(value);
              },
              onChangeEnd: (value) {
                _autoSaveSettings(settings.copyWith(logoHeight: value));
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
                selected: {settings.logoAlignment},
                onSelectionChanged: (newSelection) {
                  Provider.of<PrinterProvider>(context, listen: false)
                      .updateReceiptLogoAlignment(newSelection.first);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoEditor(ReceiptTemplateSettings settings) {
    final company =
        Provider.of<CompanyProvider>(context, listen: false).currentCompany;

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
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (company != null)
                  Tooltip(
                    message: 'Preencher com os dados cadastrados',
                    child: IconButton(
                      icon: const Icon(Icons.storefront),
                      onPressed: () {
                        final newSettings = settings.copyWith(
                          subtitleText: 'CNPJ: ${company.cnpj ?? ''}',
                          addressText:
                              '${company.rua ?? ''}, ${company.numero ?? ''}, ${company.bairro ?? ''}',
                          phoneText: 'Tel: ${company.telefone ?? ''}',
                        );
                        Provider.of<PrinterProvider>(context, listen: false)
                            .saveReceiptTemplateSettings(newSettings);
                      },
                    ),
                  ),
              ],
            ),
            const Divider(),
            buildTextAndStyleEditor(
              'Subtítulo (CNPJ)',
              settings.subtitleText,
              (newText) =>
                  _autoSaveSettings(settings.copyWith(subtitleText: newText)),
              settings.subtitleStyle,
              (newStyle) => _autoSaveSettings(
                  settings.copyWith(subtitleStyle: newStyle)),
            ),
            buildTextAndStyleEditor(
              'Endereço',
              settings.addressText,
              (newText) =>
                  _autoSaveSettings(settings.copyWith(addressText: newText)),
              settings.addressStyle,
              (newStyle) =>
                  _autoSaveSettings(settings.copyWith(addressStyle: newStyle)),
            ),
            buildTextAndStyleEditor(
              'Telefone',
              settings.phoneText,
              (newText) =>
                  _autoSaveSettings(settings.copyWith(phoneText: newText)),
              settings.phoneStyle,
              (newStyle) =>
                  _autoSaveSettings(settings.copyWith(phoneStyle: newStyle)),
            ),
            buildTextAndStyleEditor(
              'Mensagem Final',
              settings.finalMessageText,
              (newText) => _autoSaveSettings(
                  settings.copyWith(finalMessageText: newText)),
              settings.finalMessageStyle,
              (newStyle) => _autoSaveSettings(
                  settings.copyWith(finalMessageStyle: newStyle)),
            ),
          ],
        ),
      ),
    );
  }
}