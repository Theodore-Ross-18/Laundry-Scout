import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math'; // For generating OTP

class AddStaffScreen extends StatefulWidget {
  const AddStaffScreen({super.key});

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final _emailController = TextEditingController();
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _branches = [];
  String? _selectedBranchId;
  String? _selectedBranchName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchBranches();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _fetchBranches() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await _supabase
          .from('business_profiles')
          .select('id, business_name')
          .eq('is_branch', true)
          .order('business_name', ascending: true);

      setState(() {
        _branches = List<Map<String, dynamic>>.from(response);
        if (_branches.isNotEmpty) {
          _selectedBranchId = _branches.first['id'];
          _selectedBranchName = _branches.first['business_name'];
        }
      });
    } catch (error) {
      _showSnackBar('Error fetching branches: $error', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _generateOtp() {
    final random = Random();
    return List.generate(6, (_) => random.nextInt(10).toString()).join();
  }

  Future<void> _sendInvitation() async {
    if (_emailController.text.isEmpty || _selectedBranchId == null) {
      _showSnackBar('Please enter an email and select a branch.', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final otp = _generateOtp();
      final invitationLink = 'https://your-app-domain.com/invitation?shopName=LaundryScout&branchName=$_selectedBranchName&invitationCode=$otp'; // IMPORTANT: Configure deep linking for your app to handle this URL

      // In a real application, you would send this email via a backend service
      // For this example, we'll just simulate sending and show the link
      print('Sending invitation to ${_emailController.text} for branch $_selectedBranchName with OTP: $otp');
      print('Invitation Link: $invitationLink');

      // Copy the link to clipboard for easy testing
      await Clipboard.setData(ClipboardData(text: invitationLink));
      _showSnackBar('Invitation link copied to clipboard! (Check console for link)', Colors.green);
      _emailController.clear();
    } catch (error) {
      _showSnackBar('Error sending invitation: $error', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Staff'),
      ),
      body: _isLoading && _branches.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Staff Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedBranchId,
                    decoration: const InputDecoration(
                      labelText: 'Select Branch',
                      border: OutlineInputBorder(),
                    ),
                    items: _branches.map<DropdownMenuItem<String>>((branch) {
                      return DropdownMenuItem<String>(
                        value: branch['id'],
                        child: Text(branch['business_name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedBranchId = value;
                        _selectedBranchName = _branches.firstWhere((branch) => branch['id'] == value)['business_name'];
                      });
                    },
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _sendInvitation,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Send Invitation'),
                  ),
                ],
              ),
            ),
    );
  }
}