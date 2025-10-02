// lib/screens/transactions_report_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/providers/transaction_provider.dart';
import 'package:villabistromobile/widgets/charts/daily_revenue_bar_chart.dart';
import 'package:villabistromobile/widgets/charts/payment_method_pie_chart.dart';
import 'package:villabistromobile/widgets/side_menu.dart';

class TransactionsReportScreen extends StatefulWidget {
  const TransactionsReportScreen({super.key});

  @override
  State<TransactionsReportScreen> createState() =>
      _TransactionsReportScreenState();
}

class _TransactionsReportScreenState extends State<TransactionsReportScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _startDate;
  late DateTime _endDate;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    _startDate = provider.startDate;
    _endDate = provider.endDate;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.fetchDailyTransactions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final DateFormat formatter = DateFormat('dd/MM/yyyy');

    Widget bodyContent = Column(
      children: [
        _buildDateSelector(context, formatter, theme),
        _buildSummaryCards(transactionProvider, theme),
        const SizedBox(height: 8),
        Expanded(
          child: transactionProvider.isLoading
              ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
              : transactionProvider.transactions.isEmpty
                  ? const Center(
                      child: Text(
                          'Nenhuma transação encontrada para o período selecionado.'),
                    )
                  : Column(
                      children: [
                        TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(icon: Icon(Icons.pie_chart), text: 'Pagamentos'),
                            Tab(icon: Icon(Icons.bar_chart), text: 'Faturamento'),
                            Tab(icon: Icon(Icons.list_alt), text: 'Detalhes'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildChartCard(PaymentMethodPieChart(
                                  revenueByPaymentMethod: transactionProvider
                                      .revenueByPaymentMethod)),
                              _buildChartCard(DailyRevenueBarChart(
                                  dailyRevenue:
                                      transactionProvider.dailyRevenue)),
                              _buildTransactionList(transactionProvider, theme),
                            ],
                          ),
                        ),
                      ],
                    ),
        ),
      ],
    );

    if (isDesktop) {
      return bodyContent;
    } else {
      return Scaffold(
        drawer: const SideMenu(),
        appBar: AppBar(
          title: const Text('Relatório de Movimentação'),
        ),
        body: bodyContent,
      );
    }
  }

  Widget _buildChartCard(Widget chart) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: chart,
      ),
    );
  }

  Widget _buildDateSelector(
      BuildContext context, DateFormat formatter, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildDateButton('De:', formatter.format(_startDate),
              () => _selectDate(context, true), theme),
          const SizedBox(width: 20),
          _buildDateButton('Até:', formatter.format(_endDate),
              () => _selectDate(context, false), theme),
        ],
      ),
    );
  }

  Widget _buildDateButton(
      String label, String dateText, VoidCallback onPressed, ThemeData theme) {
    return Column(
      children: [
        Text(label),
        ElevatedButton(onPressed: onPressed, child: Text(dateText)),
      ],
    );
  }

  Widget _buildSummaryCards(TransactionProvider provider, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        children: [
          Expanded(
            child: Card(
              color: theme.primaryColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Text('Faturamento Total',
                        style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onBackground
                                .withOpacity(0.7))),
                    const SizedBox(height: 4),
                    Text('R\$ ${provider.totalRevenue.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onBackground)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Card(
              color: theme.colorScheme.secondary.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Text('Nº de Transações',
                        style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onBackground
                                .withOpacity(0.7))),
                    const SizedBox(height: 4),
                    Text('${provider.transactions.length}',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onBackground)),
                  ],
                ),
              ),
            ),
          ),
        ],
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
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.primaryColor,
              child: Text('M${transaction.tableNumber}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary)),
            ),
            title: Text(
                'Total: R\$ ${transaction.totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface)),
            subtitle: Text(
                '${transaction.paymentMethod} - ${DateFormat('dd/MM HH:mm').format(transaction.timestamp)}',
                style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.7))),
          ),
        );
      },
    );
  }
}