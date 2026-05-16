import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../services/wishlist_service.dart';
import '../services/firestore_repository.dart';
import 'seller_profile_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  Product? product;
  List<ProductVariant> variants = [];
  bool isLoading = true;
  int currentImageIndex = 0;
  int quantity = 1;
  String? selectedColor;
  String? selectedSize;
  ProductVariant? selectedVariant;

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    setState(() => isLoading = true);
    try {
      final doc = await FirestoreRepository.productsRef.doc(widget.productId).get();
      if (doc.exists) {
        final data = doc.data()!;
        product = Product.fromFirestore(doc.id, data);
        
        // Load seller information
        final sellerEmail = data['seller_email'];
        if (sellerEmail != null && sellerEmail.toString().isNotEmpty) {
          final sellerQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: sellerEmail)
              .limit(1)
              .get();
          
          if (sellerQuery.docs.isNotEmpty) {
            final sellerData = sellerQuery.docs.first.data();
            // Update product with seller info
            product = Product(
              id: product!.id,
              productId: product!.productId,
              name: product!.name,
              category: product!.category,
              description: product!.description,
              price: product!.price,
              image: product!.image,
              images: product!.images,
              sales: product!.sales,
              stock: product!.stock,
              sellerEmail: product!.sellerEmail,
              sellerFirstName: sellerData['first_name'],
              sellerLastName: sellerData['last_name'],
              createdAt: product!.createdAt,
            );
          }
        }
        
        // Load variants from the product document's variants array
        if (data['variants'] != null && data['variants'] is List) {
          variants = (data['variants'] as List).map((variantData) {
            return ProductVariant(
              id: '${widget.productId}_${variantData['color']}_${variantData['size']}',
              productId: widget.productId,
              color: variantData['color']?.toString() ?? '',
              size: variantData['size']?.toString() ?? '',
              stock: int.tryParse(variantData['stock']?.toString() ?? '0') ?? 0,
            );
          }).toList();
        }
        
        // Auto-select first variant if available
        if (variants.isNotEmpty) {
          selectedColor = variants.first.color;
          selectedSize = variants.first.size;
          _updateSelectedVariant();
        }
      }
    } catch (e) {
      print('Error loading product: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _updateSelectedVariant() {
    if (selectedColor != null && selectedSize != null) {
      try {
        selectedVariant = variants.firstWhere(
          (v) => v.color == selectedColor && v.size == selectedSize,
        );
      } catch (_) {
        selectedVariant = null;
      }
    }
  }

  List<String> get availableColors {
    return variants.map((v) => v.color).toSet().toList();
  }

  List<String> get availableSizes {
    if (selectedColor == null) return [];
    return variants
        .where((v) => v.color == selectedColor)
        .map((v) => v.size)
        .toSet()
        .toList();
  }

  Future<void> _addToCart() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isLoggedIn) {
      _showLoginDialog();
      return;
    }

    if (selectedVariant == null) {
      _showMessage('Please select color and size', isError: true);
      return;
    }

    if (selectedVariant!.stock < quantity) {
      _showMessage('Not enough stock available', isError: true);
      return;
    }

    final cartService = Provider.of<CartService>(context, listen: false);
    final result = await cartService.addToCart({
      'product_id': widget.productId,
      'name': product!.name,
      'price': product!.price,
      'quantity': quantity,
      'color': selectedColor!,
      'size': selectedSize!,
      'image': product!.image,
      'seller_email': product!.sellerEmail,
    });

    if (result['success']) {
      _showMessage(result['message'] ?? 'Added to cart', isError: false);
    } else {
      _showMessage(result['error'] ?? 'Failed to add to cart', isError: true);
    }
  }

  Future<void> _addToWishlist() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isLoggedIn) {
      _showLoginDialog();
      return;
    }

    final wishlistService = Provider.of<WishlistService>(context, listen: false);
    final result = await wishlistService.addToWishlist({
      'product_id': widget.productId,
      'name': product!.name,
      'price': product!.price,
      'image': product!.image,
      'seller_email': product!.sellerEmail,
    });

    if (result['success']) {
      _showMessage(result['message'] ?? 'Added to wishlist', isError: false);
    } else {
      _showMessage(result['error'] ?? 'Failed to add to wishlist', isError: true);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.login, color: Color(0xFF7C3AED)),
            SizedBox(width: 8),
            Text('Sign In Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You need to sign in to add items to your cart or wishlist.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Member Benefits:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('• Save items to cart & wishlist', style: TextStyle(fontSize: 13)),
                  Text('• Track your orders', style: TextStyle(fontSize: 13)),
                  Text('• Faster checkout', style: TextStyle(fontSize: 13)),
                  Text('• Exclusive member deals', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/auth');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF7C3AED),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (product == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF7C3AED),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Product not found')),
      );
    }

    final images = product!.images.isNotEmpty ? product!.images : [product!.image];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        title: const Text('Product Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageGallery(images),
            _buildProductInfo(),
            _buildVariantSelector(),
            _buildQuantitySelector(),
            _buildSellerInfo(),
            _buildDescription(),
            const SizedBox(height: 100), // Space for bottom buttons
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildImageGallery(List<String> images) {
    return Stack(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 350,
            viewportFraction: 1.0,
            enableInfiniteScroll: images.length > 1,
            onPageChanged: (index, reason) {
              setState(() => currentImageIndex = index);
            },
          ),
          items: images.map((img) {
            return Container(
              color: Colors.white,
              child: Image.network(
                img,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.image_not_supported,
                  size: 100,
                  color: Colors.grey,
                ),
              ),
            );
          }).toList(),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: images.asMap().entries.map((entry) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentImageIndex == entry.key
                        ? const Color(0xFF7C3AED)
                        : Colors.white.withOpacity(0.5),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildProductInfo() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product!.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '₱${product!.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7C3AED),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_bag, size: 16, color: Color(0xFF10B981)),
                    const SizedBox(width: 4),
                    Text(
                      '${product!.sales} sold',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVariantSelector() {
    if (variants.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (availableColors.isNotEmpty) ...[
            const Text(
              'Color',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableColors.map((color) {
                final isSelected = selectedColor == color;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedColor = color;
                      selectedSize = null;
                      _updateSelectedVariant();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF7C3AED) : Colors.white,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF7C3AED) : Colors.grey[300]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      color,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          if (availableSizes.isNotEmpty) ...[
            const Text(
              'Size',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableSizes.map((size) {
                final isSelected = selectedSize == size;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedSize = size;
                      _updateSelectedVariant();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF7C3AED) : Colors.white,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF7C3AED) : Colors.grey[300]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      size,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (selectedVariant != null) ...[
            const SizedBox(height: 12),
            Text(
              'Stock: ${selectedVariant!.stock} available',
              style: TextStyle(
                color: selectedVariant!.stock > 0 ? const Color(0xFF10B981) : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text(
            'Quantity',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: quantity > 1
                      ? () => setState(() => quantity--)
                      : null,
                  color: const Color(0xFF7C3AED),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '$quantity',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: selectedVariant != null && quantity < selectedVariant!.stock
                      ? () => setState(() => quantity++)
                      : null,
                  color: const Color(0xFF7C3AED),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerInfo() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF7C3AED).withOpacity(0.1),
            child: const Icon(Icons.store, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sold by',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  product!.sellerName.isNotEmpty ? product!.sellerName : 'Seller',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SellerProfileScreen(
                    sellerEmail: product!.sellerEmail,
                    sellerName: product!.sellerName,
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF7C3AED),
              side: const BorderSide(color: Color(0xFF7C3AED)),
            ),
            child: const Text('View Shop'),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            product!.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _addToWishlist,
            icon: const Icon(Icons.favorite_border),
            color: const Color(0xFFEC4899),
            iconSize: 28,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFEC4899).withOpacity(0.1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _addToCart,
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Add to Cart'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
