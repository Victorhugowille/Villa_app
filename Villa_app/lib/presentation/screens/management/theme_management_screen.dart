import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/company_provider.dart';
import '../../providers/theme_provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'site_theme_screen.dart';

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

  // Função auxiliar para verificar se uma cor é escura
  bool _isDark(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark;
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
    // Assumindo que o CompanyProvider existe no seu projeto
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
              
              // --- NOVO WIDGET SOL/LUA ---
              const SizedBox(height: 16),
              _buildBrightnessToggle(),
              // ---------------------------

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
                        // O seu código original já lida com a criação do tema
                        // baseado nas cores selecionadas aqui.
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

  // --- NOVO MÉTODO PARA CONSTRUIR O SWITCH ---
  Widget _buildBrightnessToggle() {
    // Verifica se a cor de fundo ATUALMENTE selecionada na tela é escura
    final isCurrentlyDark = _isDark(_backgroundColor);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Ícone do Sol (Claro)
        Icon(Icons.wb_sunny_rounded, 
          color: isCurrentlyDark ? Colors.grey : Colors.orangeAccent),
        
        const SizedBox(width: 8),
        Switch(
          // Se estiver escuro, o switch está ativo
          value: isCurrentlyDark, 
          activeColor: Colors.blueGrey.shade700,
          activeTrackColor: Colors.blueGrey.shade300,
          inactiveThumbColor: Colors.yellow.shade700,
          inactiveTrackColor: Colors.yellow.shade200,
          onChanged: (value) {
            setState(() {
              if (value) {
                // Mudou para Escuro (Lua) -> Define um fundo padrão escuro
                _backgroundColor = const Color(0xFF121212); 
              } else {
                // Mudou para Claro (Sol) -> Define um fundo padrão claro
                _backgroundColor = const Color(0xFFFAFAFA); 
              }
              // Nota: Não alteramos a cor primária, mantendo a escolha do usuário.
              // O sistema existente (AppThemes) se encarregará de ajustar os contrastes
              // quando o usuário clicar em "Salvar Tema".
            });
          },
        ),
        const SizedBox(width: 8),
        
        // Ícone da Lua (Escuro)
        Icon(Icons.nightlight_round, 
          color: isCurrentlyDark ? Colors.blueAccent : Colors.grey),
      ],
    );
  }
  // ---------------------------------------------------------

  Widget _buildColorSelector(String label, Color color, Function(Color) onColorSelected) {
    // Pequena melhoria visual: se a cor selecionada for muito clara, 
    // a borda branca desaparece. Usamos a cor do tema para contraste.
    final borderColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.2);

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
              border: Border.all(color: borderColor, width: 3),
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
                  Container(width: 24, height: 24, decoration: BoxDecoration(color: palette.background, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300))),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}