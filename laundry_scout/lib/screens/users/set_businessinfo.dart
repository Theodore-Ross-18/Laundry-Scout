import 'package:flutter/material.dart';

class SetBusinessInfoScreen extends StatelessWidget {
  const SetBusinessInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Explicitly set screen background to white
      appBar: AppBar(
        title: const Text('Set Business Info'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Center(
                child: Text(
                  'LETS GET STARTED',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6F5ADC), // Adjusted to user's specified color
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _buildTextField(label: 'First name', initialValue: 'Jasper'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(label: 'Last name', initialValue: 'Saez'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildTextField(label: 'Phone Number', initialValue: '09658401361', keyboardType: TextInputType.phone),
              const SizedBox(height: 20),
              _buildTextField(label: 'Business Name', initialValue: 'Don Ernesto Laundry'),
              const SizedBox(height: 20),
              _buildTextField(label: 'Business Address', initialValue: 'Plaza Feliz Bldg. Brgy. San'),
              const SizedBox(height: 40),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Handle form submission
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6F5ADC), // Adjusted to user's specified color
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: const Text('SUBMIT', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required String label, String? initialValue, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
            contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Color(0xFF6F5ADC), width: 2.0), // Adjusted to user's specified color
            ),
          ),
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ],
    );
  }
}