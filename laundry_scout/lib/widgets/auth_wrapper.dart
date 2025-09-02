import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:laundry_scout/screens/splash/splash_screen.dart';
import 'package:laundry_scout/screens/home/User/home_screen.dart';
import 'package:laundry_scout/screens/home/Owner/owner_home_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  Widget? _targetScreen;

  @override
  void initState() {
    super.initState();
    _checkInitialAuthState();
  }

  Future<void> _checkInitialAuthState() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      
      if (user == null) {
        // No authenticated user, show splash screen
        setState(() {
          _targetScreen = const SplashScreen();
          _isLoading = false;
        });
        return;
      }
      
      // User is authenticated, determine their type and navigate directly
      final userType = await _determineUserType(user.id);
      
      Widget homeScreen;
      switch (userType) {
        case 'business':
          homeScreen = const OwnerHomeScreen();
          break;
        case 'user':
          homeScreen = const HomeScreen();
          break;
        default:
          // No profile found, show splash screen to handle login
          homeScreen = const SplashScreen();
      }
      
      setState(() {
        _targetScreen = homeScreen;
        _isLoading = false;
      });
    } catch (e) {
      print('Error checking initial auth state: $e');
      // On error, show splash screen for safety
      setState(() {
        _targetScreen = const SplashScreen();
        _isLoading = false;
      });
    }
  }
  
  Future<String?> _determineUserType(String userId) async {
    try {
      // Check if user has a business profile
      final businessResponse = await Supabase.instance.client
          .from('business_profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      
      if (businessResponse != null) {
        return 'business';
      }
      
      // Check if user has a regular user profile
      final userResponse = await Supabase.instance.client
          .from('user_profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      
      if (userResponse != null) {
        return 'user';
      }
      
      return null; // No profile found
    } catch (e) {
      print('Error determining user type: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF6F5ADC),
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }
    
    return _targetScreen ?? const SplashScreen();
  }
}