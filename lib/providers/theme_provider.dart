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
      name: 'Floresta Viva',
      primary: Color(0xFF27ae60),
      onPrimary: Colors.white,
      secondary: Color(0xFF2ecc71),
      background: Color(0xFF2980b9),
      onBackground: Colors.white,
      surface: Color(0xFF3498db),
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
      name: 'Rústico',
      primary: Color(0xFF8e44ad),
      onPrimary: Colors.white,
      secondary: Color(0xFF9b59b6),
      background: Color(0xFF7f8c8d),
      onBackground: Colors.white,
      surface: Color(0xFF95a5a6),
      onSurface: Colors.white,
    ),
    AppColorPalette(
      name: 'Verão',
      primary: Color(0xFFf1c40f),
      onPrimary: Colors.black,
      secondary: Color(0xFFe67e22),
      background: Color(0xFFf39c12),
      onBackground: Colors.black,
      surface: Color(0xFFf1c40f),
      onSurface: Colors.black,
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
      name: 'Chocolate',
      primary: Color(0xFFd35400),
      onPrimary: Colors.white,
      secondary: Color(0xFFe67e22),
      background: Color(0xFF95a5a6),
      onBackground: Colors.white,
      surface: Color(0xFF7f8c8d),
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
    final Map<String, ThemeData> map = {};
    for (final palette in palettes) {
      final brightness = _getBrightness(palette.background);
      map[palette.name] = ThemeData(
        brightness: brightness,
        scaffoldBackgroundColor: palette.background,
        primaryColor: palette.primary,
        colorScheme: ColorScheme(
          brightness: brightness,
          primary: palette.primary,
          onPrimary: palette.onPrimary,
          secondary: palette.secondary,
          onSecondary: Colors.white,
          background: palette.background,
          onBackground: palette.onBackground,
          surface: palette.surface,
          onSurface: palette.onSurface,
          error: Colors.red,
          onError: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: palette.background,
          foregroundColor: palette.onBackground,
          elevation: 0,
        ),
        cardColor: palette.surface,
        dialogBackgroundColor: palette.surface,
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
    return map;
  }

  static Brightness _getBrightness(Color color) {
    return ThemeData.estimateBrightnessForColor(color);
  }
}

class ThemeProvider with ChangeNotifier {
  // Inicialize com um tema padrão para evitar valores nulos
  late String _themeName = AppThemes.palettes.first.name;
  late ThemeData _themeData = AppThemes.themes[_themeName]!;

  ThemeProvider() {
    // Carregue o tema salvo, mas não espere o resultado aqui
    loadTheme();
  }

  String get getThemeName => _themeName;
  ThemeData get getTheme => _themeData;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isCustom = prefs.getBool('isCustomTheme') ?? false;

    if (isCustom) {
      final primaryHex = prefs.getInt('customPrimaryColor');
      final secondaryHex = prefs.getInt('customSecondaryColor');
      final backgroundHex = prefs.getInt('customBackgroundColor');

      // Use valores padrão se as cores forem nulas
      final primaryColor = primaryHex != null ? Color(primaryHex) : Colors.blue;
      final secondaryColor = secondaryHex != null ? Color(secondaryHex) : Colors.red;
      final backgroundColor = backgroundHex != null ? Color(backgroundHex) : Colors.black;

      setCustomTheme(primaryColor, secondaryColor, backgroundColor);
    } else {
      final themeName = prefs.getString('theme') ?? AppThemes.palettes.first.name;
      setTheme(themeName);
    }
  }

  void setTheme(String themeName) async {
    _themeName = themeName;
    _themeData = AppThemes.themes[_themeName] ?? AppThemes.themes.values.first;
    notifyListeners();
    _saveTheme(themeName);
  }

  void setCustomTheme(Color primaryColor, Color secondaryColor, Color backgroundColor) async {
    final brightness = ThemeData.estimateBrightnessForColor(backgroundColor);

    _themeData = ThemeData(
      brightness: brightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: MaterialColor(primaryColor.value, const {}),
        accentColor: secondaryColor,
        brightness: brightness,
      ).copyWith(
        primary: primaryColor,
        secondary: secondaryColor,
        background: backgroundColor,
        onBackground: brightness == Brightness.dark ? Colors.white : Colors.black,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: secondaryColor,
      ),
    );
    _themeName = 'Personalizado';
    notifyListeners();
    _saveCustomTheme(primaryColor, secondaryColor, backgroundColor);
  }

  Future<void> _saveTheme(String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isCustomTheme', false);
    await prefs.setString('theme', themeName);
  }

  Future<void> _saveCustomTheme(Color primaryColor, Color secondaryColor, Color backgroundColor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isCustomTheme', true);
    await prefs.setInt('customPrimaryColor', primaryColor.value);
    await prefs.setInt('customSecondaryColor', secondaryColor.value);
    await prefs.setInt('customBackgroundColor', backgroundColor.value);
  }
}