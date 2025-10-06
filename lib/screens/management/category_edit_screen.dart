import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/data/app_data.dart';
import 'package:villabistromobile/providers/navigation_provider.dart';
import 'package:villabistromobile/providers/product_provider.dart';
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
  bool _isLoading = false;

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

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);

    try {
      if (_isEditMode) {
        await productProvider.updateCategory(widget.category!.id, _name, _icon);
      } else {
        await productProvider.addCategory(_name, _icon,);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Categoria "${_name}" salva com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        navProvider.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _registerActions() {
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    navProvider.setScreenActions([
      if (_isLoading)
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      else
        IconButton(
            onPressed: _saveForm, icon: const Icon(Icons.save), tooltip: 'Salvar'),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    Widget content = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              initialValue: _name,
              enabled: !_isLoading,
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
              onTap: _isLoading ? null : _selectIcon,
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
            if (!isDesktop)
              ElevatedButton(
                onPressed: _isLoading ? null : _saveForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditMode ? 'Salvar Alterações' : 'Criar Categoria'),
              ),
          ],
        ),
      ),
    );

    if (isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _registerActions();
      });
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar Categoria' : 'Nova Categoria'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(onPressed: _saveForm, icon: const Icon(Icons.save)),
        ],
      ),
      body: content,
    );
  }
}