import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/wishlist_service.dart';
import '../services/cart_service.dart';
import '../services/auth_service.dart';
import '../models/cart_order.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  Set<String> selectedItems = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      await Provider.of<WishlistService>(context, listen: false).loadWishlist();
    } catch (e) {
      print('Error loading wishlist: $e');
    }
    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final wishlistService = Provider.of<WishlistService>(context);

    // Check if user is logged in
    if (!authService.isLoggedIn) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: const Color(0xFF7C3AED),
          foregroundColor: Colors.white,
          title: const Text('Wishlist'),
          automaticallyImplyLeading: false,
        ),
        body: _buildLoginPrompt(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        title: Text('Wishlist (${wishlistService.wishlistCount})'),
        automaticallyImplyLeading: false,
        actions: [
          if (selectedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showDeleteConfirmation(wishlistService),
              tooltip: 'Delete selected',
            ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading wishlist...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : wishlistService.items.isEmpty
              ? _buildEmptyWishlist()
              : Column(
                  children: [
                    if (wishlistService.items.isNotEmpty)
                      _buildSelectAllBar(wishlistService),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadWishlist,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: wishlistService.items.length,
                          itemBuilder: (context, index) {
                            final item = wishlistService.items[index];
                            return _buildWishlistItemCard(item, wishlistService);
                          },
                        ),
                      ),
                    ),
                    if (selectedItems.isNotEmpty)
                      _buildActionBar(wishlistService),
                  ],
                ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'Sign In to View Wishlist',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please sign in to access your wishlist and saved items.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/auth'),
              icon: const Icon(Icons.login),
              label: const Text('Sign In'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWishlist() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Wishlist is Empty',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Save items you love to your wishlist.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate back to home
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                );
              },
              icon: const Icon(Icons.shopping_bag),
              label: const Text('Start Shopping'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectAllBar(WishlistService wishlistService) {
    final allSelected = wishlistService.items.isNotEmpty &&
        selectedItems.length == wishlistService.items.length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Checkbox(
            value: allSelected,
            onChanged: (checked) {
              setState(() {
                if (checked!) {
                  selectedItems = wishlistService.items
                      .map((item) => item.docId ?? item.id.toString())
                      .toSet();
                } else {
                  selectedItems.clear();
                }
              });
            },
            activeColor: const Color(0xFF7C3AED),
          ),
          const Text(
            'Select All',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          if (selectedItems.isNotEmpty)
            Text(
              '${selectedItems.length} selected',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWishlistItemCard(WishlistItem item, WishlistService wishlistService) {
    final itemId = item.docId ?? item.id.toString();
    final isSelected = selectedItems.contains(itemId);

    return Container(
      margin: const EdgeInsets.only(top: 8, left: 8, right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Navigate to product details
          Navigator.pushNamed(
            context,
            '/product-details',
            arguments: item.productIdStr ?? item.productId.toString(),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (checked) {
                  setState(() {
                    if (checked!) {
                      selectedItems.add(itemId);
                    } else {
                      selectedItems.remove(itemId);
                    }
                  });
                },
                activeColor: const Color(0xFF7C3AED),
              ),
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.image.isNotEmpty
                    ? Image.network(
                        item.image,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported, size: 40),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(Icons.shopping_bag, size: 40),
                      ),
              ),
              const SizedBox(width: 12),
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₱${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(item.dateAdded),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _moveToCart(item),
                            icon: const Icon(Icons.shopping_cart, size: 16),
                            label: const Text('Add to Cart'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF7C3AED),
                              side: const BorderSide(color: Color(0xFF7C3AED)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => _deleteItem(item, wishlistService),
                          color: Colors.red,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar(WishlistService wishlistService) {
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
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _moveSelectedToCart(wishlistService),
                icon: const Icon(Icons.shopping_cart),
                label: Text('Move to Cart (${selectedItems.length})'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF7C3AED),
                  side: const BorderSide(color: Color(0xFF7C3AED)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showDeleteConfirmation(wishlistService),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
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
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Added today';
    } else if (difference.inDays == 1) {
      return 'Added yesterday';
    } else if (difference.inDays < 7) {
      return 'Added ${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Added $weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      return 'Added on ${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _moveToCart(WishlistItem item) async {
    final cartService = Provider.of<CartService>(context, listen: false);
    final wishlistService = Provider.of<WishlistService>(context, listen: false);

    // Show loading
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Adding to cart...'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Add to cart
    final result = await cartService.addToCart({
      'product_id': item.productIdStr ?? item.productId.toString(),
      'name': item.name,
      'price': item.price,
      'quantity': 1,
      'color': '',
      'size': '',
      'image': item.image,
      'seller_email': item.sellerEmail,
    });

    if (!mounted) return;

    if (result['success']) {
      // Remove from wishlist
      await wishlistService.removeFromWishlist([item.docId ?? item.id.toString()]);
      
      setState(() => selectedItems.remove(item.docId ?? item.id.toString()));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Moved to cart successfully'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to add to cart'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _moveSelectedToCart(WishlistService wishlistService) async {
    if (selectedItems.isEmpty) return;

    final cartService = Provider.of<CartService>(context, listen: false);
    final selectedWishlistItems = wishlistService.items
        .where((item) => selectedItems.contains(item.docId ?? item.id.toString()))
        .toList();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Moving ${selectedItems.length} items to cart...'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    int successCount = 0;
    int failCount = 0;

    for (final item in selectedWishlistItems) {
      final result = await cartService.addToCart({
        'product_id': item.productIdStr ?? item.productId.toString(),
        'name': item.name,
        'price': item.price,
        'quantity': 1,
        'color': '',
        'size': '',
        'image': item.image,
        'seller_email': item.sellerEmail,
      });

      if (result['success']) {
        successCount++;
      } else {
        failCount++;
      }
    }

    // Remove successfully added items from wishlist
    if (successCount > 0) {
      await wishlistService.removeFromWishlist(
        selectedWishlistItems
            .take(successCount)
            .map((item) => item.docId ?? item.id.toString())
            .toList(),
      );
    }

    if (!mounted) return;
    setState(() => selectedItems.clear());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failCount == 0
              ? 'Moved $successCount ${successCount == 1 ? 'item' : 'items'} to cart'
              : 'Moved $successCount items, $failCount failed',
        ),
        backgroundColor: failCount == 0 ? const Color(0xFF10B981) : Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteItem(WishlistItem item, WishlistService wishlistService) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove from Wishlist'),
        content: Text('Remove "${item.name}" from your wishlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await wishlistService.removeFromWishlist([item.docId ?? item.id.toString()]);
      if (mounted) {
        setState(() => selectedItems.remove(item.docId ?? item.id.toString()));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item removed from wishlist'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(WishlistService wishlistService) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Items'),
        content: Text(
          'Remove ${selectedItems.length} selected ${selectedItems.length == 1 ? 'item' : 'items'} from your wishlist?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await wishlistService.removeFromWishlist(selectedItems.toList());
      if (mounted) {
        setState(() => selectedItems.clear());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Items removed from wishlist'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
