import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;
import 'package:villabistromobile/providers/report_provider.dart';

class SavedReportProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;
  List<app_data.SavedReport> _savedReports = [];

  bool get isLoading => _isLoading;
  List<app_data.SavedReport> get savedReports => _savedReports;

  Future<void> fetchSavedReports() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase
          .from('saved_reports')
          .select()
          .order('created_at', ascending: false);
      _savedReports = (response as List)
          .map((json) => app_data.SavedReport.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Erro ao buscar relatórios salvos: $e');
      _savedReports = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> createAndSaveReport({
    required String name,
    required ReportProvider reportProvider,
    required List<app_data.Transaction> transactions,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final filePath = await reportProvider.generateExcelReport(transactions);
      if (filePath != null) {
        await _supabase.from('saved_reports').insert({'name': name});
        await fetchSavedReports();
        return filePath;
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao criar e salvar relatório: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}