import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../data/app_data.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/product_provider.dart';

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
  late String? _categoryId;
  late bool _isSoldOut;

  Product? _currentProduct;
  bool get _isEditMode => _currentProduct != null;

  List<Category> _availableCategories = [];
  bool _isLoading = true;
  bool _isSaving = false;
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  List<GrupoAdicional> _localGrupos = [];

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;

    if (_isEditMode) {
      _name = _currentProduct!.name;
      _price = _currentProduct!.price;
      _categoryId = _currentProduct!.categoryId;
      _isSoldOut = _currentProduct!.isSoldOut;
    } else {
      _name = '';
      _price = 0.0;
      _categoryId = null;
      _isSoldOut = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);

    if (_isEditMode) {
      _localGrupos = await productProvider
          .getGruposAdicionaisParaProduto(_currentProduct!.id);
    }

    if (productProvider.categories.isEmpty) {
      await productProvider.fetchData();
    }

    if (!mounted) return;
    _availableCategories = productProvider.categories;

    if (_availableCategories.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('Nenhuma categoria cadastrada. Crie uma categoria primeiro.'),
        backgroundColor: Colors.red,
      ));
      Navigator.of(context).pop();
      return;
    }

    if (_categoryId == null && _availableCategories.isNotEmpty) {
      _categoryId = _availableCategories.first.id;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<XFile?> _pickImageFromGallery() async {
    return await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 50);
  }

  void _saveForm() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Por favor, selecione uma categoria.'),
          backgroundColor: Colors.red));
      return;
    }
    _formKey.currentState!.save();

    setState(() => _isSaving = true);
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    final isMobile = MediaQuery.of(context).size.width <= 800;

    try {
      if (_isEditMode) {
        await productProvider.updateProduct(_currentProduct!.id, _name, _price,
            _categoryId!, _isSoldOut, _imageFile);

        if (!mounted) return;
        isMobile ? Navigator.of(context).pop() : navProvider.pop();
      } else {
        final newProductId = await productProvider.addProduct(
            _name, _price, _categoryId!, _isSoldOut, _imageFile);

        await productProvider.fetchData();

        if (!mounted) return;
        final newProduct = productProvider.products.firstWhere(
            (p) => p.id == newProductId,
            orElse: () => _currentProduct!);

        setState(() {
          _currentProduct = newProduct;
          _localGrupos = [];
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Produto criado! Agora você pode adicionar grupos.'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar produto: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text(
            'Tem certeza? Todos os grupos e adicionais vinculados também serão apagados.'),
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

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    final isMobile = MediaQuery.of(context).size.width <= 800;

    try {
      await Provider.of<ProductProvider>(context, listen: false)
          .deleteProduct(_currentProduct!.id);
      if (!mounted) return;
      isMobile ? Navigator.of(context).pop() : navProvider.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao apagar: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _duplicateProduct() async {
    if (_currentProduct == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Duplicar Produto'),
        content: Text(
            'Deseja criar uma cópia de "${_currentProduct!.name}"? Todos os seus grupos e adicionais também serão duplicados.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Duplicar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    final isMobile = MediaQuery.of(context).size.width <= 800;

    try {
      await Provider.of<ProductProvider>(context, listen: false)
          .duplicateProduct(_currentProduct!.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Produto duplicado com sucesso!'),
        backgroundColor: Colors.green,
      ));
      isMobile ? Navigator.of(context).pop() : navProvider.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao duplicar: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _registerActions() {
    if (!mounted) return;
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    navProvider.setScreenActions([
      if (_isEditMode)
        IconButton(
          icon: const Icon(Icons.copy_outlined),
          tooltip: 'Duplicar Produto',
          onPressed: _isSaving ? null : _duplicateProduct,
        ),
      if (_isEditMode)
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Apagar Produto',
          onPressed: _isSaving ? null : _deleteProduct,
        ),
      if (_isSaving)
        const Padding(
          padding: EdgeInsets.all(12.0),
          child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2)),
        )
      else
        IconButton(
          icon: const Icon(Icons.save_outlined),
          tooltip: 'Salvar',
          onPressed: _saveForm,
        ),
    ]);
  }

  Future<void> _onReorderGrupo(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _localGrupos.removeAt(oldIndex);
      _localGrupos.insert(newIndex, item);
    });

    try {
      await Provider.of<ProductProvider>(context, listen: false)
          .updateGrupoAdicionalOrder(_localGrupos);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro: ${e.toString()}')));
      _loadInitialData();
    }
  }

  Future<void> _onReorderAdicional(
      int oldIndex, int newIndex, GrupoAdicional grupo) async {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = grupo.adicionais.removeAt(oldIndex);
      grupo.adicionais.insert(newIndex, item);
    });

    try {
      await Provider.of<ProductProvider>(context, listen: false)
          .updateAdicionalOrder(grupo.adicionais);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro: ${e.toString()}')));
      _loadInitialData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    Widget formContent = _isLoading
        ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
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
                  onSaved: (v) =>
                      _price = double.parse(v!.replaceAll(',', '.')),
                ),
                DropdownButtonFormField<String>(
                  value: _categoryId,
                  items: _availableCategories
                      .map((c) => DropdownMenuItem<String>(
                          value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged:
                      _isSaving ? null : (v) => setState(() => _categoryId = v),
                  validator: (v) =>
                      (v == null) ? 'Selecione uma categoria.' : null,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Produto Esgotado'),
                  value: _isSoldOut,
                  onChanged: _isSaving
                      ? null
                      : (value) => setState(() => _isSoldOut = value),
                  activeColor: theme.primaryColor,
                ),
                const SizedBox(height: 24),
                const Divider(),
                _buildGruposAdicionaisSection(theme),
              ],
            ),
          );

    if (isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _registerActions();
      });
      return formContent;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar Produto' : 'Adicionar Produto'),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.copy_outlined),
              tooltip: 'Duplicar Produto',
              onPressed: _isSaving ? null : _duplicateProduct,
            ),
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Apagar Produto',
              onPressed: _isSaving ? null : _deleteProduct,
            ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  )),
            )
          else
            IconButton(
              icon: const Icon(Icons.save_outlined),
              tooltip: 'Salvar',
              onPressed: _saveForm,
            ),
        ],
      ),
      body: formContent,
    );
  }

  // **MUDANÇA AQUI**
  void _showGrupoDialog({GrupoAdicional? grupo}) {
    final isEditing = grupo != null;
    final nameController = TextEditingController(text: grupo?.name ?? '');
    // Controladores para min e max
    final minController =
        TextEditingController(text: grupo?.minQuantity.toString() ?? '0');
    final maxController =
        TextEditingController(text: grupo?.maxQuantity?.toString() ?? '');

    XFile? dialogImageFile;
    String? existingImageUrl = grupo?.imageUrl;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (stfContext, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Editar Grupo' : 'Novo Grupo'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogImagePicker(
                      existingImageUrl: existingImageUrl,
                      pickedFile: dialogImageFile,
                      onPickImage: () async {
                        final file = await _pickImageFromGallery();
                        if (file != null) {
                          setDialogState(() => dialogImageFile = file);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                          labelText: 'Nome do Grupo (Ex: "Escolha o molho")'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: minController,
                            decoration:
                                const InputDecoration(labelText: 'Mínimo'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: maxController,
                            decoration: const InputDecoration(
                                labelText: 'Máximo',
                                hintText: 'Sem limite'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(stfContext).pop(),
                    child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) return;

                    final navigator = Navigator.of(stfContext);

                    // Pega os valores de min e max
                    final int min = int.tryParse(minController.text) ?? 0;
                    final int? max = maxController.text.isEmpty
                        ? null
                        : int.tryParse(maxController.text);

                    try {
                      final productProvider =
                          Provider.of<ProductProvider>(context, listen: false);
                      if (isEditing) {
                        // Passa os novos valores
                        await productProvider.updateGrupoAdicional(grupo.id,
                            nameController.text, dialogImageFile, min, max);
                      } else {
                        // Passa os novos valores
                        await productProvider.addGrupoAdicional(
                            nameController.text,
                            _currentProduct!.id,
                            dialogImageFile,
                            min,
                            max);
                      }
                      await _loadInitialData();
                      navigator.pop();
                    } catch (e) {
                      if (mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro: ${e.toString()}')));
                    }
                  },
                  child: const Text('Salvar'),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _showAdicionalDialog({Adicional? adicional, required String grupoId}) {
    final isEditing = adicional != null;
    final nameController = TextEditingController(text: adicional?.name ?? '');
    final priceController = TextEditingController(
        text: adicional != null ? adicional.price.toStringAsFixed(2) : '');
    final formKey = GlobalKey<FormState>();
    XFile? dialogImageFile;
    String? existingImageUrl = adicional?.imageUrl;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (stfContext, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Editar Adicional' : 'Novo Adicional'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDialogImagePicker(
                        existingImageUrl: existingImageUrl,
                        pickedFile: dialogImageFile,
                        onPickImage: () async {
                          final file = await _pickImageFromGallery();
                          if (file != null) {
                            setDialogState(() => dialogImageFile = file);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Nome'),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Insira um nome' : null,
                      ),
                      TextFormField(
                        controller: priceController,
                        decoration: const InputDecoration(
                            labelText: 'Preço (0 para sem custo)'),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => (v == null ||
                                v.isEmpty ||
                                double.tryParse(v.replaceAll(',', '.')) == null)
                            ? 'Preço inválido'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(stfContext).pop(),
                    child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final name = nameController.text;
                    final price =
                        double.parse(priceController.text.replaceAll(',', '.'));
                    final navigator = Navigator.of(stfContext);

                    try {
                      final productProvider =
                          Provider.of<ProductProvider>(context, listen: false);
                      if (isEditing) {
                        await productProvider.updateAdicional(
                            id: adicional.id,
                            name: name,
                            price: price,
                            imageFile: dialogImageFile);
                      } else {
                        await productProvider.addAdicionalToGrupo(
                            name: name,
                            price: price,
                            grupoId: grupoId,
                            imageFile: dialogImageFile);
                      }
                      await _loadInitialData();
                      navigator.pop();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro: ${e.toString()}')));
                      }
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildGruposAdicionaisSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Grupos de Adicionais',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (_isEditMode)
              IconButton(
                icon: const Icon(Icons.add_circle),
                color: theme.primaryColor,
                tooltip: 'Adicionar Grupo',
                onPressed: _isSaving ? null : () => _showGrupoDialog(),
              )
            else
              const Tooltip(
                message: 'Salve o produto para adicionar grupos',
                child: Icon(Icons.add_circle_outline, color: Colors.grey),
              ),
          ],
        ),
        if (_isEditMode && _localGrupos.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
                'Nenhum grupo de adicionais cadastrado para este produto.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _localGrupos.length,
            buildDefaultDragHandles: false,
            onReorder: _onReorderGrupo,
            itemBuilder: (context, index) {
              final grupo = _localGrupos[index];

              // **MUDANÇA AQUI**
              String subtitleText =
                  'Obrigatório: ${grupo.minQuantity}';
              if (grupo.maxQuantity != null) {
                subtitleText += ', Máximo: ${grupo.maxQuantity}';
              } else {
                subtitleText += ', Máximo: Sem limite';
              }

              return Card(
                key: ValueKey(grupo.id),
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 2,
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundImage: (grupo.imageUrl != null
                        ? NetworkImage(grupo.imageUrl!)
                        : null) as ImageProvider?,
                    child:
                        grupo.imageUrl == null ? const Icon(Icons.layers) : null,
                  ),
                  title: Text(grupo.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  // **MUDANÇA AQUI**
                  subtitle: Text(subtitleText,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy_outlined,
                            size: 20, color: Colors.blueGrey),
                        tooltip: 'Duplicar Grupo',
                        onPressed: () async {
                          try {
                            await Provider.of<ProductProvider>(context,
                                    listen: false)
                                .duplicateGrupoAdicional(grupo.id);
                            await _loadInitialData();
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Erro: ${e.toString()}')));
                            }
                          }
                        },
                      ),
                      IconButton(
                          icon: const Icon(Icons.edit,
                              size: 20, color: Colors.blueGrey),
                          onPressed: () => _showGrupoDialog(grupo: grupo)),
                      IconButton(
                          icon: const Icon(Icons.delete,
                              size: 20, color: Colors.redAccent),
                          onPressed: () async {
                            await Provider.of<ProductProvider>(context,
                                    listen: false)
                                .deleteGrupoAdicional(grupo.id);
                            await _loadInitialData();
                          }),
                      ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.drag_indicator),
                        ),
                      ),
                    ],
                  ),
                  children: [
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: grupo.adicionais.length,
                      itemBuilder: (ctx, adicionalIndex) {
                        final adicional = grupo.adicionais[adicionalIndex];
                        return ListTile(
                          key: ValueKey(adicional.id),
                          leading: CircleAvatar(
                            backgroundImage: (adicional.imageUrl != null
                                ? NetworkImage(adicional.imageUrl!)
                                : null) as ImageProvider?,
                            child: adicional.imageUrl == null
                                ? const Icon(Icons.add, size: 20)
                                : null,
                          ),
                          title: Text(adicional.name),
                          subtitle:
                              Text('R\$ ${adicional.price.toStringAsFixed(2)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                  icon: const Icon(Icons.copy_outlined, size: 18),
                                  tooltip: 'Duplicar Item',
                                  onPressed: () async {
                                    try {
                                      await Provider.of<ProductProvider>(
                                              context,
                                              listen: false)
                                          .duplicateAdicional(adicional.id);
                                      await _loadInitialData();
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(
                                                    'Erro: ${e.toString()}')));
                                      }
                                    }
                                  }),
                              IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  onPressed: () => _showAdicionalDialog(
                                      adicional: adicional,
                                      grupoId: grupo.id)),
                              IconButton(
                                  icon: const Icon(Icons.delete, size: 18),
                                  onPressed: () async {
                                    await Provider.of<ProductProvider>(
                                            context,
                                            listen: false)
                                        .deleteAdicional(adicional.id);
                                    await _loadInitialData();
                                  }),
                              ReorderableDragStartListener(
                                index: adicionalIndex,
                                child: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(Icons.drag_indicator, size: 20),
                                ),
                              )
                            ],
                          ),
                        );
                      },
                      onReorder: (oldI, newI) =>
                          _onReorderAdicional(oldI, newI, grupo),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          right: 16.0, bottom: 8.0, top: 8.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Adicionar Item'),
                          onPressed: () =>
                              _showAdicionalDialog(grupoId: grupo.id),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildImagePicker(ThemeData theme) {
    ImageProvider? backgroundImage;
    if (_imageFile != null) {
      backgroundImage = FileImage(File(_imageFile!.path));
    } else if (_isEditMode && _currentProduct!.imageUrl != null) {
      backgroundImage = NetworkImage(_currentProduct!.imageUrl!);
    }

    return Center(
      child: GestureDetector(
        onTap: () async {
          final file = await _pickImageFromGallery();
          if (file != null) {
            setState(() => _imageFile = file);
          }
        },
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
                child:
                    Icon(Icons.camera_alt, color: theme.colorScheme.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogImagePicker(
      {String? existingImageUrl,
      XFile? pickedFile,
      required VoidCallback onPickImage}) {
    final theme = Theme.of(context);
    ImageProvider? image;
    if (pickedFile != null) {
      image = FileImage(File(pickedFile.path));
    } else if (existingImageUrl != null) {
      image = NetworkImage(existingImageUrl);
    }

    return GestureDetector(
      onTap: onPickImage,
      child: CircleAvatar(
        radius: 40,
        backgroundColor: theme.primaryColor.withOpacity(0.1),
        backgroundImage: image,
        child: image == null
            ? Icon(Icons.add_a_photo, color: theme.primaryColor)
            : const Icon(Icons.edit, color: Colors.white70),
      ),
    );
  }
}