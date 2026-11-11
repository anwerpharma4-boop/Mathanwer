import 'package:material_ui/material_ui.dart';

/// Design tokens for the child-friendly interface.
class AppColors {
  static const ink = Color(0xFF26324A);
  static const inkSoft = Color(0xFF5B6680);
  static const background = Color(0xFFFFF8EE);
  static const surface = Colors.white;
  static const primary = Color(0xFF3D7BF7);
  static const sunshine = Color(0xFFFFC93C);
  static const grass = Color(0xFF2EAD5B);
  static const coral = Color(0xFFFF6B5E);
  static const berry = Color(0xFFD6479B);
  static const grape = Color(0xFF8E5CC9);
  static const sky = Color(0xFF39B6E8);
  static const orange = Color(0xFFFF8C1A);
  static const teal = Color(0xFF15A6B8);
  static const success = Color(0xFF22A45D);
  static const gentleError = Color(0xFFFF8A65);

  /// Colours for the 10 home tiles.
  static const tiles = [
    Color(0xFFFF8C1A), // start
    Color(0xFF3D7BF7), // textbook
    Color(0xFF2EAD5B), // lessons
    Color(0xFFE5484D), // alphabet
    Color(0xFF8E5CC9), // vocabulary
    Color(0xFF15A6B8), // listening
    Color(0xFFD6479B), // games
    Color(0xFFE8B10E), // quizzes
    Color(0xFF39B6E8), // progress
    Color(0xFF6C7A93), // settings
  ];
}

class AppTheme {
  static const englishFont = 'Andika';
  static const arabicFont = 'NotoKufiArabic';

  /// Cycling colours for letters in recognition grids (as in the book).
  static Color letterColour(int i) => const [
    Color(0xFFFF8C1A),
    Color(0xFF2F6FD6),
    Color(0xFFE5B800),
    Color(0xFF2EAD5B),
    Color(0xFFD6479B),
    Color(0xFF8E5CC9),
  ][i % 6];

  static ThemeData build({required bool arabic}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      surface: AppColors.surface,
    );
    final family = arabic ? arabicFont : englishFont;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      // Soft shadows (the default black reads as a hard outline on cards).
      shadowColor: const Color(0x33000000),
      fontFamily: family,
      fontFamilyFallback: const [englishFont, arabicFont],
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.ink,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: TextStyle(fontFamily: family, fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: TextStyle(fontFamily: family, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(minimumSize: const Size(52, 52))),
      chipTheme: base.chipTheme.copyWith(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      sliderTheme: base.sliderTheme.copyWith(trackHeight: 6),
    );
  }
}

/// Style for English learning content (always Andika, LTR).
TextStyle learningText(double size, {Color color = AppColors.ink, FontWeight weight = FontWeight.w700}) =>
    TextStyle(fontFamily: AppTheme.englishFont, fontSize: size, color: color, fontWeight: weight, height: 1.2);
