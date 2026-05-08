import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final int id;
  final int productId;
  /// Firestore cart document id (use for update/delete when from Firestore).
  final String? docId;
  /// Firestore product document id (when from Firestore, product_id is string).
  final String? productIdStr;
  final String name;
  final double price;
  final int quantity;
  final String color;
  final String image;
  final String size;
  final String email;
  final String sellerEmail;

  CartItem({
    required this.id,
    required this.productId,
    this.docId,
    this.productIdStr,
    required this.name,
    required this.price,
    required this.quantity,
    required this.color,
    required this.image,
    required this.size,
    required this.email,
    required this.sellerEmail,
  });

  String get cartDocId => docId ?? id.toString();

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final pid = json['product_id'];
    return CartItem(
      id: json['id'] ?? 0,
      productId: pid is int ? pid : 0,
      docId: json['doc_id'],
      productIdStr: pid is String ? pid : null,
      name: json['name'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      quantity: json['quantity'] ?? 1,
      color: json['color'] ?? '',
      image: json['image'] ?? '',
      size: json['size'] ?? '',
      email: json['email'] ?? '',
      sellerEmail: json['seller_email'] ?? '',
    );
  }

  factory CartItem.fromFirestore(String docId, Map<String, dynamic> data) {
    return CartItem(
      id: 0,
      productId: 0,
      docId: docId,
      productIdStr: data['product_id']?.toString(),
      name: data['name'] ?? '',
      price: double.tryParse(data['price'].toString()) ?? 0.0,
      quantity: data['quantity'] ?? 1,
      color: data['color'] ?? '',
      image: data['image'] ?? '',
      size: data['size'] ?? '',
      email: data['email'] ?? '',
      sellerEmail: data['seller_email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productIdStr ?? productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'color': color,
      'image': image,
      'size': size,
      'email': email,
      'seller_email': sellerEmail,
    };
  }

  double get total => price * quantity;
}

class Order {
  final int id;
  final String? docId; // Firestore document ID
  final int productId;
  final String name;
  final int quantity;
  final String color;
  final String size;
  final DateTime date;
  final double totalPrice;
  final double subtotal;
  final double shippingFee;
  final double tax;
  final String? transactionId;
  final String? paymentMethod;
  final String status;
  final String email;
  final String? sellerEmail;
  final String? riderEmail;
  final String image;
  final String? deliveryAddress;
  final double commissionAmount;
  final double commissionRate;
  final String? cancellationReason;

  Order({
    required this.id,
    this.docId,
    required this.productId,
    required this.name,
    required this.quantity,
    required this.color,
    required this.size,
    required this.date,
    required this.totalPrice,
    required this.subtotal,
    required this.shippingFee,
    required this.tax,
    this.transactionId,
    this.paymentMethod,
    required this.status,
    required this.email,
    this.sellerEmail,
    this.riderEmail,
    required this.image,
    this.deliveryAddress,
    required this.commissionAmount,
    required this.commissionRate,
    this.cancellationReason,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? 0,
      docId: json['doc_id'],
      productId: json['product_id'] ?? 0,
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 1,
      color: json['color'] ?? '',
      size: json['size'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0.0,
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0.0,
      shippingFee: double.tryParse(json['shipping_fee'].toString()) ?? 0.0,
      tax: double.tryParse(json['tax'].toString()) ?? 0.0,
      transactionId: json['transaction_id'],
      paymentMethod: json['payment_method'],
      status: json['status'] ?? 'Pending',
      email: json['email'] ?? '',
      sellerEmail: json['seller_email'],
      riderEmail: json['rider_email'],
      image: json['image'] ?? '',
      deliveryAddress: json['delivery_address'],
      commissionAmount: double.tryParse(json['commission_amount'].toString()) ?? 0.0,
      commissionRate: double.tryParse(json['commission_rate'].toString()) ?? 0.0,
      cancellationReason: json['cancellation_reason'],
    );
  }

  factory Order.fromFirestore(String docId, Map<String, dynamic> data) {
    DateTime? orderDate;
    if (data['date'] != null) {
      if (data['date'] is Timestamp) {
        orderDate = (data['date'] as Timestamp).toDate();
      } else {
        orderDate = DateTime.tryParse(data['date'].toString());
      }
    } else if (data['created_at'] != null) {
      if (data['created_at'] is Timestamp) {
        orderDate = (data['created_at'] as Timestamp).toDate();
      } else {
        orderDate = DateTime.tryParse(data['created_at'].toString());
      }
    }

    return Order(
      id: int.tryParse(docId) ?? 0,
      docId: docId,
      productId: int.tryParse(data['product_id']?.toString() ?? '0') ?? 0,
      name: data['name']?.toString() ?? '',
      quantity: int.tryParse(data['quantity']?.toString() ?? '1') ?? 1,
      color: data['color']?.toString() ?? '',
      size: data['size']?.toString() ?? '',
      date: orderDate ?? DateTime.now(),
      totalPrice: double.tryParse(data['total_price']?.toString() ?? '0') ?? 0.0,
      subtotal: double.tryParse(data['subtotal']?.toString() ?? '0') ?? 0.0,
      shippingFee: double.tryParse(data['shipping_fee']?.toString() ?? '0') ?? 0.0,
      tax: double.tryParse(data['tax']?.toString() ?? '0') ?? 0.0,
      transactionId: data['transaction_id']?.toString(),
      paymentMethod: data['payment_method']?.toString(),
      status: data['status']?.toString() ?? 'Pending',
      email: data['email']?.toString() ?? '',
      sellerEmail: data['seller_email']?.toString(),
      riderEmail: data['rider_email']?.toString(),
      image: data['image']?.toString() ?? '',
      deliveryAddress: data['delivery_address']?.toString(),
      commissionAmount: double.tryParse(data['commission_amount']?.toString() ?? '0') ?? 0.0,
      commissionRate: double.tryParse(data['commission_rate']?.toString() ?? '0') ?? 0.0,
      cancellationReason: data['cancellation_reason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'quantity': quantity,
      'color': color,
      'size': size,
      'date': date.toIso8601String(),
      'total_price': totalPrice,
      'subtotal': subtotal,
      'shipping_fee': shippingFee,
      'tax': tax,
      'transaction_id': transactionId,
      'payment_method': paymentMethod,
      'status': status,
      'email': email,
      'seller_email': sellerEmail,
      'rider_email': riderEmail,
      'image': image,
      'delivery_address': deliveryAddress,
      'commission_amount': commissionAmount,
      'commission_rate': commissionRate,
      'cancellation_reason': cancellationReason,
    };
  }
}

class WishlistItem {
  final int id;
  final String? docId;
  final String email;
  final int productId;
  final String? productIdStr;
  final String name;
  final double price;
  final String image;
  final String sellerEmail;
  final DateTime dateAdded;

  WishlistItem({
    required this.id,
    this.docId,
    required this.email,
    required this.productId,
    this.productIdStr,
    required this.name,
    required this.price,
    required this.image,
    required this.sellerEmail,
    required this.dateAdded,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    final pid = json['product_id'];
    return WishlistItem(
      id: json['id'] ?? 0,
      docId: json['doc_id'],
      email: json['email'] ?? '',
      productId: pid is int ? pid : 0,
      productIdStr: pid is String ? pid : null,
      name: json['name'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      image: json['image'] ?? '',
      sellerEmail: json['seller_email'] ?? '',
      dateAdded: json['date_added'] != null
          ? DateTime.parse(json['date_added'].toString())
          : DateTime.now(),
    );
  }

  factory WishlistItem.fromFirestore(String docId, Map<String, dynamic> data) {
    DateTime? dateAdded;
    if (data['date_added'] != null) {
      if (data['date_added'] is Timestamp) {
        dateAdded = (data['date_added'] as Timestamp).toDate();
      } else {
        dateAdded = DateTime.tryParse(data['date_added'].toString());
      }
    }
    return WishlistItem(
      id: 0,
      docId: docId,
      email: data['email'] ?? '',
      productId: 0,
      productIdStr: data['product_id']?.toString(),
      name: data['name'] ?? '',
      price: double.tryParse(data['price'].toString()) ?? 0.0,
      image: data['image'] ?? '',
      sellerEmail: data['seller_email'] ?? '',
      dateAdded: dateAdded ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'product_id': productIdStr ?? productId,
      'name': name,
      'price': price,
      'image': image,
      'seller_email': sellerEmail,
      'date_added': dateAdded.toIso8601String(),
    };
  }
}
