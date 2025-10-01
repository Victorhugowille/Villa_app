import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JoinCompanyScreen extends StatefulWidget {
  const JoinCompanyScreen({super.key});

  @override
  State<JoinCompanyScreen> createState() => _JoinCompanyScreenState();
}

class _JoinCompanyScreenState extends State<JoinCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyCnpjController = TextEditingController();

  bool _isLoading = false;

  final _cnpjMaskFormatter = MaskTextInputFormatter(
      mask: '##.###.###/####-##', filter: {"#": RegExp(r'[0-9]')});
      
  final _phoneMaskFormatter = MaskTextInputFormatter(
      mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});

  @override
  void initState() {
    super.initState();
    _emailController.text = 'teste1@gmail.com';
    _passwordController.text = '123456';
    _phoneController.text = '(45) 99999-9999';
    _companyCnpjController.text = '59.902.925/0001-70';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _companyCnpjController.dispose();
    super.dispose();
  }

  Future<void> _submitJoinRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'request-to-join-company',
        body: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'phone': _phoneMaskFormatter.unmaskText(_phoneController.text),
          'companyCnpj': _cnpjMaskFormatter.unmaskText(_companyCnpjController.text), // <-- CORREÇÃO AQUI
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sucesso! Resposta: ${response.data}'),
            backgroundColor: Colors.green,
          ),
        );
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
      appBar: AppBar(title: const Text('Solicitar Acesso')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Seu email de acesso'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Email inválido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Crie uma senha'),
                  obscureText: true,
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'A senha deve ter no mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 16),
                 TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Seu Telefone'),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [_phoneMaskFormatter],
                  validator: (v) => (v == null || v.length < 15) ? 'Telefone inválido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _companyCnpjController,
                  decoration: const InputDecoration(
                      labelText: 'CNPJ da empresa que você trabalha'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [_cnpjMaskFormatter],
                  validator: (v) =>
                      (v == null || v.length < 18) ? 'CNPJ inválido' : null,
                ),
                const SizedBox(height: 30),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _submitJoinRequest,
                    child: const Text('Enviar Solicitação'),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}