// lib/providers/table_provider.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;

class TableProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _tableMesa = 'mesas';

  List<app_data.Table> _tables = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<app_data.Table> get tables => _tables;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  TableProvider() {
    fetchAndSetTables();
  }

  Future<void> fetchAndSetTables() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final data = await _supabase.from(_tableMesa).select().order('numero', ascending: true);
      _tables = data.map((item) => app_data.Table.fromJson(item)).toList();
    } catch (error) {
      _errorMessage = "Erro ao buscar mesas: $error";
      _tables = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addTable(int tableNumber) async {
    try {
      final response = await _supabase.from(_tableMesa).insert({'numero': tableNumber}).select().single();
      _tables.add(app_data.Table.fromJson(response));
      _tables.sort((a, b) => a.tableNumber.compareTo(b.tableNumber));
      notifyListeners();
      return true;
    } catch (error) {
      debugPrint("Erro ao adicionar mesa: $error");
      return false;
    }
  }

  Future<bool> updateTable(String tableId, int newNumber) async {
    try {
      final response = await _supabase.from(_tableMesa).update({'numero': newNumber}).eq('id', tableId).select().single();
      final index = _tables.indexWhere((t) => t.id == tableId);
      if (index != -1) {
        _tables[index] = app_data.Table.fromJson(response);
        _tables.sort((a, b) => a.tableNumber.compareTo(b.tableNumber));
        notifyListeners();
      }
      return true;
    } catch (error) {
      debugPrint("Erro ao atualizar mesa: $error");
      return false;
    }
  }

  Future<bool> deleteTable(String tableId) async {
    final index = _tables.indexWhere((t) => t.id == tableId);
    if (index == -1) return false;

    final tableToRemove = _tables[index];
    _tables.removeAt(index);
    notifyListeners();

    try {
      await _supabase.from(_tableMesa).delete().eq('id', tableId);
      return true;
    } catch (error) {
      _tables.insert(index, tableToRemove);
      notifyListeners();
      debugPrint("Erro ao excluir mesa: $error");
      return false;
    }
  }

  Future<bool> updateStatus(String tableId, String newStatus) async {
    try {
      await _supabase.from(_tableMesa).update({'status': newStatus}).eq('id', tableId);
      final index = _tables.indexWhere((t) => t.id == tableId);
      if (index != -1) {
        final updatedTable = app_data.Table(
            id: _tables[index].id,
            tableNumber: _tables[index].tableNumber,
            isOccupied: newStatus == 'ocupada');
        _tables[index] = updatedTable;
        notifyListeners();
      }
      return true;
    } catch (error) {
      debugPrint("Erro ao atualizar status da mesa: $error");
      return false;
    }
  }

  Future<bool> placeOrder({required String tableId, required List<app_data.CartItem> items}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint("Erro: Usuário não autenticado para fazer pedido.");
      return false;
    }

    try {
      final orderResponse = await _supabase
          .from('pedidos')
          .insert({
            'mesa_id': tableId, 
            'status': 'production', 
            'type': 'mesa',
            'user_id': userId,
          })
          .select()
          .single();
      final orderId = orderResponse['id'];

      final itemsToInsert = items
          .map((cartItem) => {
                'pedido_id': orderId,
                'produto_id': cartItem.product.id,
                'quantidade': cartItem.quantity,
              })
          .toList();

      await _supabase.from('itens_pedido').insert(itemsToInsert);
      await updateStatus(tableId, 'ocupada');
      return true;
    } catch (error) {
      debugPrint("Erro ao fazer pedido: $error");
      return false;
    }
  }

  Future<List<app_data.Order>> getOrdersForTable(String tableId) async {
    try {
      final response = await _supabase
          .from('pedidos')
          .select('*, itens_pedido(*, produtos(*, categorias(name)))')
          .eq('mesa_id', tableId)
          .neq('status', 'completed');

      return response.map((orderData) => app_data.Order.fromJson(orderData)).toList();
    } catch (error) {
      debugPrint("Erro ao buscar pedidos: $error");
      return [];
    }
  }

  Future<bool> clearTable(String tableId) async {
    try {
      await _supabase
          .from('pedidos')
          .delete()
          .eq('mesa_id', tableId)
          .neq('status', 'completed');

      await updateStatus(tableId, 'livre');
      return true;
    } catch (error) {
      debugPrint("Erro ao limpar a mesa: $error");
      return false;
    }
  }

  Future<bool> deleteOrder(String orderId) async {
    try {
      await _supabase.from('pedidos').delete().eq('id', orderId);
      return true;
    } catch (error) {
      debugPrint("Erro ao deletar pedido: $error");
      return false;
    }
  }

  Future<bool> closeAccount({
    required app_data.Table table,
    required double totalAmount,
    required String paymentMethod,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint("Erro: Usuário não autenticado para fechar a conta.");
      return false;
    }
    
    try {
      final transactionResponse = await _supabase.from('transacoes').insert({
        'table_number': table.tableNumber,
        'total_amount': totalAmount,
        'payment_method': paymentMethod,
        'user_id': userId,
      }).select().single();

      final transactionId = transactionResponse['id'];
      
      await _supabase
          .from('pedidos')
          .update({
            'status': 'completed',
            'transaction_id': transactionId,
          })
          .eq('mesa_id', table.id)
          .neq('status', 'completed');

      await updateStatus(table.id, 'livre');
      return true;
    } catch (error) {
      debugPrint("Erro ao fechar conta: $error");
      return false;
    }
  }
}