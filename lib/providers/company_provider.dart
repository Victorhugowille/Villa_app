import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:villabistromobile/data/app_data.dart';

class CompanyProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  Company? _currentCompany;
  String? _role;
  bool _isLoading = false;

  Company? get currentCompany => _currentCompany;
  String? get role => _role;
  bool get isLoading => _isLoading;
  String get companyName => _currentCompany?.name ?? 'Carregando...';

  // ### ADIÇÃO AQUI ###
  // Getter para facilitar o acesso ao ID da empresa
  String? get companyId => _currentCompany?.id;

  Future<void> fetchCompanyForCurrentUser() async {
    if (_supabase.auth.currentUser == null) {
      debugPrint('Usuário não logado. Abortando busca de empresa.');
      return;
    }
    
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser!.id;
      
      final response = await _supabase
          .from('profiles')
          .select('role, company_id, companies (*)')
          .eq('user_id', userId)
          .single();
      
      _role = response['role'];

      if (response['companies'] != null) {
        final companyData = response['companies'] as Map<String, dynamic>;
        _currentCompany = Company.fromJson(companyData);
        debugPrint('[CompanyProvider] Empresa "${_currentCompany?.name}" carregada com sucesso.');
      } else {
        debugPrint('[CompanyProvider] Nenhuma empresa associada ao perfil.');
      }

    } catch (e) {
      debugPrint('[CompanyProvider] ERRO ao buscar dados: $e');
      _currentCompany = null;
      _role = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCompany() {
    _currentCompany = null;
    _role = null;
    notifyListeners();
  }
}