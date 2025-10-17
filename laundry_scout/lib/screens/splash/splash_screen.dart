import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:laundry_scout/screens/auth/login_screen.dart';
import 'package:laundry_scout/screens/home/User/home_screen.dart';
import 'package:laundry_scout/screens/home/Owner/owner_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _logoTitleSlideAnimation;
  late Animation<double> _logoTitleFadeAnimation;
  late Animation<double> _footerFadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2), 
      vsync: this,
    );

    _logoTitleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    ));

    _logoTitleFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.75, curve: Curves.easeIn), 
    ));

    _footerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn), 
    ));

    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _checkAuthenticationState();
        }
      });
    });
  }

  Future<void> _checkAuthenticationState() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      
      if (user == null) {
        _navigateToLogin();
        return;
      }
      
      await _determineUserTypeAndNavigate(user.id);
    } catch (e) {
      print('Error checking authentication state: $e');
      _navigateToLogin();
    }
  }
  
  Future<void> _determineUserTypeAndNavigate(String userId) async {
    try {
      final businessResponse = await Supabase.instance.client
          .from('business_profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      
      if (businessResponse != null) {
        _navigateToOwnerHome();
        return;
      }

      final userResponse = await Supabase.instance.client
          .from('user_profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      
      if (userResponse != null) {
        _navigateToUserHome();
        return;
      }
      
      _navigateToLogin();
    } catch (e) {
      print('Error determining user type: $e');
      _navigateToLogin();
    }
  }
  
  void _navigateToLogin() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }
  
  void _navigateToUserHome() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }
  
  void _navigateToOwnerHome() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const OwnerHomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5A35E3),
      body: Column(
        children: [
          Expanded( 
            child: Center(
              child: SlideTransition(
                position: _logoTitleSlideAnimation,
                child: FadeTransition(
                  opacity: _logoTitleFadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'lib/assets/lslogo.png',
                        height: 100,
                        width: 100,
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Laundry Scout',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: _footerFadeAnimation,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0), 
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Laundry Scout © 2024',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Laundry app Management',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}