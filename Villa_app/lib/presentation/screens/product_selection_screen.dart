import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/app_data.dart' as app_data;
import '../providers/cart_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/product_provider.dart';
import 'cart_screen.dart';
import '../widgets/side_menu.dart';

class ProductSelectionScreen extends StatefulWidget {
  final app_data.Table table;
  final app_data.Category category;
  final List<app_data.Product> products;

  const ProductSelectionScreen({
    super.key,
    required this.table,
    required this.category,
    required this.products,
  });

  @override
  State<ProductSelectionScreen> createState() => _ProductSelectionScreenState();
}

class _ProductSelectionScreenState extends State<ProductSelectionScreen> {
  Map<String, int> _productQuantities = {};
  Map<String, Map<String, int>> _adicionalQuantities = {};
  Map<String, List<app_data.GrupoAdicional>> _cachedAdicionais = {};

  @override
  void initState() {
    super.initState();
    final cart = Provider.of<CartProvider>(context, listen: false);

    for (final cartItem in cart.items) {
      final productId = cartItem.product.id;
      if (widget.products.any((p) => p.id == productId)) {
        _productQuantities[productId] = cartItem.quantity;
        _adicionalQuantities[productId] = {};
        for (var itemAdicional in cartItem.selectedAdicionais) {
          _adicionalQuantities[productId]![itemAdicional.adicional.id] =
              itemAdicional.quantity;
        }
      }
    }
  }

  // **NOVA FUNÇÃO DE VALIDAÇÃO**
  String? _validateAdicionais() {
    // Itera sobre cada produto que o usuário está tentando adicionar
    for (final productEntry in _productQuantities.entries) {
      final productId = productEntry.key;
      final productQty = productEntry.value;

      // Só valida se a quantidade do produto for maior que zero
      if (productQty <= 0) continue;

      final grupos = _cachedAdicionais[productId];
      if (grupos == null) continue; // Pula se não houver grupos

      // Para cada grupo de adicionais do produto...
      for (final grupo in grupos) {
        int totalSelectedInGroup = 0;
        final selectedForProduct = _adicionalQuantities[productId] ?? {};

        // Soma a quantidade de cada adicional que pertence a este grupo
        for (final adicional in grupo.adicionais) {
          totalSelectedInGroup += selectedForProduct[adicional.id] ?? 0;
        }

        // Verifica a regra de quantidade MÍNIMA
        if (totalSelectedInGroup < grupo.minQuantity) {
          return 'Para o grupo "${grupo.name}", você precisa selecionar pelo menos ${grupo.minQuantity} item(ns).';
        }

        // Verifica a regra de quantidade MÁXIMA, se ela existir
        if (grupo.maxQuantity != null &&
            totalSelectedInGroup > grupo.maxQuantity!) {
          return 'Para o grupo "${grupo.name}", o limite máximo é de ${grupo.maxQuantity} item(ns).';
        }
      }
    }

    return null; // Retorna nulo se todas as regras foram atendidas
  }

  void _updateProductQuantity(String productId, int change) {
    setState(() {
      final currentQty = _productQuantities[productId] ?? 0;
      final newQty = currentQty + change;
      _productQuantities[productId] = newQty > 0 ? newQty : 0;
    });
  }

  void _updateAdicionalQuantity(
      String productId, String adicionalId, int change) {
    setState(() {
      _adicionalQuantities.putIfAbsent(productId, () => {});
      final currentQty = _adicionalQuantities[productId]![adicionalId] ?? 0;
      final newQty = currentQty + change;
      _adicionalQuantities[productId]![adicionalId] = newQty > 0 ? newQty : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final totalSelectedItems =
        _productQuantities.values.where((qty) => qty > 0).length;

    Widget content = ListView.builder(
      itemCount: widget.products.length,
      itemBuilder: (ctx, index) {
        final product = widget.products[index];
        final productQty = _productQuantities[product.id] ?? 0;

        return Card(
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            children: [
              ListTile(
                leading: SizedBox(
                  width: 60,
                  height: 60,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      product.imageUrl ??
                          'https://placehold.co/100x100/e2e8f0/e2e8f0?text=Img',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.fastfood,
                          color: theme.primaryColor.withOpacity(0.5)),
                    ),
                  ),
                ),
                title: Text(product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('R\$ ${product.price.toStringAsFixed(2)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline,
                          color: productQty > 0 ? Colors.red : Colors.grey),
                      onPressed: productQty > 0
                          ? () => _updateProductQuantity(product.id, -1)
                          : null,
                    ),
                    Text('$productQty',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline,
                          color: theme.primaryColor),
                      onPressed: () => _updateProductQuantity(product.id, 1),
                    ),
                  ],
                ),
              ),
              FutureBuilder<List<app_data.GrupoAdicional>>(
                future: _fetchAdicionais(product.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasData &&
                      snapshot.data!.isNotEmpty) {
                    return ExpansionTile(
                      key: PageStorageKey(product.id),
                      title: Text('Escolher adicionais +',
                          style: TextStyle(color: theme.primaryColor)),
                      children: snapshot.data!.map((grupo) {
                        // **MUDANÇA AQUI: Cria o texto da regra**
                        String ruleText = 'Obrigatório: ${grupo.minQuantity}';
                        if (grupo.maxQuantity != null) {
                          ruleText += ' / Máximo: ${grupo.maxQuantity}';
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              // **MUDANÇA AQUI: Exibe o nome do grupo e a regra**
                              child: RichText(
                                text: TextSpan(
                                  style: DefaultTextStyle.of(context).style,
                                  children: <TextSpan>[
                                    TextSpan(
                                        text: grupo.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    TextSpan(
                                        text: ' ($ruleText)',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey.shade700)),
                                  ],
                                ),
                              ),
                            ),
                            ...grupo.adicionais.map((adicional) {
                              final adicionalQty =
                                  _adicionalQuantities[product.id]
                                          ?[adicional.id] ??
                                      0;
                              return ListTile(
                                title: Text(adicional.name),
                                subtitle: Text(
                                    '+ R\$ ${adicional.price.toStringAsFixed(2)}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                          Icons.remove_circle_outline,
                                          color: adicionalQty > 0
                                              ? Colors.red
                                              : Colors.grey),
                                      onPressed: adicionalQty > 0
                                          ? () => _updateAdicionalQuantity(
                                              product.id, adicional.id, -1)
                                          : null,
                                    ),
                                    Text('$adicionalQty',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: Icon(Icons.add_circle_outline,
                                          color: theme.primaryColor),
                                      onPressed: () =>
                                          _updateAdicionalQuantity(
                                              product.id, adicional.id, 1),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            const Divider(),
                          ],
                        );
                      }).toList(),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ],
          ),
        );
      },
    );

    FloatingActionButton? fab = totalSelectedItems > 0
        ? FloatingActionButton.extended(
            onPressed: () {
              // **MUDANÇA AQUI: Chama a validação antes de prosseguir**
              final validationError = _validateAdicionais();
              if (validationError != null) {
                // Se houver um erro, mostra a mensagem e não faz nada
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(validationError),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
                return;
              }

              // Se a validação passou, atualiza o carrinho
              final cart = Provider.of<CartProvider>(context, listen: false);
              cart.updateCartFromSelection(
                productQuantities: _productQuantities,
                adicionalQuantities: _adicionalQuantities,
                allProducts: widget.products,
                allAdicionais: _cachedAdicionais,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '$totalSelectedItems tipo(s) de item atualizado(s) no carrinho.'),
                  backgroundColor: theme.primaryColor,
                ),
              );

              if (isDesktop) {
                Provider.of<NavigationProvider>(context, listen: false).pop();
              } else {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.shopping_cart_checkout),
            label: const Text('ATUALIZAR CARRINHO'),
          )
        : null;

    if (isDesktop) {
      return Stack(children: [
        content,
        if (fab != null) Positioned(bottom: 24, right: 24, child: fab)
      ]);
    }

    return Scaffold(
      drawer: const SideMenu(),
      appBar: AppBar(
        title: Text(widget.category.name),
        actions: [
          Consumer<CartProvider>(
            builder: (_, cart, ch) => Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined, size: 28),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => CartScreen(table: widget.table)));
                  },
                ),
                if (cart.totalItemsQuantity > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10)),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '${cart.totalItemsQuantity}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: content,
      floatingActionButton: fab,
    );
  }

  Future<List<app_data.GrupoAdicional>> _fetchAdicionais(
      String productId) async {
    if (_cachedAdicionais.containsKey(productId)) {
      return _cachedAdicionais[productId]!;
    }
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    final adicionais =
        await productProvider.getGruposAdicionaisParaProduto(productId);
    if (mounted) {
      setState(() {
        _cachedAdicionais[productId] = adicionais;
      });
    }
    return adicionais;
  }
}