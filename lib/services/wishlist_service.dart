import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_order.dart';
import 'firestore_repository.dart';

/// Wishlist in same Firestore as E-Baby website (firestore_db), scoped by user email.
/// Current user email comes from SharedPreferences (Firestore-only login).
class WishlistService extends ChangeNotifier {
  List<WishlistItem> _items = [];
  int _wishlistCount = 0;

  List<WishlistItem> get items => _items;
  int get wishlistCount => _wishlistCount;

  Future<String?> _getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }

  Future<void> loadWishlist() async {
    final email = await _getUserEmail();
    if (email == null || email.isEmpty) {
      _items = [];
      _wishlistCount = 0;
      notifyListeners();
      return;
    }
    try {
      final snap = await FirestoreRepository.wishlistRef
          .where('email', isEqualTo: email)
          .get();
      _items = snap.docs
          .map((d) => WishlistItem.fromFirestore(d.id, d.data()))
          .toList();
      _wishlistCount = _items.length;
      notifyListeners();
    } catch (e) {
      _items = [];
      _wishlistCount = 0;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> addToWishlist(Map<String, dynamic> data) async {
    final email = await _getUserEmail();
    if (email == null || email.isEmpty) {
      return {'success': false, 'error': 'Please sign in to add to wishlist'};
    }
    
    try {
      final productId = data['product_id']?.toString() ?? '';
      
      if (productId.isEmpty) {
        return {'success': false, 'error': 'Product ID is required'};
      }
      
      // Check if item already exists in wishlist
      final snap = await FirestoreRepository.wishlistRef
          .where('email', isEqualTo: email)
          .where('product_id', isEqualTo: productId)
          .get();
      
      if (snap.docs.isNotEmpty) {
        return {'success': false, 'error': 'Item already in wishlist'};
      }
      
      // Add new item to wishlist
      data['email'] = email;
      data['date_added'] = FieldValue.serverTimestamp();
      await FirestoreRepository.wishlistRef.add(data);
      
      await loadWishlist();
      return {'success': true, 'message': 'Added to wishlist successfully'};
    } catch (e) {
      print('Error adding to wishlist: $e');
      return {'success': false, 'error': 'Failed to add to wishlist: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> removeFromWishlist(List<dynamic> ids) async {
    final email = await _getUserEmail();
    if (email == null) return {'success': false};
    for (final id in ids) {
      String? docId = id is String ? id : null;
      if (docId == null) {
        final match = _items.where((i) => i.id == id || i.docId == id.toString());
        for (final item in match) {
          if (item.docId != null) {
            await FirestoreRepository.wishlistRef.doc(item.docId!).delete();
          }
        }
      } else {
        await FirestoreRepository.wishlistRef.doc(docId).delete();
      }
    }
    await loadWishlist();
    return {'success': true};
  }
}
