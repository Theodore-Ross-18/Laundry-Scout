import 'package:flutter/material.dart';

class AddStaffScreen extends StatelessWidget {
  const AddStaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff'),
      ),
      body: const Center(
        child: Text('This is a placeholder for the Add Staff screen.'),
      ),
    );
  }
}