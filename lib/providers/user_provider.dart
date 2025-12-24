import 'package:flutter/material.dart';
import '../services/supabase_user_data_service.dart';
import '../services/supabase_business_info_service.dart';
import '../services/supabase_auth_service.dart';

class UserProvider extends ChangeNotifier {
  final SupabaseUserDataService _userDataService = SupabaseUserDataService();
  final SupabaseBusinessInfoService _businessInfoService = SupabaseBusinessInfoService();
  final SupabaseAuthService _authService = SupabaseAuthService();
  
  Map<String, dynamic> userData = {
    'phone': '',
    'logoUrl': 'null',
    'businessName': 'DormEase Business',
    'businessEmail': '',
    'address': '',
    'city': '',
    'state': '',
    'country': ''
  };

  Future<void> loadUserData() async {
    try {
      String? profileId = await _authService.getCurrentProfileId();
      if (profileId != null) {
        final userSupabaseData = await _userDataService.fetchUserData(profileId);
        final businessInfo = await _businessInfoService.fetchBusinessInfo();
        
        if (userSupabaseData != null) {
          userData.addAll(userSupabaseData);
        }
        if (businessInfo != null) {
          userData.addAll(businessInfo);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> updateBusinessDetails(
      {required String phone,
      required String logoUrl,
      required String businessName,
      required String businessEmail,
      required String address,
      required String city,
      required String state,
      required String country}) async {
    
    final data = {
      'phone': phone,
      'logoUrl': logoUrl,
      'businessName': businessName,
      'businessEmail': businessEmail,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
    };
    
    try {
      String? profileId = await _authService.getCurrentProfileId();
      if (profileId != null) {
        await _userDataService.setUserData(profileId, data);
      }
      await _businessInfoService.setBusinessInfo(data);
      
      userData.addAll(data);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating business details: $e');
    }
  }
}