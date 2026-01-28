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

  // Get all organizations using admin function (bypasses RLS)
  Future<List<Organization>> getAllOrganizations() async {
    try {
      final data = await _supabase.rpc('get_all_organizations_admin');
      return (data as List).map<Organization>((o) => Organization.fromJson(o)).toList();
    } catch (e) {
      debugPrint('Error fetching organizations: $e');
      return [];
    }
  }

  // Get single organization by ID
  Future<Organization?> getOrganizationById(String orgId) async {
    try {
      final data = await _supabase
          .from('organizations')
          .select('id, name, slug, logo_url, email, phone, address, city, state, country, plan, is_paused, paused_reason, paused_at, created_at, updated_at')
          .eq('id', orgId)
          .single();

      return Organization.fromJson(data);
    } catch (e) {
      debugPrint('Error fetching organization: $e');
      return null;
    }
  }

  // Get organization count (using Postgres count for efficiency)
  Future<int> getOrganizationCount() async {
    try {
      final response = await _supabase
          .from('organizations')
          .select('id')
          .limit(1000);  // Safety limit for admin queries
      return response.length;
    } catch (e) {
      debugPrint('Error getting organization count: $e');
      return 0;
    }
  }

  // Get total users count (using Postgres count for efficiency)
  Future<int> getTotalUsersCount() async {
    try {
      final response = await _supabase
          .from('organization_members')
          .select('id')
          .limit(1000);  // Safety limit for admin queries
      return response.length;
    } catch (e) {
      debugPrint('Error getting users count: $e');
      return 0;
    }
  }

  // Get members of an organization using admin function (bypasses RLS)
  Future<List<Map<String, dynamic>>> getOrganizationMembers(String orgId) async {
    try {
      final result = await _supabase.rpc('get_organization_members_admin', params: {
        'p_org_id': orgId,
      });
      if (result is List) {
        return List<Map<String, dynamic>>.from(result);
      }
      return [];
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

  // Pause an organization using admin function (bypasses RLS)
  Future<Map<String, dynamic>> pauseOrganization(String orgId, {String? reason}) async {
    try {
      debugPrint('Pausing organization: $orgId');
      final result = await _supabase.rpc('pause_organization_admin', params: {
        'p_organization_id': orgId,
        'p_reason': reason,
      });

      debugPrint('Pause result: $result');
      
      if (result != null && result['success'] == true) {
        return {
          'success': true,
          'message': result['message'] ?? 'Organization paused successfully',
        };
      } else {
        return {
          'success': false,
          'message': result?['message'] ?? 'Failed to pause organization',
        };
      }
    } catch (e) {
      debugPrint('Error pausing organization: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Resume an organization using admin function (bypasses RLS)
  Future<Map<String, dynamic>> resumeOrganization(String orgId) async {
    try {
      debugPrint('Resuming organization: $orgId');
      final result = await _supabase.rpc('resume_organization_admin', params: {
        'p_organization_id': orgId,
      });

      debugPrint('Resume result: $result');
      
      if (result != null && result['success'] == true) {
        return {
          'success': true,
          'message': result['message'] ?? 'Organization resumed successfully',
        };
      } else {
        return {
          'success': false,
          'message': result?['message'] ?? 'Failed to resume organization',
        };
      }
    } catch (e) {
      debugPrint('Error resuming organization: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Get organization details with stats using admin function (bypasses RLS)
  Future<Map<String, dynamic>> getOrganizationDetails(String orgId) async {
    try {
      final result = await _supabase.rpc('get_organization_details_admin', params: {
        'p_organization_id': orgId,
      });

      if (result != null && result['success'] == true) {
        return {
          'success': true,
          'organization': result['organization'],
          'stats': result['stats'],
        };
      } else {
        return {
          'success': false,
          'message': result?['message'] ?? 'Failed to get organization details',
        };
      }
    } catch (e) {
      debugPrint('Error getting organization details: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Get dashboard stats using admin function (bypasses RLS)
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final result = await _supabase.rpc('get_admin_stats');
      if (result != null) {
        return {
          'organizations': result['organizations'] ?? 0,
          'users': result['users'] ?? 0,
          'rooms': result['rooms'] ?? 0,
          'tenants': result['tenants'] ?? 0,
        };
      }
      return {
        'organizations': 0,
        'users': 0,
        'rooms': 0,
        'tenants': 0,
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
