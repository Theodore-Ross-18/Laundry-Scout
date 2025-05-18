import 'package:flutter/material.dart';
import 'package:laundry_scout/screens/users/set_businessinfo.dart'; // Import the new screen
import 'package:laundry_scout/screens/users/set_userinfo.dart'; // Import the new screen

class SelectUserScreen extends StatelessWidget {
  const SelectUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF6F5ADC), // Set the background color
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Add the logo here
              Image.asset(
                'lib/assets/lslogo.png', // Adjust the path if necessary
                height: 50, // Adjust size as needed
                width: 50, // Adjust size as needed
              ),
              const SizedBox(height: 10), // Add spacing after the logo
              Text(
                'Select User',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20), // Adjusted spacing
              _buildUserSelectionCard(
                context: context,
                avatarImagePath: 'lib/assets/user/user.png',
                title: 'Laundry Service User',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SetUserInfoScreen()),
                  );
                },
              ),
              const SizedBox(height: 20), // Adjusted spacing
              Text(
                'Or',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(color: Colors.white.withOpacity(0.8)),
              ),
              const SizedBox(height: 20), // Adjusted spacing
              _buildUserSelectionCard(
                context: context,
                avatarImagePath: 'lib/assets/user/owner.png',
                title: 'Business Owner',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SetBusinessInfoScreen()),
                  );
                },
              ),
              const Spacer(), // Pushes footer to the bottom
              Padding( // Added Padding for the footer
                padding: const EdgeInsets.only(bottom: 20.0), // Adjusted bottom padding
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Laundry Scout © 2024',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 4), // Small space between the two lines
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
          color: Colors.white.withOpacity(0.15), // Slightly transparent white or light purple
          borderRadius: BorderRadius.circular(15.0),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Use Image.asset if avatarImagePath is provided
            if (avatarImagePath != null)
              Image.asset(avatarImagePath, height: 80, width: 80)
            // Fallback to Icon if avatar is provided (though we are using images now)
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