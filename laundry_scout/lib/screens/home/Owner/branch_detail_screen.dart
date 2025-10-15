import 'package:flutter/material.dart';

class BranchDetailScreen extends StatelessWidget {
  final Map<String, dynamic> branch;

  const BranchDetailScreen({super.key, required this.branch});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(branch['business_name'] ?? 'Branch Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('ID', branch['id']),
            _buildDetailRow('Owner First Name', branch['owner_first_name']),
            _buildDetailRow('Owner Last Name', branch['owner_last_name']),
            _buildDetailRow('Business Name', branch['business_name']),
            _buildDetailRow('Business Address', branch['business_address']),
            _buildDetailRow('Business Phone Number', branch['business_phone_number']),
            _buildDetailRow('BIR Registration URL', branch['bir_registration_url']),
            _buildDetailRow('Business Certificate URL', branch['business_certificate_url']),
            _buildDetailRow('Mayors Permit URL', branch['mayors_permit_url']),
            _buildDetailRow('Created At', branch['created_at']),
            _buildDetailRow('Updated At', branch['updated_at']),
            _buildDetailRow('Username', branch['username']),
            _buildDetailRow('Email', branch['email']),
            _buildDetailRow('Cover Photo URL', branch['cover_photo_url']),
            _buildDetailRow('Services Offered', branch['services_offered']?.toString()),
            _buildDetailRow('Does Delivery', branch['does_delivery']?.toString()),
            _buildDetailRow('About Business', branch['about_business']),
            _buildDetailRow('Exact Location', branch['exact_location']),
            _buildDetailRow('Is Online', branch['is_online']?.toString()),
            _buildDetailRow('Last Active', branch['last_active']),
            _buildDetailRow('Open Hours', branch['open_hours']),
            _buildDetailRow('Phone Number', branch['phone_number']),
            _buildDetailRow('Service Prices', branch['service_prices']?.toString()),
            _buildDetailRow('Availability Status', branch['availability_status']),
            _buildDetailRow('Operating Hours', branch['operating_hours']?.toString()),
            _buildDetailRow('Time Slots', branch['time_slots']?.toString()),
            _buildDetailRow('Latitude', branch['latitude']?.toString()),
            _buildDetailRow('Longitude', branch['longitude']?.toString()),
            _buildDetailRow('Status', branch['status']),
            _buildDetailRow('Rejection Reason', branch['rejection_reason']),
            _buildDetailRow('Rejection Notes', branch['rejection_notes']),
            _buildDetailRow('Open Hours Text', branch['open_hours_text']),
            _buildDetailRow('Available Pickup Time Slots', branch['available_pickup_time_slots']?.join(', ')),
            _buildDetailRow('Available Dropoff Time Slots', branch['available_dropoff_time_slots']?.join(', ')),
            _buildDetailRow('Terms and Conditions', branch['terms_and_conditions']),
            _buildDetailRow('Is Branch', branch['is_branch']?.toString()),
            _buildDetailRow('Owner ID', branch['owner_id']),
            _buildDetailRow('Is Logged In', branch['is_logged_in']?.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 150,
              child: Text(
                '$label:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(value?.toString() ?? 'N/A'),
            ),
          ],
        ),
      ),
    );
  }
}