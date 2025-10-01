import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateCompanyScreen extends StatefulWidget {
  const CreateCompanyScreen({super.key});

  @override
  State<CreateCompanyScreen> createState() => _CreateCompanyScreenState();
}

class _CreateCompanyScreenState extends State<CreateCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  final _cnpjMaskFormatter = MaskTextInputFormatter(
      mask: '##.###.###/####-##', filter: {"#": RegExp(r'[0-9]')});

  final _phoneMaskFormatter = MaskTextInputFormatter(
      mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});

  @override
  void dispose() {
    _companyNameController.dispose();
    _cnpjController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitCreateRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.functions.invoke(
        'request-new-company',
        body: {
          'companyName': _companyNameController.text.trim(),
          'cnpj': _cnpjMaskFormatter.unmaskText(_cnpjController.text), // <-- CORREÇÃO AQUI
          'phone': _phoneMaskFormatter.unmaskText(_phoneController.text), // <-- CORREÇÃO AQUI
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Solicitação enviada com sucesso! Verifique seu e-mail.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ocorreu um erro: ${error.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar Nova Empresa')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _companyNameController,
                  decoration:
                      const InputDecoration(labelText: 'Nome da Empresa'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cnpjController,
                  decoration: const InputDecoration(labelText: 'CNPJ'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [_cnpjMaskFormatter],
                  validator: (v) =>
                      (v == null || v.length < 18) ? 'CNPJ inválido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration:
                      const InputDecoration(labelText: 'Telefone da Empresa'),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [_phoneMaskFormatter],
                  validator: (v) =>
                      (v == null || v.length < 15) ? 'Telefone inválido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration:
                      const InputDecoration(labelText: 'Seu email de administrador'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Email inválido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration:
                      const InputDecoration(labelText: 'Crie uma senha'),
                  obscureText: true,
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'A senha deve ter no mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 30),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _submitCreateRequest,
                    child: const Text('Enviar Solicitação de Cadastro'),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}