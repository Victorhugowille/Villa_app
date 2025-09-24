import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/data/app_data.dart';
import 'package:villabistromobile/providers/navigation_provider.dart';
import 'package:villabistromobile/providers/product_provider.dart';
import 'package:villabistromobile/widgets/custom_app_bar.dart';
import 'package:villabistromobile/widgets/icon_picker.dart';

class CategoryEditScreen extends StatefulWidget {
  final Category? category;
  const CategoryEditScreen({super.key, this.category});

  @override
  State<CategoryEditScreen> createState() => _CategoryEditScreenState();
}

class _CategoryEditScreenState extends State<CategoryEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late IconData _icon;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _isEditMode = true;
      _name = widget.category!.name;
      _icon = widget.category!.icon;
    } else {
      _name = '';
      _icon = Icons.category;
    }
  }

  void _selectIcon() {
    showDialog(
      context: context,
      builder: (ctx) => IconPicker(
        onIconSelected: (icon) => setState(() => _icon = icon),
      ),
    );
  }

  void _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    try {
      if (_isEditMode) {
        await productProvider.updateCategory(widget.category!.id, _name, _icon);
      } else {
        await productProvider.addCategory(_name, _icon);
      }
      if (mounted) {
        if (isDesktop) {
          Provider.of<NavigationProvider>(context, listen: false).pop();
        } else {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: CustomAppBar(
        title: _isEditMode ? 'Editar Categoria' : 'Nova Categoria',
        actions: [IconButton(onPressed: _saveForm, icon: const Icon(Icons.save))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _name,
                style: TextStyle(color: theme.colorScheme.onBackground),
                decoration:
                    const InputDecoration(labelText: 'Nome da Categoria'),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Insira um nome' : null,
                onSaved: (value) => _name = value!,
              ),
              const SizedBox(height: 24),
              Text('Ícone da Categoria',
                  style: TextStyle(
                      color: theme.colorScheme.onBackground.withOpacity(0.7),
                      fontSize: 16)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _selectIcon,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(_icon, size: 40, color: theme.primaryColor),
                      Text('Selecionar Ícone',
                          style: TextStyle(
                              color: theme.colorScheme.onBackground,
                              fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _saveForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(_isEditMode ? 'Salvar Alterações' : 'Criar Categoria'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}