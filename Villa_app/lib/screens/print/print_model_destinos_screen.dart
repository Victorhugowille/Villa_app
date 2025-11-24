// lib/screens/print/print_model_destinos_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/app_data.dart' as app_data;
import '../../providers/printer_provider.dart';
import '../../providers/auth_provider.dart';

class CategoryPrinterSettingsTab extends StatefulWidget {
  const CategoryPrinterSettingsTab({super.key});

  @override
  State<CategoryPrinterSettingsTab> createState() =>
      _CategoryPrinterSettingsTabState();
}

class _CategoryPrinterSettingsTabState
    extends State<CategoryPrinterSettingsTab> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Printer> _printers = [];
  List<app_data.Category> _categories = [];
  bool _isLoading = true;

  Map<String, dynamic> _localPrinterSettings = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final companyId =
          Provider.of<AuthProvider>(context, listen: false).companyId;
      if (companyId == null) {
        throw Exception("ID da empresa não encontrado.");
      }

      // CORREÇÃO: Carregando dados sequencialmente para evitar erro de tipo.
      final printers = await Printing.listPrinters();
      final categoriesData = await _supabase
          .from('categorias')
          .select()
          .eq('company_id', companyId)
          .order('name', ascending: true);
      
      final categories = categoriesData.map((json) => app_data.Category.fromJson(json)).toList();

      final providerSettings = Provider.of<PrinterProvider>(context, listen: false).printerSettings;

      setState(() {
        _printers = printers;
        _categories = categories;
        _localPrinterSettings = Map<String, dynamic>.from(
          providerSettings.map(
            (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
          ),
        );
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    }
  }

  void _saveSettings() {
    Provider.of<PrinterProvider>(context, listen: false).savePrinterSettings(_localPrinterSettings);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Configurações salvas com sucesso!'),
      backgroundColor: Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_printers.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma impressora encontrada no sistema.\nVerifique se as impressoras estão instaladas.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _printers.length,
        itemBuilder: (context, index) {
          final printer = _printers[index];
          final settings = _localPrinterSettings[printer.name] ?? {'size': '58', 'categories': []};
          final paperSize = settings['size'] as String;
          final selectedCategories = List<String>.from(settings['categories']);

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              initiallyExpanded: false, // Inicia fechado
              title: Text(printer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Text('${selectedCategories.length} categorias selecionadas'),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tamanho do Papel:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: '58', label: Text('58 mm')),
                          ButtonSegment(value: '80', label: Text('80 mm')),
                        ],
                        selected: {paperSize},
                        onSelectionChanged: (newSelection) {
                          setState(() {
                             if (_localPrinterSettings[printer.name] == null) {
                                _localPrinterSettings[printer.name] = {'categories': []};
                              }
                            _localPrinterSettings[printer.name]['size'] = newSelection.first;
                          });
                        },
                      ),
                      const Divider(height: 24),
                      const Text('Categorias para esta Impressora:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ..._categories.map((category) {
                        return CheckboxListTile(
                          title: Text(category.name),
                          value: selectedCategories.contains(category.id),
                          onChanged: (bool? value) {
                            setState(() {
                              if (_localPrinterSettings[printer.name] == null) {
                                _localPrinterSettings[printer.name] = {'size': '58', 'categories': []};
                              }
                              final currentCategories = List<String>.from(_localPrinterSettings[printer.name]['categories']);
                              if (value == true) {
                                if (!currentCategories.contains(category.id)) {
                                  currentCategories.add(category.id);
                                }
                              } else {
                                currentCategories.remove(category.id);
                              }
                               _localPrinterSettings[printer.name]['categories'] = currentCategories;
                            });
                          },
                        );
                      }).toList(),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveSettings,
        label: const Text('Salvar Tudo'),
        icon: const Icon(Icons.save),
      ),
    );
  }
}