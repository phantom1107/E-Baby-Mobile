import 'package:cloud_firestore/cloud_firestore.dart';

class RiderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get available orders (status = prepared)
  Stream<QuerySnapshot> getAvailableOrders() {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: 'prepared')
        .where('rider_id', isEqualTo: null)
        .snapshots();
  }

  // Get rider's deliveries
  Stream<QuerySnapshot> getRiderDeliveries(String riderId) {
    return _firestore
        .collection('orders')
        .where('rider_id', isEqualTo: riderId)
        .orderBy('order_date', descending: true)
        .snapshots();
  }

  // Accept delivery
  Future<Map<String, dynamic>> acceptDelivery(
    String orderId,
    String riderId,
  ) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'rider_id': riderId,
        'status': 'shipping',
        'accepted_at': FieldValue.serverTimestamp(),
      });
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Mark as delivered
  Future<Map<String, dynamic>> markAsDelivered(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'received',
        'delivered_at': FieldValue.serverTimestamp(),
      });
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Cancel delivery
  Future<Map<String, dynamic>> cancelDelivery(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'rider_id': FieldValue.delete(),
        'status': 'prepared',
        'cancelled_at': FieldValue.serverTimestamp(),
      });
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
