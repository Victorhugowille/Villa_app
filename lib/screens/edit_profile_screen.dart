// lib/screens/profile/edit_profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:villabistromobile/providers/company_provider.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  final _phoneMaskFormatter = MaskTextInputFormatter(
      mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});

  bool _isLoading = false;
  File? _selectedImage;
  String? _currentAvatarUrl;
  String? _userId;

  @override
  void initState() {
    super.initState();
    final provider = context.read<CompanyProvider>();

    _nameController.text = provider.fullName ?? '';
    _emailController.text = provider.email ?? '';
    _currentAvatarUrl = provider.avatarUrl;
    _userId = provider.userId;

    _phoneController.text = provider.phoneNumber ?? '';
    if (provider.phoneNumber != null) {
      _phoneController.text =
          _phoneMaskFormatter.maskText(provider.phoneNumber!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _userId == null) {
      return;
    }
    setState(() => _isLoading = true);

    String? newAvatarUrl;
    final String unmaskedPhone =
        _phoneMaskFormatter.unmaskText(_phoneController.text);
    final String fullName = _nameController.text.trim();
    final String newEmail = _emailController.text.trim();
    final String? oldEmail = context.read<CompanyProvider>().email;

    try {
      // 1. Se uma nova imagem foi selecionada, faz o upload
      if (_selectedImage != null) {
        final String fileExt = _selectedImage!.path.split('.').last;
        final String filePath = '$_userId/profile.$fileExt';

        // --- MUDANÇA AQUI ---
        await _supabase.storage.from('foto_profile').upload( // Era 'avatars'
              filePath,
              _selectedImage!,
              fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
            );

        // --- MUDANÇA AQUI ---
        newAvatarUrl = _supabase.storage.from('foto_profile').getPublicUrl(filePath); // Era 'avatars'

        // Adiciona o carimbo de tempo para quebrar o cache
        newAvatarUrl =
            '$newAvatarUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      }

      // 2. Se o email mudou, atualiza no 'auth.users'
      if (newEmail != oldEmail) {
        await _supabase.auth.updateUser(UserAttributes(email: newEmail));
      }

      // 3. Prepara os dados para atualizar na tabela 'profiles'
      final Map<String, dynamic> updates = {
        'full_name': fullName,
        'phone_number': unmaskedPhone,
        'updated_at': DateTime.now().toIso8601String(),
        if (newAvatarUrl != null) 'avatar_url': newAvatarUrl,
      };

      // 4. Atualiza a tabela 'profiles'
      // Esta linha confirma que seu _userId é o 'user_id' (auth.uid())
      await _supabase.from('profiles').update(updates).eq('user_id', _userId!);

      // 5. Atualiza o provider localmente
      if (mounted) {
        context.read<CompanyProvider>().updateLocalProfile(
              fullName: fullName,
              phoneNumber: unmaskedPhone,
              email: newEmail,
              avatarUrl: newAvatarUrl ?? _currentAvatarUrl,
            );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } on StorageException catch (e) {
      debugPrint("Erro de Storage: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao salvar imagem: ${e.message}'),
              backgroundColor: Colors.red),
        );
      }
    } catch (error) {
      debugPrint("Erro geral: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao salvar perfil: ${error.toString()}'),
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
    final companyLogoUrl =
        context.watch<CompanyProvider>().currentCompany?.logoUrl;

    ImageProvider displayImage;
    Widget? fallbackChild;

    if (_selectedImage != null) {
      displayImage = FileImage(_selectedImage!);
    } else if (_currentAvatarUrl != null) {
      displayImage = NetworkImage(_currentAvatarUrl!);
    } else if (companyLogoUrl != null) {
      displayImage = NetworkImage(companyLogoUrl);
    } else {
      displayImage = const AssetImage('assets/transparent.png'); // Imagem vazia
      fallbackChild = const Icon(Icons.person, size: 60);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: displayImage,
                        child: fallbackChild,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          child: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            onPressed: _pickImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome Completo'),
                  keyboardType: TextInputType.name,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nome é obrigatório'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Email inválido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [_phoneMaskFormatter],
                  validator: (v) => (v == null || v.length < 15)
                      ? 'Telefone inválido'
                      : null,
                ),
                const SizedBox(height: 32),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _saveProfile,
                    child: const Text('Salvar Alterações'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}