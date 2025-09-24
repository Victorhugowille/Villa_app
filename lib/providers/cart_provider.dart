import 'package:flutter/foundation.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;

class CartProvider with ChangeNotifier {
  final Map<int, app_data.CartItem> _items = {};

  Map<int, app_data.CartItem> get items => {..._items};

  List<app_data.CartItem> get itemsAsList {
    return _items.values.toList();
  }

  // Retorna o número de produtos únicos no carrinho
  int get itemCount {
    return _items.length;
  }

  // NOVO: Retorna a soma de todas as quantidades de itens
  int get totalItemsQuantity {
    return _items.values.fold(0, (sum, item) => sum + item.quantity);
  }

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.product.price * cartItem.quantity;
    });
    return total;
  }

  void addItem(app_data.Product product) {
    if (_items.containsKey(product.id)) {
      _items.update(
        product.id,
        (existing) => app_data.CartItem(
          product: existing.product,
          quantity: existing.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        product.id,
        () => app_data.CartItem(product: product, quantity: 1),
      );
    }
    notifyListeners();
  }

  void removeSingleItem(int productId) {
    if (!_items.containsKey(productId)) return;
    if (_items[productId]!.quantity > 1) {
      _items.update(
          productId,
          (existing) => app_data.CartItem(
                product: existing.product,
                quantity: existing.quantity - 1,
              ));
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void addItemsFromSelection(
      Map<int, int> selection, List<app_data.Product> products) {
    selection.forEach((productId, quantity) {
      if (quantity > 0) {
        final product = products.firstWhere((p) => p.id == productId);
        _items[productId] =
            app_data.CartItem(product: product, quantity: quantity);
      } else {
        _items.remove(productId);
      }
    });
    notifyListeners();
  }

  void removeItem(int productId) {
    _items.remove(productId);
    notifyListeners();
  }

  int getItemQuantity(int productId) {
    return _items.containsKey(productId) ? _items[productId]!.quantity : 0;
  }

  // Método 'clear()' removido para evitar duplicidade.
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}