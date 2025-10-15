import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:laundry_scout/services/business_profile_service.dart';
import 'package:laundry_scout/screens/home/Owner/branch_detail_screen.dart';

class AddBranchScreen extends StatefulWidget {
  const AddBranchScreen({super.key});

  @override
  State<AddBranchScreen> createState() => _AddBranchScreenState();
}

class _AddBranchScreenState extends State<AddBranchScreen> {
  final BusinessProfileService _businessProfileService = BusinessProfileService();
  List<Map<String, dynamic>> _branchProfiles = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchBranchProfiles();
  }

  Future<void> _fetchBranchProfiles() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not authenticated.';
          _isLoading = false;
        });
        return;
      }

      final mainProfile = await _businessProfileService.getMainBusinessProfile(user.id);

      if (mainProfile == null) {
        setState(() {
          _errorMessage = 'Main business profile not found for this user.';
          _isLoading = false;
        });
        return;
      }

      final ownerFirstName = mainProfile['owner_first_name'];
      final ownerLastName = mainProfile['owner_last_name'];

      if (ownerFirstName == null || ownerLastName == null) {
        setState(() {
          _errorMessage = 'Owner first name or last name not found for the main business profile.';
          _isLoading = false;
        });
        return;
      }

      final branches = await _businessProfileService.getBranchProfiles(
        ownerFirstName,
        ownerLastName,
      );

      setState(() {
        _branchProfiles = branches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load branch profiles: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Branches'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _branchProfiles.isEmpty
                  ? const Center(child: Text('No branches found.'))
                  : ListView.builder(
                      itemCount: _branchProfiles.length,
                      itemBuilder: (context, index) {
                        final branch = _branchProfiles[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: ListTile(
                            title: Text(branch['business_name'] ?? 'N/A'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(branch['business_address'] ?? 'N/A'),
                                Text('Status: ${branch['status'] ?? 'Pending'}'),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BranchDetailScreen(branch: branch),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}