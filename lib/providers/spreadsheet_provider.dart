import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;

class SpreadsheetProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;
  int _rows = 5;
  int _cols = 5;

  List<List<TextEditingController>> _controllers = [];
  List<List<FocusNode>> _focusNodes = [];
  List<app_data.CustomSpreadsheet> _savedSheets = [];
  int? _currentSheetId;
  
  Set<String> checkedCells = {};
  String? activeCellKey;
  Map<String, String> _formulas = {};

  bool get isLoading => _isLoading;
  int get rows => _rows;
  int get cols => _cols;
  List<List<TextEditingController>> get controllers => _controllers;
  List<List<FocusNode>> get focusNodes => _focusNodes;
  List<app_data.CustomSpreadsheet> get savedSheets => _savedSheets;
  int? get currentSheetId => _currentSheetId;

  SpreadsheetProvider() {
    _initializeNodes();
  }

  void _initializeNodes() {
    _focusNodes = List.generate(_rows, (r) => List.generate(_cols, (c) => FocusNode()));
    _controllers = List.generate(
      _rows, (r) => List.generate(
        _cols, (c) => TextEditingController(),
      ),
    );
  }

  void addRow() {
    _rows++;
    _focusNodes.add(List.generate(_cols, (c) => FocusNode()));
    _controllers.add(
      List.generate(_cols, (c) => TextEditingController()),
    );
    notifyListeners();
  }

  void addColumn() {
    _cols++;
    for (int i = 0; i < _rows; i++) {
      _focusNodes[i].add(FocusNode());
      _controllers[i].add(TextEditingController());
    }
    notifyListeners();
  }

  Future<bool> importTransactions(DateTime start, DateTime end) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase
          .from('transacoes')
          .select()
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String())
          .order('created_at', ascending: true);
      
      final transactions = (response as List)
          .map((json) => app_data.Transaction.fromJson(json))
          .toList();

      if (transactions.isEmpty) return false;
      
      clearSheet();
      
      final headers = ['ID', 'Mesa', 'Total', 'Pagamento', 'Desconto', 'Taxa', 'Data'];
      for (int i = 0; i < headers.length; i++) {
        if (i >= _cols) addColumn();
        _controllers[0][i].text = headers[i];
      }

      for (int i = 0; i < transactions.length; i++) {
        final r = i + 1;
        if (r >= _rows) addRow();
        final transaction = transactions[i];
        if (7 > _cols) {
          int neededCols = 7 - _cols;
          for(int j = 0; j < neededCols; j++) { addColumn(); }
        }
        _controllers[r][0].text = transaction.id.toString();
        _controllers[r][1].text = transaction.tableNumber.toString();
        _controllers[r][2].text = transaction.totalAmount.toStringAsFixed(2);
        _controllers[r][3].text = transaction.paymentMethod;
        _controllers[r][4].text = transaction.discount.toStringAsFixed(2);
        _controllers[r][5].text = transaction.surcharge.toStringAsFixed(2);
        _controllers[r][6].text = DateFormat('dd/MM/yy HH:mm').format(transaction.timestamp);
      }
      return true;
    } catch (e) {
      debugPrint('Erro ao importar transações: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void moveFocus(int r, int c, LogicalKeyboardKey key) {
    int nextR = r, nextC = c;
    if (key == LogicalKeyboardKey.arrowDown && r < _rows - 1) nextR++;
    if (key == LogicalKeyboardKey.arrowUp && r > 0) nextR--;
    if (key == LogicalKeyboardKey.arrowRight && c < _cols - 1) nextC++;
    if (key == LogicalKeyboardKey.arrowLeft && c > 0) nextC--;
    
    _focusNodes[nextR][nextC].requestFocus();
    setActiveCell(nextR, nextC);
  }

  void onCellSubmitted(int r, int c) {
    final text = _controllers[r][c].text.toUpperCase();
    final key = "$r,$c";

    if (text.startsWith('=')) {
      if (text == '=SOMA' || text == '=SUM') {
        _calculateCheckboxSum(_controllers[r][c]);
      } else {
        _formulas[key] = _controllers[r][c].text;
        _recalculateAllFormulas();
      }
    } else {
      _formulas.remove(key);
      _recalculateAllFormulas();
    }
  }

  void _recalculateAllFormulas() {
    _formulas.forEach((key, formula) {
      final parts = key.split(',');
      final r = int.parse(parts[0]);
      final c = int.parse(parts[1]);
      final result = _executeFormula(formula, {key});
      if (_controllers[r][c].text != result) {
        _controllers[r][c].text = result;
      }
    });
    notifyListeners();
  }

  void _calculateCheckboxSum(TextEditingController controller) {
    double sum = 0.0;
    for (final key in checkedCells) {
      final parts = key.split(',');
      final rChecked = int.parse(parts[0]);
      final cChecked = int.parse(parts[1]);
      final textValue = _controllers[rChecked][cChecked].text.replaceAll(',', '.');
      sum += double.tryParse(textValue) ?? 0.0;
    }
    controller.text = sum.toStringAsFixed(2);
    checkedCells.clear();
    notifyListeners();
  }
  
  double? _resolveArgument(String arg, Set<String> visited) {
    final cellIndex = _cellNameToIndex(arg);
    if (cellIndex != null) {
      final r = cellIndex['r']!;
      final c = cellIndex['c']!;
      final key = "$r,$c";
      if (visited.contains(key)) return null; 
      visited.add(key);
      final cellContent = _controllers[r][c].text.replaceAll(',', '.');
      if (cellContent.startsWith('=')) {
        return double.tryParse(_executeFormula(cellContent, visited));
      } else {
        return double.tryParse(cellContent);
      }
    }
    return double.tryParse(arg.replaceAll(',', '.'));
  }

  String _executeFormula(String formula, Set<String> visited) {
    try {
      final upperFormula = formula.toUpperCase();
      final match = RegExp(r'=(SUM|SUB|MULT|DIV)\(([^)]+)\)').firstMatch(upperFormula);
      if (match == null) return '#NAME?';

      final func = match.group(1);
      final argsString = match.group(2);
      if (argsString == null) return '#ARGS!';
      
      final args = argsString.split(',');
      if (func != 'SUM' && args.length != 2) return '#ARGS!';

      final values = args.map((arg) => _resolveArgument(arg.trim(), visited)).toList();
      if (values.contains(null)) return '#REF!';
      final doubleArgs = values.map((v) => v!).toList();

      switch (func) {
        case 'SUM':
          if (doubleArgs.isEmpty) return '0.00';
          return doubleArgs.reduce((a, b) => a + b).toStringAsFixed(2);
        case 'SUB': return (doubleArgs[0] - doubleArgs[1]).toStringAsFixed(2);
        case 'MULT': return (doubleArgs[0] * doubleArgs[1]).toStringAsFixed(2);
        case 'DIV':
          if (doubleArgs[1] == 0) return '#DIV/0!';
          return (doubleArgs[0] / doubleArgs[1]).toStringAsFixed(2);
        default: return '#NAME?';
      }
    } catch (e) {
      return '#ERROR!';
    }
  }

  Map<String, int>? _cellNameToIndex(String cellName) {
    final match = RegExp(r'^([A-Z]+)([0-9]+)$').firstMatch(cellName.toUpperCase());
    if (match == null) return null;
    final colStr = match.group(1)!;
    final rowStr = match.group(2)!;
    int c = colStr.codeUnitAt(0) - 'A'.codeUnitAt(0);
    int r = int.parse(rowStr) - 1;
    if (r < 0 || r >= _rows || c < 0 || c >= _cols) return null;
    return {'r': r, 'c': c};
  }

  void setActiveCell(int r, int c) {
    activeCellKey = "$r,$c";
    notifyListeners();
  }

  void toggleCheckbox(int r, int c) {
    final key = "$r,$c";
    if (checkedCells.contains(key)) {
      checkedCells.remove(key);
    } else {
      checkedCells.add(key);
    }
    notifyListeners();
  }

  void clearSheet() {
    _rows = 5;
    _cols = 5;
    _initializeNodes();
    activeCellKey = null;
    _currentSheetId = null;
    notifyListeners();
  }

  Future<void> fetchSavedSheets() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase.from('custom_spreadsheets').select().order('created_at', ascending: false);
      _savedSheets = (response as List).map((json) => app_data.CustomSpreadsheet.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Erro ao buscar planilhas salvas: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSheet(int sheetId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase.from('custom_spreadsheets').select().eq('id', sheetId).single();
      final sheet = app_data.CustomSpreadsheet.fromJson(response);
      clearSheet();
      _currentSheetId = sheet.id;
      for (int r = 0; r < sheet.sheetData.length && r < _rows; r++) {
        for (int c = 0; c < sheet.sheetData[r].length && c < _cols; c++) {
          _controllers[r][c].text = sheet.sheetData[r][c];
        }
      }
      _recalculateAllFormulas();
    } catch (e) {
      debugPrint('Erro ao carregar planilha: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveSheet(String name) async {
    _isLoading = true;
    notifyListeners();
    bool success = false;
    try {
      List<List<String>> sheetData = _controllers.map((row) => row.map((controller) {
        final key = "${_controllers.indexOf(row)},${row.indexOf(controller)}";
        return _formulas[key] ?? controller.text;
      }).toList()).toList();
      
      // MUDANÇA PRINCIPAL AQUI: REMOVIDO O jsonEncode
      final dataToSave = {'name': name, 'sheet_data': sheetData};
      
      if (_currentSheetId == null) {
        final response = await _supabase.from('custom_spreadsheets').insert(dataToSave).select().single();
        _currentSheetId = response['id'];
      } else {
        await _supabase.from('custom_spreadsheets').update(dataToSave).eq('id', _currentSheetId!);
      }
      success = true;
    } catch (e) {
      debugPrint('Erro ao salvar planilha: $e');
      success = false;
    } finally {
      if (success) await fetchSavedSheets();
      _isLoading = false;
      notifyListeners();
    }
    return success;
  }
}