import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const PearlsApp());
}

class PearlsApp extends StatelessWidget {
  const PearlsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pearls',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAF7F2),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B5C48),
          surface: const Color(0xFFFAF7F2),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF0EBE0),
          foregroundColor: Color(0xFF3A2E1E),
          elevation: 0,
            scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFF3A2E1E),
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFE8E0D0),
          selectedColor: const Color(0xFF6B5C48),
          labelStyle: const TextStyle(
            color: Color(0xFF6B5C48),
            fontSize: 13,
          ),
          secondaryLabelStyle: const TextStyle(
            color: Color(0xFFFAF7F2),
            fontSize: 13,
          ),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF6B5C48),
          foregroundColor: Color(0xFFFAF7F2),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF0EBE0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6B5C48), width: 1.5),
          ),
          hintStyle: const TextStyle(color: Color(0xFFA0906E)),
          labelStyle: const TextStyle(color: Color(0xFF6B5C48)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}