import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:villabistromobile/data/app_data.dart';
import 'package:villabistromobile/providers/navigation_provider.dart';
import 'package:villabistromobile/providers/printer_provider.dart';
import 'package:villabistromobile/providers/product_provider.dart';
import 'package:villabistromobile/screens/print_layout_editor_screen.dart';
import 'package:villabistromobile/screens/receipt_layout_editor_screen.dart';
import 'package:villabistromobile/widgets/custom_app_bar.dart';

class PrinterModelScreen extends StatefulWidget {
  const PrinterModelScreen({super.key});

  @override
  State<PrinterModelScreen> createState() => _PrinterModelScreenState();
}

class _PrinterModelScreenState extends State<PrinterModelScreen> {
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
      if (mounted) {
        final providerSettings =
            Provider.of<PrinterProvider>(context, listen: false)
                .categoryPrinterSettings;

        setState(() {
          _printers = loadedPrinters;
          _currentSettings = Map<int, Map<String, String>>.from(
              providerSettings.map(
                  (key, value) => MapEntry(key, Map<String, String>.from(value))));
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
    final printerProvider = Provider.of<PrinterProvider>(context, listen: false);
    final nav = Provider.of<NavigationProvider>(context, listen: false);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    printerProvider.saveSettings(_currentSettings);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Configurações salvas!'),
      backgroundColor: Colors.green,
    ));

    if (isDesktop) {
      nav.pop();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _navigateToLayoutEditor(Widget screen) {
    final nav = Provider.of<NavigationProvider>(context, listen: false);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    if (isDesktop) {
      nav.push(screen);
    } else {
       Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => screen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = Provider.of<ProductProvider>(context).categories;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Modelos de Impressão',
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit_document),
                    label: const Text('Editar Layout da Impressão da Cozinha'),
                    onPressed: () => _navigateToLayoutEditor(const PrintLayoutEditorScreen()),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Editar Layout da Impressão de Conferência'),
                    onPressed: () => _navigateToLayoutEditor(const ReceiptLayoutEditorScreen()),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final Category category = categories[index];
                      final settings = _currentSettings[category.id] ?? {};
                      final selectedPrinterName = settings['name'];
                      final selectedSize = settings['size'] ?? '58';
            
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(category.name,
                                  style:
                                      const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Impressora:'),
                                  DropdownButton<String>(
                                    hint: const Text('Nenhuma'),
                                    value: selectedPrinterName,
                                    items: _printers.map((Printer printer) {
                                      return DropdownMenuItem<String>(
                                        value: printer.name,
                                        child: Text(printer.name,
                                            overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
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
            ],
          ),
    );
  }
}