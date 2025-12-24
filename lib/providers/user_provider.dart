import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_data_service.dart';
import '../services/business_info_service.dart';

class UserProvider extends ChangeNotifier {
  final UserDataService _userDataService = UserDataService();
  final BusinessInfoService _businessInfoService = BusinessInfoService();
  
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
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userFirebaseData = await _userDataService.fetchUserData(user.uid);
        final businessInfo = await _businessInfoService.fetchBusinessInfo();
        
        if (userFirebaseData != null) {
          userData.addAll(userFirebaseData);
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
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _userDataService.setUserData(user.uid, data);
      }
      await _businessInfoService.setBusinessInfo(data);
      
      userData.addAll(data);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating business details: $e');
    }
  }
}
