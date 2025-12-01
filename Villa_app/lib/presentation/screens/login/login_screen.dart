import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/company_provider.dart';
import 'signup_selection_screen.dart';
import 'privacy_terms_screen.dart';

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

  bool _acceptedPrivacy = true;
  bool _acceptedTerms = true;

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

    bool runCnpjCheck = false;
    if (_emailController.text.isEmpty) {
      _emailController.text = 'victorhugowille@gmail.com';
    }
    if (_passwordController.text.isEmpty) {
      _passwordController.text = '123456';
    }
    if (_cnpjController.text.isEmpty) {
      // Define o texto visualmente
      _cnpjController.text = _cnpjMaskFormatter.maskText('59902925000170');
      runCnpjCheck = true;
    }

    if (runCnpjCheck) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fetchCompanyData();
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

  // Função auxiliar para limpar o CNPJ manualmente
  String _getCleanCnpj() {
    return _cnpjController.text.replaceAll(RegExp(r'[^0-9]'), '');
  }

  void _onCnpjChanged(String cnpj) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      // CORREÇÃO: Usar a limpeza manual do controller
      String unmasked = _getCleanCnpj();
      
      if (unmasked.length == 14) {
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

    // CORREÇÃO: Pega o texto direto do controller e remove símbolos, 
    // garantindo que funcione mesmo no initState
    final unmaskedCnpj = _getCleanCnpj();

    if (unmaskedCnpj.length != 14) {
      if (mounted) setState(() => _isCheckingCnpj = false);
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('companies')
          .select('id, name')
          .eq('cnpj', unmaskedCnpj) // O banco espera apenas números conforme sua imagem
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
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedPrivacy || !_acceptedTerms) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Você precisa aceitar as Políticas de Privacidade e os Termos de Uso.'),
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
    final scaffoldMessenger = ScaffoldMessenger.of(context);

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
      if (supabase.auth.currentUser != null) {
        await supabase.auth.signOut().catchError((_) {});
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateCnpj(String? value) {
    if (value == null || value.isEmpty) {
      return 'CNPJ é obrigatório';
    }
    // CORREÇÃO: Usar o método limpo também na validação
    String unmaskedCnpj = _getCleanCnpj();
    if (unmaskedCnpj.length != 14) {
      return 'CNPJ incompleto';
    }
    return null;
  }

  Future<void> _showTermsDialog(String type) async {
    String title;
    String content;

    if (type == 'privacy') {
      title = 'Políticas de Privacidade';
      content = _privacyPolicyText;
    } else {
      title = 'Termos de Uso';
      content = _termsOfUseText;
    }

    final bool? result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PrivacyTermsScreen(
          title: title,
          content: content,
        ),
        fullscreenDialog: true,
      ),
    );

    if (result == true) {
      if (mounted) {
        setState(() {
          if (type == 'privacy') {
            _acceptedPrivacy = true;
          } else {
            _acceptedTerms = true;
          }
        });
      }
    }
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
                      validator: _validateCnpj,
                    ),
                    SizedBox(
                      height: 24,
                      child: Padding(
                        padding: const EdgeInsets.only(
                            top: 4.0,
                            left: 12.0,
                            right: 12.0),
                        child: Center(
                          child: Text(
                            _isCheckingCnpj
                                ? 'Verificando...'
                                : (_companyName.isNotEmpty && !empresaValida
                                    ? _companyName
                                    : ''),
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
                    const SizedBox(height: 16),

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
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    Container(
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(
                              _acceptedPrivacy
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: _acceptedPrivacy
                                  ? theme.primaryColor
                                  : Colors.grey,
                            ),
                            title: const Text('Políticas de Privacidade'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _isLoading ? null : () => _showTermsDialog('privacy'),
                          ),
                          Divider(height: 1, indent: 16, endIndent: 16),
                          ListTile(
                            leading: Icon(
                              _acceptedTerms
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: _acceptedTerms
                                  ? theme.primaryColor
                                  : Colors.grey,
                            ),
                            title: const Text('Termos de Uso'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _isLoading ? null : () => _showTermsDialog('terms'),
                          ),
                        ],
                      ),
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
                                        const SignUpSelectionScreen(),
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

  final String _privacyPolicyText = """
Bem-vindo ao VillaBistroMobile.

Sua privacidade é importante para nós. Esta política explica como coletamos, usamos e protegemos suas informações.

1. Coleta de Informações
Coletamos informações que você nos fornece diretamente:
- Informações de Cadastro: Nome, e-mail, telefone.
- Informações da Empresa: Razão social, CNPJ, endereço.

2. Uso de Informações
Usamos suas informações para:
- Fornecer e operar nossos serviços.
- Processar transações e enviar informações de faturamento.
- Comunicar com você sobre seu pedido ou conta.

3. Permissões Solicitadas
Para o funcionamento completo do app, poderemos solicitar acesso a:
- Câmera: Para escanear códigos de barras, QR codes de notas fiscais ou fotos de produtos.
- E-mail e Telefone: Para verificação de conta e comunicação essencial.
- Impressora: Para permitir a impressão de pedidos e relatórios via Bluetooth ou Wi-Fi.

4. Compartilhamento de Informações
Não compartilhamos suas informações pessoais com terceiros, exceto:
- Com seu consentimento.
- Para cumprir obrigações legais (como emissão de nota fiscal que exige o CNPJ).
- Com provedores de serviço que nos auxiliam (ex: processamento de pagamento).

5. Segurança
Empregamos medidas de segurança para proteger seus dados.

... (continue com seu texto) ...

Ao rolar até o final, você confirma que leu e compreendeu esta Política de Privacidade.
""";

  final String _termsOfUseText = """
Termos de Uso do VillaBistroMobile

Estes termos regem o uso do nosso aplicativo.

1. Aceite dos Termos
Ao usar nosso app, você concorda com estes termos.

2. Licença de Uso
Concedemos a você uma licença limitada, não exclusiva e intransferível para usar o aplicativo para fins comerciais internos do seu restaurante.

3. Restrições
Você concorda em não:
- Modificar, copiar ou criar trabalhos derivados do app.
- Fazer engenharia reversa.
- Usar o app para fins ilegais.

4. Responsabilidades do Usuário
Você é responsável por:
- Manter a confidencialidade de sua senha.
- Fornecer informações precisas (CNPJ, e-mail, telefone).
- Garantir o uso adequado dos recursos, como a impressão de pedidos.

5. Isenção de Garantia
O aplicativo é fornecido "como está". Não garantimos que o app estará livre de erros.

... (continue com seu texto) ...

Ao rolar até o final, você confirma que leu e concorda com estes Termos de Uso.
""";
}