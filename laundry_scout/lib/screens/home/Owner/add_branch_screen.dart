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
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(branch['cover_photo_url'] ?? 'https://via.placeholder.com/150'), // Placeholder image
                            ),
                            title: Text(branch['business_name'] ?? 'N/A'),
                            subtitle: Text('Status: ${branch['status'] ?? 'Pending'}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDeleteBranch(branch['id']),
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

  void _confirmDeleteBranch(String branchId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete', style: TextStyle(color: Colors.black)),
          content: const Text(
            'Are you sure you want to delete this branch?',
            style: TextStyle(color: Colors.black),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteBranch(branchId);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteBranch(String branchId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _businessProfileService.deleteBranchProfile(branchId);
      _fetchBranchProfiles();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to delete branch: $e';
        _isLoading = false;
      });
    }
  }
}