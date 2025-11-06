// lib/providers/company_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data; // Using alias

class CompanyProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  app_data.Company? _currentCompany;
  String? _role;
  bool _isLoading = false;

  // --- CAMPOS PARA O PERFIL DO USUÁRIO ---
  String? _fullName;
  String? _phoneNumber;
  String? _avatarUrl;
  String? _userId;
  String? _email; // <-- NOVO CAMPO

  // --- Getters ---
  app_data.Company? get currentCompany => _currentCompany;
  String? get role => _role;
  bool get isLoading => _isLoading;
  String get companyName => _currentCompany?.name ?? 'Carregando...';
  String? get companyId => _currentCompany?.id;

  // --- GETTERS DO PERFIL ---
  String? get fullName => _fullName;
  String? get phoneNumber => _phoneNumber;
  String? get avatarUrl => _avatarUrl;
  String? get userId => _userId;
  String? get email => _email; // <-- NOVO GETTER

  /// Atualiza localmente os dados do perfil após a edição
  void updateLocalProfile(
      {String? fullName,
      String? phoneNumber,
      String? avatarUrl,
      String? email}) { // <-- NOVO PARÂMETRO
    _fullName = fullName ?? _fullName;
    _phoneNumber = phoneNumber ?? _phoneNumber;
    _avatarUrl = avatarUrl ?? _avatarUrl;
    _email = email ?? _email; // <-- ATUALIZA EMAIL
    notifyListeners();
  }

  void updateLocalCompanyLocation(double latitude, double longitude) {
    if (_currentCompany != null) {
      _currentCompany = app_data.Company(
        id: _currentCompany!.id,
        name: _currentCompany!.name,
        logoUrl: _currentCompany!.logoUrl,
        cnpj: _currentCompany!.cnpj,
        telefone: _currentCompany!.telefone,
        rua: _currentCompany!.rua,
        numero: _currentCompany!.numero,
        bairro: _currentCompany!.bairro,
        cidade: _currentCompany!.cidade,
        estado: _currentCompany!.estado,
        zapiInstanceId: _currentCompany!.zapiInstanceId,
        zapiToken: _currentCompany!.zapiToken,
        notificationEmail: _currentCompany!.notificationEmail,
        slug: _currentCompany!.slug,
        colorSite: _currentCompany!.colorSite,
        latitude: latitude,
        longitude: longitude,
        status: _currentCompany!.status,
      );
      notifyListeners();
    }
  }

  Future<void> fetchCompanyForCurrentUser() async {
    if (_supabase.auth.currentUser == null) {
      debugPrint('[CompanyProvider] User not logged in.');
      clearCompany();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _userId = _supabase.auth.currentUser!.id; // Salva o ID do usuário
      _email = _supabase.auth.currentUser!.email; // <-- PEGA O EMAIL

      // ATUALIZADO: Busca mais campos do profile
      final response = await _supabase
          .from('profiles')
          .select(
              'role, company_id, full_name, phone_number, avatar_url, companies (*)')
          .eq('user_id', _userId!)
          .single();

      // Salva os dados do perfil
      _role = response['role'] as String?;
      _fullName = response['full_name'] as String?;
      _phoneNumber = response['phone_number'] as String?;
      _avatarUrl = response['avatar_url'] as String?;

      if (response['companies'] != null) {
        final companyData = response['companies'] as Map<String, dynamic>;
        _currentCompany = app_data.Company.fromJson(companyData);
        debugPrint(
            '[CompanyProvider] Company "${_currentCompany?.name}" loaded.');
      } else {
        _currentCompany = null;
        debugPrint('[CompanyProvider] No company associated with profile.');
      }
    } catch (e) {
      debugPrint('[CompanyProvider] ERROR fetching data: $e');
      clearCompany(); // Limpa tudo em caso de erro
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCompany() {
    _currentCompany = null;
    _role = null;
    _isLoading = false;
    // --- LIMPA DADOS DO PERFIL ---
    _fullName = null;
    _phoneNumber = null;
    _avatarUrl = null;
    _userId = null;
    _email = null; // <-- LIMPA EMAIL
    notifyListeners();
    debugPrint('[CompanyProvider] All data cleared.');
  }
}