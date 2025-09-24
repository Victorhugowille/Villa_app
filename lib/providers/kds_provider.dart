import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;
import 'package:villabistromobile/providers/navigation_provider.dart';
import 'package:villabistromobile/screens/payment_screen.dart';

enum KdsFilter { all, table, delivery }

class KdsProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _ordersChannel;
  RealtimeChannel? _orderItemsChannel;

  List<app_data.Order> _allOrders = [];
  KdsFilter _filter = KdsFilter.all;
  bool _isLoading = true;

  bool get isLoading => _isLoading;
  KdsFilter get filter => _filter;

  List<app_data.Order> get productionOrders {
    final filtered = _getFilteredOrders();
    return filtered.where((order) => order.status == 'production').toList()..sort((a,b) => a.timestamp.compareTo(b.timestamp));
  }

  List<app_data.Order> get readyOrders {
    final filtered = _getFilteredOrders();
    return filtered.where((order) => order.status == 'ready').toList()..sort((a,b) => a.timestamp.compareTo(b.timestamp));
  }
  
  List<app_data.Order> _getFilteredOrders() {
    switch (_filter) {
      case KdsFilter.table:
        return _allOrders.where((order) => order.type == 'mesa').toList();
      case KdsFilter.delivery:
        return _allOrders.where((order) => order.type == 'delivery').toList();
      case KdsFilter.all:
      default:
        return _allOrders;
    }
  }

  void setFilter(KdsFilter newFilter) {
    _filter = newFilter;
    notifyListeners();
  }

  Future<void> fetchOrders() async {
    _isLoading = true;
    try {
      final response = await _supabase
          .from('pedidos')
          .select('*, mesa_id(id, numero), itens_pedido(*, produtos(*))')
          .inFilter('status', ['production', 'ready']);

      _allOrders = (response as List).map((json) => app_data.Order.fromJson(json)).toList();
    } catch (e) {
      // Tratar erro
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void listenToOrders() {
    fetchOrders();

    _ordersChannel = _supabase.channel('public:pedidos');
    _ordersChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'pedidos',
      callback: (payload) => fetchOrders(),
    ).subscribe();
    
    _orderItemsChannel = _supabase.channel('public:itens_pedido');
    _orderItemsChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'itens_pedido',
      callback: (payload) => fetchOrders(),
    ).subscribe();
  }

  void stopListening() {
    if (_ordersChannel != null) {
      _supabase.removeChannel(_ordersChannel!);
      _ordersChannel = null;
    }
    if (_orderItemsChannel != null) {
      _supabase.removeChannel(_orderItemsChannel!);
      _orderItemsChannel = null;
    }
  }

  Future<void> advanceOrder(BuildContext context, app_data.Order order) async {
    String nextStatus = '';
    if (order.status == 'production') {
      nextStatus = 'ready';
    } else if (order.status == 'ready') {
      if (order.type == 'mesa') {
        final tableData = app_data.Table(
            id: order.tableId!,
            tableNumber: order.tableNumber!,
            isOccupied: true);
            
        final ordersForTable = _allOrders.where((o) => o.tableId == order.tableId).toList();
        final totalAmount = ordersForTable.fold(0.0, (sum, o) => sum + o.total);

        Provider.of<NavigationProvider>(context, listen: false).navigateTo(context, PaymentScreen(
          table: tableData, 
          totalAmount: totalAmount, 
          orders: ordersForTable
        ), 'Pagamento - Mesa ${tableData.tableNumber}');
        return;
      }
      nextStatus = 'completed';
    }

    if (nextStatus.isNotEmpty) {
      await _supabase
          .from('pedidos')
          .update({'status': nextStatus})
          .eq('id', order.id);
    }
  }
}