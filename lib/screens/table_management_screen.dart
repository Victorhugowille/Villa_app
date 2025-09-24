import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/providers/table_provider.dart';
import 'package:villabistromobile/screens/table_edit_screen.dart';

class TableManagementScreen extends StatefulWidget {
  const TableManagementScreen({super.key});

  @override
  State<TableManagementScreen> createState() => _TableManagementScreenState();
}

class _TableManagementScreenState extends State<TableManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tableProvider = Provider.of<TableProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesas'),
      ),
      body: ListView.builder(
        itemCount: tableProvider.tables.length,
        itemBuilder: (ctx, index) {
          final table = tableProvider.tables[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: Icon(
                Icons.table_restaurant_outlined,
                color: table.isOccupied ? Colors.red.shade700 : theme.primaryColor,
              ),
              title: Text(
                'Mesa ${table.tableNumber}',
                style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                table.isOccupied ? 'Ocupada' : 'Livre',
                style: TextStyle(color: table.isOccupied ? Colors.red.shade700 : Colors.green.shade600),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: table.isOccupied ? null : () => _deleteTable(context, table.id),
              ),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => TableEditScreen(table: table)),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => const TableEditScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _deleteTable(BuildContext context, int tableId) async {
    try {
      await Provider.of<TableProvider>(context, listen: false).deleteTable(tableId);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mesa excluída com sucesso!')));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir mesa: ${e.toString()}')));
    }
  }
}