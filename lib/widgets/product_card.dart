import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../services/wishlist_service.dart';
import '../widgets/variant_selector_sheet.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                  child: product.image.startsWith('http')
                      ? Image.network(
                          product.image,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading image: ${product.image}');
                            print('Error: $error');
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.shopping_bag, size: 50, color: Colors.grey),
                              ),
                            );
                          },
                        )
                      : Image.asset(
                          'assets/images/products/${product.image}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading asset: ${product.image}');
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.shopping_bag, size: 50, color: Colors.grey),
                              ),
                            );
                          },
                        ),
                ),
                // Eye icon for viewing product details
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.visibility, size: 20),
                      color: Colors.white,
                      onPressed: () => _viewProductDetails(context),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.favorite_border, size: 20),
                      color: Colors.red,
                      onPressed: () => _addToWishlist(context),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Category badge
                if (product.category.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.category,
                      style: const TextStyle(
                        color: Color(0xFF7C3AED),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  '₱${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF7C3AED),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                // Stock and Sales indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 12,
                          color: product.stock > 0 ? const Color(0xFF10B981) : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Stock: ${product.stock}',
                          style: TextStyle(
                            fontSize: 11,
                            color: product.stock > 0 ? const Color(0xFF10B981) : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.shopping_cart,
                          size: 12,
                          color: Color(0xFF7C3AED),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${product.sales} sold',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF7C3AED),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: product.stock > 0 ? () => _addToCart(context) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          disabledForegroundColor: Colors.grey[600],
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: Text(product.stock > 0 ? 'Add to Cart' : 'Out of Stock'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _viewProductDetails(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Check if user is logged in
    if (!authService.isLoggedIn) {
      _showGuestModal(context, isViewingProduct: true);
      return;
    }
    
    // Navigate to product details
    Navigator.pushNamed(
      context,
      '/product_details',
      arguments: product,
    );
  }

  void _addToCart(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Check if user is logged in
    if (!authService.isLoggedIn) {
      _showGuestModal(context);
      return;
    }
    
    // Show variant selector bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VariantSelectorSheet(product: product),
    );
  }

  void _addToWishlist(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Check if user is logged in
    if (!authService.isLoggedIn) {
      _showGuestModal(context);
      return;
    }
    
    final wishlistService = Provider.of<WishlistService>(context, listen: false);
    
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Adding to wishlist...'),
          ],
        ),
        duration: Duration(seconds: 1),
      ),
    );
    
    final result = await wishlistService.addToWishlist({
      'product_id': product.productId,
      'name': product.name,
      'price': product.price,
      'image': product.image,
      'seller_email': product.sellerEmail,
    });
    
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.favorite, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(result['message'] ?? 'Added to wishlist'),
              ),
            ],
          ),
          backgroundColor: Colors.pink,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(result['error'] ?? 'Failed to add to wishlist'),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showGuestModal(BuildContext context, {bool isViewingProduct = false}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: const Color(0xFF7C3AED)),
              const SizedBox(width: 8),
              const Text('Sign In Required'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isViewingProduct
                    ? 'You need to sign in to view product details.'
                    : 'You need to sign in to add items to your cart or wishlist.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Member Benefits:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              _buildBenefit('View detailed product information'),
              _buildBenefit('Save items to wishlist'),
              _buildBenefit('Manage your cart'),
              _buildBenefit('Track your orders'),
              _buildBenefit('Exclusive member deals'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continue as Guest'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/auth');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
              ),
              child: const Text('Sign In'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            size: 16,
            color: Color(0xFF10B981),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
