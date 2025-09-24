import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/providers/transaction_provider.dart';

class TransactionsReportScreen extends StatefulWidget {
  const TransactionsReportScreen({super.key});

  @override
  State<TransactionsReportScreen> createState() => _TransactionsReportScreenState();
}

class _TransactionsReportScreenState extends State<TransactionsReportScreen> {
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    _startDate = provider.startDate;
    _endDate = provider.endDate;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.fetchDailyTransactions();
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    final initialDate = isStartDate ? _startDate : _endDate;
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      provider.fetchTransactionsByDateRange(_startDate, _endDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final DateFormat formatter = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
      ),
      body: Column(
        children: [
          _buildDateSelector(context, formatter, theme),
          _buildSummaryCard(transactionProvider, theme),
          Expanded(
            child: transactionProvider.isLoading
                ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
                : transactionProvider.transactions.isEmpty
                    ? const Center(
                        child: Text('Nenhuma transação encontrada para o período selecionado.'),
                      )
                    : _buildTransactionList(transactionProvider, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context, DateFormat formatter, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildDateButton('De:', formatter.format(_startDate), () => _selectDate(context, true), theme),
          _buildDateButton('Até:', formatter.format(_endDate), () => _selectDate(context, false), theme),
        ],
      ),
    );
  }

  Widget _buildDateButton(String label, String dateText, VoidCallback onPressed, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: theme.colorScheme.onBackground.withOpacity(0.7))),
        const SizedBox(height: 4),
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.cardColor,
            foregroundColor: theme.colorScheme.onSurface,
          ),
          child: Text(dateText),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(TransactionProvider provider, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: theme.primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text('Faturamento Total', style: TextStyle(color: theme.colorScheme.onBackground.withOpacity(0.7))),
                const SizedBox(height: 4),
                Text('R\$ ${provider.totalRevenue.toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onBackground)),
              ],
            ),
            Column(
              children: [
                Text('Nº de Transações', style: TextStyle(color: theme.colorScheme.onBackground.withOpacity(0.7))),
                const SizedBox(height: 4),
                Text('${provider.transactions.length}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onBackground)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(TransactionProvider provider, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: provider.transactions.length,
      itemBuilder: (ctx, index) {
        final transaction = provider.transactions[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 5),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.primaryColor,
              child: Text('M${transaction.tableNumber}', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimary)),
            ),
            title: Text('Total: R\$ ${transaction.totalAmount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            subtitle: Text('${transaction.paymentMethod} - ${DateFormat('dd/MM HH:mm').format(transaction.timestamp)}', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))),
          ),
        );
      },
    );
  }
}