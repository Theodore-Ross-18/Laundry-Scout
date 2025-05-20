import 'package:flutter/material.dart';

class SetBusinessProfileScreen extends StatelessWidget { // Or StatefulWidget
  final String username;

  const SetBusinessProfileScreen({Key? key, required this.username}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Set Profile for $username'),
        automaticallyImplyLeading: false, // Add this line to remove the back button
      ),
      body: Center(
        child: Text('TODO: Business Profile Screen for $username'),
      ),
    );
  }
}