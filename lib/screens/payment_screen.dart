import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;
import 'package:villabistromobile/providers/navigation_provider.dart';
import 'package:villabistromobile/providers/table_provider.dart';
import 'package:villabistromobile/widgets/custom_app_bar.dart';

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
  final _discountController = TextEditingController(text: '0,00');
  final _surchargeController = TextEditingController(text: '0,00');
  bool _isLoading = false;

  double get _discount =>
      double.tryParse(_discountController.text.replaceAll(',', '.')) ?? 0.0;
  double get _surcharge =>
      double.tryParse(_surchargeController.text.replaceAll(',', '.')) ?? 0.0;
  double get finalAmount => widget.totalAmount - _discount + _surcharge;

  @override
  void dispose() {
    _discountController.dispose();
    _surchargeController.dispose();
    super.dispose();
  }

  void _finalizePayment() async {
    setState(() => _isLoading = true);
    final isDesktop = MediaQuery.of(context).size.width > 800;
    try {
      await Provider.of<TableProvider>(context, listen: false).closeAccount(
        table: widget.table,
        totalAmount: finalAmount,
        paymentMethod: _paymentMethod,
      );
      if (mounted) {
        if (isDesktop) {
          Provider.of<NavigationProvider>(context, listen: false).popToHome();
        } else {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao finalizar: ${e.toString()}'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Pagamento - Mesa ${widget.table.tableNumber}',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryRow('Subtotal', widget.totalAmount, theme),
            _buildModifierInput(_discountController, 'Desconto', theme),
            _buildModifierInput(_surchargeController, 'Acréscimo', theme),
            const SizedBox(height: 8),
            _buildSummaryRow('Total a Pagar', finalAmount, theme, isFinal: true),
            const SizedBox(height: 24),
            Text('Forma de Pagamento',
                style: TextStyle(
                    color: theme.colorScheme.onBackground,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            _buildPaymentMethodSelector(theme),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _finalizePayment,
                child: const Text('FINALIZAR PAGAMENTO'),
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
    final methods = [
      'Dinheiro',
      'Cartão de Débito',
      'Cartão de Crédito',
      'Pix'
    ];
    return DropdownButtonFormField<String>(
      value: _paymentMethod,
      items: methods.map((String method) {
        return DropdownMenuItem<String>(value: method, child: Text(method));
      }).toList(),
      onChanged: (newValue) => setState(() => _paymentMethod = newValue!),
      style: TextStyle(color: theme.colorScheme.onSurface),
      dropdownColor: theme.cardColor,
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
                  color: theme.colorScheme.onBackground,
                  fontSize: isFinal ? 20 : 16,
                  fontWeight: isFinal ? FontWeight.bold : FontWeight.normal)),
          Text('R\$ ${value.toStringAsFixed(2)}',
              style: TextStyle(
                  color: isFinal ? theme.primaryColor : theme.colorScheme.onBackground,
                  fontSize: isFinal ? 20 : 16,
                  fontWeight: isFinal ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}