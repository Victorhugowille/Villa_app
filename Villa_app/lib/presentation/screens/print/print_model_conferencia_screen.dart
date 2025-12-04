import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../providers/printer_provider.dart';

class ConferencePrinterSettingsTab extends StatefulWidget {
  const ConferencePrinterSettingsTab({super.key});

  @override
  State<ConferencePrinterSettingsTab> createState() =>
      _ConferencePrinterSettingsTabState();
}

class _ConferencePrinterSettingsTabState
    extends State<ConferencePrinterSettingsTab> {
  List<Printer> _printers = [];
  Printer? _selectedPrinter;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    setState(() => _isLoading = true);
    try {
      final availablePrinters = await Printing.listPrinters();
      if (!mounted) return;
      final printerProvider = Provider.of<PrinterProvider>(context, listen: false);
      setState(() {
        _printers = availablePrinters;
        _selectedPrinter = printerProvider.conferencePrinter != null
            ? availablePrinters.firstWhereOrNull(
                (p) => p.url == printerProvider.conferencePrinter!.url)
            : null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao buscar impressoras: $e')));
      setState(() => _isLoading = false);
    }
  }

  void _saveConferencePrinter() {
    final printerProvider = Provider.of<PrinterProvider>(context, listen: false);
    printerProvider.saveConferencePrinter(_selectedPrinter);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('✅ Impressora de conferência salva!'),
      backgroundColor: Colors.green,
    ));
  }

  void _autoSaveStyle(dynamic newStyle, int styleType) {
    final printerProvider = Provider.of<PrinterProvider>(context, listen: false);
    final currentSettings = printerProvider.receiptTemplateSettings;

    late dynamic updatedSettings;
    switch (styleType) {
      case 0: // Header
        updatedSettings = currentSettings.copyWith(headerStyle: newStyle);
        break;
      case 1: // Subtitle (CNPJ)
        updatedSettings = currentSettings.copyWith(subtitleStyle: newStyle);
        break;
      case 2: // Address
        updatedSettings = currentSettings.copyWith(addressStyle: newStyle);
        break;
      case 3: // Phone
        updatedSettings = currentSettings.copyWith(phoneStyle: newStyle);
        break;
      case 4: // Items
        updatedSettings = currentSettings.copyWith(itemStyle: newStyle);
        break;
      case 5: // Total
        updatedSettings = currentSettings.copyWith(totalStyle: newStyle);
        break;
      case 6: // Final Message
        updatedSettings = currentSettings.copyWith(finalMessageStyle: newStyle);
        break;
    }

    printerProvider.saveReceiptTemplateSettings(updatedSettings);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Consumer<PrinterProvider>(
      builder: (context, printerProvider, child) {
        final receiptSettings = printerProvider.receiptTemplateSettings;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== SELEÇÃO DE IMPRESSORA =====
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Impressora para Conferência',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      const Text(
                          'Selecione a impressora para imprimir conferência (conta). Impressão será feita direto, sem diálogo.'),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Printer>(
                        value: _selectedPrinter,
                        items: _printers
                            .map<DropdownMenuItem<Printer>>((Printer printer) {
                          return DropdownMenuItem<Printer>(
                            value: printer,
                            child: Text(printer.name),
                          );
                        }).toList(),
                        onChanged: (Printer? newValue) {
                          setState(() {
                            _selectedPrinter = newValue;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Selecione uma impressora',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveConferencePrinter,
                          style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16)),
                          child: const Text('Salvar Impressora'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ===== ESTILOS DE TEXTO DO RECIBO =====
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Estilos de Impressão do Recibo',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      const Text(
                          'Customize o tamanho, negrito e alinhamento do recibo:'),
                      const Divider(),
                      _buildStyleEditor(
                          'Cabeçalho (Nome da Empresa)',
                          receiptSettings.headerStyle,
                          0),
                      _buildStyleEditor('CNPJ/Documento',
                          receiptSettings.subtitleStyle, 1),
                      _buildStyleEditor(
                          'Endereço', receiptSettings.addressStyle, 2),
                      _buildStyleEditor(
                          'Telefone', receiptSettings.phoneStyle, 3),
                      _buildStyleEditor('Items do Pedido',
                          receiptSettings.itemStyle, 4),
                      _buildStyleEditor(
                          'Total', receiptSettings.totalStyle, 5),
                      _buildStyleEditor('Mensagem Final',
                          receiptSettings.finalMessageStyle, 6),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStyleEditor(String title, dynamic style, int styleType) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildStyleControls(style, styleType),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleControls(dynamic style, int styleType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tamanho da Fonte
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tamanho da Fonte'),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  onPressed: () => _autoSaveStyle(
                      style.copyWith(
                          fontSize: (style.fontSize - 1).clamp(6.0, 30.0)),
                      styleType),
                ),
                Text(style.fontSize.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 12)),
                IconButton(
                  icon: const Icon(Icons.add),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  onPressed: () => _autoSaveStyle(
                      style.copyWith(
                          fontSize: (style.fontSize + 1).clamp(6.0, 30.0)),
                      styleType),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Negrito
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Negrito'),
            Switch(
              value: style.isBold,
              onChanged: (isBold) =>
                  _autoSaveStyle(style.copyWith(isBold: isBold), styleType),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Alinhamento
        const Text('Alinhamento', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 6),
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
          onSelectionChanged: (newSelection) => _autoSaveStyle(
              style.copyWith(alignment: newSelection.first), styleType),
        ),
      ],
    );
  }
}