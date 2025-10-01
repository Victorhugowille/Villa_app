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
  String? _role; // Adicionado para guardar o cargo
  bool _isLoading = false;

  Company? get currentCompany => _currentCompany;
  String? get role => _role; // Getter para o cargo
  bool get isLoading => _isLoading;
  String get companyName => _currentCompany?.name ?? 'Carregando...';

  Future<void> fetchCompanyForCurrentUser() async {
    if (_supabase.auth.currentUser == null) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser!.id;
      final response = await _supabase
          .from('profiles')
          .select('role, company_id, companies (id, name)') // Puxando o 'role'
          .eq('user_id', userId)
          .single();
      
      _role = response['role']; // Salvando o cargo

      if (response['companies'] != null) {
        final companyData = response['companies'];
        _currentCompany = Company(
          id: companyData['id'],
          name: companyData['name'],
        );
      }
    } catch (e) {
      debugPrint('Erro ao buscar empresa: $e');
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