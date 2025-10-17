import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:laundry_scout/widgets/auth_wrapper.dart';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  String supabaseUrl;
  String supabaseAnonKey;
  
  if (kIsWeb) {
    // For web deployment, use compile-time environment variables
    supabaseUrl = const String.fromEnvironment('SUPABASE_URL', 
        defaultValue: 'https://aoyaedzbgollhajvrxiu.supabase.co');
    supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY', 
        defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFveWFlZHpiZ29sbGhhanZyeGl1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDcyNzY1NzUsImV4cCI6MjA2Mjg1MjU3NX0.iShQfGX-jB7798jk6fLim6m_eGpupzPb8lVgEBTMd1U');
  } else {
    // For mobile platforms, load from .env file
    await dotenv.load();
    supabaseUrl = dotenv.env['SUPABASE_URL']!;
    supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']!;
  }
  
  // Debug prints
  print('SUPABASE_URL: $supabaseUrl');
  print('SUPABASE_ANON_KEY: $supabaseAnonKey');
  
  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Laundry Scout',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF5A35E3),
        primaryColor: const Color(0xFF5A35E3),
        fontFamily: 'Poppins', // Default font
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF5A35E3),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFFFFFFFF),
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(
            color: Color(0xFFFFFFFF), // AppBar icons color
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
          titleLarge: TextStyle(color: Color(0xFFFFFFFF), fontFamily: 'Poppins'), // Used for TextFormField input style
          titleMedium: TextStyle(color: Color(0xFFFFFFFF), fontFamily: 'Poppins'),
          titleSmall: TextStyle(color: Color(0xFFFFFFFF), fontFamily: 'Poppins'),
          labelLarge: TextStyle(color: Color(0xFFFFFFFF), fontFamily: 'Poppins'), // For ElevatedButton text if not overridden
          labelMedium: TextStyle(color: Color(0xFFFFFFFF), fontFamily: 'Poppins'),
          labelSmall: TextStyle(color: Color(0xFFFFFFFF), fontFamily: 'Poppins'),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFFFFF), // White background for buttons
            foregroundColor: const Color(0xFF5A35E3), // Purple text for buttons
            textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
            minimumSize: const Size(double.infinity, 50), // Keep existing minimum size if desired
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFFFFFFF), // White text for TextButtons
            textStyle: const TextStyle(fontFamily: 'Poppins', decoration: TextDecoration.underline),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Color(0xFFFFFFFF), fontFamily: 'Poppins'),
          hintStyle: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFFFFFFF)),
            borderRadius: BorderRadius.all(Radius.circular(18.0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white70),
            borderRadius: BorderRadius.all(Radius.circular(18.0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFFFFFFF)),
            borderRadius: BorderRadius.all(Radius.circular(18.0)),
          ),
          errorStyle: TextStyle(fontFamily: 'Poppins', color: Colors.yellowAccent), // Example error color
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFFFFFFF)),
            borderRadius: BorderRadius.all(Radius.circular(18.0)),
          ),
          iconColor: Color(0xFFFFFFFF),
          prefixIconColor: Color(0xFFFFFFFF),
          suffixIconColor: Color(0xFFFFFFFF),
          // cursorColor: Color(0xFFFFFFFF), // This line was incorrect and is removed
        ),
        textSelectionTheme: const TextSelectionThemeData( // Add this section
          cursorColor: Color(0xFFFFFFFF),                 // Set global cursor color here
          selectionColor: Colors.white30,                 // Optional: selection color
          selectionHandleColor: Colors.white70,           // Optional: selection handle color
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xFFFFFFFF),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(), // Use AuthWrapper to handle initial routing
    );
  }
}