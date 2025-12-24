import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dormease/services/auth_service.dart';

class BusinessInfoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>?> fetchBusinessInfo() async {
    String? profileId = await _authService.getCurrentProfileId();
    if (profileId == null) return null;
    
    final snapshot = await _firestore.collection('businessInfo').doc(profileId).get();
    return snapshot.exists ? snapshot.data() : null;
  }

  Future<void> setBusinessInfo(Map<String, dynamic> info) async {
    String? profileId = await _authService.getCurrentProfileId();
    if (profileId == null) return;
    
    await _firestore.collection('businessInfo').doc(profileId).set(info, SetOptions(merge: true));
  }
}