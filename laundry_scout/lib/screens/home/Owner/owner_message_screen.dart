import 'package:flutter/material.dart';

class OwnerMessageScreen extends StatelessWidget {
  const OwnerMessageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: const Center(
        child: Text('Owner Messages Screen - Placeholder'),
      ),
    );
  }
}