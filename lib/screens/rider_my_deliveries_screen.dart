import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/cloudinary_service.dart';

class RiderMyDeliveriesScreen extends StatelessWidget {
  const RiderMyDeliveriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final riderEmail = authService.currentUser?.email;

    if (riderEmail == null) {
      return const Center(child: Text('Please login'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('rider_email', isEqualTo: riderEmail)
          .where('status', isEqualTo: 'Shipping')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return _buildEmptyState();
        }

        final allDeliveries = snapshot.data!.docs;

        // Sort by order_date manually (descending)
        allDeliveries.sort((a, b) {
          final aDate = (a.data() as Map<String, dynamic>)['order_date'] as Timestamp?;
          final bDate = (b.data() as Map<String, dynamic>)['order_date'] as Timestamp?;
          if (aDate == null || bDate == null) return 0;
          return bDate.compareTo(aDate);
        });

        if (allDeliveries.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allDeliveries.length,
            itemBuilder: (context, index) {
              final doc = allDeliveries[index];
              final data = doc.data() as Map<String, dynamic>;
              final orderId = doc.id;

              return _buildDeliveryCard(context, orderId, data);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Deliveries',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Accept orders to start delivering',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(
    BuildContext context,
    String orderId,
    Map<String, dynamic> data,
  ) {
    final productName = data['name'] ?? 'Unknown Product';
    final quantity = data['quantity'] ?? 1;
    final totalPrice = (data['total_price'] ?? 0).toDouble();
    String imageUrl = data['image'] ?? '';
    
    // Fix Cloudinary URL format
    if (imageUrl.isNotEmpty && imageUrl.startsWith('//')) {
      imageUrl = 'https:$imageUrl';
    } else if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      imageUrl = 'https://$imageUrl';
    }
    
    final customerEmail = data['email'] ?? '';
    final deliveryAddress = data['delivery_address'] ?? 'No address';
    final orderDate = (data['order_date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final formattedDate = DateFormat('MMM dd, yyyy hh:mm a').format(orderDate);

    // Get distance-based commission from order data
    final distanceKm = (data['delivery_distance_km'] ?? 0).toDouble();
    final distanceCommission = (data['distance_commission'] ?? 0).toDouble();
    final shippingFee = 38.0; // Base shipping fee
    
    // Calculate total earnings (use stored value if available, otherwise calculate)
    final totalEarnings = (data['rider_total_earnings'] ?? (shippingFee + distanceCommission)).toDouble();
    
    final color = data['color'] ?? '';
    final size = data['size'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 30),
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 30),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (color.isNotEmpty || size.isNotEmpty)
                        Text(
                          [if (color.isNotEmpty) color, if (size.isNotEmpty) size].join(' • '),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'Qty: $quantity',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_shipping, size: 14, color: Color(0xFF3B82F6)),
                      SizedBox(width: 4),
                      Text(
                        'Delivering',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivery Address',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              deliveryAddress,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              customerEmail,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Earnings',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '₱${totalEarnings.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    if (distanceKm > 0)
                      Text(
                        '${distanceKm.toStringAsFixed(2)} km • ₱${shippingFee.toStringAsFixed(0)} + ₱${distanceCommission.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      )
                    else
                      Text(
                        'Base fee: ₱${shippingFee.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _markAsDelivered(context, orderId, totalPrice),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Mark Delivered'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _viewOrderDetails(context, orderId, data),
                          icon: const Icon(Icons.info_outline, size: 20),
                          tooltip: 'View Details',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _openMaps(deliveryAddress),
                          icon: const Icon(Icons.map, size: 20),
                          tooltip: 'Open Maps',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.blue[100],
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Started: $formattedDate',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAsDelivered(
    BuildContext context,
    String orderId,
    double totalPrice,
  ) async {
    // First, take delivery photo
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (photo == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery photo is required'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Mark as Delivered'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                constraints: const BoxConstraints(
                  maxHeight: 200,
                  maxWidth: 300,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(photo.path),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Confirm that this order has been delivered to the customer?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final riderEmail = authService.currentUser?.email;

      if (riderEmail == null) return;

      // Upload photo to Cloudinary
      final cloudinaryService = CloudinaryService();
      final photoUrl = await CloudinaryService.uploadProductImage(
        File(photo.path),
        'delivery_$orderId',
      );

      // Get order data
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();
      
      if (!orderDoc.exists) return;
      
      final orderData = orderDoc.data() as Map<String, dynamic>;
      
      // Get distance-based commission from order data
      final distanceKm = (orderData['delivery_distance_km'] ?? 0).toDouble();
      final distanceCommission = (orderData['distance_commission'] ?? 0).toDouble();
      final shippingFee = 38.0;
      final totalEarnings = (orderData['rider_total_earnings'] ?? (shippingFee + distanceCommission)).toDouble();

      // Update order with delivery photo
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'status': 'Delivered',
        'delivery_photo': photoUrl,
        'delivery_photo_timestamp': FieldValue.serverTimestamp(),
      });

      // Create earnings record with distance-based commission
      await FirebaseFirestore.instance.collection('rider_earnings').add({
        'rider_email': riderEmail,
        'order_id': orderId,
        'distance_km': distanceKm,
        'distance_commission': distanceCommission,
        'shipping_fee': shippingFee,
        'total_earned': totalEarnings,
        'status': 'Completed',
        'date': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delivery completed! You earned ₱${totalEarnings.toStringAsFixed(2)}'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing delivery: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewOrderDetails(BuildContext context, String orderId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Order Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Order ID', orderId),
              _buildDetailRow('Product', data['name'] ?? 'N/A'),
              _buildDetailRow('Quantity', '${data['quantity'] ?? 0}'),
              _buildDetailRow('Color', data['color'] ?? 'N/A'),
              _buildDetailRow('Size', data['size'] ?? 'N/A'),
              _buildDetailRow('Subtotal', '₱${(data['subtotal'] ?? 0).toStringAsFixed(2)}'),
              _buildDetailRow('Total Price', '₱${(data['total_price'] ?? 0).toStringAsFixed(2)}'),
              _buildDetailRow('Customer', data['email'] ?? 'N/A'),
              _buildDetailRow('Phone', data['phone'] ?? 'N/A'),
              _buildDetailRow('Address', data['delivery_address'] ?? 'N/A'),
              _buildDetailRow('Payment', data['payment_method'] ?? 'N/A'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _openMaps(String address) async {
    // Clean up address - remove newlines and extra whitespace
    final cleanAddress = address.trim().replaceAll(RegExp(r'\s+'), ' ');
    final encodedAddress = Uri.encodeComponent(cleanAddress);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Fallback - try to open with any available app
        await launchUrl(url);
      }
    } catch (e) {
      print('Error opening maps: $e');
    }
  }
}
