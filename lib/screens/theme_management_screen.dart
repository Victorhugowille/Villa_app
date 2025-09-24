import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villabistromobile/providers/theme_provider.dart';

class ThemeManagementScreen extends StatefulWidget {
  const ThemeManagementScreen({super.key});

  @override
  State<ThemeManagementScreen> createState() => _ThemeManagementScreenState();
}

class _ThemeManagementScreenState extends State<ThemeManagementScreen> {
  // Inicialize as cores com os valores do tema atual
  late Color _primaryColor;
  late Color _secondaryColor;
  late Color _backgroundColor;

  final List<Color> _colorOptions = [
    // Cores primárias padrão
    ...Colors.primaries,
    
    // Novas cores escuras e tons de verde
    const Color(0xFF004d40),
    const Color(0xFF00695c),
    const Color(0xFF01579b),
    const Color(0xFF0d47a1),
    const Color(0xFF1b5e20),
    const Color(0xFF2e7d32),
    const Color(0xFF33691e),
    const Color(0xFF455a64),
    const Color(0xFF37474f),
    const Color(0xFF263238),
    const Color(0xFF424242),
    const Color(0xFF212121),

    // Cores básicas
    Colors.black,
    Colors.white,
  ];

  @override
  void initState() {
    super.initState();
    final theme = Provider.of<ThemeProvider>(context, listen: false).getTheme;
    _primaryColor = theme.primaryColor;
    _secondaryColor = theme.colorScheme.secondary;
    _backgroundColor = theme.scaffoldBackgroundColor;
  }

  // Função para mostrar um seletor de cores simples
  Future<void> _showColorPickerDialog(
      BuildContext context, int colorType) async {
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            colorType == 1
                ? 'Escolha a Cor Primária'
                : colorType == 2
                    ? 'Escolha a Cor Secundária'
                    : 'Escolha a Cor de Fundo',
            style: const TextStyle(fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final color in _colorOptions)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (colorType == 1) {
                              _primaryColor = color;
                            } else if (colorType == 2) {
                              _secondaryColor = color;
                            } else {
                              _backgroundColor = color;
                            }
                          });
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: color == Colors.white ? Colors.black : Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.getTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Temas'),
        actions: [
          IconButton(
            icon: Icon(Icons.color_lens, color: theme.primaryColor),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Seção de Cores Personalizadas
              Text(
                'Cores Personalizadas',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () => _showColorPickerDialog(context, 1),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.colorScheme.onSurface, width: 3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Primária'),
                    ],
                  ),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () => _showColorPickerDialog(context, 2),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _secondaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.colorScheme.onSurface, width: 3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Secundária'),
                    ],
                  ),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () => _showColorPickerDialog(context, 3),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _backgroundColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.colorScheme.onSurface, width: 3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Fundo'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  themeProvider.setCustomTheme(_primaryColor, _secondaryColor, _backgroundColor);
                },
                child: const Text('Aplicar Cores Personalizadas'),
              ),
              const SizedBox(height: 32),

              // Seção de Temas Pré-definidos
              Text(
                'Temas Pré-definidos',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: AppThemes.themes.length,
                itemBuilder: (context, index) {
                  final themeName = AppThemes.themes.keys.elementAt(index);
                  return Card(
                    color: theme.cardColor,
                    child: ListTile(
                      title: Text(themeName,
                          style: TextStyle(color: theme.colorScheme.onSurface)),
                      onTap: () {
                        themeProvider.setTheme(themeName);
                      },
                      trailing: themeProvider.getThemeName == themeName
                          ? Icon(Icons.check_circle, color: theme.primaryColor)
                          : null,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}