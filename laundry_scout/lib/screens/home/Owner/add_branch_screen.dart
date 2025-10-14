import 'package:flutter/material.dart';
import 'package:laundry_scout/screens/auth/signup_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddBranchScreen extends StatefulWidget {
  const AddBranchScreen({super.key});

  @override
  State<AddBranchScreen> createState() => _AddBranchScreenState();
}

class _AddBranchScreenState extends State<AddBranchScreen> {
  List<Map<String, dynamic>> _branches = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchBranches();
  }

  Future<void> _fetchBranches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final response = await Supabase.instance.client
          .from('business_profiles')
          .select('*')
          .eq('owner_id', user.id)
          .eq('is_branch', true);

      setState(() {
        _branches = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load branches: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Branch (Placeholder)'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _branches.isEmpty
                  ? const Center(child: Text('No branches added yet.'))
                  : ListView.builder(
                      itemCount: _branches.length,
                      itemBuilder: (context, index) {
                        final branch = _branches[index];
                        return Card(
                          margin: const EdgeInsets.all(8.0),
                          child: ListTile(
                            title: Text(branch['business_name'] ?? 'N/A'),
                            subtitle: Text(branch['business_address'] ?? 'N/A'),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              // TODO: Navigate to branch details screen
                            },
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SignupScreen(isBranchSignup: true),
            ),
          );
          if (result == true) {
            _fetchBranches(); // Refresh branches if a new one was added
          }
        },
        label: const Text('Add Branch'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}