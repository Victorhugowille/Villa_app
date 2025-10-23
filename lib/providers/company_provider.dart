import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Added Material import for ChangeNotifier if not implicitly imported
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data; // Using alias

class CompanyProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  app_data.Company? _currentCompany; // Use the alias
  String? _role;
  bool _isLoading = false;

  // --- Getters ---
  app_data.Company? get currentCompany => _currentCompany; // Use the alias
  String? get role => _role;
  bool get isLoading => _isLoading;
  String get companyName => _currentCompany?.name ?? 'Carregando...';
  String? get companyId => _currentCompany?.id;

  // --- Methods ---

  /// Updates the locally stored company's latitude and longitude.
  /// Does NOT save to the database, only updates the provider state.
  void updateLocalCompanyLocation(double latitude, double longitude) {
    if (_currentCompany != null) {
      // Create a new instance with updated values
      _currentCompany = app_data.Company( // Use the alias
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
        // Update the latitude and longitude
        latitude: latitude,
        longitude: longitude,
      );
      notifyListeners(); // Notify listeners about the change
    }
  }

  /// Fetches the company data associated with the currently logged-in user.
  Future<void> fetchCompanyForCurrentUser() async {
    // Check if user is logged in
    if (_supabase.auth.currentUser == null) {
      debugPrint('[CompanyProvider] User not logged in. Aborting company fetch.');
      // Optionally clear existing data if user logs out
      // clearCompany();
      return;
    }

    _isLoading = true;
    notifyListeners(); // Notify UI that loading started

    try {
      final userId = _supabase.auth.currentUser!.id;

      // Fetch profile and associated company data in one go
      final response = await _supabase
          .from('profiles')
          .select('role, company_id, companies (*)') // Select profile role, company_id, and all columns from the related company
          .eq('user_id', userId)
          .single(); // Expect only one profile per user

      _role = response['role'] as String?; // Safely cast role

      // Check if the nested 'companies' data exists
      if (response['companies'] != null) {
        final companyData = response['companies'] as Map<String, dynamic>;
        _currentCompany = app_data.Company.fromJson(companyData); // Use the alias
        debugPrint('[CompanyProvider] Company "${_currentCompany?.name}" loaded successfully.');
      } else {
        _currentCompany = null; // Ensure company is null if not found
        debugPrint('[CompanyProvider] No company associated with the profile.');
      }

    } catch (e) {
      debugPrint('[CompanyProvider] ERROR fetching company data: $e');
       // Clear data on error to avoid showing stale info
      _currentCompany = null;
      _role = null;
      // You might want to re-throw the error or handle it differently
      // depending on your app's error handling strategy.
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify UI that loading finished (success or error)
    }
  }

  /// Clears the current company and role information.
  void clearCompany() {
    _currentCompany = null;
    _role = null;
    _isLoading = false; // Reset loading state as well
    notifyListeners();
    debugPrint('[CompanyProvider] Company data cleared.');
  }
}