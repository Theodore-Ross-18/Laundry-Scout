import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> getMainBusinessProfile(String ownerId) async {
    try {
      final response = await _supabase
          .from('business_profiles')
          .select('id, owner_first_name, owner_last_name, business_name')
          .eq('owner_id', ownerId)
          .eq('is_branch', false)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error fetching main business profile: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getBranchProfiles(String ownerFirstName, String ownerLastName) async {
    try {
      final response = await _supabase
          .from('business_profiles')
          .select('id, business_name, owner_first_name, owner_last_name, cover_photo_url')
          .eq('is_branch', true)
          .eq('owner_first_name', ownerFirstName)
          .eq('owner_last_name', ownerLastName);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching branch profiles: $e');
      return [];
    }
  }
}