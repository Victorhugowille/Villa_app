import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';

class SiteThemeScreen extends StatefulWidget {
  const SiteThemeScreen({super.key});

  @override
  State<SiteThemeScreen> createState() => _SiteThemeScreenState();
}

class _SiteThemeScreenState extends State<SiteThemeScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isSaving = false;
  Color _currentColor = const Color(0xFFFF5722); // Cor padrão

  @override
  void initState() {
    super.initState();
    _fetchInitialColor();
  }

  Future<void> _fetchInitialColor() async {
    setState(() => _isLoading = true);
    try {
      final companyId =
          Provider.of<AuthProvider>(context, listen: false).companyId;
      if (companyId == null) {
        throw 'ID da empresa não encontrado.';
      }

      final data = await _supabase
          .from('companies')
          .select('color_site')
          .eq('id', companyId)
          .single();

      final hexColor = data['color_site'] as String?;
      if (hexColor != null && hexColor.isNotEmpty) {
        _currentColor = _colorFromHex(hexColor);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar cor: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _colorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  Future<void> _showColorPicker() async {
    Color pickerColor = _currentColor;
    final newColor = await showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Escolha uma cor para o site'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) => pickerColor = color,
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false,
              displayThumbColor: true,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(pickerColor),
            ),
          ],
        );
      },
    );

    if (newColor != null) {
      setState(() => _currentColor = newColor);
    }
  }

  Future<void> _saveColor() async {
    setState(() => _isSaving = true);
    try {
      final companyId = Provider.of<AuthProvider>(context, listen: false).companyId;
      if (companyId == null) throw 'ID da empresa não encontrado.';

      final hexColor = _colorToHex(_currentColor);
      await _supabase
          .from('companies')
          .update({'color_site': hexColor})
          .eq('id', companyId);

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cor do site atualizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar a cor: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tema do Site Delivery'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Cor Principal do Site',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Esta cor será a principal no seu site de delivery, aplicada em botões, títulos e outros detalhes.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: _showColorPicker,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: _currentColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Theme.of(context).colorScheme.onSurface,
                            width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.edit, color: Colors.white, size: 40),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _colorToHex(_currentColor),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _isSaving
                          ? Container(
                              width: 24,
                              height: 24,
                              padding: const EdgeInsets.all(2.0),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Salvar Alterações'),
                      onPressed: _isSaving ? null : _saveColor,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}