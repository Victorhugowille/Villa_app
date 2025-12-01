import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  User? _user;
  String? _companyId;
  bool _isLoading = true;

  User? get user => _user;
  String? get companyId => _companyId;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get hasCompany => _companyId != null;

  AuthProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Tenta carregar o usuário atual
      final session = _supabase.auth.currentSession;

      // Se existir uma sessão mas ela estiver expirada, o SDK tentará o refresh.
      // Se o refresh falhar com erro 500 (como no seu log), precisamos limpar tudo.
      if (session != null && session.isExpired) {
         // Opcional: Tentar refresh manual ou apenas deixar o fluxo seguir.
         // Se o token estiver corrompido, o catch abaixo ou o listener capturará.
      }

      _handleUserChange(_supabase.auth.currentUser);
    } catch (e) {
      // Se houver erro crítico na inicialização (token corrompido), força logout
      debugPrint('Erro na inicialização da Auth: $e');
      await _supabase.auth.signOut();
      _user = null;
      _companyId = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // Escuta mudanças de autenticação
    _supabase.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      
      // Se o usuário deslogou ou o token foi invalidado
      if (event == AuthChangeEvent.signedOut) {
        _user = null;
        _companyId = null;
        notifyListeners();
      } else {
        _handleUserChange(data.session?.user);
      }
    });
  }

  void _handleUserChange(User? user) {
    _user = user;
    if (_user != null && _user!.appMetadata.containsKey('company_id')) {
      _companyId = _user!.appMetadata['company_id'] as String?;
    } else {
      _companyId = null;
    }
    notifyListeners();
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String companyId,
    String? fullName,
  }) async {
    final authResponse = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'company_id': companyId,
        if (fullName != null) 'full_name': fullName,
      },
    );

    if (authResponse.user != null) {
      await _supabase.from('profiles').insert({
        'user_id': authResponse.user!.id,
        'company_id': companyId,
        'full_name': fullName,
      });
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      _user = null;
      _companyId = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao fazer logout: $e');
    }
  }
}