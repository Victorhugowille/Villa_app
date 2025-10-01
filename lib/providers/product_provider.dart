// lib/providers/product_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;
import 'package:villabistromobile/providers/auth_provider.dart';

class ProductProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final BuildContext context;

  List<app_data.Product> _products = [];
  List<app_data.Category> _categories = [];
  List<app_data.Adicional> _adicionais = [];
  bool isLoading = true;

  List<app_data.Product> get products => _products;
  List<app_data.Category> get categories => _categories;
  List<app_data.Adicional> get adicionais => _adicionais;

  ProductProvider(this.context) {
    fetchData();
  }

  String _getCompanyId() {
    final companyId = Provider.of<AuthProvider>(context, listen: false).companyId;
    if (companyId == null) {
      throw Exception('ID da empresa não encontrado. O usuário está logado?');
    }
    return companyId;
  }

  Future<void> fetchData() async {
    isLoading = true;
    notifyListeners();
    try {
      final companyId = _getCompanyId();
      final results = await Future.wait([
        _supabase.from('produtos').select('*, categorias(name)').eq('company_id', companyId).order('display_order', ascending: true),
        _supabase.from('categorias').select().eq('company_id', companyId).order('name', ascending: true),
        _supabase.from('adicionais').select().eq('company_id', companyId).order('name', ascending: true),
      ]);

      final productData = results[0] as List;
      final categoryData = results[1] as List;
      final adicionalData = results[2] as List;

      _products = productData.map((item) => app_data.Product.fromJson(item)).toList();
      _categories = categoryData.map((item) => app_data.Category.fromJson(item)).toList();
      _adicionais = adicionalData.map((item) => app_data.Adicional.fromJson(item)).toList();

    } catch (error) {
      debugPrint("Erro ao buscar dados: $error");
      _products = [];
      _categories = [];
      _adicionais = [];
    }
    isLoading = false;
    notifyListeners();
  }
  
  Future<void> addCategory(String name, IconData icon) async {
    try {
      await _supabase.from('categorias').insert({
        'name': name,
        'icon_code_point': icon.codePoint,
        'icon_font_family': icon.fontFamily,
        'company_id': _getCompanyId(),
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
  
  Future<void> addAdicional(String name, double price) async {
    try {
      await _supabase.from('adicionais').insert({
        'name': name,
        'price': price,
        'company_id': _getCompanyId(),
      });
      await fetchData();
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw Exception('Um adicional com este nome já existe.');
      }
      rethrow;
    } catch (error) {
      throw Exception('Falha ao criar adicional.');
    }
  }

  Future<void> updateAdicional(int id, String name, double price) async {
    try {
      await _supabase.from('adicionais').update({
        'name': name,
        'price': price,
      }).eq('id', id).eq('company_id', _getCompanyId());
      await fetchData();
    } catch (error) {
      throw Exception('Falha ao atualizar adicional.');
    }
  }

  Future<void> deleteAdicional(int id) async {
    try {
      await _supabase.from('adicionais').delete().eq('id', id).eq('company_id', _getCompanyId());
      await fetchData();
    } catch (error) {
      throw Exception('Falha ao deletar adicional. Verifique se ele não está vinculado a um produto.');
    }
  }
  Future<List<int>> getAdicionaisForProduct(int productId) async {
    try {
      final response = await _supabase
          .from('produtos_adicionais')
          .select('adicional_id')
          .eq('produto_id', productId);
      
      return response.map<int>((item) => item['adicional_id'] as int).toList();
    } catch (e) {
      debugPrint('Erro ao buscar adicionais do produto: $e');
      return [];
    }
  }

  Future<String?> _uploadProductImage(XFile imageFile, int productId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado.');
      
      final fileExt = imageFile.path.split('.').last;
      final path = '${_getCompanyId()}/$productId.$fileExt';

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

  Future<void> addProduct(String name, double price, int categoryId, int displayOrder, bool isSoldOut, XFile? imageFile, List<int> adicionalIds) async {
    try {
      final companyId = _getCompanyId();
      final newProduct = await _supabase.from('produtos').insert({
        'name': name,
        'price': price,
        'category_id': categoryId,
        'display_order': displayOrder,
        'is_sold_out': isSoldOut,
        'company_id': companyId,
      }).select().single();

      final newProductId = newProduct['id'];

      if (imageFile != null) {
        final imageUrl = await _uploadProductImage(imageFile, newProductId);
        if (imageUrl != null) {
          await _supabase.from('produtos').update({'image_url': imageUrl}).eq('id', newProductId);
        }
      }

      if (adicionalIds.isNotEmpty) {
        final newLinks = adicionalIds.map((adicionalId) => {
          'produto_id': newProductId,
          'adicional_id': adicionalId,
        }).toList();
        await _supabase.from('produtos_adicionais').insert(newLinks);
      }

      await fetchData();
    } catch (error) {
      throw Exception('Falha ao adicionar produto.');
    }
  }

  Future<void> updateProduct(int id, String name, double price, int categoryId, bool isSoldOut, XFile? imageFile, List<int> adicionalIds) async {
    try {
      final updates = {
        'name': name,
        'price': price,
        'category_id': categoryId,
        'is_sold_out': isSoldOut,
      };

      if (imageFile != null) {
        final imageUrl = await _uploadProductImage(imageFile, id);
        if (imageUrl != null) {
          updates['image_url'] = imageUrl;
        }
      }

      await _supabase.from('produtos').update(updates).eq('id', id).eq('company_id', _getCompanyId());

      await _supabase.from('produtos_adicionais').delete().eq('produto_id', id);

      if (adicionalIds.isNotEmpty) {
        final newLinks = adicionalIds.map((adicionalId) => {
          'produto_id': id,
          'adicional_id': adicionalId,
        }).toList();
        await _supabase.from('produtos_adicionais').insert(newLinks);
      }
      
      await fetchData();
    } catch (error) {
      throw Exception('Falha ao atualizar produto.');
    }
  }
  
  Future<void> deleteProduct(int id) async {
    try {
      await _supabase.from('produtos').delete().eq('id', id).eq('company_id', _getCompanyId());
      await fetchData();
    } catch (error) {
      throw Exception('Falha ao deletar produto.');
    }
  }

  Future<void> updateCategory(int id, String name, IconData icon) async {
    try {
      await _supabase.from('categorias').update({
        'name': name,
        'icon_code_point': icon.codePoint,
        'icon_font_family': icon.fontFamily,
      }).eq('id', id).eq('company_id', _getCompanyId());
      await fetchData();
    } catch(error) {
      throw Exception('Falha ao atualizar categoria.');
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _supabase.from('categorias').delete().eq('id', id).eq('company_id', _getCompanyId());
      await fetchData();
    } catch (error) {
      throw Exception('Falha ao deletar categoria. Verifique se ela não está sendo usada por algum produto.');
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