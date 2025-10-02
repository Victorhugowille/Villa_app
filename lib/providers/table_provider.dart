import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;
import 'package:villabistromobile/providers/auth_provider.dart';

class TableProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  AuthProvider? _authProvider;
  final String _tableMesa = 'mesas';

  List<app_data.Table> _tables = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<app_data.Table> get tables => _tables;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  TableProvider(this._authProvider) {
    if (_authProvider?.companyId != null) {
      fetchAndSetTables();
    }
  }

  void updateAuthProvider(AuthProvider newAuthProvider) {
    final oldCompanyId = _authProvider?.companyId;
    _authProvider = newAuthProvider;
    final newCompanyId = newAuthProvider.companyId;

    if (newCompanyId != null && newCompanyId != oldCompanyId) {
      fetchAndSetTables();
    }
  }

  String? _getCompanyId() {
    return _authProvider?.companyId;
  }

  Future<void> fetchAndSetTables() async {
    final companyId = _getCompanyId();
    if (companyId == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final data = await _supabase
          .from(_tableMesa)
          .select()
          .eq('company_id', companyId)
          .order('numero', ascending: true);
      _tables = data.map((item) => app_data.Table.fromJson(item)).toList();
    } catch (error) {
      _errorMessage = "Erro ao buscar mesas: $error";
      _tables = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addNextTable({int maxRetries = 3}) async {
    final companyId = _getCompanyId();
    if (companyId == null) throw Exception('Empresa não encontrada.');

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final response = await _supabase
            .from(_tableMesa)
            .select('numero')
            .eq('company_id', companyId)
            .order('numero', ascending: false)
            .limit(1)
            .maybeSingle();

        int nextNumber = 1;
        if (response != null && response['numero'] != null) {
          nextNumber = (response['numero'] as int) + 1;
        }

        await _supabase
            .from(_tableMesa)
            .insert({'numero': nextNumber, 'company_id': companyId});

        await fetchAndSetTables();
        return; // Sucesso, sai da função.

      } on PostgrestException catch (error) {
        if (error.code == '23505' && attempt < maxRetries - 1) {
          await Future.delayed(const Duration(milliseconds: 100)); // Espera antes de tentar de novo
          continue; // Tenta o loop novamente
        }
        rethrow;
      } catch (error) {
        rethrow;
      }
    }
    throw Exception('Não foi possível adicionar a mesa após $maxRetries tentativas.');
  }

  Future<void> updateTable(String tableId, int newNumber) async {
    await _supabase
        .from(_tableMesa)
        .update({'numero': newNumber})
        .eq('id', tableId);
    await fetchAndSetTables();
  }

  Future<void> deleteHighestTable() async {
    final companyId = _getCompanyId();
    if (companyId == null) throw Exception('Empresa não encontrada.');

    final response = await _supabase
        .from(_tableMesa)
        .select('id, numero, status')
        .eq('company_id', companyId)
        .order('numero', ascending: false)
        .limit(1)
        .maybeSingle();
    
    if (response == null) {
      throw Exception('Não há mesas para excluir.');
    }

    if (response['status'] == 'ocupada') {
      throw Exception('A mesa de maior número (Mesa ${response['numero']}) está ocupada e não pode ser excluída.');
    }

    await _supabase.from(_tableMesa).delete().eq('id', response['id']);
    await fetchAndSetTables();
  }

  Future<void> updateStatus(String tableId, String newStatus) async {
    await _supabase
        .from(_tableMesa)
        .update({'status': newStatus})
        .eq('id', tableId);
    await fetchAndSetTables();
  }

  Future<void> placeOrder(
      {required String tableId, required List<app_data.CartItem> items}) async {
    final companyId = _getCompanyId();
    if (companyId == null) throw Exception('Empresa não encontrada.');

    final orderResponse = await _supabase
        .from('pedidos')
        .insert({
          'mesa_id': tableId,
          'status': 'awaiting_print',
          'type': 'mesa',
          'company_id': companyId,
        })
        .select()
        .single();
    final orderId = orderResponse['id'];

    final itemsToInsert = items
        .map((cartItem) => {
              'pedido_id': orderId,
              'produto_id': cartItem.product!.id,
              'quantidade': cartItem.quantity,
            })
        .toList();

    await _supabase.from('itens_pedido').insert(itemsToInsert);
    await updateStatus(tableId, 'ocupada');
  }

  Future<List<app_data.Order>> getOrdersForTable(String tableId) async {
    final companyId = _getCompanyId();
    if (companyId == null) return [];

    try {
      final response = await _supabase
          .from('pedidos')
          .select('*, itens_pedido!inner(*, produtos!inner(*, categorias(name)))')
          .eq('mesa_id', tableId)
          .eq('company_id', companyId)
          .neq('status', 'completed');

      return response
          .map((orderData) => app_data.Order.fromJson(orderData))
          .toList();
    } catch (error) {
      debugPrint("Erro ao buscar pedidos: $error");
      return [];
    }
  }

  Future<void> clearTable(String tableId) async {
    final companyId = _getCompanyId();
    if (companyId == null) return;
    
    await _supabase
        .from('pedidos')
        .delete()
        .eq('mesa_id', tableId)
        .eq('company_id', companyId)
        .neq('status', 'completed');

    await updateStatus(tableId, 'livre');
  }

  Future<void> deleteOrder(String orderId) async {
    await _supabase.from('pedidos').delete().eq('id', orderId);
  }

  Future<void> closeAccount({
    required app_data.Table table,
    required double totalAmount,
    required String paymentMethod,
  }) async {
    final companyId = _getCompanyId();
    if (companyId == null) throw Exception('Empresa não encontrada.');

    final transactionResponse = await _supabase
        .from('transacoes')
        .insert({
          'table_number': table.tableNumber,
          'total_amount': totalAmount,
          'payment_method': paymentMethod,
          'company_id': companyId,
        })
        .select()
        .single();

    final transactionId = transactionResponse['id'];

    await _supabase
        .from('pedidos')
        .update({
          'status': 'completed',
          'transaction_id': transactionId,
        })
        .eq('mesa_id', table.id)
        .eq('company_id', companyId)
        .neq('status', 'completed');

    await updateStatus(table.id, 'livre');
  }
}