import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:villabistromobile/data/app_data.dart'; // Ajuste o import

class EstabelecimentoScreen extends StatefulWidget {
  const EstabelecimentoScreen({super.key});

  @override
  State<EstabelecimentoScreen> createState() => _EstabelecimentoScreenState();
}

class _EstabelecimentoScreenState extends State<EstabelecimentoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Estabelecimento? _estabelecimento;

  final _nomeFantasiaController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchEstabelecimento();
  }

  @override
  void dispose() {
    _nomeFantasiaController.dispose();
    _cnpjController.dispose();
    _telefoneController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  Future<void> _fetchEstabelecimento() async {
    try {
      final response = await _supabase
          .from('estabelecimentos')
          .select()
          .limit(1)
          .maybeSingle();

      if (response != null) {
        _estabelecimento = Estabelecimento.fromJson(response);
        _nomeFantasiaController.text = _estabelecimento!.nomeFantasia;
        _cnpjController.text = _estabelecimento!.cnpj;
        _telefoneController.text = _estabelecimento!.telefone;
        _ruaController.text = _estabelecimento!.rua;
        _numeroController.text = _estabelecimento!.numero;
        _bairroController.text = _estabelecimento!.bairro;
        _cidadeController.text = _estabelecimento!.cidade;
        _estadoController.text = _estabelecimento!.estado;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao buscar dados: ${e.toString()}')),
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

  Future<void> _salvarDados() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedEstabelecimento = Estabelecimento(
        id: _estabelecimento?.id,
        nomeFantasia: _nomeFantasiaController.text.trim(),
        cnpj: _cnpjController.text.trim(),
        telefone: _telefoneController.text.trim(),
        rua: _ruaController.text.trim(),
        numero: _numeroController.text.trim(),
        bairro: _bairroController.text.trim(),
        cidade: _cidadeController.text.trim(),
        estado: _estadoController.text.trim(),
      );

      await _supabase.from('estabelecimentos').upsert(updatedEstabelecimento.toJson());

      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dados salvos com sucesso!')),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dados do Estabelecimento'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nomeFantasiaController,
                      decoration: const InputDecoration(labelText: 'Nome Fantasia'),
                      validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cnpjController,
                      decoration: const InputDecoration(labelText: 'CNPJ'),
                       validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _telefoneController,
                      decoration: const InputDecoration(labelText: 'Telefone'),
                       validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                    ), 
                    TextFormField(
                      controller: _ruaController,
                      decoration: const InputDecoration(labelText: 'Rua'),
                       validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _numeroController,
                      decoration: const InputDecoration(labelText: 'Número'),
                       validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bairroController,
                      decoration: const InputDecoration(labelText: 'Bairro'),
                       validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cidadeController,
                      decoration: const InputDecoration(labelText: 'Cidade'),
                       validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _estadoController,
                      decoration: const InputDecoration(labelText: 'Estado (UF)'),
                       validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _salvarDados,
                      icon: const Icon(Icons.save),
                      label: const Text('Salvar Alterações'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}