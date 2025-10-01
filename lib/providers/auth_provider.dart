import 'package:flutter/material.dart';
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

  Future<void> _initialize() async {
    _user = _supabase.auth.currentUser;
    if (_user != null) {
      await _loadUserProfile();
    }
    _isLoading = false;
    notifyListeners();

    _supabase.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      if (_user != null) {
        _loadUserProfile();
      } else {
        _companyId = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserProfile() async {
    if (_user == null) return;
    try {
      final response = await _supabase
          .from('profiles')
          .select('company_id')
          .eq('id', _user!.id)
          .single();
      _companyId = response['company_id'] as String?;
    } catch (e) {
      _companyId = null;
    }
    notifyListeners();
  }
}