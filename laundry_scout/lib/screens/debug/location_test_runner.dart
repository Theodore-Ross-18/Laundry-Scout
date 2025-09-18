import 'package:flutter/material.dart';
import 'location_test.dart';

// This is a standalone test runner for the location test screen
// To run this test individually, use this file as the main entry point

class LocationTestApp extends StatelessWidget {
  const LocationTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location Test',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF6F5ADC),
        primaryColor: const Color(0xFF6F5ADC),
        fontFamily: 'Poppins',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6F5ADC),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFFFFFFFF),
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(
            color: Color(0xFFFFFFFF),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFFFFFFF), fontFamily: 'Poppins'),
          bodyMedium: TextStyle(color: Color(0xFFFFFFFF), fontFamily: 'Poppins'),
          bodySmall: TextStyle(color: Color(0xFFFFFFFF), fontFamily: 'Poppins'),
          displayLarge: TextStyle(color: Color(0xFFFFFFFF), fontFamily: 'Poppins'),
          displayMedium: TextStyle(color: Color(0xFFFFFFFF), fontFamily: 'Poppins'),
          displaySmall: TextStyle(color: Color(0xFFFFFFFF), fontFamily: 'Poppins'),
          headlineLarge: TextStyle(color: Color(0xFFFFFFFF), fontFamily: 'Poppins'),
          headlineMedium: TextStyle(color: Color(0xFFFFFFFF), fontFamily: 'Poppins'),
          headlineSmall: TextStyle(color: Color(0xFFFFFFFF), fontFamily: 'Poppins'),
          titleLarge: TextStyle(color: Color(0xFFFFFFFF), fontFamily: 'Poppins'),
          titleMedium: TextStyle(color: Color(0xFFFFFFFF), fontFamily: 'Poppins'),
          titleSmall: TextStyle(color: Color(0xFFFFFFFF), fontFamily: 'Poppins'),
          labelLarge: TextStyle(color: Color(0xFFFFFFFF), fontFamily: 'Poppins'),
          labelMedium: TextStyle(color: Color(0xFFFFFFFF), fontFamily: 'Poppins'),
          labelSmall: TextStyle(color: Color(0xFFFFFFFF), fontFamily: 'Poppins'),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFFFFF),
            foregroundColor: const Color(0xFF6F5ADC),
            textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFFFFFFF),
            textStyle: const TextStyle(fontFamily: 'Poppins', decoration: TextDecoration.underline),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Color(0xFFFFFFFF), fontFamily: 'Poppins'),
          hintStyle: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFFFFFFF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white70),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFFFFFFF)),
          ),
          errorStyle: TextStyle(fontFamily: 'Poppins', color: Colors.yellowAccent),
          iconColor: Color(0xFFFFFFFF),
          prefixIconColor: Color(0xFFFFFFFF),
          suffixIconColor: Color(0xFFFFFFFF),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFFFFFFFF),
          selectionColor: Colors.white30,
          selectionHandleColor: Colors.white70,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xFFFFFFFF),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: const LocationTestScreen(),
    );
  }
}

// Main function to run the location test individually
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LocationTestApp());
}