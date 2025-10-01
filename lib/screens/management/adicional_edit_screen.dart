import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/data/app_data.dart';
import 'package:villabistromobile/providers/navigation_provider.dart';
import 'package:villabistromobile/providers/product_provider.dart';
import 'package:villabistromobile/widgets/custom_app_bar.dart';

class AdicionalEditScreen extends StatefulWidget {
  final Adicional? adicional;
  const AdicionalEditScreen({super.key, this.adicional});

  @override
  State<AdicionalEditScreen> createState() => _AdicionalEditScreenState();
}

class _AdicionalEditScreenState extends State<AdicionalEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late double _price;
  bool _isEditMode = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.adicional != null) {
      _isEditMode = true;
      _name = widget.adicional!.name;
      _price = widget.adicional!.price;
    } else {
      _name = '';
      _price = 0.0;
    }
  }

  void _saveForm() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    try {
      if (_isEditMode) {
        await productProvider.updateAdicional(widget.adicional!.id, _name, _price);
      } else {
        await productProvider.addAdicional(_name, _price);
      }
      if (mounted) {
        Provider.of<NavigationProvider>(context, listen: false).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _isEditMode ? 'Editar Adicional' : 'Novo Adicional',
        actions: [
          IconButton(onPressed: _saveForm, icon: const Icon(Icons.save))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _name,
                enabled: !_isLoading,
                decoration: const InputDecoration(labelText: 'Nome do Adicional'),
                validator: (value) => (value == null || value.isEmpty) ? 'Insira um nome' : null,
                onSaved: (value) => _name = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _price > 0 ? _price.toStringAsFixed(2) : '',
                enabled: !_isLoading,
                decoration: const InputDecoration(labelText: 'Preço'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => (v == null || v.isEmpty || double.tryParse(v.replaceAll(',', '.')) == null)
                    ? 'Insira um preço válido.'
                    : null,
                onSaved: (v) => _price = double.parse(v!.replaceAll(',', '.')),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_isEditMode ? 'Salvar Alterações' : 'Criar Adicional'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}