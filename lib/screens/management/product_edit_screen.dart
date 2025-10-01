// lib/screens/management/product_edit_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/data/app_data.dart';
import 'package:villabistromobile/providers/navigation_provider.dart';
import 'package:villabistromobile/providers/product_provider.dart';
import 'package:villabistromobile/widgets/custom_app_bar.dart';

class ProductEditScreen extends StatefulWidget {
  final Product? product;
  const ProductEditScreen({super.key, this.product});

  @override
  State<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late double _price;
  late int? _categoryId;
  late bool _isSoldOut;
  bool _isEditMode = false;
  List<Category> _availableCategories = [];
  bool _isLoading = true;
  bool _isSaving = false;
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  List<Adicional> _todosOsAdicionais = [];
  Set<int> _adicionaisSelecionados = {};

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _isEditMode = true;
      _name = widget.product!.name;
      _price = widget.product!.price;
      _categoryId = widget.product!.categoryId;
      _isSoldOut = widget.product!.isSoldOut;
    } else {
      _name = '';
      _price = 0.0;
      _categoryId = null;
      _isSoldOut = false;
    }
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    
    _availableCategories = productProvider.categories;
    if (!_isEditMode && _availableCategories.isNotEmpty) {
      _categoryId = _availableCategories.first.id;
    }

    _todosOsAdicionais = productProvider.adicionais;

    if (_isEditMode) {
      final idsVinculados = await productProvider.getAdicionaisForProduct(widget.product!.id);
      _adicionaisSelecionados = idsVinculados.toSet();
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    final XFile? selectedImage = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 50);
    if (selectedImage != null) setState(() => _imageFile = selectedImage);
  }

  void _saveForm() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    _formKey.currentState!.save();

    setState(() {
      _isSaving = true;
    });

    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    try {
      if (_isEditMode) {
        await productProvider.updateProduct(
            widget.product!.id, _name, _price, _categoryId!, _isSoldOut, _imageFile, _adicionaisSelecionados.toList());
      } else {
        final productsInCategory = productProvider.products
            .where((p) => p.categoryId == _categoryId!)
            .length;
        await productProvider.addProduct(_name, _price, _categoryId!,
            productsInCategory, _isSoldOut, _imageFile, _adicionaisSelecionados.toList());
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
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text(
            'Tem certeza que deseja apagar este produto? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Apagar',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _isSaving = true;
      });
      try {
        await Provider.of<ProductProvider>(context, listen: false)
            .deleteProduct(widget.product!.id);
        if (mounted) {
          Provider.of<NavigationProvider>(context, listen: false).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao apagar: ${e.toString()}')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    Widget content = _isLoading
        ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: <Widget>[
                  _buildImagePicker(theme),
                  const SizedBox(height: 24),
                  TextFormField(
                    initialValue: _name,
                    enabled: !_isSaving,
                    decoration:
                        const InputDecoration(labelText: 'Nome do Produto'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Insira um nome.' : null,
                    onSaved: (v) => _name = v!,
                  ),
                  TextFormField(
                    initialValue: _price > 0 ? _price.toStringAsFixed(2) : '',
                    enabled: !_isSaving,
                    decoration: const InputDecoration(labelText: 'Preço'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => (v == null ||
                            v.isEmpty ||
                            double.tryParse(v.replaceAll(',', '.')) == null)
                        ? 'Insira um preço válido.'
                        : null,
                    onSaved: (v) => _price = double.parse(v!.replaceAll(',', '.')),
                  ),
                  DropdownButtonFormField<int>(
                    value: _categoryId,
                    items: _availableCategories
                        .map((c) =>
                            DropdownMenuItem<int>(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: _isSaving ? null : (v) => setState(() => _categoryId = v),
                    validator: (v) =>
                        (v == null) ? 'Selecione uma categoria.' : null,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Produto Esgotado'),
                    value: _isSoldOut,
                    onChanged: _isSaving ? null : (value) => setState(() => _isSoldOut = value),
                    activeColor: theme.primaryColor,
                  ),
                  const SizedBox(height: 24),
                  const Text('Adicionais Disponíveis para este Produto', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const Divider(),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _todosOsAdicionais.length,
                    itemBuilder: (context, index) {
                      final adicional = _todosOsAdicionais[index];
                      return CheckboxListTile(
                        title: Text(adicional.name),
                        subtitle: Text('R\$ ${adicional.price.toStringAsFixed(2)}'),
                        value: _adicionaisSelecionados.contains(adicional.id),
                        onChanged: _isSaving ? null : (bool? value) {
                          setState(() {
                            if (value == true) {
                              _adicionaisSelecionados.add(adicional.id);
                            } else {
                              _adicionaisSelecionados.remove(adicional.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveForm,
                     style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _isEditMode ? 'Salvar Alterações' : 'Adicionar Produto'),
                  ),
                ],
              ),
            ),
          );

    if (isDesktop) {
      return content;
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: _isEditMode ? 'Editar Produto' : 'Novo Produto',
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            if (_isEditMode)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _deleteProduct,
                tooltip: 'Apagar Produto',
              ),
            IconButton(
                icon: const Icon(Icons.save), onPressed: _saveForm, tooltip: 'Salvar'),
          ],
        ],
      ),
      body: content,
    );
  }

  Widget _buildImagePicker(ThemeData theme) {
    ImageProvider? backgroundImage;
    if (_imageFile != null) {
      backgroundImage = FileImage(File(_imageFile!.path));
    } else if (_isEditMode && widget.product!.imageUrl != null) {
      backgroundImage = NetworkImage(widget.product!.imageUrl!);
    }

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 80,
            backgroundColor: theme.primaryColor.withOpacity(0.1),
            backgroundImage: backgroundImage,
            child: backgroundImage == null
                ? Icon(Icons.fastfood,
                    size: 80, color: theme.primaryColor.withOpacity(0.5))
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              backgroundColor: theme.primaryColor,
              child: IconButton(
                icon: Icon(Icons.camera_alt, color: theme.colorScheme.onPrimary),
                onPressed: _isSaving ? null : _pickImage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}