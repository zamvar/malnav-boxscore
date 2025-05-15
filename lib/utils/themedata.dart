import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // For custom fonts

// --- Color Palette ---
// Primary Colors (Deep Blues/Grays for the main dark background elements)
const Color primaryDarkColor = Color(0xFF1A237E); // A deep indigo
const Color primaryColor = Color(0xFF283593); // A slightly lighter indigo
const Color primaryLightColor =
    Color(0xFF5C6BC0); // A lighter shade for highlights or variants

// Accent Colors (Vibrant for calls to action, highlights, scores)
const Color accentColor = Color(0xFFFFAB00); // Amber or a bright orange/yellow
const Color accentColorVariant = Color(0xFFFFC400);

// Background & Surface Colors
const Color backgroundColor =
    Color(0xFF121212); // Standard dark theme background
const Color surfaceColor =
    Color(0xFF1E1E1E); // Slightly lighter for cards, dialogs
const Color scaffoldBackgroundColor =
    Color(0xFF0D1117); // A very dark, almost black for main scaffold

// Text & Icon Colors
const Color onPrimaryColor = Colors.white; // Text on primary color surfaces
const Color onBackgroundColor =
    Colors.white; // Text on background color surfaces
const Color onSurfaceColor = Colors.white; // Text on surface color surfaces
const Color textPrimaryColor =
    Color(0xFFE0E0E0); // Main text (slightly off-white)
const Color textSecondaryColor = Color(0xFFB0BEC5); // Secondary text (greyer)
const Color disabledTextColor = Color(0xFF757575); // For disabled elements

// Error Color
const Color errorColor = Color(0xFFCF6679); // Standard dark theme error color

// --- Font Scheme ---
// Using Google Fonts. Make sure to add the google_fonts package to your pubspec.yaml
// and import it. You can choose other fonts as well.
final TextTheme scoreboardTextTheme = TextTheme(
  displayLarge: GoogleFonts.montserrat(
      fontSize: 57, fontWeight: FontWeight.bold, color: textPrimaryColor),
  displayMedium: GoogleFonts.montserrat(
      fontSize: 45, fontWeight: FontWeight.bold, color: textPrimaryColor),
  displaySmall: GoogleFonts.montserrat(
      fontSize: 36, fontWeight: FontWeight.w600, color: textPrimaryColor),
  headlineLarge: GoogleFonts.montserrat(
      fontSize: 32, fontWeight: FontWeight.w600, color: textPrimaryColor),
  headlineMedium: GoogleFonts.montserrat(
      fontSize: 28, fontWeight: FontWeight.w600, color: textPrimaryColor),
  headlineSmall: GoogleFonts.montserrat(
      fontSize: 24, fontWeight: FontWeight.w600, color: textPrimaryColor),
  titleLarge: GoogleFonts.lato(
      fontSize: 22, fontWeight: FontWeight.w700, color: textPrimaryColor),
  titleMedium: GoogleFonts.lato(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
      color: textPrimaryColor),
  titleSmall: GoogleFonts.lato(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: textSecondaryColor),
  bodyLarge: GoogleFonts.lato(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.5,
      color: textPrimaryColor),
  bodyMedium: GoogleFonts.lato(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.25,
      color: textSecondaryColor),
  bodySmall: GoogleFonts.lato(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.4,
      color: textSecondaryColor),
  labelLarge: GoogleFonts.lato(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.25,
      color: onPrimaryColor), // For button text
  labelMedium: GoogleFonts.lato(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: textSecondaryColor),
  labelSmall: GoogleFonts.lato(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: textSecondaryColor),
);

// --- ThemeData Definition ---
ThemeData darkScoreboardTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: primaryColor,
  primaryColorDark: primaryDarkColor,
  primaryColorLight: primaryLightColor,
  scaffoldBackgroundColor: scaffoldBackgroundColor,
  colorScheme: const ColorScheme(
    primary: primaryColor,
    primaryContainer: primaryDarkColor, // Often a darker shade of primary
    secondary: accentColor,
    secondaryContainer: accentColorVariant, // Often a darker shade of secondary
    surface: surfaceColor,
    background: backgroundColor,
    error: errorColor,
    onPrimary: onPrimaryColor,
    onSecondary: Colors.black, // Text on accent color
    onSurface: onSurfaceColor,
    onBackground: onBackgroundColor,
    onError: Colors.black, // Text on error color
    brightness: Brightness.dark,
  ),
  textTheme: scoreboardTextTheme,
  appBarTheme: AppBarTheme(
    backgroundColor: surfaceColor, // Or primaryDarkColor
    foregroundColor: onSurfaceColor, // Text and icon color
    elevation: 4,
    titleTextStyle:
        scoreboardTextTheme.titleLarge?.copyWith(color: onSurfaceColor),
    iconTheme: const IconThemeData(color: onSurfaceColor),
  ),
  cardTheme: CardTheme(
    color: surfaceColor,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: accentColor,
      foregroundColor: Colors.black, // Text color on accent button
      textStyle: scoreboardTextTheme.labelLarge?.copyWith(color: Colors.black),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: accentColor, // Text and border color
      side: const BorderSide(color: accentColor, width: 1.5),
      textStyle: scoreboardTextTheme.labelLarge?.copyWith(color: accentColor),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: accentColorVariant, // Text color
      textStyle: scoreboardTextTheme.labelLarge
          ?.copyWith(color: accentColorVariant, fontWeight: FontWeight.normal),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: surfaceColor.withOpacity(0.5),
    hintStyle: scoreboardTextTheme.bodyLarge
        ?.copyWith(color: textSecondaryColor.withOpacity(0.7)),
    labelStyle:
        scoreboardTextTheme.bodyLarge?.copyWith(color: accentColorVariant),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: surfaceColor.withOpacity(0.7), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: accentColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: errorColor, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: errorColor, width: 2),
    ),
    prefixIconColor: textSecondaryColor,
  ),
  dialogTheme: DialogTheme(
    backgroundColor: surfaceColor,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    titleTextStyle:
        scoreboardTextTheme.titleLarge?.copyWith(color: onSurfaceColor),
    contentTextStyle:
        scoreboardTextTheme.bodyMedium?.copyWith(color: onSurfaceColor),
  ),
  listTileTheme: const ListTileThemeData(
    iconColor: accentColorVariant,
    textColor: textPrimaryColor,
    dense: true,
  ),
  dividerTheme: DividerThemeData(
    color: Colors.grey.shade700,
    thickness: 0.5,
  ),
  iconTheme: const IconThemeData(
    color: textSecondaryColor, // Default icon color
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: accentColor,
  ),
  // You can further customize other components like BottomNavigationBar, TabBar, etc.
);
