import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta de colores oficial del sistema MiniMarket Pro
/// Diseño basado en imagen de referencia (estilo neumórfico claro)
class AppColors {
  AppColors._();

  // Primario (azul vibrante)
  static const Color primary    = Color(0xFF3B6FF0);
  static const Color primary50  = Color(0xFFEBF0FE);
  static const Color primary100 = Color(0xFFBDD0FA);
  static const Color primary200 = Color(0xFF90AFF7);
  static const Color primary300 = Color(0xFF638DF4);
  static const Color primary700 = Color(0xFF2A55C4);
  static const Color primary900 = Color(0xFF1A3A8F);

  // Secundario
  static const Color secondary   = Color(0xFF7AA3F0);
  static const Color secondary50 = Color(0xFFEEF4FD);

  // Acentos de íconos (dashboard KPIs)
  static const Color accent       = Color(0xFF3B6FF0);
  static const Color accentDark   = Color(0xFF2A55C4);
  static const Color accentOrange = Color(0xFFFF9A3C);
  static const Color accentPink   = Color(0xFFFF5C8E);
  static const Color accentGreen  = Color(0xFF2ED573);
  static const Color accentPurple = Color(0xFF9B59F5);

  // Fondo general (azul gris suave)
  static const Color background = Color(0xFFEEF1F8);

  // Sidebar (blanco como en la imagen de referencia)
  static const Color sidebarBg         = Color(0xFFFFFFFF);
  static const Color sidebarActiveBg   = Color(0xFFEEF1F8);
  static const Color sidebarText       = Color(0xFF5A6478);
  static const Color sidebarActiveText = Color(0xFF3B6FF0);

  // Superficie / tarjetas
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card    = Color(0xFFFFFFFF);

  // Estado
  static const Color success = Color(0xFF2ED573);
  static const Color warning = Color(0xFFFF9A3C);
  static const Color error   = Color(0xFFFF4757);
  static const Color info    = Color(0xFF3B6FF0);

  // Neutrales
  static const Color textPrimary   = Color(0xFF1A1F36);
  static const Color textSecondary = Color(0xFF5A6478);
  static const Color textHint      = Color(0xFFA0ADB8);
  static const Color border        = Color(0xFFE2E8F0);

  // Stock states
  static const Color stockNormal   = Color(0xFF2ED573);
  static const Color stockBajo     = Color(0xFFFF9A3C);
  static const Color stockCritico  = Color(0xFFFF4757);
  static const Color stockSinStock = Color(0xFFA0ADB8);
}

class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor:  AppColors.primary,
        primary:    AppColors.primary,
        secondary:  AppColors.secondary,
        surface:    AppColors.surface,
        error:      AppColors.error,
      ).copyWith(
        surfaceContainerHighest: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge:  const TextStyle(fontSize: 32, fontWeight: FontWeight.bold,   color: AppColors.textPrimary),
        displayMedium: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold,   color: AppColors.textPrimary),
        headlineLarge: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700,   color: AppColors.textPrimary),
        headlineMedium:const TextStyle(fontSize: 20, fontWeight: FontWeight.w700,   color: AppColors.textPrimary),
        headlineSmall: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600,   color: AppColors.textPrimary),
        titleLarge:    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600,   color: AppColors.textPrimary),
        titleMedium:   const TextStyle(fontSize: 14, fontWeight: FontWeight.w500,   color: AppColors.textPrimary),
        bodyLarge:     const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.textPrimary),
        bodyMedium:    const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.textSecondary),
        bodySmall:     const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.textHint),
        labelLarge:    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,   color: AppColors.primary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation:       0,
        centerTitle:     false,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize:   18,
          fontWeight: FontWeight.w700,
          color:      AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color:       AppColors.card,
        elevation:   0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation:       0,
          shadowColor:     Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled:           true,
        fillColor:        AppColors.surface,
        contentPadding:   const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        hintStyle:  const TextStyle(color: AppColors.textHint, fontSize: 14),
        prefixIconColor: AppColors.textHint,
        suffixIconColor: AppColors.textHint,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor:  AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Inter'),
        shape:  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        extendedTextStyle: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14),
      ),
      dividerTheme: const DividerThemeData(
        color:     AppColors.border,
        space:     1,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor:    AppColors.primary50,
        selectedColor:      AppColors.primary,
        labelStyle: const TextStyle(fontSize: 13, fontFamily: 'Inter', color: AppColors.textSecondary),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor:         AppColors.primary,
        unselectedLabelColor: AppColors.textHint,
        indicatorColor:     AppColors.primary,
        labelStyle:   TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.normal, fontSize: 13),
      ),
    );
  }
}

/// Helper: crea una sombra suave estilo neumórfico para tarjetas
List<BoxShadow> get cardShadow => [
      BoxShadow(
        color:  const Color(0xFF3B6FF0).withOpacity(0.06),
        blurRadius:  12,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color:  Colors.black.withOpacity(0.04),
        blurRadius:  8,
        offset: const Offset(0, 2),
      ),
    ];
