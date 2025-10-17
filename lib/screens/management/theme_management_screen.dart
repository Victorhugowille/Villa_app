import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/providers/company_provider.dart';
import 'package:villabistromobile/providers/theme_provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:villabistromobile/screens/management/site_theme_screen.dart';

class ThemeManagementScreen extends StatefulWidget {
  const ThemeManagementScreen({super.key});

  @override
  State<ThemeManagementScreen> createState() => _ThemeManagementScreenState();
}

class _ThemeManagementScreenState extends State<ThemeManagementScreen> {
  late Color _primaryColor;
  late Color _backgroundColor;

  @override
  void initState() {
    super.initState();
    _loadCurrentColors();
  }

  void _loadCurrentColors() {
    final theme = Provider.of<ThemeProvider>(context, listen: false).getTheme;
    setState(() {
      _primaryColor = theme.primaryColor;
      _backgroundColor = theme.scaffoldBackgroundColor;
    });
  }

  Future<void> _showAdvancedColorPicker(
      BuildContext context, Color initialColor, Function(Color) onColorSelected) async {
    Color pickerColor = initialColor;

    final newColor = await showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Escolha uma cor'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) => pickerColor = color,
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hsv,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(pickerColor);
              },
            ),
          ],
        );
      },
    );

    if (newColor != null) {
      onColorSelected(newColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final companyProvider = Provider.of<CompanyProvider>(context, listen: false);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Tema'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Cores Personalizadas',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildColorSelector(
                    'Primária',
                    _primaryColor,
                    (color) => setState(() => _primaryColor = color),
                  ),
                  _buildColorSelector(
                    'Fundo',
                    _backgroundColor,
                    (color) => setState(() => _backgroundColor = color),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                   Expanded(
                    child: OutlinedButton(
                      onPressed: _loadCurrentColors,
                      child: const Text('Resetar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Salvar Tema'),
                      onPressed: () {
                        themeProvider.setCustomTheme(
                          primaryColor: _primaryColor,
                          backgroundColor: _backgroundColor,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tema personalizado salvo!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const Divider(height: 48),
              Text(
                'Temas Pré-definidos',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: AppThemes.palettes.map((palette) {
                  return _buildPredefinedThemeCard(palette, themeProvider);
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: companyProvider.role == 'owner'
        ? FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SiteThemeScreen()),
              );
            },
            tooltip: 'Editar Tema do Site',
            child: const Icon(Icons.web),
          )
        : null,
    );
  }

  Widget _buildColorSelector(String label, Color color, Function(Color) onColorSelected) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _showAdvancedColorPicker(context, color, onColorSelected),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }

  Widget _buildPredefinedThemeCard(AppColorPalette palette, ThemeProvider themeProvider) {
    bool isSelected = themeProvider.getThemeName == palette.name;
    return GestureDetector(
      onTap: () => themeProvider.setTheme(palette.name),
      child: Card(
        elevation: isSelected ? 8 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
              : BorderSide.none,
        ),
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text(
                palette.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(width: 24, height: 24, decoration: BoxDecoration(color: palette.primary, shape: BoxShape.circle)),
                  Container(width: 24, height: 24, decoration: BoxDecoration(color: palette.secondary, shape: BoxShape.circle)),
                  Container(width: 24, height: 24, decoration: BoxDecoration(color: palette.background, shape: BoxShape.circle)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

}