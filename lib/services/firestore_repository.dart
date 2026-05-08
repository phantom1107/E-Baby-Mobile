/// Firestore collections and helpers aligned with E-Baby website (firestore_db.py).
/// Same project and collections so Flutter and website share data.

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreRepository {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String products = 'products';
  static const String cart = 'cart';
  static const String wishlist = 'wishlist';
  static const String orders = 'orders';
  static const String users = 'users';
  static const String productVariants = 'product_variants';

  static CollectionReference<Map<String, dynamic>> get productsRef =>
      _db.collection(products);
  static CollectionReference<Map<String, dynamic>> get cartRef =>
      _db.collection(cart);
  static CollectionReference<Map<String, dynamic>> get wishlistRef =>
      _db.collection(wishlist);
  static CollectionReference<Map<String, dynamic>> get ordersRef =>
      _db.collection(orders);
  static CollectionReference<Map<String, dynamic>> get usersRef =>
      _db.collection(users);
  static CollectionReference<Map<String, dynamic>> get productVariantsRef =>
      _db.collection(productVariants);

  /// Parse Firestore Timestamp or DateTime to DateTime
  static DateTime? toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
