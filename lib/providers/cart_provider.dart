import 'package:flutter/foundation.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;

class CartProvider with ChangeNotifier {
  final List<app_data.CartItem> _items = [];

  List<app_data.CartItem> get items => [..._items];

  int get totalItemsQuantity {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  void updateCartFromSelection({
    required Map<String, int> productQuantities,
    required Map<String, Map<String, int>> adicionalQuantities,
    required List<app_data.Product> allProducts,
    required Map<String, List<app_data.GrupoAdicional>> allAdicionais,
  }) {
    allProducts.forEach((product) {
      _items.removeWhere((item) => item.product.id == product.id);
    });

    productQuantities.forEach((productId, productQty) {
      if (productQty > 0) {
        final product = allProducts.firstWhere((p) => p.id == productId);
        final selectedAdicionais = <app_data.CartItemAdicional>[];

        final adicionaisForProduct = adicionalQuantities[productId];
        if (adicionaisForProduct != null) {
          adicionaisForProduct.forEach((adicionalId, adicionalQty) {
            if (adicionalQty > 0) {
              final allProductAdicionais = allAdicionais[productId] ?? [];
              for (var grupo in allProductAdicionais) {
                final adicional = grupo.adicionais.firstWhere(
                    (ad) => ad.id == adicionalId,
                    orElse: () => app_data.Adicional(
                        id: '', name: '', price: 0, imageUrl: null));
                if (adicional.id.isNotEmpty) {
                  selectedAdicionais.add(app_data.CartItemAdicional(
                      adicional: adicional, quantity: adicionalQty));
                  break;
                }
              }
            }
          });
        }

        _items.add(app_data.CartItem(
          product: product,
          quantity: productQty,
          selectedAdicionais: selectedAdicionais,
        ));
      }
    });

    notifyListeners();
  }

  void increaseQuantity(String cartItemId) {
    final index = _items.indexWhere((item) => item.cartItemId == cartItemId);
    if (index != -1) {
      final oldItem = _items[index];
      final newItem = oldItem.copyWith(quantity: oldItem.quantity + 1);
      _items[index] = newItem;
      notifyListeners();
    }
  }

  void decreaseQuantity(String cartItemId) {
    final index = _items.indexWhere((item) => item.cartItemId == cartItemId);
    if (index != -1) {
      final oldItem = _items[index];
      if (oldItem.quantity > 1) {
        final newItem = oldItem.copyWith(quantity: oldItem.quantity - 1);
        _items[index] = newItem;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeItem(String cartItemId) {
    _items.removeWhere((item) => item.cartItemId == cartItemId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}