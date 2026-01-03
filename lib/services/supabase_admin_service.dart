import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/organization.dart';

class SupabaseAdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Admin credentials
  static const String adminEmail = 'admin@dormease.com';
  static const String adminPassword = 'Dormease@8923';

  // Check if current user is admin
  bool isAdmin() {
    final user = _supabase.auth.currentUser;
    return user?.email == adminEmail;
  }

  // Check admin credentials
  static bool checkAdminCredentials(String email, String password) {
    return email == adminEmail && password == adminPassword;
  }

  // Get all organizations
  Future<List<Organization>> getAllOrganizations() async {
    try {
      final data = await _supabase
          .from('organizations')
          .select('*')
          .order('created_at', ascending: false);

      return data.map<Organization>((o) => Organization.fromJson(o)).toList();
    } catch (e) {
      debugPrint('Error fetching organizations: $e');
      return [];
    }
  }

  // Get organization count
  Future<int> getOrganizationCount() async {
    try {
      final response = await _supabase
          .from('organizations')
          .select('id');
      return response.length;
    } catch (e) {
      debugPrint('Error getting organization count: $e');
      return 0;
    }
  }

  // Get total users count
  Future<int> getTotalUsersCount() async {
    try {
      final response = await _supabase
          .from('organization_members')
          .select('id');
      return response.length;
    } catch (e) {
      debugPrint('Error getting users count: $e');
      return 0;
    }
  }

  // Get members of an organization
  Future<List<Map<String, dynamic>>> getOrganizationMembers(String orgId) async {
    try {
      final members = await _supabase
          .from('organization_members')
          .select('*, profiles!organization_members_profile_id_fkey(*)')
          .eq('organization_id', orgId);

      return List<Map<String, dynamic>>.from(members);
    } catch (e) {
      debugPrint('Error fetching organization members: $e');
      return [];
    }
  }

  // Create new organization with owner using database function
  Future<Map<String, dynamic>> createOrganizationWithOwner({
    required String ownerEmail,
    required String ownerPassword,
    required String ownerName,
    required String hostelName,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? country,
  }) async {
    try {
      // Build full address
      String? fullAddress;
      List<String> addressParts = [];
      if (address != null && address.isNotEmpty) addressParts.add(address);
      if (city != null && city.isNotEmpty) addressParts.add(city);
      if (state != null && state.isNotEmpty) addressParts.add(state);
      if (country != null && country.isNotEmpty) addressParts.add(country);
      if (addressParts.isNotEmpty) {
        fullAddress = addressParts.join(', ');
      }

      // Create slug from hostel name
      String slug = hostelName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
      slug = '$slug-${DateTime.now().millisecondsSinceEpoch}';

      // Call the database function to create everything (user, profile, org, membership, business_info)
      final result = await _supabase.rpc('create_organization_with_owner', params: {
        'p_owner_email': ownerEmail.toLowerCase().trim(),
        'p_owner_password': ownerPassword,
        'p_owner_name': ownerName,
        'p_hostel_name': hostelName,
        'p_slug': slug,
        'p_phone': phone,
        'p_address': fullAddress,
      });

      debugPrint('Create org result: $result');

      if (result != null && result['success'] == true) {
        return {
          'success': true,
          'organization_id': result['organization_id'],
          'owner_email': ownerEmail.toLowerCase().trim(),
          'owner_password': ownerPassword,
          'message': 'Organization created successfully!',
        };
      } else {
        return {
          'success': false,
          'message': result?['message'] ?? 'Failed to create organization',
        };
      }
    } catch (e) {
      debugPrint('Error creating organization: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Add user to existing organization using database function
  Future<Map<String, dynamic>> addUserToOrganization({
    required String orgId,
    required String userEmail,
    required String userPassword,
    required String userName,
    required String role,
  }) async {
    try {
      // Get organization details for hostel name
      final org = await _supabase
          .from('organizations')
          .select('name, phone, address')
          .eq('id', orgId)
          .single();

      // Call the database function
      final result = await _supabase.rpc('add_user_to_organization', params: {
        'p_organization_id': orgId,
        'p_email': userEmail.toLowerCase().trim(),
        'p_password': userPassword,
        'p_full_name': userName,
        'p_role': role,
        'p_hostel_name': org['name'],
        'p_phone': org['phone'],
        'p_address': org['address'],
      });

      debugPrint('Add user result: $result');

      if (result != null && result['success'] == true) {
        return {
          'success': true,
          'user_email': userEmail.toLowerCase().trim(),
          'user_password': userPassword,
          'message': 'User added successfully!',
        };
      } else {
        return {
          'success': false,
          'message': result?['message'] ?? 'Failed to add user',
        };
      }
    } catch (e) {
      debugPrint('Error adding user to organization: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Delete organization using database function
  Future<Map<String, dynamic>> deleteOrganization(String orgId) async {
    try {
      final result = await _supabase.rpc('delete_organization', params: {
        'p_organization_id': orgId,
      });

      debugPrint('Delete org result: $result');
      
      if (result != null && result['success'] == true) {
        return {
          'success': true,
          'message': result['message'] ?? 'Organization deleted successfully',
          'deleted_counts': result['deleted_counts'],
        };
      } else {
        return {
          'success': false,
          'message': result?['message'] ?? 'Failed to delete organization',
        };
      }
    } catch (e) {
      debugPrint('Error deleting organization: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Delete user by email (for cleanup)
  Future<bool> deleteUserByEmail(String email) async {
    try {
      final result = await _supabase.rpc('delete_user_by_email', params: {
        'p_email': email.toLowerCase().trim(),
      });

      debugPrint('Delete user result: $result');
      return result != null && result['success'] == true;
    } catch (e) {
      debugPrint('Error deleting user: $e');
      return false;
    }
  }

  // Get dashboard stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final orgsCount = await getOrganizationCount();
      final usersCount = await getTotalUsersCount();
      
      // Get total rooms
      final roomsResponse = await _supabase.from('rooms').select('id');
      final totalRooms = roomsResponse.length;
      
      // Get total tenants
      final tenantsResponse = await _supabase.from('tenants').select('id');
      final totalTenants = tenantsResponse.length;

      return {
        'organizations': orgsCount,
        'users': usersCount,
        'rooms': totalRooms,
        'tenants': totalTenants,
      };
    } catch (e) {
      debugPrint('Error getting dashboard stats: $e');
      return {
        'organizations': 0,
        'users': 0,
        'rooms': 0,
        'tenants': 0,
      };
    }
  }
}
