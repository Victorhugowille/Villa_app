import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;
import 'package:villabistromobile/providers/table_provider.dart';

class TableEditScreen extends StatefulWidget {
  final app_data.Table? table;
  const TableEditScreen({super.key, this.table});

  @override
  State<TableEditScreen> createState() => _TableEditScreenState();
}

class _TableEditScreenState extends State<TableEditScreen> {
  final _formKey = GlobalKey<FormState>();
  int _tableNumber = 0;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.table != null) {
      _isEditMode = true;
      _tableNumber = widget.table!.tableNumber;
    }
  }

  void _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    final tableProvider = Provider.of<TableProvider>(context, listen: false);

    try {
      if (_isEditMode) {
        await tableProvider.updateTable(widget.table!.id, _tableNumber);
      } else {
        await tableProvider.addTable(_tableNumber);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar Mesa' : 'Nova Mesa'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _saveForm)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                initialValue: _isEditMode ? _tableNumber.toString() : '',
                style: TextStyle(color: theme.colorScheme.onBackground),
                decoration: InputDecoration(
                  labelText: 'Número da Mesa',
                  labelStyle: TextStyle(color: theme.colorScheme.onBackground),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.colorScheme.onBackground)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.primaryColor)),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty || int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Insira um número válido e maior que zero.';
                  }
                  return null;
                },
                onSaved: (value) => _tableNumber = int.parse(value!),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveForm,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                child: Text(_isEditMode ? 'Salvar Alterações' : 'Adicionar Mesa'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}