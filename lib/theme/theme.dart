import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Define blue color scheme
const Color primaryColor = Color(0xFF1565C0); // Strong Blue
const Color secondaryColor = Color(0xFF42A5F5); // Lighter Blue
const Color accentColor = Color(0xFF90CAF9); // Light Blue
const Color backgroundColor = Color(0xFFE3F2FD); // Very light blue background
const Color surfaceColor = Colors.white;
const Color errorColor = Color(0xFFD32F2F); // Red for error
const Color onPrimaryColor = Colors.white;
const Color onSecondaryColor = Colors.black;
const Color onBackgroundColor = Colors.black;
const Color onSurfaceColor = Colors.black;
const Color onErrorColor = Colors.white;

// Define the Text Theme using Google Fonts
TextTheme buildTextTheme(TextTheme base) {
  return GoogleFonts.latoTextTheme(base).copyWith(
    headlineLarge: GoogleFonts.montserrat(
      fontSize: 32.0,
      fontWeight: FontWeight.bold,
      color: onBackgroundColor,
    ),
    headlineMedium: GoogleFonts.montserrat(
      fontSize: 24.0,
      fontWeight: FontWeight.bold,
      color: onBackgroundColor,
    ),
    headlineSmall: GoogleFonts.montserrat(
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
      color: onBackgroundColor,
    ),
    titleLarge: GoogleFonts.lato(
      fontSize: 18.0,
      fontWeight: FontWeight.w600,
      color: onBackgroundColor,
    ),
    titleMedium: GoogleFonts.lato(
      fontSize: 16.0,
      fontWeight: FontWeight.w600,
      color: onBackgroundColor,
    ),
    bodyLarge: GoogleFonts.lato(
      fontSize: 16.0,
      color: onBackgroundColor,
    ),
    bodyMedium: GoogleFonts.lato(
      fontSize: 14.0,
      color: onBackgroundColor,
    ),
    labelLarge: GoogleFonts.lato(
      fontSize: 14.0,
      fontWeight: FontWeight.bold,
      color: onPrimaryColor, // Often used on buttons
    ),
  );
}

// Define the main application theme
ThemeData buildAppTheme() {
  final ThemeData base = ThemeData.light(); // Start with a base light theme
  final TextTheme customTextTheme = buildTextTheme(base.textTheme);

  return base.copyWith(
    colorScheme: const ColorScheme(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      background: backgroundColor,
      error: errorColor,
      onPrimary: onPrimaryColor,
      onSecondary: onSecondaryColor,
      onSurface: onSurfaceColor,
      onBackground: onBackgroundColor,
      onError: onErrorColor,
      brightness: Brightness.light,
    ),
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    textTheme: customTextTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: onPrimaryColor, // Icon and title color
      elevation: 4.0,
      centerTitle: true,
      titleTextStyle:
          customTextTheme.titleLarge?.copyWith(color: onPrimaryColor),
    ),
    cardTheme: CardTheme(
      elevation: 2.0,
      color: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: onPrimaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        textStyle: customTextTheme.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: primaryColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: secondaryColor, width: 2.0),
      ),
      labelStyle: customTextTheme.bodyMedium?.copyWith(color: primaryColor),
    ),
    // Add other widget themes as needed (e.g., floatingActionButtonTheme, bottomNavigationBarTheme)
  );
}
