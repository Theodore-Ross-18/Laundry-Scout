import 'package:flutter/material.dart';

class AddStaffScreen extends StatelessWidget {
  const AddStaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Staff'),
      ),
      body: const Center(
        child: Text('Add Staff Screen Content'),
      ),
    );
  }
}