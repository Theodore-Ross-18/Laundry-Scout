import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:laundry_scout/screens/splash/splash_screen.dart';
import 'package:laundry_scout/screens/home/User/home_screen.dart';
import 'package:laundry_scout/screens/home/Owner/owner_home_screen.dart';
import 'package:laundry_scout/screens/users/set_userinfo.dart';
import 'package:laundry_scout/screens/users/set_businessinfo.dart';

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
      
      // User is authenticated, determine their profile state and navigate accordingly
      final profileState = await _determineProfileState(user.id);
      
      Widget targetScreen;
      final email = user.email ?? ''; // Retrieve email here
      switch (profileState['type']) {
        case 'complete_business':
          targetScreen = const OwnerHomeScreen();
          break;
        case 'complete_user':
          targetScreen = const HomeScreen();
          break;
        case 'incomplete_business_info':
          // User has started business setup but hasn't completed business info
          targetScreen = SetBusinessInfoScreen(username: profileState['username'] ?? 'User', email: email);
          break;
        case 'incomplete_business_profile':
          // User has completed business info but hasn't set up business profile
          targetScreen = const OwnerHomeScreen();
          break;
        case 'incomplete_user_info':
          // User has started user setup but hasn't completed user info
          targetScreen = SetUserInfoScreen(username: profileState['username'] ?? 'User', email: email);
          break;
        default:
          // No profile found or unknown state, show splash screen
          targetScreen = const SplashScreen();
      }
      
      setState(() {
        _targetScreen = targetScreen;
        _isLoading = false;
      });
    } catch (e) {
      // Error checking initial auth state: $e
      // On error, show splash screen for safety
      setState(() {
        _targetScreen = const SplashScreen();
        _isLoading = false;
      });
    }
  }
  
  Future<Map<String, dynamic>> _determineProfileState(String userId) async {
    try {
      // Get user data from auth
      final user = Supabase.instance.client.auth.currentUser;
      final username = user?.userMetadata?['username'] ?? 'User';
      
      // Check if user has a business profile
      final businessResponse = await Supabase.instance.client
          .from('business_profiles')
          .select('id, business_name, exact_location, owner_first_name, owner_last_name, business_address')
          .eq('id', userId)
          .maybeSingle();
      
      if (businessResponse != null) {
        // Check if business profile is complete (has required fields for business profile screen)
        final hasBusinessName = businessResponse['business_name'] != null && businessResponse['business_name'].toString().isNotEmpty;
        final hasOwnerInfo = businessResponse['owner_first_name'] != null && businessResponse['owner_last_name'] != null;
        final hasBusinessAddress = businessResponse['business_address'] != null && businessResponse['business_address'].toString().isNotEmpty;
        
        if (hasBusinessName && hasOwnerInfo && hasBusinessAddress) {
          // Business info is complete, check if business profile setup is complete
          final hasExactLocation = businessResponse['exact_location'] != null && businessResponse['exact_location'].toString().isNotEmpty;
          
          if (hasExactLocation) {
            return {
              'type': 'complete_business',
              'username': username,
            };
          } else {
            // Business info exists but profile setup is incomplete
            return {
              'type': 'incomplete_business_profile',
              'username': username,
              'business_name': businessResponse['business_name'] ?? '',
              'exact_location': businessResponse['business_address'] ?? '',
            };
          }
        } else {
          // Business profile exists but basic info is incomplete
          return {
            'type': 'incomplete_business_info',
            'username': username,
          };
        }
      }
      
      // Check if user has a user profile
      final userResponse = await Supabase.instance.client
          .from('user_profiles')
          .select('id, first_name, last_name, mobile_number, email')
          .eq('id', userId)
          .maybeSingle();
      
      if (userResponse != null) {
        // Check if user profile is complete
        final hasFirstName = userResponse['first_name'] != null && userResponse['first_name'].toString().isNotEmpty;
        final hasLastName = userResponse['last_name'] != null && userResponse['last_name'].toString().isNotEmpty;
        final hasMobileNumber = userResponse['mobile_number'] != null && userResponse['mobile_number'].toString().isNotEmpty;
        final hasEmail = userResponse['email'] != null && userResponse['email'].toString().isNotEmpty;
        
        if (hasFirstName && hasLastName && hasMobileNumber && hasEmail) {
          return {
            'type': 'complete_user',
            'username': username,
          };
        } else {
          // User profile exists but is incomplete
          return {
            'type': 'incomplete_user_info',
            'username': username,
          };
        }
      }
      
      // No profile found, check user metadata to determine intended user type
      final userType = user?.userMetadata?['user_type'];
      if (userType == 'business') {
        return {
          'type': 'incomplete_business_info',
          'username': username,
        };
      } else if (userType == 'user') {
        return {
          'type': 'incomplete_user_info',
          'username': username,
        };
      }
      
      // No profile found and no clear indication of user type
      return {
        'type': 'unknown',
        'username': username,
      };
    } catch (e) {
      // Error determining profile state: $e
      return {
        'type': 'error',
        'username': 'User',
      };
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