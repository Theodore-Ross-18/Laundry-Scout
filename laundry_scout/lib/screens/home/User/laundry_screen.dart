import 'package:flutter/material.dart';

class LaundryScreen extends StatelessWidget {
  const LaundryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laundry'),
      ),
      body: const Center(
        child: Text('Laundry Screen Content'),
      ),
    );
  }
}