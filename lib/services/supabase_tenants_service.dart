import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'supabase_auth_service.dart';

class SupabaseTenantsService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SupabaseAuthService _authService = SupabaseAuthService();

  // Stream of tenants for current profile
  Stream<List<Map<String, dynamic>>> tenantsStream() async* {
    String? profileId = await _authService.getCurrentProfileId();
    if (profileId == null) {
      yield [];
      return;
    }

    yield* _supabase
        .from('tenants')
        .stream(primaryKey: ['id'])
        .eq('profile_id', profileId)
        .map((data) => data.map((item) {
              // Convert UUID to string for compatibility
              return {
                'id': item['id'].toString(),
                ...item,
              };
            }).toList());
  }

  // Fetch tenants with payment history
  Future<List<Map<String, dynamic>>> fetchTenants() async {
    String? profileId = await _authService.getCurrentProfileId();
    if (profileId == null) return [];

    try {
      final tenants = await _supabase
          .from('tenants')
          .select('*')
          .eq('profile_id', profileId);

      // Fetch payment history for each tenant
      List<Map<String, dynamic>> tenantsWithPayments = [];
      for (var tenant in tenants) {
        final payments = await _supabase
            .from('payment_history')
            .select('*')
            .eq('tenant_id', tenant['id'])
            .order('date', ascending: false);

        tenantsWithPayments.add({
          ...tenant,
          'paymentHistory': payments,
        });
      }

      return tenantsWithPayments;
    } catch (e) {
      debugPrint('Error fetching tenants: $e');
      return [];
    }
  }

  // Add tenant
  Future<void> addTenant(Map<String, dynamic> tenant) async {
    String? profileId = await _authService.getCurrentProfileId();
    if (profileId == null) return;

    try {
      tenant['profile_id'] = profileId;
      
      // Convert DateTime to ISO string for Supabase
      if (tenant['joinedDate'] != null) {
        tenant['joined_date'] = (tenant['joinedDate'] as DateTime).toIso8601String();
        tenant.remove('joinedDate');
      }
      if (tenant['rentDueDate'] != null) {
        tenant['rent_due_date'] = (tenant['rentDueDate'] as DateTime).toIso8601String();
        tenant.remove('rentDueDate');
      }
      if (tenant['leavingDate'] != null) {
        tenant['leaving_date'] = (tenant['leavingDate'] as DateTime).toIso8601String();
        tenant.remove('leavingDate');
      }
      
      // Convert camelCase to snake_case
      final mappedTenant = _mapToSnakeCase(tenant);
      
      await _supabase.from('tenants').insert(mappedTenant);
    } catch (e) {
      debugPrint('Error adding tenant: $e');
      rethrow;
    }
  }

  // Update tenant
  Future<void> updateTenant(String tenantId, Map<String, dynamic> data) async {
    try {
      // Convert DateTime fields
      if (data['joinedDate'] != null) {
        data['joined_date'] = (data['joinedDate'] as DateTime).toIso8601String();
        data.remove('joinedDate');
      }
      if (data['rentDueDate'] != null) {
        data['rent_due_date'] = (data['rentDueDate'] as DateTime).toIso8601String();
        data.remove('rentDueDate');
      }
      if (data['leavingDate'] != null) {
        data['leaving_date'] = (data['leavingDate'] as DateTime).toIso8601String();
        data.remove('leavingDate');
      }
      
      final mappedData = _mapToSnakeCase(data);
      
      await _supabase
          .from('tenants')
          .update(mappedData)
          .eq('id', tenantId);
    } catch (e) {
      debugPrint('Error updating tenant: $e');
      rethrow;
    }
  }

  // Delete tenant
  Future<void> deleteTenant(String tenantId) async {
    try {
      await _supabase
          .from('tenants')
          .delete()
          .eq('id', tenantId);
    } catch (e) {
      debugPrint('Error deleting tenant: $e');
      rethrow;
    }
  }

  // Mark rent as paid
  Future<void> markRentPaid(String tenantId, String month, [String paymentMethod = 'Cash']) async {
    String? profileId = await _authService.getCurrentProfileId();
    if (profileId == null) return;

    try {
      // Get tenant data
      final tenant = await _supabase
          .from('tenants')
          .select('*')
          .eq('id', tenantId)
          .single();

      final monthlyRent = (tenant['monthly_rent'] ?? 0).toDouble();

      // Check if payment record exists
      final existingPayment = await _supabase
          .from('payment_history')
          .select('*')
          .eq('tenant_id', tenantId)
          .eq('month', month)
          .maybeSingle();

      if (existingPayment != null) {
        // Update existing payment
        await _supabase
            .from('payment_history')
            .update({
              'status': 'Paid',
              'date': DateTime.now().toIso8601String(),
              'payment_method': paymentMethod,
            })
            .eq('id', existingPayment['id']);
      } else {
        // Create new payment record
        await _supabase.from('payment_history').insert({
          'tenant_id': tenantId,
          'profile_id': profileId,
          'month': month,
          'amount': monthlyRent,
          'status': 'Paid',
          'date': DateTime.now().toIso8601String(),
          'payment_method': paymentMethod,
        });
      }

      // Check current month and rent due date to determine if rent is still due
      final now = DateTime.now();
      final currentMonthYear = DateFormat('MMMM yyyy').format(now);
      
      // If we just paid the current month's rent, mark rent_due as false
      // Otherwise, check if rent due date has passed
      bool rentDue = false;
      if (month == currentMonthYear) {
        // Just paid current month, so no longer due
        rentDue = false;
      } else {
        // Check if rent due date has passed for current month
        if (tenant['rent_due_date'] != null) {
          final rentDueDate = DateTime.parse(tenant['rent_due_date']);
          rentDue = now.isAfter(rentDueDate);
          
          // Also check if current month payment exists
          final currentMonthPayment = await _supabase
              .from('payment_history')
              .select('*')
              .eq('tenant_id', tenantId)
              .eq('month', currentMonthYear)
              .eq('status', 'Paid')
              .maybeSingle();
          
          if (currentMonthPayment != null) {
            rentDue = false;
          }
        }
      }

      // Update tenant
      await _supabase
          .from('tenants')
          .update({
            'rent_due': rentDue,
            'last_payment_date': DateTime.now().toIso8601String(),
            'last_payment_month': month,
          })
          .eq('id', tenantId);

      debugPrint('Payment marked as paid: $month for tenant $tenantId');
    } catch (e) {
      debugPrint('Error marking rent as paid: $e');
      rethrow;
    }
  }

  // Mark rent as unpaid (revert payment)
  Future<void> markRentUnpaid(String tenantId, String month) async {
    String? profileId = await _authService.getCurrentProfileId();
    if (profileId == null) return;

    try {
      // Delete the payment record for this month
      await _supabase
          .from('payment_history')
          .delete()
          .eq('tenant_id', tenantId)
          .eq('month', month);

      // Get tenant data to recalculate rent_due status
      final tenant = await _supabase
          .from('tenants')
          .select('*')
          .eq('id', tenantId)
          .single();

      // Check current month and rent due date to determine if rent is due
      final now = DateTime.now();
      final currentMonthYear = DateFormat('MMMM yyyy').format(now);
      
      bool rentDue = false;
      if (tenant['rent_due_date'] != null) {
        final rentDueDate = DateTime.parse(tenant['rent_due_date']);
        rentDue = now.isAfter(rentDueDate);
        
        // Check if current month payment still exists
        final currentMonthPayment = await _supabase
            .from('payment_history')
            .select('*')
            .eq('tenant_id', tenantId)
            .eq('month', currentMonthYear)
            .eq('status', 'Paid')
            .maybeSingle();
        
        if (currentMonthPayment != null) {
          rentDue = false;
        }
      }

      // Update tenant
      await _supabase
          .from('tenants')
          .update({
            'rent_due': rentDue,
          })
          .eq('id', tenantId);

      debugPrint('Payment marked as unpaid: $month for tenant $tenantId');
    } catch (e) {
      debugPrint('Error marking rent as unpaid: $e');
      rethrow;
    }
  }

  // Fetch payment history for a tenant
  Future<List<Map<String, dynamic>>> fetchPaymentHistory(String tenantId) async {
    try {
      final payments = await _supabase
          .from('payment_history')
          .select('*')
          .eq('tenant_id', tenantId)
          .order('date', ascending: false);
      
      return payments;
    } catch (e) {
      debugPrint('Error fetching payment history: $e');
      return [];
    }
  }

  // Helper method to convert camelCase to snake_case
  Map<String, dynamic> _mapToSnakeCase(Map<String, dynamic> data) {
    final mapped = <String, dynamic>{};
    data.forEach((key, value) {
      final snakeKey = key.replaceAllMapped(
        RegExp(r'[A-Z]'),
        (match) => '_${match.group(0)!.toLowerCase()}',
      );
      mapped[snakeKey] = value;
    });
    return mapped;
  }
}
