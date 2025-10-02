import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Company {
  final String id;
  final String name;

  Company({required this.id, required this.name});
}

class CompanyProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  Company? _currentCompany;
  String? _role;
  bool _isLoading = false;

  Company? get currentCompany => _currentCompany;
  String? get role => _role;
  bool get isLoading => _isLoading;
  String get companyName => _currentCompany?.name ?? 'Carregando...';

  Future<void> fetchCompanyForCurrentUser() async {
    if (_supabase.auth.currentUser == null) {
      debugPrint('[DEBUG] A função fetch foi chamada, mas não há usuário logado. Saindo.');
      return;
    }
    
    debugPrint('[DEBUG] Iniciando a busca de dados da empresa e cargo...');
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser!.id;
      debugPrint('[DEBUG] Buscando perfil para o user_id: $userId');

      final response = await _supabase
          .from('profiles')
          .select('role, company_id, companies (id, name)')
          .eq('user_id', userId)
          .single();
      
      debugPrint('[DEBUG] Resposta do Supabase: $response');

      _role = response['role'];
      debugPrint('[DEBUG] Cargo (role) encontrado: $_role');

      if (response['companies'] != null) {
        final companyData = response['companies'];
        _currentCompany = Company(
          id: companyData['id'],
          name: companyData['name'],
        );
        debugPrint('[DEBUG] Empresa encontrada: ${companyData['name']}');
      } else {
        debugPrint('[DEBUG] Nenhuma empresa associada encontrada na resposta.');
      }
    } catch (e) {
      debugPrint('[DEBUG] ERRO ao buscar dados: $e');
      _currentCompany = null;
      _role = null;
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('[DEBUG] Busca finalizada.');
    }
  }

  void clearCompany() {
    _currentCompany = null;
    _role = null;
    notifyListeners();
  }
}