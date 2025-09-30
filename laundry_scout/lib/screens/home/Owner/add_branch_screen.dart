import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../users/set_businessinfo.dart'; // Import the SetBusinessInfoScreen
import 'branch_detail_screen.dart'; // Import the BranchDetailScreen

class AddBranchScreen extends StatefulWidget {
  const AddBranchScreen({super.key});

  @override
  State<AddBranchScreen> createState() => _AddBranchScreenState();
}

class _AddBranchScreenState extends State<AddBranchScreen> {
  List<Map<String, dynamic>> _branches = [];
  bool _isLoading = true;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchBranches();
  }

  Future<void> _fetchBranches() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not logged in')),
          );
        }
        return;
      }

      final response = await _supabase
          .from('business_profiles')
          .select()
          .eq('owner_id', user.id)
          .eq('is_branch', true);

      if (mounted) {
        setState(() {
          _branches = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching branches: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Branches'),
        backgroundColor: const Color(0xFF7B61FF),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _branches.isEmpty
              ? const Center(child: Text('No branches added yet.'))
              : ListView.builder(
                  itemCount: _branches.length,
                  itemBuilder: (context, index) {
                    final branch = _branches[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(branch['business_name'] ?? 'N/A'),
                        subtitle: Text(branch['business_address'] ?? 'N/A'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDeleteBranch(branch['id']),
                            ),
                            const Icon(Icons.arrow_forward_ios),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => BranchDetailScreen(
                                branchId: branch['id'],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (user != null) {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SetBusinessInfoScreen(
                  isBranch: true,
                  ownerId: user.id,
                ),
              ),
            );
            if (result == true) {
              _fetchBranches(); // Refresh branches after adding a new one
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User not logged in')),
              );
            }
          }
        },
        backgroundColor: const Color(0xFF7B61FF),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmDeleteBranch(String branchId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Confirm Delete',
            style: TextStyle(color: Colors.black), // Make title text black
          ),
          content: const Text(
            'Are you sure you want to delete this branch?',
            style: TextStyle(color: Colors.black),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black), // Make Cancel text black
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _deleteBranch(branchId);
    }
  }

  Future<void> _deleteBranch(String branchId) async {
    try {
      await _supabase.from('business_profiles').delete().eq('id', branchId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Branch deleted successfully!')),
        );
        _fetchBranches(); // Refresh the list after deletion
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting branch: $e')),
        );
      }
    }
  }
}