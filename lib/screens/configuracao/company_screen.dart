import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // NOVO PACOTE
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:villabistromobile/data/app_data.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:villabistromobile/providers/company_provider.dart';
import 'package:provider/provider.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  String? _errorMessage;

  Company? _company;

  final _nameController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();

  final _cnpjMaskFormatter = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _telefoneMaskFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _company = context.read<CompanyProvider>().currentCompany;
    _populateForm();
  }

  void _populateForm() {
    if (_company != null) {
      _nameController.text = _company!.name;
      _cnpjController.text = _company!.cnpj ?? '';
      _telefoneController.text = _company!.telefone ?? '';
      _ruaController.text = _company!.rua ?? '';
      _numeroController.text = _company!.numero ?? '';
      _bairroController.text = _company!.bairro ?? '';
      _cidadeController.text = _company!.cidade ?? '';
      _estadoController.text = _company!.estado ?? '';
      setState(() {
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Não foi possível carregar os dados da empresa. Verifique sua conexão e tente novamente.';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cnpjController.dispose();
    _telefoneController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    if (_company == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Erro: Não há dados da empresa para salvar.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedData = {
        'id': _company!.id,
        'name': _nameController.text.trim(),
        'cnpj': _cnpjMaskFormatter.getUnmaskedText(),
        'telefone': _telefoneMaskFormatter.getUnmaskedText(),
        'rua': _ruaController.text.trim(),
        'numero': _numeroController.text.trim(),
        'bairro': _bairroController.text.trim(),
        'cidade': _cidadeController.text.trim(),
        'estado': _estadoController.text.trim(),
      };

      await _supabase
          .from('companies')
          .update(updatedData)
          .eq('id', _company!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Dados da empresa salvos com sucesso!')),
        );
        context.read<CompanyProvider>().fetchCompanyForCurrentUser();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar dados: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // NOVA FUNÇÃO PARA UPLOAD DA LOGO 📸
  Future<void> _uploadLogo() async {
    if (_company == null) return;

    final picker = ImagePicker();
    final imageFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Comprime a imagem para economizar espaço
    );

    if (imageFile == null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
      
      // ### CORREÇÃO AQUI ###
      // O caminho não deve começar com 'public/'. O bucket já é público.
      final filePath = '${_company!.id}/$fileName';

      await _supabase.storage.from('product_images').uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$fileExt'),
          );

      final imageUrl =
          _supabase.storage.from('product_images').getPublicUrl(filePath);

      await _supabase
          .from('companies')
          .update({'logo_url': imageUrl})
          .eq('id', _company!.id);

      if (mounted) {
        // Atualiza os dados da empresa no provider para refletir a nova logo
        await context.read<CompanyProvider>().fetchCompanyForCurrentUser();
        // Atualiza o state local para redesenhar a tela
        setState(() {
          _company = context.read<CompanyProvider>().currentCompany;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logo atualizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on StorageException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro no upload: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ocorreu um erro: ${e.toString()}'),
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
  Future<void> _resetOrderCounter() async {
    if (_company == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Ação'),
        content: const Text(
            'Você tem certeza que deseja zerar a CONTAGEM de pedidos? Os pedidos antigos serão mantidos, mas a numeração para novos pedidos recomeçará do 1.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange.shade700),
            child: const Text('Zerar Contagem'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _supabase
          .from('pedidos')
          .update({'contador_ativo': false})
          .eq('company_id', _company!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Contador de pedidos zerado com sucesso!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao zerar contador: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pega a URL da logo do provider, que é a fonte mais atualizada dos dados
    final logoUrl = context.watch<CompanyProvider>().currentCompany?.logoUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text(_company?.name ?? 'Dados da Empresa'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _company == null ? null : _resetOrderCounter,
        label: const Text('Zerar Contador'),
        icon: const Icon(Icons.refresh),
        backgroundColor: Colors.orange.shade700,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade300)),
                ))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // NOVO WIDGET PARA EXIBIR E EDITAR A LOGO
                        Center(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey.shade800,
                                backgroundImage:
                                    logoUrl != null ? NetworkImage(logoUrl) : null,
                                child: logoUrl == null
                                    ? const Icon(Icons.store,
                                        size: 50, color: Colors.white70)
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Theme.of(context).primaryColor,
                                  child: IconButton(
                                    icon: const Icon(Icons.edit,
                                        size: 20, color: Colors.white),
                                    onPressed: _uploadLogo,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        TextFormField(
                          controller: _nameController,
                          decoration:
                              const InputDecoration(labelText: 'Nome Fantasia'),
                          validator: (value) =>
                              value!.isEmpty ? 'Campo obrigatório' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _cnpjController,
                          inputFormatters: [_cnpjMaskFormatter],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'CNPJ'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _telefoneController,
                          inputFormatters: [_telefoneMaskFormatter],
                          keyboardType: TextInputType.phone,
                          decoration:
                              const InputDecoration(labelText: 'Telefone'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _ruaController,
                          decoration: const InputDecoration(labelText: 'Rua'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _numeroController,
                          decoration:
                              const InputDecoration(labelText: 'Número'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _bairroController,
                          decoration:
                              const InputDecoration(labelText: 'Bairro'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _cidadeController,
                          decoration:
                              const InputDecoration(labelText: 'Cidade'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _estadoController,
                          decoration:
                              const InputDecoration(labelText: 'Estado (UF)'),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed:
                              _isLoading || _company == null ? null : _saveData,
                          icon: const Icon(Icons.save),
                          label: const Text('Salvar Alterações'),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
    );
  }
}