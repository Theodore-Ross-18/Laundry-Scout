import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:laundry_scout/screens/auth/login_screen.dart';
import 'package:laundry_scout/screens/home/home_screen.dart'; // Add this import

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load();
  
  // Debug prints
  print('SUPABASE_URL: ${dotenv.env['SUPABASE_URL']}');
  print('SUPABASE_ANON_KEY: ${dotenv.env['SUPABASE_ANON_KEY']}');
  
  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
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
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Optionally, show a loading indicator while checking auth state
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          final session = snapshot.data?.session;
          if (session != null) {
            // User is logged in, navigate to HomeScreen
            return const HomeScreen();
          } else {
            // User is not logged in, navigate to LoginScreen
            return const LoginScreen();
          }
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        // You can add other named routes here if needed
      },
    );
  }
}