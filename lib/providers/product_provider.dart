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
      return;
    }

    if (_isLoading) return;

    _isLoading = true;
     Future.microtask(() {
      notifyListeners();
    });

    try {
      final categoryData = await _supabase
          .from('categorias')
          .select()
          .eq('company_id', companyId)
          .order('display_order', ascending: true)
          .order('name', ascending: true);

      final productData = await _supabase
          .from('produtos')
          .select('*, categorias(name)')
          .eq('company_id', companyId)
          .order('display_order', ascending: true);

      _products = (productData as List)
          .map((item) => app_data.Product.fromJson(item))
          .toList();
      _categories =
          categoryData.map((item) => app_data.Category.fromJson(item)).toList();
    } catch (error, stackTrace) {
      debugPrint("ERRO AO BUSCAR DADOS: $error");
      debugPrint("STACK TRACE: $stackTrace");
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
      final response = await _supabase
          .from('categorias')
          .select()
          .eq('company_id', companyId)
          .count();
      final newDisplayOrder = response.count;

      await _supabase.from('categorias').insert({
        'name': name,
        'icon_code_point': icon.codePoint,
        'icon_font_family': icon.fontFamily,
        'company_id': companyId,
        'display_order': newDisplayOrder,
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
    } catch (error) {
      throw Exception('Falha ao atualizar categoria.');
    }
  }

  Future<void> _deleteProductCascading(String productId) async {
    final companyId = _getCompanyId();
    if (companyId == null) throw Exception('Usuário não autenticado.');

    try {
      final grupos = await _supabase
          .from('grupos_adicionais')
          .select('id, image_url')
          .eq('produto_id', productId);

      final List<String> grupoIds =
          grupos.map((g) => g['id'].toString()).toList();

      if (grupoIds.isNotEmpty) {
        final orFilter = grupoIds.map((id) => 'grupo_id.eq.$id').join(',');

        final adicionais = await _supabase
            .from('adicionais')
            .select('id, image_url')
            .or(orFilter);

        final List<String> adicionalImagePaths = adicionais
            .map((a) => a['image_url'] as String?)
            .where((url) => url != null)
            .map((url) => url!.split('/product_images/').last)
            .toList();
        if (adicionalImagePaths.isNotEmpty) {
          await _supabase.storage.from('product_images').remove(adicionalImagePaths);
        }

        await _supabase.from('adicionais').delete().or(orFilter);

        final List<String> grupoImagePaths = grupos
            .map((g) => g['image_url'] as String?)
            .where((url) => url != null)
            .map((url) => url!.split('/product_images/').last)
            .toList();
        if (grupoImagePaths.isNotEmpty) {
          await _supabase.storage.from('product_images').remove(grupoImagePaths);
        }

        await _supabase.from('grupos_adicionais').delete().eq('produto_id', productId);
      }

      final product = await _supabase
          .from('produtos')
          .select('image_url')
          .eq('id', productId)
          .maybeSingle();
      if (product != null && product['image_url'] != null) {
        final path =
            (product['image_url'] as String).split('/product_images/').last;
        await _supabase.storage.from('product_images').remove([path]);
      }

      await _supabase.from('produtos').delete().eq('id', productId);
    } catch (error) {
      debugPrint("Falha na deleção em cascata: $error");
      throw Exception('Falha no processo de deleção em cascata do produto.');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _deleteProductCascading(productId);
      await fetchData();
    } catch (error) {
      debugPrint(error.toString());
      throw Exception('Falha ao deletar produto.');
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    final companyId = _getCompanyId();
    if (companyId == null) throw Exception('Usuário não autenticado.');

    try {
      final productsToDelete = await _supabase
          .from('produtos')
          .select('id')
          .eq('category_id', categoryId);

      for (final product in productsToDelete) {
        await _deleteProductCascading(product['id'].toString());
      }

      await _supabase
          .from('categorias')
          .delete()
          .eq('id', categoryId)
          .eq('company_id', companyId);

      await fetchData();
    } catch (error) {
      debugPrint(error.toString());
      throw Exception('Falha ao deletar categoria.');
    }
  }

  Future<List<app_data.GrupoAdicional>> getGruposAdicionaisParaProduto(
      String produtoId) async {
    final companyId = _getCompanyId();
    if (companyId == null) return [];
    try {
      final response = await _supabase
          .from('grupos_adicionais')
          .select('*, adicionais(*)')
          .eq('produto_id', produtoId)
          .eq('company_id', companyId)
          .order('display_order', ascending: true);

      return response
          .map((item) => app_data.GrupoAdicional.fromJson(item))
          .toList();
    } catch (e) {
      return [];
    }
  }
// ATUALIZAÇÃO 1: Adicionar os parâmetros min e max
Future<void> addGrupoAdicional(
    String name, String produtoId, XFile? imageFile, int min, int? max) async {
  final companyId = _getCompanyId();
  if (companyId == null) throw Exception('Usuário não autenticado.');
  try {
    final response = await _supabase
        .from('grupos_adicionais')
        .select()
        .eq('produto_id', produtoId)
        .count();
    final newDisplayOrder = response.count;

    final newGrupo = await _supabase.from('grupos_adicionais').insert({
      'name': name,
      'produto_id': produtoId,
      'company_id': companyId,
      'display_order': newDisplayOrder,
      'min_quantity': min, // NOVO
      'max_quantity': max, // NOVO
    }).select().maybeSingle();

    if (newGrupo == null) {
      throw Exception(
          'Falha ao criar grupo: não foi possível obter o retorno do banco de dados.');
    }

    if (imageFile != null) {
      final newGrupoId = newGrupo['id'].toString();
      final imageUrl = await _uploadImage(imageFile, 'grupos', newGrupoId);
      if (imageUrl != null) {
        await _supabase
            .from('grupos_adicionais')
            .update({'image_url': imageUrl}).eq('id', newGrupoId);
      }
    }
  } catch (e) {
    throw Exception('Falha ao criar grupo de adicionais.');
  }
}

// ATUALIZAÇÃO 2: Adicionar os parâmetros min e max
Future<void> updateGrupoAdicional(
    String id, String name, XFile? imageFile, int min, int? max) async {
  final companyId = _getCompanyId();
  if (companyId == null) throw Exception('Usuário não autenticado.');
  try {
    // Adicionado min_quantity e max_quantity ao objeto de atualização
    final updates = <String, dynamic>{
      'name': name,
      'min_quantity': min,
      'max_quantity': max,
    };

    if (imageFile != null) {
      final imageUrl = await _uploadImage(imageFile, 'grupos', id);
      if (imageUrl != null) {
        updates['image_url'] = imageUrl;
      }
    }
    await _supabase
        .from('grupos_adicionais')
        .update(updates)
        .eq('id', id)
        .eq('company_id', companyId);
  } catch (e) {
    throw Exception('Falha ao atualizar grupo de adicionais.');
  }
}

  Future<void> deleteGrupoAdicional(String id) async {
    final companyId = _getCompanyId();
    if (companyId == null) throw Exception('Usuário não autenticado.');
    try {
      await _supabase
          .from('grupos_adicionais')
          .delete()
          .eq('id', id)
          .eq('company_id', companyId);
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
      final response = await _supabase
          .from('adicionais')
          .select()
          .eq('grupo_id', grupoId)
          .count();
      final newDisplayOrder = response.count;

      final newAdicional = await _supabase.from('adicionais').insert({
        'name': name,
        'price': price,
        'grupo_id': grupoId,
        'company_id': companyId,
        'display_order': newDisplayOrder,
      }).select().maybeSingle();

      if (newAdicional == null) {
        throw Exception(
            'Falha ao criar adicional: não foi possível obter o retorno do banco de dados.');
      }

      if (imageFile != null) {
        final newAdicionalId = newAdicional['id'].toString();
        final imageUrl =
            await _uploadImage(imageFile, 'adicionais', newAdicionalId);
        if (imageUrl != null) {
          await _supabase
              .from('adicionais')
              .update({'image_url': imageUrl}).eq('id', newAdicionalId);
        }
      }
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw Exception('Um adicional com este nome já existe.');
      }
      rethrow;
    } catch (error) {
      throw Exception('Falha ao criar adicional.');
    }
  }

  Future<void> updateAdicional({
    required String id,
    required String name,
    required double price,
    XFile? imageFile,
  }) async {
    final companyId = _getCompanyId();
    if (companyId == null) throw Exception('Usuário não autenticado.');
    try {
      final updates = <String, dynamic>{'name': name, 'price': price};
      if (imageFile != null) {
        final imageUrl = await _uploadImage(imageFile, 'adicionais', id);
        if (imageUrl != null) {
          updates['image_url'] = imageUrl;
        }
      }
      await _supabase
          .from('adicionais')
          .update(updates)
          .eq('id', id)
          .eq('company_id', companyId);
    } catch (error) {
      throw Exception('Falha ao atualizar adicional.');
    }
  }

  Future<void> deleteAdicional(String id) async {
    final companyId = _getCompanyId();
    if (companyId == null) throw Exception('Usuário não autenticado.');
    try {
      await _supabase
          .from('adicionais')
          .delete()
          .eq('id', id)
          .eq('company_id', companyId);
    } catch (error) {
      throw Exception('Falha ao deletar adicional.');
    }
  }

  Future<String?> _uploadImage(
      XFile imageFile, String folder, String entityId) async {
    final companyId = _getCompanyId();
    if (companyId == null)
      throw Exception('Usuário não autenticado para upload.');
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
      return null;
    }
  }

  Future<String> addProduct(String name, double price, String categoryId,
      bool isSoldOut, XFile? imageFile) async {
    final companyId = _getCompanyId();
    if (companyId == null) throw Exception('Usuário não autenticado.');
    try {
      final response = await _supabase
          .from('produtos')
          .select()
          .eq('company_id', companyId)
          .eq('category_id', categoryId)
          .count();

      final newDisplayOrder = response.count;

      final newProduct = await _supabase.from('produtos').insert({
        'name': name,
        'price': price,
        'category_id': categoryId,
        'display_order': newDisplayOrder,
        'is_sold_out': isSoldOut,
        'company_id': companyId,
      }).select().maybeSingle();

      if (newProduct == null) {
        throw Exception(
            'Falha ao criar produto: não foi possível obter o retorno do banco de dados.');
      }

      final newProductId = newProduct['id'].toString();

      if (imageFile != null) {
        final imageUrl =
            await _uploadImage(imageFile, 'produtos', newProductId);
        if (imageUrl != null) {
          await _supabase
              .from('produtos')
              .update({'image_url': imageUrl}).eq('id', newProductId);
        }
      }
      await fetchData();
      return newProductId;
    } catch (error) {
      throw Exception('Falha ao adicionar produto.');
    }
  }

  Future<void> updateProduct(String id, String name, double price,
      String categoryId, bool isSoldOut, XFile? imageFile) async {
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

      await _supabase
          .from('produtos')
          .update(updates)
          .eq('id', id)
          .eq('company_id', companyId);
      await fetchData();
    } catch (error) {
      throw Exception('Falha ao atualizar produto.');
    }
  }

  Future<void> updateProductOrder(List<app_data.Product> products) async {
    final companyId = _getCompanyId();
    if (companyId == null) throw Exception('Usuário não autenticado.');
    try {
      for (int i = 0; i < products.length; i++) {
        await _supabase
            .from('produtos')
            .update({'display_order': i})
            .eq('id', products[i].id)
            .eq('company_id', companyId);
      }
      await fetchData();
    } catch (error) {
      throw Exception('Falha ao reordenar produtos.');
    }
  }

  Future<void> updateCategoryOrder(List<app_data.Category> categories) async {
    final companyId = _getCompanyId();
    if (companyId == null) throw Exception('Usuário não autenticado.');
    try {
      for (int i = 0; i < categories.length; i++) {
        await _supabase
            .from('categorias')
            .update({'display_order': i})
            .eq('id', categories[i].id)
            .eq('company_id', companyId);
      }
      await fetchData();
    } catch (error) {
      throw Exception('Falha ao reordenar categorias.');
    }
  }

  Future<void> updateGrupoAdicionalOrder(
      List<app_data.GrupoAdicional> grupos) async {
    final companyId = _getCompanyId();
    if (companyId == null) throw Exception('Usuário não autenticado.');
    try {
      for (int i = 0; i < grupos.length; i++) {
        await _supabase
            .from('grupos_adicionais')
            .update({'display_order': i})
            .eq('id', grupos[i].id)
            .eq('company_id', companyId);
      }
    } catch (error) {
      throw Exception('Falha ao reordenar grupos de adicionais.');
    }
  }

  Future<void> updateAdicionalOrder(List<app_data.Adicional> adicionais) async {
    final companyId = _getCompanyId();
    if (companyId == null) throw Exception('Usuário não autenticado.');
    try {
      for (int i = 0; i < adicionais.length; i++) {
        await _supabase
            .from('adicionais')
            .update({'display_order': i})
            .eq('id', adicionais[i].id)
            .eq('company_id', companyId);
      }
    } catch (error) {
      throw Exception('Falha ao reordenar adicionais.');
    }
  }
Future<String> _getNewCopyName({
    required String tableName,
    required String nameColumn,
    required String baseName,
    required String filterColumn,
    required dynamic filterValue,
  }) async {
    final companyId = _getCompanyId();
    if (companyId == null) throw Exception('Usuário não autenticado.');

    final cleanBaseName = baseName.replaceAll(RegExp(r'_copia\(\d+\)$'), '').trim();

    final response = await _supabase
        .from(tableName)
        .select(nameColumn)
        .eq('company_id', companyId)
        .eq(filterColumn, filterValue)
        .like(nameColumn, '$cleanBaseName\_copia(%)');

    int maxCopy = 0;
    final regex = RegExp(r'_copia\((\d+)\)$');
    for (var item in response) {
      final name = item[nameColumn] as String;
      final match = regex.firstMatch(name);
      if (match != null) {
        final copyNum = int.tryParse(match.group(1) ?? '0') ?? 0;
        if (copyNum > maxCopy) {
          maxCopy = copyNum;
        }
      }
    }
    return '$cleanBaseName\_copia(${maxCopy + 1})';
  }

  Future<String?> _copyImage(
      String? originalUrl, String newEntityId, String folder) async {
    if (originalUrl == null || originalUrl.isEmpty) return null;

    final companyId = _getCompanyId();
    if (companyId == null) throw Exception('Usuário não autenticado.');

    try {
      final uri = Uri.parse(originalUrl);
      final pathSegments = uri.pathSegments;
      final bucketName = 'product_images';
      final bucketIndex = pathSegments.indexOf(bucketName);
      if (bucketIndex == -1) throw Exception('Bucket não encontrado na URL');
      
      final originalPath = pathSegments.sublist(bucketIndex + 1).join('/');
      final fileExt = originalPath.split('.').last;
      final newPath = '$companyId/$folder/$newEntityId.$fileExt';

      await _supabase.storage.from(bucketName).copy(originalPath, newPath);
      return _supabase.storage.from(bucketName).getPublicUrl(newPath);
    } catch (e) {
      debugPrint("Erro ao copiar imagem: $e");
      return null;
    }
  }

  Future<void> _duplicateAdicionalInternal(
      dynamic adicionalId, String newGrupoId,
      {bool keepOriginalName = false}) async {
    final companyId = _getCompanyId();
    if (companyId == null) throw Exception('Usuário não autenticado.');
    final String idStr = adicionalId.toString();

    final originalAdicional = await _supabase
        .from('adicionais')
        .select()
        .eq('id', idStr)
        .eq('company_id', companyId)
        .single();

    final String newName;
    if (keepOriginalName) {
      newName = originalAdicional['name'];
    } else {
      newName = await _getNewCopyName(
        tableName: 'adicionais',
        nameColumn: 'name',
        baseName: originalAdicional['name'],
        filterColumn: 'grupo_id',
        filterValue: newGrupoId,
      );
    }

    final newAdicionalData = Map<String, dynamic>.from(originalAdicional)
      ..remove('id')
      ..remove('created_at')
      ..['grupo_id'] = newGrupoId
      ..['name'] = newName;

    final inserted = await _supabase
        .from('adicionais')
        .insert(newAdicionalData)
        .select()
        .single();
    final newAdicionalId = inserted['id'].toString();

    final newImageUrl = await _copyImage(
        originalAdicional['image_url'], newAdicionalId, 'adicionais');
    if (newImageUrl != null) {
      await _supabase
          .from('adicionais')
          .update({'image_url': newImageUrl}).eq('id', newAdicionalId);
    }
  }

  Future<void> duplicateAdicional(String adicionalId) async {
    final companyId = _getCompanyId();
    if (companyId == null) throw Exception('Usuário não autenticado.');

    final originalAdicional = await _supabase
        .from('adicionais')
        .select('grupo_id')
        .eq('id', adicionalId)
        .single();
    await _duplicateAdicionalInternal(
        adicionalId, originalAdicional['grupo_id'].toString());

    await fetchData();
  }

  Future<void> _duplicateGrupoAdicionalInternal(
      dynamic grupoId, String newProdutoId,
      {bool keepOriginalName = false}) async {
    final companyId = _getCompanyId();
    if (companyId == null) throw Exception('Usuário não autenticado.');
    final String idStr = grupoId.toString();

    final originalGrupo = await _supabase
        .from('grupos_adicionais')
        .select('*, adicionais:adicionais(*)')
        .eq('id', idStr)
        .eq('company_id', companyId)
        .single();

    final String newName;
    if (keepOriginalName) {
      newName = originalGrupo['name'];
    } else {
      newName = await _getNewCopyName(
        tableName: 'grupos_adicionais',
        nameColumn: 'name',
        baseName: originalGrupo['name'],
        filterColumn: 'produto_id',
        filterValue: newProdutoId,
      );
    }

    final newGrupoData = Map<String, dynamic>.from(originalGrupo)
      ..remove('id')
      ..remove('created_at')
      ..remove('adicionais')
      ..['produto_id'] = newProdutoId
      ..['name'] = newName;

    final inserted = await _supabase
        .from('grupos_adicionais')
        .insert(newGrupoData)
        .select()
        .single();
    final newGrupoId = inserted['id'].toString();

    final newImageUrl =
        await _copyImage(originalGrupo['image_url'], newGrupoId, 'grupos');
    if (newImageUrl != null) {
      await _supabase
          .from('grupos_adicionais')
          .update({'image_url': newImageUrl}).eq('id', newGrupoId);
    }

    final List<dynamic> adicionais = originalGrupo['adicionais'] ?? [];
    for (final adicional in adicionais) {
      await _duplicateAdicionalInternal(adicional['id'], newGrupoId,
          keepOriginalName: true);
    }
  }

  Future<void> duplicateGrupoAdicional(String grupoId) async {
    final companyId = _getCompanyId();
    if (companyId == null) throw Exception('Usuário não autenticado.');

    final originalGrupo = await _supabase
        .from('grupos_adicionais')
        .select('produto_id')
        .eq('id', grupoId)
        .single();
    await _duplicateGrupoAdicionalInternal(
        grupoId, originalGrupo['produto_id'].toString());

    await fetchData();
  }

  Future<void> _duplicateProductInternal(
      dynamic productId, String newCategoryId,
      {bool keepOriginalName = false}) async {
    final companyId = _getCompanyId();
    if (companyId == null) throw Exception('Usuário não autenticado.');
    final String idStr = productId.toString();

    final originalProduct = await _supabase
        .from('produtos')
        .select('*, grupos_adicionais:grupos_adicionais(*, adicionais:adicionais(*))')
        .eq('id', idStr)
        .eq('company_id', companyId)
        .single();

    final String newName;
    if (keepOriginalName) {
      newName = originalProduct['name'];
    } else {
      newName = await _getNewCopyName(
        tableName: 'produtos',
        nameColumn: 'name',
        baseName: originalProduct['name'],
        filterColumn: 'category_id',
        filterValue: newCategoryId,
      );
    }

    final newProductData = Map<String, dynamic>.from(originalProduct)
      ..remove('id')
      ..remove('created_at')
      ..remove('grupos_adicionais')
      ..['category_id'] = newCategoryId
      ..['name'] = newName;

    final inserted =
        await _supabase.from('produtos').insert(newProductData).select().single();
    final newProductId = inserted['id'].toString();

    final newImageUrl = await _copyImage(
        originalProduct['image_url'], newProductId, 'produtos');
    if (newImageUrl != null) {
      await _supabase
          .from('produtos')
          .update({'image_url': newImageUrl}).eq('id', newProductId);
    }

    final List<dynamic> grupos = originalProduct['grupos_adicionais'] ?? [];
    for (final grupo in grupos) {
      await _duplicateGrupoAdicionalInternal(grupo['id'], newProductId,
          keepOriginalName: true);
    }
  }

  Future<void> duplicateProduct(String productId) async {
    final companyId = _getCompanyId();
    if (companyId == null) throw Exception('Usuário não autenticado.');

    final originalProduct = await _supabase
        .from('produtos')
        .select('category_id')
        .eq('id', productId)
        .single();
    await _duplicateProductInternal(
        productId, originalProduct['category_id'].toString());

    await fetchData();
  }

  Future<void> duplicateCategory(String categoryId) async {
    final companyId = _getCompanyId();
    if (companyId == null) throw Exception('Usuário não autenticado.');

    final originalCategory = await _supabase
        .from('categorias')
        .select()
        .eq('id', categoryId)
        .eq('company_id', companyId)
        .single();

    final productsToCopy = await _supabase
        .from('produtos')
        .select('id')
        .eq('category_id', categoryId);

    final newName = await _getNewCopyName(
      tableName: 'categorias',
      nameColumn: 'name',
      baseName: originalCategory['name'],
      filterColumn: 'company_id',
      filterValue: companyId,
    );

    final newCategoryData = Map<String, dynamic>.from(originalCategory)
      ..remove('id')
      ..remove('created_at')
      ..['name'] = newName;

    final inserted = await _supabase
        .from('categorias')
        .insert(newCategoryData)
        .select()
        .single();
    final newCategoryId = inserted['id'].toString();

    for (final product in productsToCopy) {
      // ===== A CORREÇÃO ESTÁ AQUI =====
      // Ao duplicar uma categoria, os produtos dentro dela também devem ser
      // criados como cópias, não com o nome original.
      await _duplicateProductInternal(product['id'], newCategoryId,
          keepOriginalName: false); 
    }

    await fetchData();
  }}