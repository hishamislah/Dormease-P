import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dormease/models/organization.dart';
import 'supabase_auth_service.dart';

class SupabaseOrganizationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SupabaseAuthService _authService = SupabaseAuthService();

  // Get current user's organization ID
  Future<String?> getCurrentOrganizationId() async {
    final userId = _authService.getCurrentUserId();
    if (userId == null) return null;

    try {
      final membership = await _supabase
          .from('organization_members')
          .select('organization_id')
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();

      return membership?['organization_id']?.toString();
    } catch (e) {
      debugPrint('Error getting organization ID: $e');
      return null;
    }
  }

  // Get current user's organization
  Future<Organization?> getCurrentOrganization() async {
    final orgId = await getCurrentOrganizationId();
    if (orgId == null) return null;

    try {
      final data = await _supabase
          .from('organizations')
          .select('id, name, slug, logo_url, email, phone, address, city, state, country, plan, is_paused, paused_reason, paused_at, created_at, updated_at')
          .eq('id', orgId)
          .single();

      return Organization.fromJson(data);
    } catch (e) {
      debugPrint('Error getting organization: $e');
      return null;
    }
  }

  // Get all organizations for current user
  Future<List<Organization>> getUserOrganizations() async {
    final userId = _authService.getCurrentUserId();
    if (userId == null) return [];

    try {
      final memberships = await _supabase
          .from('organization_members')
          .select('organization_id')
          .eq('user_id', userId);

      if (memberships.isEmpty) return [];

      final orgIds = memberships.map((m) => m['organization_id']).toList();
      
      final orgs = await _supabase
          .from('organizations')
          .select('id, name, slug, logo_url, email, phone, address, city, state, country, plan, is_paused, paused_reason, paused_at, created_at, updated_at')
          .inFilter('id', orgIds);

      return orgs.map((o) => Organization.fromJson(o)).toList();
    } catch (e) {
      debugPrint('Error getting user organizations: $e');
      return [];
    }
  }

  // Create a new organization
  Future<Organization?> createOrganization({
    required String name,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? country,
    String? logoUrl,
  }) async {
    final userId = _authService.getCurrentUserId();
    final profileId = await _authService.getCurrentProfileId();
    
    if (userId == null) return null;

    try {
      // Generate slug from name
      String slug = name.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '-');
      slug = '$slug-${DateTime.now().millisecondsSinceEpoch}';

      // Create organization
      final orgData = await _supabase
          .from('organizations')
          .insert({
            'name': name,
            'slug': slug,
            'email': email,
            'phone': phone,
            'address': address,
            'city': city,
            'state': state,
            'country': country,
            'logo_url': logoUrl,
          })
          .select('id, name, slug, logo_url, email, phone, address, city, state, country, plan, is_paused, paused_reason, paused_at, created_at, updated_at')
          .single();

      final org = Organization.fromJson(orgData);

      // Add current user as owner
      await _supabase.from('organization_members').insert({
        'organization_id': org.id,
        'user_id': userId,
        'profile_id': profileId,
        'role': 'owner',
        'joined_at': DateTime.now().toIso8601String(),
      });

      return org;
    } catch (e) {
      debugPrint('Error creating organization: $e');
      rethrow;
    }
  }

  // Update organization details
  Future<void> updateOrganization(Organization org) async {
    try {
      await _supabase
          .from('organizations')
          .update({
            'name': org.name,
            'email': org.email,
            'phone': org.phone,
            'address': org.address,
            'city': org.city,
            'state': org.state,
            'country': org.country,
            'logo_url': org.logoUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', org.id);
    } catch (e) {
      debugPrint('Error updating organization: $e');
      rethrow;
    }
  }

  // Get organization members
  Future<List<OrganizationMember>> getOrganizationMembers(String orgId) async {
    try {
      final members = await _supabase
          .from('organization_members')
          .select('id, organization_id, user_id, profile_id, role, invited_at, joined_at')
          .eq('organization_id', orgId)
          .limit(50);

      return members.map((m) => OrganizationMember.fromJson(m)).toList();
    } catch (e) {
      debugPrint('Error getting organization members: $e');
      return [];
    }
  }

  // Check if user is owner/admin of organization
  Future<bool> isUserAdmin(String orgId) async {
    final userId = _authService.getCurrentUserId();
    if (userId == null) return false;

    try {
      final member = await _supabase
          .from('organization_members')
          .select('role')
          .eq('organization_id', orgId)
          .eq('user_id', userId)
          .maybeSingle();

      if (member == null) return false;
      return member['role'] == 'owner' || member['role'] == 'admin';
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  // Check if user has an organization
  Future<bool> hasOrganization() async {
    final orgId = await getCurrentOrganizationId();
    return orgId != null;
  }
}
