import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Preenche os campos com dados de exemplo para o repositório
    _emailController.text = 'user@gmail.com';
    _passwordController.text = 'user123';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ocorreu um erro inesperado.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('VillaBistrô', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: theme.colorScheme.onBackground)),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  style: TextStyle(color: theme.colorScheme.onBackground),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: theme.primaryColor),
                    prefixIcon: Icon(Icons.person_outline, color: theme.primaryColor),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.primaryColor)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.colorScheme.onBackground.withOpacity(0.5))),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => (value == null || !value.contains('@')) ? 'Por favor, insira um email válido.' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  style: TextStyle(color: theme.colorScheme.onBackground),
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    labelStyle: TextStyle(color: theme.primaryColor),
                    prefixIcon: Icon(Icons.lock_outline, color: theme.primaryColor),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.primaryColor)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.colorScheme.onBackground.withOpacity(0.5))),
                  ),
                  obscureText: true,
                  validator: (value) => (value == null || value.length < 6) ? 'A senha deve ter no mínimo 6 caracteres.' : null,
                ),
                const SizedBox(height: 30),
                if (_isLoading)
                  CircularProgressIndicator(color: theme.primaryColor)
                else
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('ENTRAR'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}