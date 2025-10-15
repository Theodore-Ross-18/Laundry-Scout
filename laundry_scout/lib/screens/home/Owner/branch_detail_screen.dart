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
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            elevation: 4.0,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Branch Information',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const Divider(),
                  _buildDetailRow('ID', branch['id']),
                  _buildDetailRow('Business Name', branch['business_name']),
                  _buildDetailRow('Business Address', branch['business_address']),
                  _buildDetailRow('About Business', branch['about_business']),
                  _buildDetailRow('Exact Location', branch['exact_location']),
                ],
              ),
            ),
          ),
          Card(
            elevation: 4.0,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Owner Information',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const Divider(),
                  _buildDetailRow('Owner First Name', branch['owner_first_name']),
                  _buildDetailRow('Owner Last Name', branch['owner_last_name']),
                  _buildDetailRow('Owner ID', branch['owner_id']),
                ],
              ),
            ),
          ),
          Card(
            elevation: 4.0,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Information',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const Divider(),
                  _buildDetailRow('Business Phone Number', branch['business_phone_number']),
                  _buildDetailRow('Phone Number', branch['phone_number']),
                  _buildDetailRow('Email', branch['email']),
                ],
              ),
            ),
          ),
          Card(
            elevation: 4.0,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Operational Details',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const Divider(),
                  _buildDetailRow('Created At', branch['created_at']),
                  _buildDetailRow('Updated At', branch['updated_at']),
                  _buildDetailRow('Last Active', branch['last_active']),
                  _buildDetailRow('Is Online', branch['is_online']?.toString()),
                  _buildDetailRow('Availability Status', branch['availability_status']),
                  _buildDetailRow('Operating Hours', branch['operating_hours']?.toString()),
                  _buildDetailRow('Open Hours', branch['open_hours']),
                  _buildDetailRow('Open Hours Text', branch['open_hours_text']),
                  _buildDetailRow('Time Slots', branch['time_slots']?.toString()),
                  _buildDetailRow('Available Pickup Time Slots', branch['available_pickup_time_slots']?.join(', ')),
                  _buildDetailRow('Available Dropoff Time Slots', branch['available_dropoff_time_slots']?.join(', ')),
                  _buildDetailRow('Service Prices', branch['service_prices']?.toString()),
                  _buildDetailRow('Services Offered', branch['services_offered']?.toString()),
                  _buildDetailRow('Does Delivery', branch['does_delivery']?.toString()),
                ],
              ),
            ),
          ),
          Card(
            elevation: 4.0,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verification Documents',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const Divider(),
                  _buildDetailRow('BIR Registration URL', branch['bir_registration_url']),
                  _buildDetailRow('Business Certificate URL', branch['business_certificate_url']),
                  _buildDetailRow('Mayors Permit URL', branch['mayors_permit_url']),
                ],
              ),
            ),
          ),
          Card(
            elevation: 4.0,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location Coordinates',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const Divider(),
                  _buildDetailRow('Latitude', branch['latitude']?.toString()),
                  _buildDetailRow('Longitude', branch['longitude']?.toString()),
                ],
              ),
            ),
          ),
          Card(
            elevation: 4.0,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Status',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const Divider(),
                  _buildDetailRow('Username', branch['username']),
                  _buildDetailRow('Status', branch['status']),
                  _buildDetailRow('Rejection Reason', branch['rejection_reason']),
                  _buildDetailRow('Rejection Notes', branch['rejection_notes']),
                  _buildDetailRow('Is Branch', branch['is_branch']?.toString()),
                  _buildDetailRow('Is Logged In', branch['is_logged_in']?.toString()),
                ],
              ),
            ),
          ),
          Card(
            elevation: 4.0,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Other Details',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const Divider(),
                  _buildDetailRow('Cover Photo URL', branch['cover_photo_url']),
                  _buildDetailRow('Terms and Conditions', branch['terms_and_conditions']),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}