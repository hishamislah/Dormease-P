import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dormease/services/auth_service.dart';

class UserDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>?> fetchUserData(String uid) async {
    String? profileId = await _authService.getCurrentProfileId();
    if (profileId == null) return null;
    
    final doc = await _firestore.collection('profiles').doc(profileId).get();
    return doc.exists ? doc.data() : null;
  }

  Future<void> setUserData(String uid, Map<String, dynamic> data) async {
    String? profileId = await _authService.getCurrentProfileId();
    if (profileId == null) return;
    
    await _firestore.collection('profiles').doc(profileId).set(data, SetOptions(merge: true));
  }

  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    String? profileId = await _authService.getCurrentProfileId();
    if (profileId == null) return;
    
    await _firestore.collection('profiles').doc(profileId).update(data);
  }
}