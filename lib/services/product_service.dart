import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';
import 'firestore_repository.dart';

/// Loads products from the same Firestore as the E-Baby website (firestore_db).
class ProductService {
  static Future<int> getProductTotalSales(String productId) async {
    try {
      final snap = await FirestoreRepository.ordersRef
          .where('product_id', isEqualTo: productId)
          .where('status', isEqualTo: 'Received')
          .get();
      int totalSold = 0;
      for (var doc in snap.docs) {
        totalSold += (doc.data()['quantity'] as int? ?? 0);
      }
      return totalSold;
    } catch (e) {
      return 0;
    }
  }

  static Future<List<Product>> getFeaturedProducts() async {
    try {
      final snap = await FirestoreRepository.productsRef
          .orderBy('created_at', descending: true)
          .limit(10)
          .get();
      final products = snap.docs
          .map((d) => Product.fromFirestore(d.id, d.data()))
          .toList();
      
      // Enrich with total sales
      for (var product in products) {
        final sales = await getProductTotalSales(product.productId);
        // Update the sales field (note: this creates a new object since Product is immutable)
        // For now, we'll just use the sales from Firestore or calculate on-demand
      }
      
      return products;
    } catch (e) {
      return [];
    }
  }

  static Future<List<Product>> getNewArrivals() async {
    try {
      final snap = await FirestoreRepository.productsRef
          .orderBy('created_at', descending: true)
          .limit(10)
          .get();
      return snap.docs
          .map((d) => Product.fromFirestore(d.id, d.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<Product>> searchProducts(String query) async {
    if (query.trim().isEmpty) return getFeaturedProducts();
    try {
      final snap = await FirestoreRepository.productsRef.get();
      final lower = query.toLowerCase();
      return snap.docs
          .where((d) =>
              (d.data()['name'] as String? ?? '').toLowerCase().contains(lower))
          .map((d) => Product.fromFirestore(d.id, d.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final snap = await FirestoreRepository.productsRef
          .where('category', isEqualTo: category)
          .get();
      return snap.docs
          .map((d) => Product.fromFirestore(d.id, d.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<Product?> getProductDetails(dynamic productId) async {
    final id = productId is int ? productId.toString() : productId as String;
    try {
      final doc = await FirestoreRepository.productsRef.doc(id).get();
      if (doc.exists && doc.data() != null) {
        return Product.fromFirestore(doc.id, doc.data()!);
      }
    } catch (_) {}
    return null;
  }

  static Future<List<ProductVariant>> getProductVariants(dynamic productId) async {
    final id = productId is int ? productId.toString() : productId as String;
    try {
      final snap = await FirestoreRepository.productVariantsRef
          .where('product_id', isEqualTo: id)
          .get();
      return snap.docs
          .map((d) => ProductVariant.fromFirestore(d.id, d.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> addProduct(
    Map<String, dynamic> data,
  ) async {
    try {
      data['created_at'] = FieldValue.serverTimestamp();
      if (data['sales'] == null) data['sales'] = 0;
      final ref = await FirestoreRepository.productsRef.add(data);
      return {'success': true, 'id': ref.id};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateProduct(
    dynamic productId,
    Map<String, dynamic> data,
  ) async {
    final id = productId is int ? productId.toString() : productId as String;
    try {
      await FirestoreRepository.productsRef.doc(id).update(data);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteProduct(dynamic productId) async {
    final id = productId is int ? productId.toString() : productId as String;
    try {
      await FirestoreRepository.productsRef.doc(id).delete();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
