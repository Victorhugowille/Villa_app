// lib/providers/transaction_provider.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/app_data.dart' as app_data;
import 'package:collection/collection.dart';
import 'auth_provider.dart';

class TransactionProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  AuthProvider? _authProvider;
  List<app_data.Transaction> _transactions = [];
  bool isLoading = false;

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  List<app_data.Transaction> get transactions => _transactions;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;

  TransactionProvider(this._authProvider);

  void updateAuthProvider(AuthProvider newAuthProvider) {
    final oldCompanyId = _authProvider?.companyId;
    _authProvider = newAuthProvider;
    final newCompanyId = newAuthProvider.companyId;

    if (newCompanyId != null && newCompanyId != oldCompanyId) {
      fetchDailyTransactions();
    }
  }

  String? _getCompanyId() {
    return _authProvider?.companyId;
  }

  double get totalRevenue {
    return _transactions.fold(0.0, (sum, item) => sum + item.totalAmount);
  }

  Map<String, double> get revenueByPaymentMethod {
    return groupBy(_transactions, (t) => t.paymentMethod).map((key, value) =>
        MapEntry(key, value.fold(0.0, (sum, item) => sum + item.totalAmount)));
  }

  Map<DateTime, double> get dailyRevenue {
    return groupBy(_transactions,
            (t) => DateTime(t.timestamp.year, t.timestamp.month, t.timestamp.day))
        .map((key, value) => MapEntry(
            key, value.fold(0.0, (sum, item) => sum + item.totalAmount)))
        .entries
        .sortedBy((entry) => entry.key)
        .fold(
            {}, (previousValue, element) => previousValue..[element.key] = element.value);
  }

  Future<void> fetchTransactionsByDateRange(DateTime start, DateTime end) async {
    final companyId = _getCompanyId();
    if (companyId == null) return;

    isLoading = true;
    _startDate = start;
    _endDate = end;
    notifyListeners();

    try {
      final startOfDay =
          DateTime(start.year, start.month, start.day).toIso8601String();
      final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59)
          .toIso8601String();

      final dataList = await _supabase
          .from('transacoes')
          .select()
          .eq('company_id', companyId)
          .gte('created_at', startOfDay)
          .lte('created_at', endOfDay)
          .order('created_at', ascending: false);

      _transactions = dataList.map((item) {
        try {
          return app_data.Transaction.fromJson(item);
        } catch (e) {
          debugPrint("Falha ao processar transação: $item. Erro: $e");
          return null;
        }
      }).whereType<app_data.Transaction>().toList();
      
    } catch (error) {
      debugPrint("Erro ao carregar transações: $error");
      _transactions = [];
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchDailyTransactions() async {
    final now = DateTime.now();
    await fetchTransactionsByDateRange(now, now);
  }
}