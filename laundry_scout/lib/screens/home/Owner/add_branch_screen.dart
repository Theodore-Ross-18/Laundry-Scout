import 'package:flutter/material.dart';

class AddBranchScreen extends StatelessWidget {
  const AddBranchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Branch'),
      ),
      body: const Center(
        child: Text('Add Branch Screen Content'),
      ),
    );
  }
}