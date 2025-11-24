import 'package:flutter/foundation.dart';
import '../data/app_data.dart' as app_data;
import 'package:uuid/uuid.dart';

class CartProvider with ChangeNotifier {
  final List<app_data.CartItem> _items = [];
  String _orderObservation = '';

  List<app_data.CartItem> get items => [..._items];
  String get orderObservation => _orderObservation;

  int get totalItemsQuantity {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  void updateOrderObservation(String text) {
    _orderObservation = text;
    notifyListeners();
  }

  void updateItemObservation(String itemId, String observation) {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      _items[index].observacao = observation;
      notifyListeners();
    }
  }

  void updateCartFromSelection({
    required Map<String, int> productQuantities,
    required Map<String, Map<String, int>> adicionalQuantities,
    required List<app_data.Product> allProducts,
    required Map<String, List<app_data.GrupoAdicional>> allAdicionais,
  }) {
    for (final productId in productQuantities.keys) {
      _items.removeWhere((item) => item.product.id == productId);

      final quantity = productQuantities[productId]!;
      if (quantity > 0) {
        final product = allProducts.firstWhere((p) => p.id == productId);

        final selectedAdicionais = <app_data.CartItemAdicional>[];
        if (adicionalQuantities.containsKey(productId)) {
          for (final adicionalId in adicionalQuantities[productId]!.keys) {
            final adicionalQty = adicionalQuantities[productId]![adicionalId]!;
            if (adicionalQty > 0) {
              for (final grupo in allAdicionais[productId]!) {
                final adicional = grupo.adicionais.firstWhere(
                  (ad) => ad.id == adicionalId,
                  orElse: () => app_data.Adicional(
                      id: '', name: 'Not Found', price: 0.0, displayOrder: 0),
                );
                if (adicional.id.isNotEmpty) {
                  selectedAdicionais.add(app_data.CartItemAdicional(
                    adicional: adicional,
                    quantity: adicionalQty,
                  ));
                }
              }
            }
          }
        }

        _items.add(app_data.CartItem(
          id: const Uuid().v4(),
          product: product,
          quantity: quantity,
          selectedAdicionais: selectedAdicionais,
        ));
      }
    }
    notifyListeners();
  }

  void addItem(app_data.Product product) {
    final index = _items.indexWhere((item) =>
        item.product.id == product.id &&
        item.selectedAdicionais.isEmpty &&
        (item.observacao == null || item.observacao!.isEmpty));

    if (index != -1) {
      _items[index].quantity++;
    } else {
      _items.add(app_data.CartItem(
        id: const Uuid().v4(),
        product: product,
        quantity: 1,
      ));
    }
    notifyListeners();
  }

  void increaseQuantity(String itemId) {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      _items[index].quantity++;
      notifyListeners();
    }
  }

  void decreaseQuantity(String itemId) {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeItem(String itemId) {
    _items.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _orderObservation = '';
    notifyListeners();
  }
}