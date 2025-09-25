import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/providers/spreadsheet_provider.dart';
import 'package:villabistromobile/screens/saved_spreadsheets_list_screen.dart';

class ExcelGeneratorScreen extends StatefulWidget {
  const ExcelGeneratorScreen({super.key});

  @override
  State<ExcelGeneratorScreen> createState() => _ExcelGeneratorScreenState();
}

class _ExcelGeneratorScreenState extends State<ExcelGeneratorScreen> {
  final _nameController = TextEditingController();
  final ScrollController _headerScrollController = ScrollController();
  final List<ScrollController> _bodyScrollControllers = [];
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _headerScrollController.addListener(_syncHeaderScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncBodyControllers();
    });
  }
  
  void _syncBodyControllers() {
    final provider = context.read<SpreadsheetProvider>();
    if (_bodyScrollControllers.length != provider.rows) {
      _bodyScrollControllers.forEach((controller) => controller.dispose());
      _bodyScrollControllers.clear();
      for (int i = 0; i < provider.rows; i++) {
        final controller = ScrollController();
        controller.addListener(() => _syncBodyScroll(controller));
        _bodyScrollControllers.add(controller);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncBodyControllers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _headerScrollController.dispose();
    _bodyScrollControllers.forEach((controller) => controller.dispose());
    super.dispose();
  }
  
  void _syncHeaderScroll() {
    if (_isSyncing) return;
    _isSyncing = true;
    for (final controller in _bodyScrollControllers) {
      if (controller.hasClients && controller.offset != _headerScrollController.offset) {
        controller.jumpTo(_headerScrollController.offset);
      }
    }
    _isSyncing = false;
  }

  void _syncBodyScroll(ScrollController activeController) {
    if (_isSyncing) return;
    _isSyncing = true;
    if (_headerScrollController.hasClients && _headerScrollController.offset != activeController.offset) {
      _headerScrollController.jumpTo(activeController.offset);
    }
    for (final controller in _bodyScrollControllers) {
      if (controller != activeController && controller.hasClients && controller.offset != activeController.offset) {
        controller.jumpTo(activeController.offset);
      }
    }
    _isSyncing = false;
  }

  Future<void> _saveSheet() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, dê um nome ao arquivo.')));
      return;
    }
    final provider = context.read<SpreadsheetProvider>();
    final success = await provider.saveSheet(_nameController.text.trim());
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Arquivo salvo com sucesso!' : 'Erro ao salvar o arquivo.'),
        backgroundColor: success ? Colors.green : Colors.red,
      ));
      
      if (success) {
        _nameController.clear();
        provider.clearSheet();
      }
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ajuda de Fórmulas'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('SOMA COM CHECKBOX', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('1. Marque as caixas para selecionar as células.'),
                Text('2. Digite =SOMA em uma célula para ver o resultado.'),
                SizedBox(height: 16),
                Text('OPERAÇÕES BÁSICAS (2 valores)', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Soma: =SUM(A1,B1)'),
                Text('Subtração: =SUB(A1,B1)'),
                Text('Multiplicação: =MULT(A1,B1)'),
                Text('Divisão: =DIV(A1,B1)'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _importTransactions() async {
    final now = DateTime.now();
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
    );

    if (dateRange != null && mounted) {
      final provider = context.read<SpreadsheetProvider>();
      final success = await provider.importTransactions(dateRange.start, dateRange.end.add(const Duration(days: 1)));
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma transação encontrada no período selecionado.')),
        );
      } else if (success) {
        _nameController.text = 'Relatório de ${DateFormat('dd-MM-yy').format(dateRange.start)} a ${DateFormat('dd-MM-yy').format(dateRange.end)}';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SpreadsheetProvider>();
    if (provider.currentSheetId == null) _nameController.clear();
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildToolbar(provider),
            const SizedBox(height: 10),
            Expanded(child: _buildSpreadsheet(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(SpreadsheetProvider provider) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  labelText: 'Nome do Arquivo',
                  labelStyle: TextStyle(color: Colors.black54),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                ),
              ),
            ),
            IconButton(icon: const Icon(Icons.clear, color: Colors.red), onPressed: () => provider.clearSheet(), tooltip: 'Limpar / Novo Arquivo'),
            IconButton(icon: const Icon(Icons.save, color: Colors.blue), onPressed: _saveSheet, tooltip: 'Salvar Arquivo'),
          ],
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
               TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.teal),
                icon: const Icon(Icons.download_for_offline_outlined),
                label: const Text('Importar'),
                onPressed: _importTransactions,
              ),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                icon: const Icon(Icons.add_box_outlined),
                label: const Text('Linha'),
                onPressed: provider.addRow,
              ),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                icon: const Icon(Icons.add_to_photos_outlined),
                label: const Text('Coluna'),
                onPressed: provider.addColumn,
              ),
              IconButton(icon: const Icon(Icons.help_outline, color: Colors.orange), onPressed: () => _showHelpDialog(context), tooltip: 'Ajuda'),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                icon: const Icon(Icons.archive_outlined),
                label: const Text('Arquivos Salvos'),
                onPressed: () {
                  context.read<SpreadsheetProvider>().fetchSavedSheets();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SavedSpreadsheetsListScreen()));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpreadsheet(SpreadsheetProvider provider) {
    if (provider.isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        _buildHeaderRow(provider),
        Expanded(
          child: ListView.builder(
            itemCount: provider.rows,
            itemBuilder: (context, r) {
              return _buildDataRow(r, provider);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderRow(SpreadsheetProvider provider) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          SizedBox(width: 50, child: Center(child: Text('#', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)))),
          Expanded(
            child: ListView.builder(
              controller: _headerScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: provider.cols,
              itemBuilder: (context, c) {
                return SizedBox(
                  width: 150,
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + c),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
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

  Widget _buildDataRow(int r, SpreadsheetProvider provider) {
    if (_bodyScrollControllers.length <= r) {
      _syncBodyControllers();
    }
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Center(child: Text('${r + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
          ),
          Expanded(
            child: ListView.builder(
              controller: _bodyScrollControllers.length > r ? _bodyScrollControllers[r] : null,
              scrollDirection: Axis.horizontal,
              itemCount: provider.cols,
              itemBuilder: (context, c) {
                final key = "$r,$c";
                final isActive = provider.activeCellKey == key;
                return SizedBox(
                  width: 150,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: isActive ? 2 : 1),
                    ),
                    child: RawKeyboardListener(
                      focusNode: FocusNode(),
                      onKey: (event) {
                        if (event is RawKeyDownEvent) {
                          provider.moveFocus(r, c, event.logicalKey);
                        }
                      },
                      child: Row(
                        children: [
                          Checkbox(
                            value: provider.checkedCells.contains(key),
                            onChanged: (value) => provider.toggleCheckbox(r, c),
                            activeColor: Colors.black,
                            checkColor: Colors.white,
                          ),
                          Expanded(
                            child: TextField(
                              controller: provider.controllers[r][c],
                              focusNode: provider.focusNodes[r][c],
                              style: const TextStyle(color: Colors.black),
                              cursorColor: Colors.black,
                              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 4)),
                              onTap: () => provider.setActiveCell(r, c),
                              onSubmitted: (_) => provider.onCellSubmitted(r, c),
                            ),
                          ),
                        ],
                      ),
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