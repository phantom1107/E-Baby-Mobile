import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_repository.dart';
import '../models/cart_order.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  String _paymentMethod = 'Cash on Delivery';
  bool _isProcessing = false;
  bool _isLoadingAddress = true;
  List<CartItem> checkoutItems = [];
  List<String> selectedIds = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCheckoutItems();
      _loadUserAddress();
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _loadCheckoutItems() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is List) {
      selectedIds = args.cast<String>();
      final cartService = Provider.of<CartService>(context, listen: false);
      setState(() {
        checkoutItems = cartService.items
            .where((item) => selectedIds.contains(item.cartDocId))
            .toList();
      });
    }
  }

  Future<void> _loadUserAddress() async {
    setState(() => _isLoadingAddress = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userEmail = authService.currentUser?.email;
      
      if (userEmail != null && userEmail.isNotEmpty) {
        // Query users collection by email
        final userQuery = await FirestoreRepository.usersRef
            .where('email', isEqualTo: userEmail)
            .limit(1)
            .get();
        
        if (userQuery.docs.isNotEmpty) {
          final userData = userQuery.docs.first.data();
          
          // Try to get the full address field first, or build from components
          String address = userData['address']?.toString() ?? '';
          
          if (address.isEmpty) {
            // Build address from components if full address not available
            final parts = <String>[];
            if (userData['street_address']?.toString().isNotEmpty ?? false) {
              parts.add(userData['street_address'].toString());
            }
            if (userData['city']?.toString().isNotEmpty ?? false) {
              parts.add(userData['city'].toString());
            }
            if (userData['province']?.toString().isNotEmpty ?? false) {
              parts.add(userData['province'].toString());
            }
            if (userData['region']?.toString().isNotEmpty ?? false) {
              parts.add(userData['region'].toString());
            }
            if (userData['country']?.toString().isNotEmpty ?? false) {
              parts.add(userData['country'].toString());
            }
            address = parts.join(', ');
          }
          
          if (address.isNotEmpty && mounted) {
            setState(() {
              _addressController.text = address;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading user address: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingAddress = false);
      }
    }
  }

  double get subtotal =>
      checkoutItems.fold(0.0, (sum, item) => sum + item.total);
  double get shippingFee => 38.0;
  double get tax => subtotal * 0.025;
  double get total => subtotal + shippingFee + tax;

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (checkoutItems.isEmpty) {
      _showMessage('No items to checkout', isError: true);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userEmail = authService.currentUser?.email;

      if (userEmail == null || userEmail.isEmpty) {
        _showMessage('Please login first', isError: true);
        setState(() => _isProcessing = false);
        return;
      }

      final orderDate = DateTime.now();
      final riderCommissionTotal = (total / 2000.0) * 5.0;
      int successfulOrders = 0;
      List<String> failedItems = [];

      // Process each item
      for (final item in checkoutItems) {
        try {
          // Get product details
          final productDoc = await FirestoreRepository.productsRef
              .doc(item.productIdStr ?? item.productId.toString())
              .get();

          if (!productDoc.exists) {
            failedItems.add('${item.name} - Product not found');
            continue;
          }

          final productData = productDoc.data()!;
          final sellerEmail = productData['seller_email'] ?? '';

          // Get variants from product document array
          final variants = productData['variants'] as List<dynamic>? ?? [];
          
          // Find matching variant
          final matchingVariant = variants.firstWhere(
            (v) => v['color'] == item.color && v['size'] == item.size,
            orElse: () => null,
          );

          if (matchingVariant == null) {
            failedItems.add('${item.name} - Variant not found');
            continue;
          }

          final currentStock = int.tryParse(matchingVariant['stock']?.toString() ?? '0') ?? 0;

          if (currentStock < item.quantity) {
            failedItems.add('${item.name} - Insufficient stock');
            continue;
          }

          // Calculate proportional values
          final itemSubtotal = item.total;
          final itemShipping =
              subtotal > 0 ? (itemSubtotal / subtotal) * shippingFee : 0;
          final itemTax = subtotal > 0 ? (itemSubtotal / subtotal) * tax : 0;
          final itemTotal = itemSubtotal + itemTax;
          final itemCommission = subtotal > 0
              ? (itemSubtotal / subtotal) * riderCommissionTotal
              : 0;

          // Generate transaction ID
          final transactionId =
              'TXN${orderDate.millisecondsSinceEpoch}${item.cartDocId}';

          // Create order
          final orderData = {
            'email': userEmail,
            'name': item.name,
            'total_price': itemTotal,
            'price': item.price,
            'total': itemTotal,
            'subtotal': itemSubtotal,
            'shipping': itemShipping,
            'tax': itemTax,
            'quantity': item.quantity,
            'image': item.image,
            'status': 'Pending',
            'payment_method': _paymentMethod,
            'date': FieldValue.serverTimestamp(),
            'created_at': FieldValue.serverTimestamp(),
            'delivery_address': _addressController.text.trim(),
            'seller_email': sellerEmail,
            'transaction_id': transactionId,
            'product_id': item.productIdStr ?? item.productId.toString(),
            'category': productData['category'] ?? 'N/A',
            'color': item.color,
            'size': item.size,
            'commission': itemCommission,
            'commission_rate': 5.0,
          };

          await FirestoreRepository.ordersRef.add(orderData);

          // Update variant stock in product document
          final newStock = currentStock - item.quantity;
          
          // Update the specific variant in the array
          final updatedVariants = variants.map((v) {
            if (v['color'] == item.color && v['size'] == item.size) {
              return {
                ...v,
                'stock': newStock,
              };
            }
            return v;
          }).toList();
          
          // Update product document with new variants array
          await FirestoreRepository.productsRef
              .doc(item.productIdStr ?? item.productId.toString())
              .update({
                'variants': updatedVariants,
                'stock': updatedVariants.fold<int>(0, (sum, v) => sum + (int.tryParse(v['stock']?.toString() ?? '0') ?? 0)),
              });

          successfulOrders++;
        } catch (e) {
          print('Error processing item ${item.name}: $e');
          failedItems.add('${item.name} - ${e.toString()}');
        }
      }

      if (successfulOrders == 0) {
        _showMessage(
          'Unable to process any items. ${failedItems.join(", ")}',
          isError: true,
        );
        setState(() => _isProcessing = false);
        return;
      }

      // Remove items from cart
      final cartService = Provider.of<CartService>(context, listen: false);
      await cartService.deleteSelected(selectedIds);

      if (!mounted) return;

      // Show success and navigate
      _showMessage(
        '$successfulOrders item(s) ordered successfully!',
        isError: false,
      );

      // Navigate to orders screen
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/orders',
          (route) => false,
        );
      }
    } catch (e) {
      print('Order error: $e');
      _showMessage('Failed to place order: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: checkoutItems.isEmpty
          ? const Center(child: Text('No items to checkout'))
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildItemsList(),
                  _buildDeliveryAddressSection(),
                  _buildPaymentMethodSection(),
                  _buildOrderSummary(),
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
      bottomNavigationBar: _buildPlaceOrderButton(),
    );
  }

  Widget _buildItemsList() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_bag, color: Color(0xFF7C3AED)),
              const SizedBox(width: 8),
              Text(
                'Order Items (${checkoutItems.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...checkoutItems.map((item) => _buildItemCard(item)),
        ],
      ),
    );
  }

  Widget _buildItemCard(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              item.image,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 60,
                height: 60,
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported, size: 30),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (item.color.isNotEmpty || item.size.isNotEmpty)
                  Text(
                    [
                      if (item.color.isNotEmpty) item.color,
                      if (item.size.isNotEmpty) item.size,
                    ].join(' • '),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                const SizedBox(height: 4),
                Text(
                  '₱${item.price.toStringAsFixed(2)} × ${item.quantity}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            '₱${item.total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7C3AED),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddressSection() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF7C3AED)),
                const SizedBox(width: 8),
                const Text(
                  'Delivery Address',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoadingAddress)
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Loading your address...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else ...[
              if (_addressController.text.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF7C3AED).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: const Color(0xFF7C3AED),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your registered address is pre-filled. You can edit it if needed.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter your complete delivery address',
                  helperText: 'Street, Barangay, City, Province, Region',
                  helperStyle: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter delivery address';
                  }
                  if (value.trim().length < 10) {
                    return 'Please enter a complete address (at least 10 characters)';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payment, color: Color(0xFF7C3AED)),
              const SizedBox(width: 8),
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF7C3AED), width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: RadioListTile<String>(
              value: 'Cash on Delivery',
              groupValue: _paymentMethod,
              onChanged: (value) {
                setState(() => _paymentMethod = value!);
              },
              title: const Text(
                'Cash on Delivery (COD)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Pay when you receive your order'),
              activeColor: const Color(0xFF7C3AED),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: Color(0xFF7C3AED)),
              const SizedBox(width: 8),
              const Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Subtotal', subtotal),
          _buildSummaryRow('Shipping Fee', shippingFee),
          _buildSummaryRow('Tax (2.5%)', tax),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₱${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceOrderButton() {
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
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              disabledBackgroundColor: Colors.grey[300],
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Place Order - ₱${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
