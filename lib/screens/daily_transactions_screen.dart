import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/providers/transaction_provider.dart';

class DailyTransactionsScreen extends StatefulWidget {
  const DailyTransactionsScreen({super.key});

  @override
  State<DailyTransactionsScreen> createState() =>
      _DailyTransactionsScreenState();
}

class _DailyTransactionsScreenState extends State<DailyTransactionsScreen> {
  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    // Usamos 'mounted' para garantir que o widget ainda está na tela
    if (mounted) {
      await Provider.of<TransactionProvider>(context, listen: false)
          .fetchDailyTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimentação do Dia'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        color: theme.primaryColor,
        child: Column(
          children: [
            _buildSummaryCard(transactionProvider, theme),
            Expanded(
              child: transactionProvider.isLoading
                  ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
                  : transactionProvider.transactions.isEmpty
                      ? LayoutBuilder(
                          builder: (ctx, constraints) => SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: constraints.maxHeight),
                              child: const Center(
                                child: Text(
                                  'Nenhuma transação registrada hoje.\nPuxe para atualizar.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        )
                      : _buildTransactionList(transactionProvider, theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(TransactionProvider provider, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.all(12),
      color: theme.primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(
                  'Faturamento Total',
                  style: TextStyle(
                      color: theme.colorScheme.onBackground.withOpacity(0.7)),
                ),
                const SizedBox(height: 4),
                Text(
                  'R\$ ${provider.totalRevenue.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onBackground),
                ),
              ],
            ),
            Column(
              children: [
                Text(
                  'Nº de Transações',
                  style: TextStyle(
                      color: theme.colorScheme.onBackground.withOpacity(0.7)),
                ),
                const SizedBox(height: 4),
                Text(
                  '${provider.transactions.length}',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onBackground),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(TransactionProvider provider, ThemeData theme) {
    return ListView.builder(
      itemCount: provider.transactions.length,
      itemBuilder: (ctx, index) {
        final transaction = provider.transactions[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.primaryColor,
              child: Text(
                'M${transaction.tableNumber}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary),
              ),
            ),
            title: Text(
              'Total: R\$ ${transaction.totalAmount.toStringAsFixed(2)}',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface),
            ),
            subtitle: Text(
              '${transaction.paymentMethod} - ${DateFormat('HH:mm').format(transaction.timestamp)}',
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7)),
            ),
          ),
        );
      },
    );
  }
}