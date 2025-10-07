import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppColorPalette {
  final String name;
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color background;
  final Color onBackground;
  final Color surface;
  final Color onSurface;

  const AppColorPalette({
    required this.name,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.background,
    required this.onBackground,
    required this.surface,
    required this.onSurface,
  });
}

class AppThemes {
  static const palettes = [
    AppColorPalette(
      name: 'Vinho e Ouro',
      primary: Color(0xFFC09553), // Ouro envelhecido
      onPrimary: Colors.black,
      secondary: Color(0xFFF5F5DC), // Bege
      background: Color(0xFF2B2B2B), // Carvão escuro
      onBackground: Color(0xFFEAEAEA),
      surface: Color(0xFF3D3D3D), // Grafite
      onSurface: Color(0xFFEAEAEA),
    ),
    AppColorPalette(
      name: 'Mármore e Grafite',
      primary: Color(0xFF343A40), // Grafite escuro
      onPrimary: Colors.white,
      secondary: Color(0xFF6C757D), // Cinza ardósia
      background: Color(0xFFF8F9FA), // Mármore claro
      onBackground: Color(0xFF212529),
      surface: Color(0xFFFFFFFF), // Branco puro
      onSurface: Color(0xFF212529),
    ),
    AppColorPalette(
      name: 'Oliva e Terracota',
      primary: Color(0xFFE87461), // Terracota
      onPrimary: Color(0xFFFAF3E0),
      secondary: Color(0xFF556B2F), // Verde Oliva
      background: Color(0xFFFAF3E0), // Creme
      onBackground: Color(0xFF4A403A), // Marrom escuro
      surface: Color(0xFFEADDC6), // Linho
      onSurface: Color(0xFF4A403A),
    ),
    AppColorPalette(
      name: 'Azul Noturno',
      primary: Color(0xFF415A77), // Azul aço
      onPrimary: Color(0xFFE0E1DD),
      secondary: Color(0xFFE0E1DD), // Cinza claro
      background: Color(0xFF0D1B2A), // Azul noite
      onBackground: Color(0xFFE0E1DD),
      surface: Color(0xFF1B263B), // Azul escuro
      onSurface: Color(0xFFE0E1DD),
    ),
    AppColorPalette(
      name: 'Café e Creme',
      primary: Color(0xFFA37B73), // Caramelo
      onPrimary: Color(0xFF3D2C2E),
      secondary: Color(0xFFE4D8C8), // Creme
      background: Color(0xFF3D2C2E), // Café expresso
      onBackground: Color(0xFFE4D8C8),
      surface: Color(0xFF6A5A5A), // Chocolate ao leite
      onSurface: Color(0xFFE4D8C8),
    ),
    AppColorPalette(
      name: 'Verde e Bege',
      primary: Color(0xFFD4A373),
      onPrimary: Color(0xFF1E392A),
      secondary: Color(0xFFF0E6D1),
      background: Color(0xFF1E392A),
      onBackground: Color(0xFFF0E6D1),
      surface: Color(0xFF2A4B3A),
      onSurface: Color(0xFFF0E6D1),
    ),
    AppColorPalette(
      name: 'Azul e Branco',
      primary: Color(0xFF3498db),
      onPrimary: Colors.white,
      secondary: Color(0xFFecf0f1),
      background: Color(0xFF2c3e50),
      onBackground: Colors.white,
      surface: Color(0xFF34495e),
      onSurface: Colors.white,
    ),
    AppColorPalette(
      name: 'Pôr do Sol',
      primary: Color(0xFFe74c3c),
      onPrimary: Colors.white,
      secondary: Color(0xFFf39c12),
      background: Color(0xFFc0392b),
      onBackground: Colors.white,
      surface: Color(0xFFd35400),
      onSurface: Colors.white,
    ),
    AppColorPalette(
      name: 'Ouro e Preto',
      primary: Color(0xFFf1c40f),
      onPrimary: Colors.black,
      secondary: Color(0xFFecf0f1),
      background: Color(0xFF1c1c1c),
      onBackground: Color(0xFFf1c40f),
      surface: Color(0xFF2c3e50),
      onSurface: Color(0xFFf1c40f),
    ),
    AppColorPalette(
      name: 'Oceano Profundo',
      primary: Color(0xFF3498db),
      onPrimary: Colors.white,
      secondary: Color(0xFF2980b9),
      background: Color(0xFF16a085),
      onBackground: Colors.white,
      surface: Color(0xFF1abc9c),
      onSurface: Colors.white,
    ),
    AppColorPalette(
      name: 'Noite Estrelada',
      primary: Color(0xFF34495e),
      onPrimary: Colors.white,
      secondary: Color(0xFF9b59b6),
      background: Color(0xFF2c3e50),
      onBackground: Colors.white,
      surface: Color(0xFF34495e),
      onSurface: Colors.white,
    ),
    AppColorPalette(
      name: 'Céu Azul',
      primary: Color(0xFF2980b9),
      onPrimary: Colors.white,
      secondary: Color(0xFF3498db),
      background: Color(0xFFecf0f1),
      onBackground: Colors.black,
      surface: Color(0xFFbdc3c7),
      onSurface: Colors.black,
    ),
    AppColorPalette(
      name: 'Rosa Doce',
      primary: Color(0xFFe91e63),
      onPrimary: Colors.white,
      secondary: Color(0xFFf8bbd0),
      background: Color(0xFFfce4ec),
      onBackground: Colors.black,
      surface: Color(0xFFf48fb1),
      onSurface: Colors.black,
    ),
  ];

  static Map<String, ThemeData> get themes {
    return {
      for (var palette in palettes)
        palette.name: _createThemeFromPalette(palette)
    };
  }

  static Brightness _getBrightness(Color color) {
    return ThemeData.estimateBrightnessForColor(color);
  }

  static ThemeData _createThemeFromPalette(AppColorPalette palette) {
    final brightness = _getBrightness(palette.background);
    final onSecondary = _getBrightness(palette.secondary) == Brightness.dark ? Colors.white : Colors.black;

    return ThemeData(
      brightness: brightness,
      primaryColor: palette.primary,
      scaffoldBackgroundColor: palette.background,
      cardColor: palette.surface,
      dialogBackgroundColor: palette.surface,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: palette.primary,
        onPrimary: palette.onPrimary,
        secondary: palette.secondary,
        onSecondary: onSecondary,
        background: palette.background,
        onBackground: palette.onBackground,
        surface: palette.surface,
        onSurface: palette.onSurface,
        error: Colors.red.shade700,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.onBackground,
        elevation: 0,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
        ),
      ),
    );
  }

  static ThemeData createCustomTheme({
    required Color primary,
    required Color background,
  }) {
    // Deriva a cor secundária a partir da primária
    final Color secondary = Color.lerp(
        primary,
        _getBrightness(primary) == Brightness.dark ? Colors.white : Colors.black,
        0.2)!;

    final palette = AppColorPalette(
      name: 'Personalizado',
      primary: primary,
      onPrimary: _getBrightness(primary) == Brightness.dark ? Colors.white : Colors.black,
      secondary: secondary,
      background: background,
      onBackground: _getBrightness(background) == Brightness.dark ? Colors.white : Colors.black,
      surface: Color.lerp(background, _getBrightness(background) == Brightness.dark ? Colors.white : Colors.black, 0.08)!,
      onSurface: _getBrightness(background) == Brightness.dark ? Colors.white : Colors.black,
    );
    return _createThemeFromPalette(palette);
  }
}

class ThemeProvider with ChangeNotifier {
  late ThemeData _themeData;
  late String _themeName;

  ThemeProvider() {
    final defaultPalette = AppThemes.palettes.first;
    _themeName = defaultPalette.name;
    _themeData = AppThemes.themes[_themeName]!;
    loadTheme();
  }

  ThemeData get getTheme => _themeData;
  String get getThemeName => _themeName;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isCustom = prefs.getBool('isCustomTheme') ?? false;

    if (isCustom) {
      final primaryHex = prefs.getInt('customPrimaryColor');
      final backgroundHex = prefs.getInt('customBackgroundColor');
      
      final defaultPalette = AppThemes.palettes.first;

      if (primaryHex != null && backgroundHex != null) {
        setCustomTheme(
          primaryColor: Color(primaryHex),
          backgroundColor: Color(backgroundHex),
        );
      } else {
        setTheme(defaultPalette.name);
      }
    } else {
      final themeName = prefs.getString('theme') ?? AppThemes.palettes.first.name;
      setTheme(themeName);
    }
  }

  Future<void> setTheme(String themeName) async {
    _themeName = themeName;
    _themeData = AppThemes.themes[_themeName] ?? AppThemes.themes.values.first;
    notifyListeners();
    await _saveTheme(themeName);
  }

  Future<void> setCustomTheme(
      {required Color primaryColor,
      required Color backgroundColor}) async {
    _themeData = AppThemes.createCustomTheme(
      primary: primaryColor,
      background: backgroundColor,
    );
    _themeName = 'Personalizado';
    notifyListeners();
    await _saveCustomTheme(primaryColor, backgroundColor);
  }

  Future<void> _saveTheme(String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isCustomTheme', false);
    await prefs.setString('theme', themeName);
  }

  Future<void> _saveCustomTheme(Color primaryColor, Color backgroundColor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isCustomTheme', true);
    await prefs.setInt('customPrimaryColor', primaryColor.value);
    await prefs.remove('customSecondaryColor'); // Remove a chave antiga
    await prefs.setInt('customBackgroundColor', backgroundColor.value);
  }
}