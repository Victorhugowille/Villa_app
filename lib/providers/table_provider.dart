import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;
import 'package:villabistromobile/providers/auth_provider.dart';

class TableProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  AuthProvider? _authProvider;
  final String _tableMesa = 'mesas';

  String? _lastFetchedCompanyId;

  List<app_data.Table> _tables = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<app_data.Table> get tables => _tables;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  TableProvider(AuthProvider? authProvider) {
    _authProvider = authProvider;
    _lastFetchedCompanyId = _authProvider?.companyId;
    if (_authProvider?.companyId != null) {
      fetchAndSetTables();
    }
  }

  void updateAuthProvider(AuthProvider newAuthProvider) {
    _authProvider = newAuthProvider;
    final newCompanyId = newAuthProvider.companyId;

    if (newCompanyId != null && newCompanyId != _lastFetchedCompanyId) {
      fetchAndSetTables();
    }
  }

  String? _getCompanyId() {
    return _authProvider?.companyId;
  }

  String? _getUserId() {
    return _authProvider?.user?.id;
  }

  Future<void> fetchAndSetTables() async {
    if (!_isLoading) {
      _isLoading = true;
      notifyListeners();
    }

    final companyId = _getCompanyId();
    if (companyId == null) {
      _tables = [];
      _isLoading = false;
      _lastFetchedCompanyId = null;
      notifyListeners();
      return;
    }
    
    _lastFetchedCompanyId = companyId;

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
        return;
      } on PostgrestException catch (error) {
        if (error.code == '23505' && attempt < maxRetries - 1) {
          await Future.delayed(const Duration(milliseconds: 100));
          continue;
        }
        rethrow;
      } catch (error) {
        rethrow;
      }
    }
    throw Exception(
        'Não foi possível adicionar a mesa após $maxRetries tentativas.');
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
      throw Exception(
          'A mesa de maior número (Mesa ${response['numero']}) está ocupada e não pode ser excluída.');
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

    final itemsToInsert = items.map((cartItem) {
      final adicionaisJson = cartItem.selectedAdicionais.map((itemAd) {
        return {
          'adicional_id': itemAd.adicional.id,
          'quantity': itemAd.quantity,
          'adicional': {
            'id': itemAd.adicional.id,
            'name': itemAd.adicional.name,
            'price': itemAd.adicional.price,
          }
        };
      }).toList();

      return {
        'pedido_id': orderId,
        'produto_id': cartItem.product.id,
        'quantidade': cartItem.quantity,
        'adicionais_selecionados': adicionaisJson,
      };
    }).toList();

    await _supabase.from('itens_pedido').insert(itemsToInsert);
    await updateStatus(tableId, 'ocupada');
  }

  Future<List<app_data.Order>> getOrdersForTable(String tableId) async {
    final companyId = _getCompanyId();
    if (companyId == null) return [];

    try {
      final response = await _supabase
          .from('pedidos')
          .select(
              '*, itens_pedido(*, adicionais_selecionados, produtos(*, categorias(*))), mesas!inner(numero)')
          .eq('mesa_id', tableId)
          .eq('company_id', companyId)
          .neq('status', 'finalizado');

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

    final orders = await getOrdersForTable(tableId);
    final orderIds = orders.map((o) => o.id).toList();

    if (orderIds.isNotEmpty) {
      final filter = orderIds.map((id) => 'id.eq.$id').join(',');
      await _supabase
          .from('pedidos')
          .update({'status': 'finalizado'})
          .or(filter);
    }

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
    final userId = _getUserId();

    if (companyId == null) {
      throw Exception(
          'Empresa não encontrada. Não é possível salvar a transação.');
    }
    if (userId == null) {
      throw Exception(
          'Usuário não autenticado. Não é possível salvar a transação.');
    }

    final payload = {
      'table_number': table.tableNumber,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'company_id': companyId,
      'user_id': userId,
    };

    final transactionResponse = await _supabase
        .from('transacoes')
        .insert(payload)
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