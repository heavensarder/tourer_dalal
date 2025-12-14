import 'package:flutter/material.dart';

// Colors
const Color kBackgroundColor = Color(0xFF121212);
const Color kSurfaceColor = Color(0xFF1E1E1E);
const Color kPrimaryColor = Color(0xFF4CAF50);
const Color kAccentColor = Color(0xFF03DAC6);
const Color kErrorColor = Color(0xFFCF6679);

// Text Styles
const TextTheme kTextTheme = TextTheme(
  headlineLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.white),
  headlineMedium: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, color: Colors.white),
  headlineSmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.white),
  titleLarge: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Colors.white),
  titleMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500, color: Colors.white),
  titleSmall: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w400, color: Colors.white),
  bodyLarge: TextStyle(fontSize: 16.0, color: Colors.white),
  bodyMedium: TextStyle(fontSize: 14.0, color: Colors.white),
  bodySmall: TextStyle(fontSize: 12.0, color: Colors.white),
  labelLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white),
);

// Spacing
const double kSpacingUnit = 8.0;
const double kSpacingXXS = kSpacingUnit * 0.5; // 4
const double kSpacingXS = kSpacingUnit;      // 8
const double kSpacingS = kSpacingUnit * 2;   // 16
const double kSpacingM = kSpacingUnit * 3;   // 24
const double kSpacingL = kSpacingUnit * 4;   // 32
const double kSpacingXL = kSpacingUnit * 5;  // 40
const double kSpacingXXL = kSpacingUnit * 6; // 48

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  primaryColor: kPrimaryColor,
  scaffoldBackgroundColor: kBackgroundColor,
  cardColor: kSurfaceColor,
  colorScheme: const ColorScheme.dark(
    primary: kPrimaryColor,
    secondary: kAccentColor,
    background: kBackgroundColor,
    surface: kSurfaceColor,
    error: kErrorColor,
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onBackground: Colors.white,
    onSurface: Colors.white,
    onError: Colors.black,
  ),
  textTheme: kTextTheme,
  appBarTheme: const AppBarTheme(
    backgroundColor: kSurfaceColor,
    elevation: 0,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: IconThemeData(color: Colors.white),
  ),
  cardTheme: CardThemeData(
    color: kSurfaceColor,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(kSpacingS),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: kPrimaryColor,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kSpacingS),
      ),
    ),
  ),
);
