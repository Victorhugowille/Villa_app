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

  AuthProvider() {
    _initialize();
  }

  void _initialize() {
    _handleUserChange(_supabase.auth.currentUser);
    _isLoading = false;
    notifyListeners();

    _supabase.auth.onAuthStateChange.listen((data) {
      _handleUserChange(data.session?.user);
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
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}