// lib/providers/report_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

class ReportProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<List<app_data.Transaction>> fetchTransactionsForDateRange(DateTime start, DateTime end) async {
    try {
      final response = await _supabase
          .from('transacoes')
          .select()
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String())
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => app_data.Transaction.fromJson(json))
          .toList();

    } catch (e) {
      debugPrint('Erro ao buscar transações: $e');
      return [];
    }
  }

  Future<String?> generateExcelReport(List<app_data.Transaction> transactions) async {
    _isLoading = true;
    notifyListeners();

    try {
      final excel = Excel.createExcel();
      final Sheet sheet = excel[excel.getDefaultSheet()!];

      final headers = [
        TextCellValue('ID Transação'),
        TextCellValue('Nº Mesa'),
        TextCellValue('Valor Total'),
        TextCellValue('Método Pag.'),
        TextCellValue('Desconto'),
        TextCellValue('Taxa'),
        TextCellValue('Data e Hora')
      ];
      sheet.appendRow(headers);

      final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');

      for (final transaction in transactions) {
        final row = [
          TextCellValue(transaction.id),
          IntCellValue(transaction.tableNumber),
          DoubleCellValue(transaction.totalAmount),
          TextCellValue(transaction.paymentMethod),
          DoubleCellValue(transaction.discount),
          DoubleCellValue(transaction.surcharge),
          TextCellValue(formatter.format(transaction.timestamp.toLocal())),
        ];
        sheet.appendRow(row);
      }

      final Directory? directory = await getTemporaryDirectory();
      if (directory == null) {
        throw Exception('Não foi possível acessar o diretório temporário.');
      }
      
      final String filePath = '${directory.path}/relatorio_villabistro_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final fileBytes = excel.save();
      
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        return filePath;
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao gerar Excel: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}