class AppConstants {
  // API
  static const String baseUrl = 'https://api.villabistro.com';
  static const Duration timeoutDuration = Duration(seconds: 30);

  // Local Storage Keys
  static const String userKey = 'user';
  static const String companyKey = 'company';
  static const String authTokenKey = 'auth_token';
  static const String themeKey = 'theme';
  static const String languageKey = 'language';

  // Messages
  static const String noInternetMessage =
      'Sem conexão com a internet. Verifique sua conexão.';
  static const String serverErrorMessage =
      'Erro no servidor. Tente novamente mais tarde.';
  static const String unexpectedErrorMessage =
      'Erro inesperado. Tente novamente.';
  static const String unauthorizedMessage = 'Não autorizado. Faça login novamente.';
}
