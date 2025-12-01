import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/app_data.dart' as app_data;
import '../../providers/table_provider.dart';

class TableManagementScreen extends StatefulWidget {
  const TableManagementScreen({super.key});

  @override
  State<TableManagementScreen> createState() => _TableManagementScreenState();
}

class _TableManagementScreenState extends State<TableManagementScreen> {
  bool _isProcessing = false;

  void _addTable() async {
    setState(() => _isProcessing = true);
    try {
      await Provider.of<TableProvider>(context, listen: false).addNextTable();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Nova mesa adicionada!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao adicionar mesa: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _confirmAndDeleteHighestTable(BuildContext context) {
    final tableProvider = Provider.of<TableProvider>(context, listen: false);
    if (tableProvider.tables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Não há mesas para excluir.'),
          backgroundColor: Colors.orange));
      return;
    }

    final highestTable = tableProvider.tables
        .reduce((a, b) => a.tableNumber > b.tableNumber ? a : b);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
            'Isso irá apagar permanentemente a mesa de maior número (Mesa ${highestTable.tableNumber}). Deseja continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              _deleteHighestTable();
            },
            child:
                const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteHighestTable() async {
    setState(() => _isProcessing = true);
    try {
      await Provider.of<TableProvider>(context, listen: false)
          .deleteHighestTable();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Mesa de maior número excluída com sucesso!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao excluir mesa: ${e.toString()}'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tableProvider = Provider.of<TableProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesas'),
      ),
      body: RefreshIndicator(
        onRefresh: () => tableProvider.fetchAndSetTables(),
        child: ListView.builder(
          itemCount: tableProvider.tables.length,
          itemBuilder: (ctx, index) {
            final app_data.Table table = tableProvider.tables[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: Icon(
                  Icons.table_restaurant_outlined,
                  color: table.isOccupied
                      ? Colors.red.shade700
                      : theme.primaryColor,
                ),
                title: Text(
                  'Mesa ${table.tableNumber}',
                  style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  table.isOccupied ? 'Ocupada' : 'Livre',
                  style: TextStyle(
                      color: table.isOccupied
                          ? Colors.red.shade700
                          : Colors.green.shade600),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'delete_table_button',
            onPressed: _isProcessing
                ? null
                : () => _confirmAndDeleteHighestTable(context),
            backgroundColor: Colors.red,
            child: _isProcessing
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.remove),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            heroTag: 'add_table_button',
            onPressed: _isProcessing ? null : _addTable,
            child: _isProcessing
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}