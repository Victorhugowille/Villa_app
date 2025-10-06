import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;
import 'package:villabistromobile/providers/navigation_provider.dart';
import 'package:villabistromobile/providers/table_provider.dart';

class PaymentScreen extends StatefulWidget {
  final app_data.Table table;
  final double totalAmount;
  final List<app_data.Order> orders;

  const PaymentScreen({
    super.key,
    required this.table,
    required this.totalAmount,
    required this.orders,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _paymentMethod = 'Dinheiro';
  final _discountController = TextEditingController(text: '0.00');
  final _surchargeController = TextEditingController(text: '0.00');
  bool _isLoading = false;

  final Set<String> _selectedItemIds = {};
  late final List<app_data.CartItem> _allItems;
  late final Set<String> _alreadyPaidItemIds;

  @override
  void initState() {
    super.initState();
    _allItems = widget.orders.expand((order) => order.items).toList();
    _alreadyPaidItemIds = Provider.of<TableProvider>(context, listen: false)
        .getPaidItemIdsForTable(widget.table.id);
  }

  double get _discount =>
      double.tryParse(_discountController.text.replaceAll(',', '.')) ?? 0.0;
  double get _surcharge =>
      double.tryParse(_surchargeController.text.replaceAll(',', '.')) ?? 0.0;

  double get _selectedItemsTotal {
    if (_selectedItemIds.isEmpty) {
      double remainingTotal = 0.0;
      for (final item in _allItems) {
        if (!_alreadyPaidItemIds.contains(item.id)) {
          remainingTotal += item.totalPrice;
        }
      }
      return remainingTotal;
    }

    double total = 0.0;
    for (final item in _allItems) {
      if (_selectedItemIds.contains(item.id)) {
        total += item.totalPrice;
      }
    }
    return total;
  }

  double get finalAmount => _selectedItemsTotal - _discount + _surcharge;

  @override
  void dispose() {
    _discountController.dispose();
    _surchargeController.dispose();
    super.dispose();
  }

  void _processPayment() {
    final isPartialPayment = _selectedItemIds.isNotEmpty;

    final allItemIds = _allItems.map((item) => item.id).toSet();
    final totalPaidIds = _alreadyPaidItemIds.union(_selectedItemIds);
    final isPayingAllRemaining = totalPaidIds.containsAll(allItemIds);

    if (isPartialPayment && !isPayingAllRemaining) {
      _finalizePartialPayment();
    } else {
      _finalizeTotalPayment();
    }
  }

  void _finalizePartialPayment() async {
    setState(() => _isLoading = true);
    try {
      Provider.of<TableProvider>(context, listen: false)
          .registerPartialPayment(widget.table.id, _selectedItemIds);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pagamento parcial registrado com sucesso!'),
          backgroundColor: Colors.green,
        ));
        _navigateHome();
      }
    } catch (e) {
      _handleError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _finalizeTotalPayment() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<TableProvider>(context, listen: false).closeAccount(
        table: widget.table,
        totalAmount: finalAmount,
        paymentMethod: _paymentMethod,
        discount: _discount,
        surcharge: _surcharge,
      );
      if (mounted) {
        _navigateHome();
      }
    } catch (e) {
      _handleError(e, prefix: 'Erro ao finalizar conta');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  void _handleError(Object e, {String prefix = 'Erro'}) {
     if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$prefix: ${e.toString()}'),
            backgroundColor: Colors.red));
      }
  }

  void _navigateHome() {
    if (!mounted) return;
    Provider.of<NavigationProvider>(context, listen: false).popToHome();
    if (MediaQuery.of(context).size.width <= 800) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isPartialPayment = _selectedItemIds.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagamento'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Selecione os Itens para Pagamento',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                      'Itens já pagos estão desabilitados. Se nada for selecionado, o restante da conta será pago.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = _allItems[index];
                final bool isAlreadyPaid =
                    _alreadyPaidItemIds.contains(item.id);
                final bool isSelected = _selectedItemIds.contains(item.id);

                return CheckboxListTile(
                  title: Row(
                    children: [
                      Expanded(child: Text('${item.quantity}x ${item.product.name}')),
                      if(isAlreadyPaid)
                        const Chip(
                          label: Text('PAGO'),
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.green,
                          labelStyle: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  subtitle:
                      Text('R\$ ${item.totalPrice.toStringAsFixed(2)}'),
                  value: isSelected || isAlreadyPaid,
                  onChanged: isAlreadyPaid
                      ? null
                      : (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedItemIds.add(item.id);
                            } else {
                              _selectedItemIds.remove(item.id);
                            }
                          });
                        },
                  activeColor: isAlreadyPaid ? Colors.grey : theme.primaryColor,
                  controlAffinity: ListTileControlAffinity.leading,
                );
              },
              childCount: _allItems.length,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Divider(height: 20),
                  _buildSummaryRow(
                      isPartialPayment ? 'Subtotal Selecionado' : 'Subtotal Restante',
                      _selectedItemsTotal,
                      theme),
                  _buildModifierInput(_discountController, 'Desconto', theme),
                  _buildModifierInput(_surchargeController, 'Acréscimo', theme),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Total a Pagar', finalAmount, theme,
                      isFinal: true),
                  const SizedBox(height: 24),
                  _buildPaymentMethodSelector(theme),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: isPartialPayment
                        ? Colors.orange.shade700
                        : theme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _processPayment,
                child: Text(isPartialPayment
                    ? 'PAGAR ITENS SELECIONADOS'
                    : 'PAGAR CONTA RESTANTE'),
              ),
      ),
    );
  }

  Widget _buildModifierInput(
      TextEditingController controller, String label, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: theme.colorScheme.onBackground),
        decoration: InputDecoration(
          labelText: label,
          prefixText: 'R\$ ',
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildPaymentMethodSelector(ThemeData theme) {
    final methods = ['Dinheiro', 'Cartão de Débito', 'Cartão de Crédito', 'Pix'];
    return DropdownButtonFormField<String>(
      value: _paymentMethod,
      items: methods.map((String method) {
        return DropdownMenuItem<String>(value: method, child: Text(method));
      }).toList(),
      onChanged: (newValue) => setState(() => _paymentMethod = newValue!),
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, ThemeData theme,
      {bool isFinal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: isFinal ? 20 : 16,
                  fontWeight: isFinal ? FontWeight.bold : FontWeight.normal)),
          Text('R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}',
              style: TextStyle(
                  color: isFinal ? theme.primaryColor : null,
                  fontSize: isFinal ? 20 : 16,
                  fontWeight: isFinal ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}