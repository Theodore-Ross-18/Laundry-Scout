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
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchBranchDetails();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Branch Details'),
        backgroundColor: const Color(0xFF7B61FF),
        foregroundColor: Colors.white,
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
                      _buildDetailRow('Business Name', _branchDetails!['business_name']),
                      _buildDetailRow('Address', _branchDetails!['business_address']),
                      _buildDetailRow('Phone Number', _branchDetails!['business_phone_number']),
                      _buildDetailRow('Email', _branchDetails!['email']),
                      _buildDetailRow('About', _branchDetails!['about_business']),
                      _buildDetailRow('Services Offered', _branchDetails!['services_offered']?.toString()),
                      _buildDetailRow('Does Delivery', _branchDetails!['does_delivery']?.toString()),
                      _buildDetailRow('Is Online', _branchDetails!['is_online']?.toString()),
                      _buildDetailRow('Availability Status', _branchDetails!['availability_status']),
                      _buildDetailRow('Operating Hours', _branchDetails!['open_hours_text']),
                      _buildDetailRow('Terms and Conditions', _branchDetails!['terms_and_conditions']),
                      // Add more fields as needed
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value ?? 'N/A',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}