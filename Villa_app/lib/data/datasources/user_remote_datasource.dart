abstract class UserRemoteDataSource {
  Future<dynamic> login(String email, String password);
  Future<void> logout();
  Future<dynamic> getCurrentUser();
  Future<dynamic> getUserById(String userId);
  Future<void> updateUser(dynamic user);
  Future<void> deleteUser(String userId);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  // TODO: Implementar com Supabase
  // final SupabaseClient supabaseClient;
  // UserRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<dynamic> login(String email, String password) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() {
    throw UnimplementedError();
  }

  @override
  Future<dynamic> getCurrentUser() {
    throw UnimplementedError();
  }

  @override
  Future<dynamic> getUserById(String userId) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateUser(dynamic user) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteUser(String userId) {
    throw UnimplementedError();
  }
}
