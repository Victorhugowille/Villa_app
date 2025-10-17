import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/providers/printer_provider.dart';

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
      content: Text('Impressora de conferência salva!'),
      backgroundColor: Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Impressora para Conferência',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
              'Selecione a impressora que será usada para imprimir a conferência da mesa (conta do cliente). A impressão será feita diretamente, sem abrir a caixa de diálogo.'),
          const SizedBox(height: 24),
          DropdownButtonFormField<Printer>(
            value: _selectedPrinter,
            items: _printers.map<DropdownMenuItem<Printer>>((Printer printer) {
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
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveConferencePrinter,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Salvar'),
            ),
          ),
        ],
      ),
    );
  }
}