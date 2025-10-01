import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:villabistromobile/data/app_data.dart'; // Ajuste o caminho se necessário

class EstabelecimentoProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  
  Estabelecimento? _estabelecimento;
  bool _isLoading = false;

  Estabelecimento? get estabelecimento => _estabelecimento;
  bool get isLoading => _isLoading;
  
  String get nomeFantasia => _estabelecimento?.nomeFantasia ?? 'VillaBistrô';

  Future<void> fetchEstabelecimento() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('estabelecimentos')
          .select()
          .limit(1)
          .maybeSingle();

      if (response != null) {
        _estabelecimento = Estabelecimento.fromJson(response);
      }
    } catch (e) {
      // Aqui você pode tratar o erro, se desejar
      print('Erro ao buscar estabelecimento: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}