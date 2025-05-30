import 'package:flutter/material.dart';

class OwnerNotificationScreen extends StatelessWidget {
  const OwnerNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: const Center(
        child: Text('Owner Notifications Screen - Placeholder'),
      ),
    );
  }
}