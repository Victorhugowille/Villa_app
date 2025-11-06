// lib/screens/login/login_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:villabistromobile/providers/company_provider.dart';
import 'package:villabistromobile/screens/login/signup_selection_screen.dart'; // Ajuste o caminho se necessário

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
  bool _obscurePassword = true;

  String _companyName = '';
  String? _verifiedCompanyId;
  Timer? _debounce;

  final _cnpjMaskFormatter = MaskTextInputFormatter(
      mask: '##.###.###/####-##',
      filter: {"#": RegExp(r'[0-9]')},
      type: MaskAutoCompletionType.lazy);

  @override
  void initState() {
    super.initState();

    // --- CORREÇÃO AQUI ---
    // Só preenchemos os campos se eles estiverem vazios.
    // Isso mantém os dados de teste no Hot Restart,
    // mas preserva suas edições durante um Hot Reload.
    bool runCnpjCheck = false;
    if (_emailController.text.isEmpty) {
      _emailController.text = 'victorhugowille@gmail.com';
    }
    if (_passwordController.text.isEmpty) {
      _passwordController.text = '123456';
    }
    if (_cnpjController.text.isEmpty) {
      _cnpjController.text = _cnpjMaskFormatter.maskText('59902925000170');
      runCnpjCheck = true; // Marca para verificar o CNPJ
    }
    // --- FIM DA CORREÇÃO ---

    // Verifica o CNPJ inicial após a primeira renderização,
    // mas somente se o preenchemos agora.
    if (runCnpjCheck) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fetchCompanyData(); // Chama a verificação inicial
        }
      });
    }
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
      String unmasked = _cnpjMaskFormatter.getUnmaskedText();
      if (unmasked.length == 14) { // Verifica pelo tamanho sem máscara
        _fetchCompanyData();
      } else {
        if (mounted) {
          setState(() {
            _companyName = '';
            _verifiedCompanyId = null;
          });
        }
      }
    });
  }

  Future<void> _fetchCompanyData() async {
    if (!mounted) return;
    setState(() {
      _isCheckingCnpj = true;
      _companyName = '';
      _verifiedCompanyId = null;
    });

    final unmaskedCnpj = _cnpjMaskFormatter.getUnmaskedText();
    if (unmaskedCnpj.length != 14) {
      if (mounted) setState(() => _isCheckingCnpj = false);
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('companies')
          .select('id, name')
          .eq('cnpj', unmaskedCnpj)
          .maybeSingle();

      if (mounted) {
        setState(() {
          if (response != null) {
            _companyName = response['name'];
            _verifiedCompanyId = response['id'];
          } else {
            _companyName = 'Empresa não encontrada';
            _verifiedCompanyId = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _companyName = 'Erro ao buscar';
          _verifiedCompanyId = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingCnpj = false);
      }
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus(); // Esconde teclado
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedPrivacy) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você precisa aceitar as políticas de privacidade.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_verifiedCompanyId == null ||
        _companyName == 'Empresa não encontrada' ||
        _companyName == 'Erro ao buscar') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Por favor, informe um CNPJ de uma empresa válida.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;
    final scaffoldMessenger =
        ScaffoldMessenger.of(context); // Guarda para uso seguro após await

    try {
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final userId = supabase.auth.currentUser!.id;

      final profileResponse = await supabase
          .from('profiles')
          .select('company_id')
          .eq('user_id', userId)
          .single();

      final userCompanyId = profileResponse['company_id'];

      if (userCompanyId != null && userCompanyId == _verifiedCompanyId) {
        if (mounted) {
          await Provider.of<CompanyProvider>(context, listen: false)
              .fetchCompanyForCurrentUser();
          // Certifique-se que '/home' está definido nas suas rotas
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        if (mounted) {
          scaffoldMessenger.showSnackBar(const SnackBar(
            content:
                Text('Este usuário não tem permissão para acessar esta empresa.'),
            backgroundColor: Colors.red,
          ));
        }
        // Desloga o usuário se a empresa não bate
        await supabase.auth.signOut();
      }
    } on SocketException catch (_) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text('Sem conexão com a internet. Verifique sua rede.'),
          backgroundColor: Colors.orange,
        ));
      }
    } on AuthException catch (error) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(
              'Ocorreu um erro: ${e is PostgrestException ? e.message : e.toString()}'),
          backgroundColor: Colors.red,
        ));
      }
      // Garante deslogar se houver erro após autenticação parcial
      if (supabase.auth.currentUser != null) {
        await supabase.auth.signOut().catchError((_) {}); // Ignora erro no signOut
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateCnpj(String? value) {
    if (value == null || value.isEmpty) {
      return 'CNPJ é obrigatório';
    }
    String unmaskedCnpj = _cnpjMaskFormatter.getUnmaskedText();
    if (unmaskedCnpj.length != 14) {
      return 'CNPJ incompleto';
    }
    // Adicione validação de dígito verificador se necessário
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool empresaValida = _verifiedCompanyId != null;

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
                    Icon(Icons.storefront,
                        size: 60, color: theme.primaryColor),
                    const SizedBox(height: 16),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        empresaValida
                            ? 'Bem-vindo à\n$_companyName'
                            : 'Bem-vindo',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _cnpjController,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        labelText: 'CNPJ da Empresa',
                        prefixIcon: const Icon(Icons.business_center_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        suffixIcon: _isCheckingCnpj
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)))
                            : _companyName.isNotEmpty
                                ? Icon(
                                    empresaValida
                                        ? Icons.check_circle_outline
                                        : Icons.error_outline,
                                    color: empresaValida
                                        ? Colors.green
                                        : Colors.red)
                                : null,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [_cnpjMaskFormatter],
                      onChanged: _onCnpjChanged,
                      validator: _validateCnpj, // Usa a função separada
                    ),
                    // Espaço para feedback sem empurrar layout se nome for grande
                    SizedBox(
                      height: 24,
                      child: Padding(
                        padding: const EdgeInsets.only(
                            top: 4.0,
                            left: 12.0,
                            right: 12.0), // Ajuste padding
                        child: Center(
                          child: Text(
                            _isCheckingCnpj
                                ? 'Verificando...'
                                : (_companyName.isNotEmpty && !empresaValida
                                    ? _companyName
                                    : ''), // Só mostra erro aqui
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16), // Espaço ajustado

                    TextFormField(
                      controller: _emailController,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty)
                          return 'Email é obrigatório';
                        if (!value.contains('@') || !value.contains('.'))
                          return 'Formato de email inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Senha é obrigatória';
                        // if (v.length < 6) return 'Mínimo 6 caracteres'; // Exemplo
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Checkbox(
                          value: _acceptedPrivacy,
                          onChanged: _isLoading
                              ? null
                              : (v) =>
                                  setState(() => _acceptedPrivacy = v ?? false),
                        ),
                        Flexible(
                          child: GestureDetector(
                            onTap: () {
                              // TODO: Mostrar dialog/modal com as políticas
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Exibir políticas de privacidade...')),
                              );
                            },
                            child: const Text(
                              "Li e aceito as Políticas de Privacidade",
                              style:
                                  TextStyle(decoration: TextDecoration.underline),
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
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _submit,
                            child: const Text('ENTRAR',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Não tem uma conta?'),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) =>
                                        const SignUpSelectionScreen(), // Verifique o nome da tela
                                  ));
                                },
                          child: const Text('Cadastre-se'),
                        ),
                      ],
                    ),
                    // Botão "Esqueci minha senha" (opcional)
                    // TextButton(
                    //   onPressed: _isLoading ? null : () { /* Implementar recuperação */ },
                    //   child: const Text('Esqueci minha senha'),
                    // ),
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