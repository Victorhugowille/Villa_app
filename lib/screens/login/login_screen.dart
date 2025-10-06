import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:villabistromobile/providers/company_provider.dart';
import 'package:villabistromobile/screens/login/signup_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cnpjController = TextEditingController();

  bool _isLoading = false;
  bool _isCheckingCnpj = false;
  bool _acceptedPrivacy = false;

  String _companyName = '';
  Timer? _debounce;

  final _cnpjMaskFormatter =
      MaskTextInputFormatter(mask: '##.###.###/####-##', filter: {"#": RegExp(r'[0-9]')});

  @override
  void initState() {
    super.initState();
    _emailController.text = 'victorhugowille@gmail.com';
    _passwordController.text = '123456';
    _cnpjController.text = '59.902.925/0001-70';
    _fetchCompanyName();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _cnpjController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onCnpjChanged(String cnpj) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      if (cnpj.length == 18) {
        _fetchCompanyName();
      } else {
        if (mounted) setState(() => _companyName = '');
      }
    });
  }

  Future<void> _fetchCompanyName() async {
    if (!mounted) return;
    setState(() {
      _isCheckingCnpj = true;
      _companyName = '';
    });

    final unmaskedCnpj = _cnpjMaskFormatter.getUnmaskedText();
    if (unmaskedCnpj.length != 14) {
      setState(() {
        _isCheckingCnpj = false;
      });
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('companies')
          .select('name')
          .eq('cnpj', unmaskedCnpj)
          .maybeSingle();

      if (mounted && response != null) {
        setState(() {
          _companyName = response['name'];
        });
      } else if (mounted) {
        setState(() {
          _companyName = 'Empresa não encontrada';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _companyName = 'Erro ao buscar';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingCnpj = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa aceitar as políticas de privacidade.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        await Provider.of<CompanyProvider>(context, listen: false).fetchCompanyForCurrentUser();
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool empresaValida = _companyName.isNotEmpty &&
        _companyName != 'Empresa não encontrada' &&
        _companyName != 'Erro ao buscar';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.storefront, size: 60, color: theme.primaryColor),
                    const SizedBox(height: 16),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        empresaValida ? 'Bem-vindo à\n$_companyName' : 'Bem-vindo',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    TextFormField(
                      controller: _cnpjController,
                      decoration: InputDecoration(
                        labelText: 'CNPJ da Empresa',
                        prefixIcon: const Icon(Icons.business_center_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [_cnpjMaskFormatter],
                      onChanged: _onCnpjChanged,
                      validator: (v) => (v == null || v.length < 18) ? 'CNPJ inválido' : null,
                    ),
                    SizedBox(
                      height: 24,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: _isCheckingCnpj
                            ? const Center(
                                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                            : Center(
                                child: Text(
                                  _companyName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: empresaValida ? theme.primaryColor.withOpacity(0.8) : Colors.redAccent,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      obscureText: true,
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Checkbox(
                          value: _acceptedPrivacy,
                          onChanged: (v) => setState(() => _acceptedPrivacy = v ?? false),
                        ),
                        Flexible(
                          child: GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Exibir políticas de privacidade...')),
                              );
                            },
                            child: const Text(
                              "Li e aceito as Políticas de Privacidade",
                              style: TextStyle(decoration: TextDecoration.underline),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _submit,
                            child: const Text('ENTRAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Não tem uma conta?'),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => const SignUpSelectionScreen(),
                            ));
                          },
                          child: const Text('Cadastre-se'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}