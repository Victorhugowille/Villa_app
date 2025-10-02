// lib/providers/product_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;
import 'package:villabistromobile/providers/auth_provider.dart';

class ProductProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  AuthProvider? _authProvider;

  List<app_data.Product> _products = [];
  List<app_data.Category> _categories = [];
  bool _isLoading = false;

  List<app_data.Product> get products => _products;
  List<app_data.Category> get categories => _categories;
  bool get isLoading => _isLoading;

  ProductProvider(this._authProvider);

  void updateAuthProvider(AuthProvider newAuthProvider) {
    final oldCompanyId = _authProvider?.companyId;
    _authProvider = newAuthProvider;
    final newCompanyId = newAuthProvider.companyId;

    if (newCompanyId != null && newCompanyId != oldCompanyId) {
      fetchData();
    }
  }

  String? _getCompanyId() {
    return _authProvider?.companyId;
  }

  Future<void> fetchData() async {
    final companyId = _getCompanyId();
    if (companyId == null) {
      debugPrint("ProductProvider: Tentativa de buscar dados sem companyId. Aguardando...");
      return; 
    }

    _isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _supabase.from('produtos').select('*, categorias(name)').eq('company_id', companyId).order('display_order', ascending: true),
        _supabase.from('categorias').select().eq('company_id', companyId).order('name', ascending: true),
      ]);

      final productData = results[0] as List;
      final categoryData = results[1] as List;

      _products = productData.map((item) => app_data.Product.fromJson(item)).toList();
      _categories = categoryData.map((item) => app_data.Category.fromJson(item)).toList();
    } catch (error) {
      debugPrint("ProductProvider - Erro ao buscar dados: $error");
      _products = [];
      _categories = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCategory(String name, IconData icon) async {
    final companyId = _getCompanyId();
    if (companyId == null) throw Exception('Usuário não autenticado.');
    try {
      await _supabase.from('categorias').insert({
        'name': name,
        'icon_code_point': icon.codePoint,
        'icon_font_family': icon.fontFamily,
        'company_id': companyId,
      });
      await fetchData();
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw Exception('Uma categoria com este nome já existe.');
      }
      rethrow;
    } catch (error) {
      throw Exception('Falha ao criar categoria.');
    }
  }

  Future<void> updateCategory(String id, String name, IconData icon) async {
    final companyId = _getCompanyId();
    if (companyId == null) throw Exception('Usuário não autenticado.');
    try {
      await _supabase.from('categorias').update({
        'name': name,
        'icon_code_point': icon.codePoint,
        'icon_font_family': icon.fontFamily,
      }).eq('id', id).eq('company_id', companyId);
      await fetchData();
    } catch(error) {
      throw Exception('Falha ao atualizar categoria.');
    }
  }

  Future<void> deleteCategory(String id) async {
    final companyId = _getCompanyId();
    if (companyId == null) throw Exception('Usuário não autenticado.');
    try {
      await _supabase.from('categorias').delete().eq('id', id).eq('company_id', companyId);
      await fetchData();
    } catch (error) {
      throw Exception('Falha ao deletar categoria. Verifique se ela não está sendo usada por algum produto.');
    }
  }

  Future<List<app_data.GrupoAdicional>> getGruposAdicionaisParaProduto(String produtoId) async {
    try {
      final response = await _supabase
          .from('grupos_adicionais')
          .select('*, adicionais(*)')
          .eq('produto_id', produtoId)
          .order('name', ascending: true);
      
      return response.map((item) => app_data.GrupoAdicional.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Erro ao buscar grupos de adicionais: $e');
      return [];
    }
  }

  Future<void> addGrupoAdicional(String name, String produtoId, XFile? imageFile) async {
    final companyId = _getCompanyId();
    if (companyId == null) throw Exception('Usuário não autenticado.');
    try {
      final newGrupo = await _supabase.from('grupos_adicionais').insert({
        'name': name,
        'produto_id': produtoId,
        'company_id': companyId,
      }).select().single();
      
      if (imageFile != null) {
        final newGrupoId = newGrupo['id'].toString();
        final imageUrl = await _uploadImage(imageFile, 'grupos', newGrupoId);
        if (imageUrl != null) {
          await _supabase.from('grupos_adicionais').update({'image_url': imageUrl}).eq('id', newGrupoId);
        }
      }
    } catch (e) {
      throw Exception('Falha ao criar grupo de adicionais.');
    }
  }
  
  Future<void> updateGrupoAdicional(String id, String name, XFile? imageFile) async {
    try {
      final updates = <String, dynamic>{'name': name};
      if (imageFile != null) {
        final imageUrl = await _uploadImage(imageFile, 'grupos', id);
        if (imageUrl != null) {
          updates['image_url'] = imageUrl;
        }
      }
      await _supabase.from('grupos_adicionais').update(updates).eq('id', id);
    } catch (e) {
       throw Exception('Falha ao atualizar grupo de adicionais.');
    }
  }

  Future<void> deleteGrupoAdicional(String id) async {
    try {
      await _supabase.from('grupos_adicionais').delete().eq('id', id);
    } catch (e) {
      throw Exception('Falha ao deletar grupo.');
    }
  }

  Future<void> addAdicionalToGrupo({
    required String name,
    required double price,
    required String grupoId,
    XFile? imageFile,
  }) async {
    final companyId = _getCompanyId();
    if (companyId == null) throw Exception('Usuário não autenticado.');
    try {
      final newAdicional = await _supabase.from('adicionais').insert({
        'name': name,
        'price': price,
        'grupo_id': grupoId,
        'company_id': companyId,
      }).select().single();

      if (imageFile != null) {
        final newAdicionalId = newAdicional['id'].toString();
        final imageUrl = await _uploadImage(imageFile, 'adicionais', newAdicionalId);
        if (imageUrl != null) {
          await _supabase.from('adicionais').update({'image_url': imageUrl}).eq('id', newAdicionalId);
        }
      }
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw Exception('Um adicional com este nome já existe.');
      }
      rethrow;
    } catch (error) {
      debugPrint('ERRO AO ADICIONAR ADICIONAL: $error');
      throw Exception('Falha ao criar adicional.');
    }
  }

  Future<void> updateAdicional({
    required String id,
    required String name,
    required double price,
    XFile? imageFile,
  }) async {
    try {
      final updates = <String, dynamic>{'name': name, 'price': price};
      if(imageFile != null) {
        final imageUrl = await _uploadImage(imageFile, 'adicionais', id);
        if (imageUrl != null) {
          updates['image_url'] = imageUrl;
        }
      }
      await _supabase.from('adicionais').update(updates).eq('id', id);
    } catch (error) {
      throw Exception('Falha ao atualizar adicional.');
    }
  }
  
  Future<void> deleteAdicional(String id) async {
    try {
      await _supabase.from('adicionais').delete().eq('id', id);
    } catch (error) {
      throw Exception('Falha ao deletar adicional.');
    }
  }

  Future<String?> _uploadImage(XFile imageFile, String folder, String entityId) async {
    final companyId = _getCompanyId();
    if (companyId == null) throw Exception('Usuário não autenticado para upload.');
     try {
       final fileExt = imageFile.path.split('.').last;
       final path = '$companyId/$folder/$entityId.$fileExt';

       await _supabase.storage.from('product_images').upload(
         path,
         File(imageFile.path),
         fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
       );
       return _supabase.storage.from('product_images').getPublicUrl(path);
    } catch (e) {
      debugPrint("Erro no upload da imagem: $e");
      return null;
    }
  }

  Future<String> addProduct(String name, double price, String categoryId, int displayOrder, bool isSoldOut, XFile? imageFile) async {
    final companyId = _getCompanyId();
    if (companyId == null) throw Exception('Usuário não autenticado.');
    try {
      final newProduct = await _supabase.from('produtos').insert({
        'name': name,
        'price': price,
        'category_id': categoryId,
        'display_order': displayOrder,
        'is_sold_out': isSoldOut,
        'company_id': companyId,
      }).select().single();

      final newProductId = newProduct['id'].toString();

      if (imageFile != null) {
        final imageUrl = await _uploadImage(imageFile, 'produtos', newProductId);
        if (imageUrl != null) {
          await _supabase.from('produtos').update({'image_url': imageUrl}).eq('id', newProductId);
        }
      }
      await fetchData();
      return newProductId;
    } catch (error) {
      debugPrint('ERRO DETALHADO AO ADICIONAR PRODUTO: $error');
      throw Exception('Falha ao adicionar produto.');
    }
  }

  Future<void> updateProduct(String id, String name, double price, String categoryId, bool isSoldOut, XFile? imageFile) async {
    final companyId = _getCompanyId();
    if (companyId == null) throw Exception('Usuário não autenticado.');
    try {
      final updates = <String, dynamic>{
        'name': name,
        'price': price,
        'category_id': categoryId,
        'is_sold_out': isSoldOut,
      };

      if (imageFile != null) {
        final imageUrl = await _uploadImage(imageFile, 'produtos', id);
        if (imageUrl != null) {
          updates['image_url'] = imageUrl;
        }
      }

      await _supabase.from('produtos').update(updates).eq('id', id).eq('company_id', companyId);
      await fetchData();
    } catch (error) {
      throw Exception('Falha ao atualizar produto.');
    }
  }
  
  Future<void> deleteProduct(String id) async {
    final companyId = _getCompanyId();
    if (companyId == null) throw Exception('Usuário não autenticado.');
    try {
      await _supabase.from('produtos').delete().eq('id', id).eq('company_id', companyId);
      await fetchData();
    } catch (error) {
      throw Exception('Falha ao deletar produto.');
    }
  }

  Future<void> updateProductOrder(List<app_data.Product> products) async {
    try {
      final updates = products.asMap().entries.map((entry) {
        return {'id': entry.value.id, 'display_order': entry.key};
      }).toList();

      await _supabase.from('produtos').upsert(updates);
      await fetchData();
    } catch(error) {
      throw Exception('Falha ao reordenar produtos.');
    }
  }
}