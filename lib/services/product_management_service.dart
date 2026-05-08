import 'package:cloud_firestore/cloud_firestore.dart';

class ProductManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get products for a specific seller
  Stream<QuerySnapshot> getSellerProducts(String sellerId) {
    return _firestore
        .collection('products')
        .where('seller_id', isEqualTo: sellerId)
        .snapshots();
  }

  // Add new product
  Future<Map<String, dynamic>> addProduct(Map<String, dynamic> productData) async {
    try {
      productData['created_at'] = FieldValue.serverTimestamp();
      productData['updated_at'] = FieldValue.serverTimestamp();
      
      final docRef = await _firestore.collection('products').add(productData);
      return {'success': true, 'productId': docRef.id};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Update product
  Future<Map<String, dynamic>> updateProduct(
    String productId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updated_at'] = FieldValue.serverTimestamp();
      await _firestore.collection('products').doc(productId).update(updates);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Delete product
  Future<Map<String, dynamic>> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get orders for seller
  Stream<QuerySnapshot> getSellerOrders(String sellerId) {
    return _firestore
        .collection('orders')
        .where('seller_id', isEqualTo: sellerId)
        .orderBy('order_date', descending: true)
        .snapshots();
  }

  // Update order status
  Future<Map<String, dynamic>> updateOrderStatus(
    String orderId,
    String newStatus,
  ) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
