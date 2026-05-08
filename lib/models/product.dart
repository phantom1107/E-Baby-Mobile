import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final int id;
  final String productId;
  final String name;
  final String category;
  final String description;
  final double price;
  final String image;
  final List<String> images;
  final int sales;
  final int stock; // Total stock across all variants
  final String sellerEmail;
  final String? sellerFirstName;
  final String? sellerLastName;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.productId,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.image,
    required this.images,
    required this.sales,
    required this.stock,
    required this.sellerEmail,
    this.sellerFirstName,
    this.sellerLastName,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    List<String> imagesList = [];
    if (json['images'] != null && json['images'].toString().isNotEmpty) {
      imagesList = json['images'].toString().split(',');
    }

    // Prefer Cloudinary URL fields if present.
    final mainImage = json['image_url'] ?? json['image'] ?? '';

    return Product(
      id: json['id'] ?? 0,
      productId: json['product_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      image: mainImage,
      images: imagesList,
      sales: json['sales'] ?? 0,
      stock: json['stock'] ?? 0,
      sellerEmail: json['seller_email'] ?? '',
      sellerFirstName: json['first_name'],
      sellerLastName: json['last_name'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  /// From Firestore document (same fields as E-Baby website).
  factory Product.fromFirestore(String docId, Map<String, dynamic> data) {
    List<String> imagesList = [];
    // Prefer image_urls array if present (Cloudinary), else fall back to images string.
    if (data['image_urls'] != null && data['image_urls'] is List) {
      imagesList = (data['image_urls'] as List)
          .whereType<String>()
          .toList();
    } else if (data['images'] != null && data['images'].toString().isNotEmpty) {
      imagesList = data['images'].toString().split(',');
    }
    DateTime? createdAt;
    if (data['created_at'] != null) {
      if (data['created_at'] is Timestamp) {
        createdAt = (data['created_at'] as Timestamp).toDate();
      } else {
        createdAt = DateTime.tryParse(data['created_at'].toString());
      }
    }
    // Prefer image_url for main image; fall back to legacy image field.
    final mainImage = data['image_url'] ?? data['image'] ?? '';

    return Product(
      id: 0,
      productId: docId,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      price: double.tryParse(data['price'].toString()) ?? 0.0,
      image: mainImage,
      images: imagesList,
      sales: data['sales'] ?? 0,
      stock: data['stock'] ?? 0,
      sellerEmail: data['seller_email'] ?? '',
      sellerFirstName: data['first_name'],
      sellerLastName: data['last_name'],
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'category': category,
      'description': description,
      'price': price,
      'image': image,
      'images': images.join(','),
      'sales': sales,
      'stock': stock,
      'seller_email': sellerEmail,
      'first_name': sellerFirstName,
      'last_name': sellerLastName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get sellerName =>
      '${sellerFirstName ?? ''} ${sellerLastName ?? ''}'.trim();
}

class ProductVariant {
  final String id; // Firestore document ID
  final String productId; // Product ID as string (Firestore)
  final String color;
  final String size;
  final int stock;

  ProductVariant({
    required this.id,
    required this.productId,
    required this.color,
    required this.size,
    required this.stock,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      color: json['color']?.toString() ?? '',
      size: json['size']?.toString() ?? '',
      stock: int.tryParse(json['stock']?.toString() ?? '0') ?? 0,
    );
  }

  /// From Firestore document
  factory ProductVariant.fromFirestore(String docId, Map<String, dynamic> data) {
    return ProductVariant(
      id: docId,
      productId: data['product_id']?.toString() ?? '',
      color: data['color']?.toString() ?? '',
      size: data['size']?.toString() ?? '',
      stock: int.tryParse(data['stock']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'color': color,
      'size': size,
      'stock': stock,
    };
  }
}
