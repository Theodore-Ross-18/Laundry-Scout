import 'package:flutter/material.dart';
import 'package:laundry_scout/screens/users/set_businessinfo.dart'; 
import 'package:laundry_scout/screens/users/set_userinfo.dart'; 


class SelectUserScreen extends StatefulWidget {

  final String username;

  
  const SelectUserScreen({super.key, required this.username});

  @override
  State<SelectUserScreen> createState() => _SelectUserScreenState();
}

class _SelectUserScreenState extends State<SelectUserScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'User verified successfully!',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF5A35E3), 
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              
              Image.asset(
                'lib/assets/lslogo.png', 
                height: 50,
                width: 50, 
              ),
              const SizedBox(height: 10),
              Text(
                'Select User',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              _buildUserSelectionCard(
                context: context,
                avatarImagePath: 'lib/assets/user/user.png',
                title: 'Laundry Shop User',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SetUserInfoScreen(username: widget.username), // Pass the nullable username
                    ),
                  );
                },
              ),
              const SizedBox(height: 20), 
              Text(
                'Or',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(color: Colors.white.withOpacity(0.8)),
              ),
              const SizedBox(height: 20), 
              _buildUserSelectionCard(
                context: context,
                avatarImagePath: 'lib/assets/user/owner.png',
                title: 'Laundry Shop Owner',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SetBusinessInfoScreen(username: widget.username,),
                    ),
                  );
                },
              ),
              const Spacer(),
              Padding( 
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Laundry Scout © 2024',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 4), 
                    Text(
                      'Laundry app Management',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserSelectionCard({
    required BuildContext context,
    IconData? avatar,
    String? avatarImagePath,
    required String title,
    required VoidCallback onTap,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 20.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(15.0),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            
            if (avatarImagePath != null)
              Image.asset(avatarImagePath, height: 80, width: 80)
           
            else if (avatar != null)
              Icon(avatar, size: 70, color: Colors.white),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}