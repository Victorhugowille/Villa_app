// lib/providers/product_provider.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:villabistromobile/data/app_data.dart' as app_data;

class ProductProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<app_data.Product> _products = [];
  List<app_data.Category> _categories = [];
  bool isLoading = true;

  List<app_data.Product> get products => _products;
  List<app_data.Category> get categories => _categories;

  ProductProvider() {
    fetchData();
  }

  Future<void> fetchData() async {
    isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _supabase.from('produtos').select('*, categorias(name)').order('display_order', ascending: true),
        _supabase.from('categorias').select().order('name', ascending: true),
      ]);
      
      final productData = results[0] as List;
      final categoryData = results[1] as List;

      _products = productData.map((item) => app_data.Product.fromJson(item)).toList();
      _categories = categoryData.map((item) => app_data.Category.fromJson(item)).toList();

    } catch (error) {
      debugPrint("Erro ao buscar produtos/categorias: $error");
      _products = [];
      _categories = [];
    }
    isLoading = false;
    notifyListeners();
  }

  Future<String?> _uploadProductImage(XFile imageFile, int productId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado para fazer upload.');
      }
      
      final fileExt = imageFile.path.split('.').last;
      final path = '${user.id}/$productId.$fileExt';

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

  Future<void> addProduct(String name, double price, int categoryId, int displayOrder, bool isSoldOut, XFile? imageFile) async {
    try {
      final newProduct = await _supabase.from('produtos').insert({
        'name': name,
        'price': price,
        'category_id': categoryId,
        'display_order': displayOrder,
        'is_sold_out': isSoldOut
      }).select().single();

      if(imageFile != null) {
        final imageUrl = await _uploadProductImage(imageFile, newProduct['id']);
        if (imageUrl != null) {
          await _supabase.from('produtos').update({'image_url': imageUrl}).eq('id', newProduct['id']);
        }
      }

      await fetchData();
    } catch (error) {
      throw Exception('Falha ao adicionar produto.');
    }
  }

  Future<void> updateProduct(int id, String name, double price, int categoryId, bool isSoldOut, XFile? imageFile) async {
    try {
      final updates = {
        'name': name,
        'price': price,
        'category_id': categoryId,
        'is_sold_out': isSoldOut,
      };

      if(imageFile != null) {
        final imageUrl = await _uploadProductImage(imageFile, id);
        if (imageUrl != null) {
          updates['image_url'] = imageUrl;
        }
      }

      await _supabase.from('produtos').update(updates).eq('id', id);
      await fetchData();
    } catch (error) {
      throw Exception('Falha ao atualizar produto.');
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
  
  Future<void> deleteProduct(int id) async {
    try {
      await _supabase.from('produtos').delete().eq('id', id);
      await fetchData();
    } catch (error) {
      throw Exception('Falha ao deletar produto.');
    }
  }

  Future<void> addCategory(String name, IconData icon) async {
    try {
      await _supabase.from('categorias').insert({
        'name': name,
        'icon_code_point': icon.codePoint,
        'icon_font_family': icon.fontFamily,
      });
      await fetchData();
    } catch(error) {
      throw Exception('Falha ao criar categoria. O nome já pode existir.');
    }
  }

  Future<void> updateCategory(int id, String name, IconData icon) async {
    try {
      await _supabase.from('categorias').update({
        'name': name,
        'icon_code_point': icon.codePoint,
        'icon_font_family': icon.fontFamily,
      }).eq('id', id);
      await fetchData();
    } catch(error) {
      throw Exception('Falha ao atualizar categoria.');
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _supabase.from('categorias').delete().eq('id', id);
      await fetchData();
    } catch (error) {
      throw Exception('Falha ao deletar categoria. Verifique se ela não está sendo usada por algum produto.');
    }
  }
}