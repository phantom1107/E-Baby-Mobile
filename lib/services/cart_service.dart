import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_order.dart';
import 'firestore_repository.dart';

/// Cart in same Firestore as E-Baby website (firestore_db), scoped by user email.
/// Current user email comes from SharedPreferences (Firestore-only login).
class CartService extends ChangeNotifier {
  List<CartItem> _items = [];
  int _cartCount = 0;

  List<CartItem> get items => _items;
  int get cartCount => _cartCount;
  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.total);
  double get shippingFee => 38.0;
  double get tax => subtotal * 0.025;
  double get total => subtotal + shippingFee + tax;

  Future<String?> _getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }

  Future<void> loadCart() async {
    final email = await _getUserEmail();
    if (email == null || email.isEmpty) {
      _items = [];
      _cartCount = 0;
      notifyListeners();
      return;
    }
    try {
      print('Loading cart for email: $email');
      final snap = await FirestoreRepository.cartRef
          .where('email', isEqualTo: email)
          .get()
          .timeout(const Duration(seconds: 10));
      print('Cart query returned ${snap.docs.length} items');
      _items = snap.docs
          .map((d) => CartItem.fromFirestore(d.id, d.data()))
          .toList();
      _cartCount = _items.fold(0, (sum, item) => sum + item.quantity);
      print('Cart loaded: $_cartCount items');
      notifyListeners();
    } catch (e) {
      print('Error loading cart: $e');
      _items = [];
      _cartCount = 0;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> addToCart(Map<String, dynamic> data) async {
    final email = await _getUserEmail();
    if (email == null || email.isEmpty) {
      return {'success': false, 'error': 'Please sign in to add to cart'};
    }
    
    try {
      // Validate required fields
      final productId = data['product_id']?.toString() ?? '';
      final color = data['color']?.toString() ?? '';
      final size = data['size']?.toString() ?? '';
      final quantity = data['quantity'] as int? ?? 1;
      final name = data['name']?.toString() ?? '';
      final price = double.tryParse(data['price']?.toString() ?? '0') ?? 0.0;
      final image = data['image']?.toString() ?? '';
      final sellerEmail = data['seller_email']?.toString() ?? '';
      
      if (productId.isEmpty) {
        return {'success': false, 'error': 'Product ID is required'};
      }
      
      if (name.isEmpty) {
        return {'success': false, 'error': 'Product name is required'};
      }
      
      // Validate stock from variants if color and size are provided
      if (color.isNotEmpty && size.isNotEmpty) {
        // Load product document to get variants array
        final productDoc = await FirestoreRepository.productsRef.doc(productId).get();
        
        if (!productDoc.exists) {
          return {'success': false, 'error': 'Product not found'};
        }
        
        final productData = productDoc.data()!;
        final variantsList = productData['variants'] as List?;
        
        if (variantsList == null || variantsList.isEmpty) {
          return {'success': false, 'error': 'No variants available for this product'};
        }
        
        // Find matching variant
        final matchingVariant = variantsList.firstWhere(
          (v) => v['color'] == color && v['size'] == size,
          orElse: () => null,
        );
        
        if (matchingVariant == null) {
          return {'success': false, 'error': 'Selected variant not available'};
        }
        
        final variantStock = int.tryParse(matchingVariant['stock']?.toString() ?? '0') ?? 0;
        
        if (variantStock <= 0) {
          return {'success': false, 'error': 'This variant is out of stock'};
        }
        
        if (quantity > variantStock) {
          return {
            'success': false,
            'error': 'Only $variantStock items available for this variant'
          };
        }
      }
      
      // Check if item already exists in cart with same color/size
      final snap = await FirestoreRepository.cartRef
          .where('email', isEqualTo: email)
          .where('product_id', isEqualTo: productId)
          .get();
      
      CartItem? existingItem;
      for (var doc in snap.docs) {
        final item = CartItem.fromFirestore(doc.id, doc.data());
        if (item.color == color && item.size == size) {
          existingItem = item;
          break;
        }
      }
      
      if (existingItem != null && existingItem.docId != null) {
        // Update quantity of existing item
        final newQty = existingItem.quantity + quantity;
        
        // Re-validate stock for new quantity
        if (color.isNotEmpty && size.isNotEmpty) {
          // Load product document to get variants array
          final productDoc = await FirestoreRepository.productsRef.doc(productId).get();
          
          if (productDoc.exists) {
            final productData = productDoc.data()!;
            final variantsList = productData['variants'] as List?;
            
            if (variantsList != null) {
              // Find matching variant
              final matchingVariant = variantsList.firstWhere(
                (v) => v['color'] == color && v['size'] == size,
                orElse: () => null,
              );
              
              if (matchingVariant != null) {
                final variantStock = int.tryParse(matchingVariant['stock']?.toString() ?? '0') ?? 0;
                
                if (newQty > variantStock) {
                  return {
                    'success': false,
                    'error': 'Only $variantStock items available for this variant'
                  };
                }
              }
            }
          }
        }
        
        await FirestoreRepository.cartRef.doc(existingItem.docId).update({
          'quantity': newQty,
          'updated_at': FieldValue.serverTimestamp(),
        });
      } else {
        // Add new item to cart
        final cartData = {
          'email': email,
          'product_id': productId,
          'name': name,
          'price': price,
          'image': image,
          'color': color,
          'size': size,
          'quantity': quantity,
          'seller_email': sellerEmail,
          'created_at': FieldValue.serverTimestamp(),
        };
        
        await FirestoreRepository.cartRef.add(cartData);
      }
      
      await loadCart();
      return {'success': true, 'message': 'Added to cart successfully'};
    } catch (e) {
      print('Error adding to cart: $e');
      return {'success': false, 'error': 'Failed to add to cart: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> updateQuantity(dynamic productOrDocId, int change) async {
    final email = await _getUserEmail();
    if (email == null) return {'success': false, 'error': 'Not signed in'};
    CartItem? item;
    if (productOrDocId is String) {
      try {
        item = _items.firstWhere((i) => i.docId == productOrDocId);
      } catch (_) {}
    }
    if (item == null) {
      final pidStr = productOrDocId.toString();
      try {
        item = _items.firstWhere((i) =>
            i.productId.toString() == pidStr || i.productIdStr == pidStr);
      } catch (_) {}
    }
    if (item == null || item.docId == null) return {'success': false};
    final newQty = item.quantity + change;
    if (newQty < 1) {
      await FirestoreRepository.cartRef.doc(item.docId).delete();
    } else {
      await FirestoreRepository.cartRef.doc(item.docId).update({'quantity': newQty});
    }
    await loadCart();
    return {'success': true};
  }

  Future<Map<String, dynamic>> removeFromCart(
    dynamic productId,
    String color,
    String size,
  ) async {
    final email = await _getUserEmail();
    if (email == null) return {'success': false};
    final pidStr = productId is String ? productId : productId.toString();
    final match = _items.where((i) =>
        (i.productIdStr == pidStr || i.productId.toString() == pidStr) &&
        i.color == color &&
        i.size == size);
    for (final item in match) {
      if (item.docId != null) {
        await FirestoreRepository.cartRef.doc(item.docId).delete();
      }
    }
    await loadCart();
    return {'success': true};
  }

  Future<Map<String, dynamic>> deleteSelected(List<dynamic> ids) async {
    final email = await _getUserEmail();
    if (email == null) return {'success': false};
    for (final id in ids) {
      String? docId = id is String ? id : null;
      if (docId == null) {
        final match = _items.where((i) => i.id == id || i.cartDocId == id.toString());
        for (final item in match) {
          if (item.docId != null) {
            await FirestoreRepository.cartRef.doc(item.docId!).delete();
          }
        }
      } else {
        await FirestoreRepository.cartRef.doc(docId).delete();
      }
    }
    await loadCart();
    return {'success': true};
  }

  Future<Map<String, dynamic>> checkout(List<dynamic> ids) async {
    // Navigate to checkout; actual order creation on confirm.
    return {'success': true};
  }

  Future<Map<String, dynamic>> confirmOrder(Map<String, dynamic> data) async {
    // TODO: create order docs in Firestore and clear cart items.
    await loadCart();
    return {'success': true};
  }
}
