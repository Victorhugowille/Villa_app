import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/providers/spreadsheet_provider.dart';

class SavedSpreadsheetsListScreen extends StatefulWidget {
  const SavedSpreadsheetsListScreen({super.key});

  @override
  State<SavedSpreadsheetsListScreen> createState() =>
      _SavedSpreadsheetsListScreenState();
}

class _SavedSpreadsheetsListScreenState
    extends State<SavedSpreadsheetsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SpreadsheetProvider>(context, listen: false)
          .fetchSavedSheets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SpreadsheetProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Arquivos Salvos'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.savedSheets.isEmpty
              ? const Center(child: Text('Nenhuma planilha salva encontrada.'))
              : ListView.builder(
                  itemCount: provider.savedSheets.length,
                  itemBuilder: (context, index) {
                    final sheet = provider.savedSheets[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading:
                            Icon(Icons.grid_on, color: theme.primaryColor),
                        title: Text(sheet.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            'Salvo em: ${DateFormat('dd/MM/yyyy HH:mm').format(sheet.createdAt.toLocal())}'),
                        onTap: () {
                          context.read<SpreadsheetProvider>().loadSheet(sheet.id!);
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                ),
    );
  }
}