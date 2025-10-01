import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;
import 'package:collection/collection.dart';

class TransactionProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<app_data.Transaction> _transactions = [];
  bool isLoading = false;
  
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  List<app_data.Transaction> get transactions => _transactions;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;

  double get totalRevenue {
    return _transactions.fold(0.0, (sum, item) => sum + item.totalAmount);
  }

  Map<String, double> get revenueByPaymentMethod {
    return groupBy(_transactions, (t) => t.paymentMethod)
        .map((key, value) => MapEntry(key, value.fold(0.0, (sum, item) => sum + item.totalAmount)));
  }

  Map<DateTime, double> get dailyRevenue {
    return groupBy(_transactions, (t) => DateTime(t.timestamp.year, t.timestamp.month, t.timestamp.day))
        .map((key, value) => MapEntry(key, value.fold(0.0, (sum, item) => sum + item.totalAmount)))
        .entries
        .sortedBy((entry) => entry.key)
        .fold({}, (previousValue, element) => previousValue..[element.key] = element.value);
  }

  Future<void> fetchTransactionsByDateRange(DateTime start, DateTime end) async {
    isLoading = true;
    _startDate = start;
    _endDate = end;
    notifyListeners();

    try {
      final startOfDay = DateTime(start.year, start.month, start.day).toIso8601String();
      final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();

      final dataList = await _supabase
          .from('transacoes')
          .select()
          .gte('created_at', startOfDay)
          .lte('created_at', endOfDay)
          .order('created_at', ascending: false);

      _transactions = dataList.map((item) => app_data.Transaction.fromJson(item)).toList();
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