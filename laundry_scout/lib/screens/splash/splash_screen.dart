import 'package:flutter/material.dart';
import 'package:laundry_scout/screens/auth/login_screen.dart';

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
      duration: const Duration(seconds: 2), // Total duration for all animations
      vsync: this,
    );

    // Animation for Logo and Title: Slide from bottom and Fade In
    _logoTitleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5), // Start 50% down from its final position
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart, // A smooth easing out curve
    ));

    _logoTitleFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.75, curve: Curves.easeIn), // Fade in during the first 75% of the animation
    ));

    // Animation for Footer: Fade In with a delay
    _footerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn), // Fade in during the last 50% of the animation
    ));

    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
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
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6F5ADC),
      body: Column( // Use a Column to arrange content vertically
        children: [
          Expanded( // This Expanded widget pushes the content below it to the bottom
            child: Center( // Center the main content (logo and title)
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
          // Footer content at the bottom
          FadeTransition(
            opacity: _footerFadeAnimation,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0), // Add some padding from the bottom edge
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end, // Align content to the bottom
                children: [
                  Text(
                    'Laundry Scout © 2024',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 1), // Small space between the two lines
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