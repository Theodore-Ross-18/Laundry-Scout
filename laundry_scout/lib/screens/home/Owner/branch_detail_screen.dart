import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BranchDetailScreen extends StatefulWidget {
  final String branchId;

  const BranchDetailScreen({super.key, required this.branchId});

  @override
  State<BranchDetailScreen> createState() => _BranchDetailScreenState();
}

class _BranchDetailScreenState extends State<BranchDetailScreen> {
  Map<String, dynamic>? _branchDetails;
  bool _isLoading = true;
  bool _isEditing = false; // New state variable for edit mode
  final _supabase = Supabase.instance.client;

  // Controllers for editable fields
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Controllers for About & Services
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _servicesOfferedController = TextEditingController();

  // Controllers for Operational Details
  final TextEditingController _availabilityStatusController = TextEditingController();
  final TextEditingController _operatingHoursController = TextEditingController();
  final TextEditingController _termsAndConditionsController = TextEditingController();



  @override
  void initState() {
    super.initState();
    _fetchBranchDetails();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _aboutController.dispose();
    _servicesOfferedController.dispose();
    _availabilityStatusController.dispose();
    _operatingHoursController.dispose();
    _termsAndConditionsController.dispose();

    super.dispose();
  }

  Future<void> _fetchBranchDetails() async {
    try {
      final response = await _supabase
          .from('business_profiles')
          .select()
          .eq('id', widget.branchId)
          .single();

      if (mounted) {
        setState(() {
          _branchDetails = response;
          _isLoading = false;
          // Initialize controllers with fetched data
          _businessNameController.text = _branchDetails!['business_name'] ?? '';
          _addressController.text = _branchDetails!['business_address'] ?? '';
          _phoneNumberController.text = _branchDetails!['business_phone_number'] ?? '';
          _emailController.text = _branchDetails!['email'] ?? '';
          _aboutController.text = _branchDetails!['about_business'] ?? '';
          _servicesOfferedController.text = _branchDetails!['services_offered']?.toString() ?? '';
          _availabilityStatusController.text = _branchDetails!['availability_status'] ?? '';
          _operatingHoursController.text = _branchDetails!['open_hours_text'] ?? '';
          _termsAndConditionsController.text = _branchDetails!['terms_and_conditions'] ?? '';

        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching branch details: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
    if (!_isEditing) {
      _saveBranchDetails();
    }
  }

  Future<void> _saveBranchDetails() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _supabase.from('business_profiles').update({
        'business_name': _businessNameController.text,
        'business_address': _addressController.text,
        'business_phone_number': _phoneNumberController.text,
        'email': _emailController.text,
        'about_business': _aboutController.text,
        'services_offered': _servicesOfferedController.text.split(',').map((e) => e.trim()).toList(),
        'availability_status': _availabilityStatusController.text,
        'open_hours_text': _operatingHoursController.text,
        'terms_and_conditions': _termsAndConditionsController.text,

      }).eq('id', widget.branchId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Branch details updated successfully!')),
        );
        _fetchBranchDetails(); // Re-fetch to update UI with saved data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating branch details: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Branch Details'),
        backgroundColor: const Color(0xFF7B61FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: _toggleEditMode,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _branchDetails == null
              ? const Center(child: Text('Branch details not found.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Business Information'),
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildDetailRow(
                                  'Business Name',
                                  _branchDetails!['business_name'],
                                  isEditable: true,
                                  onChanged: (value) => _businessNameController.text = value),
                              _buildDetailRow(
                                  'Address',
                                  _branchDetails!['business_address'],
                                  isEditable: true,
                                  onChanged: (value) => _addressController.text = value),
                              _buildDetailRow(
                                  'Phone Number',
                                  _branchDetails!['business_phone_number'],
                                  isEditable: true,
                                  onChanged: (value) => _phoneNumberController.text = value),
                              _buildDetailRow(
                                  'Email',
                                  _branchDetails!['email'],
                                  isEditable: true,
                                  onChanged: (value) => _emailController.text = value),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionHeader('About & Services'),
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildDetailRow(
                                  'About',
                                  _branchDetails!['about_business'],
                                  isEditable: true,
                                  onChanged: (value) => _aboutController.text = value),
                              _buildDetailRow(
                                  'Services Offered',
                                  _branchDetails!['services_offered']?.toString(),
                                  isEditable: true,
                                  onChanged: (value) => _servicesOfferedController.text = value),
                              _buildDetailRow('Does Delivery', (_branchDetails!['does_delivery'] as bool?) == true ? 'Yes' : 'No'),
                              _buildDetailRow('Is Online', (_branchDetails!['is_online'] as bool?) == true ? 'Yes' : 'No'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionHeader('Operational Details'),
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildDetailRow(
                                  'Availability Status',
                                  _branchDetails!['availability_status'],
                                  isEditable: true,
                                  onChanged: (value) => _availabilityStatusController.text = value),
                              _buildDetailRow(
                                  'Operating Hours',
                                  _branchDetails!['open_hours_text'],
                                  isEditable: true,
                                  onChanged: (value) => _operatingHoursController.text = value),
                              _buildDetailRow(
                                  'Terms and Conditions',
                                  _branchDetails!['terms_and_conditions'],
                                  isEditable: true,
                                  onChanged: (value) => _termsAndConditionsController.text = value),
                            ],
                          ),
                        ),
                      ),
                      // Add more fields as needed

                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 255, 255, 255), // Changed to black
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value, {bool isEditable = false, Function(String)? onChanged}) {
    return ListTile(
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.black, // Ensure label is black
        ),
      ),
      subtitle: _isEditing && isEditable
          ? TextFormField(
              initialValue: value ?? '',
              onChanged: onChanged,
              style: const TextStyle(fontSize: 16, color: Colors.black), // Ensure input text is black
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            )
          : Text(
              value ?? 'N/A',
              style: const TextStyle(fontSize: 16, color: Colors.black), // Ensure display text is black
            ),
      contentPadding: EdgeInsets.zero,
    );
  }
}