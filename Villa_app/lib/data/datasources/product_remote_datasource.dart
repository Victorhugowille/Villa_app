import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_data.dart';

/// Interface para acesso remoto aos dados de Produto e Categoria
abstract class ProductRemoteDatasource {
  Future<List<Product>> getProducts(String companyId);
  Future<Product> getProductById(String productId);
  Future<List<Category>> getCategories(String companyId);
  Future<Product> createProduct(Map<String, dynamic> productData);
  Future<void> addCategory(
    String companyId,
    String name,
    int iconCodePoint,
    String? iconFontFamily,
    String appType,
  );
  Future<void> addProduct(Map<String, dynamic> productData);
  Future<void> updateProduct(String productId, Map<String, dynamic> updates);
  Future<void> deleteProduct(String productId);
  Future<void> deleteCategory(String categoryId);
}

/// Implementação real usando Supabase
class ProductRemoteDatasourceImpl implements ProductRemoteDatasource {
  final SupabaseClient supabaseClient;

  ProductRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Product>> getProducts(String companyId) async {
    try {
      final response = await supabaseClient
          .from('produtos')
          .select('*, categorias(name)')
          .eq('company_id', companyId)
          .order('display_order', ascending: true);

      return (response as List)
          .map((item) => Product.fromJson(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Erro ao buscar produtos: ${e.message}');
    } catch (e) {
      throw Exception('Erro desconhecido ao buscar produtos: $e');
    }
  }

  @override
  Future<Product> getProductById(String productId) async {
    try {
      final response = await supabaseClient
          .from('produtos')
          .select('*, categorias(name)')
          .eq('id', productId)
          .single();

      return Product.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Erro ao buscar produto: ${e.message}');
    } catch (e) {
      throw Exception('Erro desconhecido ao buscar produto: $e');
    }
  }

  @override
  Future<List<Category>> getCategories(String companyId) async {
    try {
      final response = await supabaseClient
          .from('categorias')
          .select()
          .eq('company_id', companyId)
          .order('display_order', ascending: true)
          .order('name', ascending: true);

      return (response as List)
          .map((item) => Category.fromJson(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Erro ao buscar categorias: ${e.message}');
    } catch (e) {
      throw Exception('Erro desconhecido ao buscar categorias: $e');
    }
  }

  @override
  Future<Product> createProduct(Map<String, dynamic> productData) async {
    try {
      final response = await supabaseClient
          .from('produtos')
          .insert(productData)
          .select()
          .single();

      return Product.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Erro ao criar produto: ${e.message}');
    } catch (e) {
      throw Exception('Erro desconhecido ao criar produto: $e');
    }
  }

  @override
  Future<void> addCategory(
    String companyId,
    String name,
    int iconCodePoint,
    String? iconFontFamily,
    String appType,
  ) async {
    try {
      final countResponse = await supabaseClient
          .from('categorias')
          .select()
          .eq('company_id', companyId)
          .count();

      final newDisplayOrder = countResponse.count;

      await supabaseClient.from('categorias').insert({
        'name': name,
        'icon_code_point': iconCodePoint,
        'icon_font_family': iconFontFamily,
        'company_id': companyId,
        'display_order': newDisplayOrder,
        'app_type': appType,
      });
    } on PostgrestException catch (e) {
      throw Exception('Erro ao adicionar categoria: ${e.message}');
    } catch (e) {
      throw Exception('Erro desconhecido ao adicionar categoria: $e');
    }
  }

  @override
  Future<void> addProduct(Map<String, dynamic> productData) async {
    try {
      await supabaseClient.from('produtos').insert(productData);
    } on PostgrestException catch (e) {
      throw Exception('Erro ao adicionar produto: ${e.message}');
    } catch (e) {
      throw Exception('Erro desconhecido ao adicionar produto: $e');
    }
  }

  @override
  Future<void> updateProduct(String productId, Map<String, dynamic> updates) async {
    try {
      await supabaseClient.from('produtos').update(updates).eq('id', productId);
    } on PostgrestException catch (e) {
      throw Exception('Erro ao atualizar produto: ${e.message}');
    } catch (e) {
      throw Exception('Erro desconhecido ao atualizar produto: $e');
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    try {
      await supabaseClient.from('produtos').delete().eq('id', productId);
    } on PostgrestException catch (e) {
      throw Exception('Erro ao deletar produto: ${e.message}');
    } catch (e) {
      throw Exception('Erro desconhecido ao deletar produto: $e');
    }
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    try {
      await supabaseClient
          .from('categorias')
          .delete()
          .eq('id', categoryId);
    } on PostgrestException catch (e) {
      throw Exception('Erro ao deletar categoria: ${e.message}');
    } catch (e) {
      throw Exception('Erro desconhecido ao deletar categoria: $e');
    }
  }
}
