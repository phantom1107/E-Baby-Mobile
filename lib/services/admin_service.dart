import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all users
  Stream<QuerySnapshot> getAllUsers() {
    return _firestore.collection('users').snapshots();
  }

  // Get users by type
  Stream<QuerySnapshot> getUsersByType(String userType) {
    return _firestore
        .collection('users')
        .where('user_type', isEqualTo: userType)
        .snapshots();
  }

  // Get pending registration requests
  Stream<QuerySnapshot> getPendingRequests() {
    return _firestore
        .collection('users')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // Approve registration
  Future<Map<String, dynamic>> approveRegistration(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': 'active',
        'approved_at': FieldValue.serverTimestamp(),
      });
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Reject registration
  Future<Map<String, dynamic>> rejectRegistration(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Ban user
  Future<Map<String, dynamic>> banUser(String userId, String reason) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': 'banned',
        'ban_reason': reason,
        'banned_at': FieldValue.serverTimestamp(),
      });
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Unban user
  Future<Map<String, dynamic>> unbanUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': 'active',
        'ban_reason': FieldValue.delete(),
        'unbanned_at': FieldValue.serverTimestamp(),
      });
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Delete user
  Future<Map<String, dynamic>> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get all products (for moderation)
  Stream<QuerySnapshot> getAllProducts() {
    return _firestore.collection('products').snapshots();
  }

  // Get all orders
  Stream<QuerySnapshot> getAllOrders() {
    return _firestore
        .collection('orders')
        .orderBy('order_date', descending: true)
        .snapshots();
  }
}
