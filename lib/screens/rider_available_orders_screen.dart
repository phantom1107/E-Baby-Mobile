import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/auth_service.dart';
import '../utils/image_utils.dart';

class RiderAvailableOrdersScreen extends StatelessWidget {
  const RiderAvailableOrdersScreen({super.key});

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
          .where('status', isEqualTo: 'Prepared')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return _buildEmptyState();
        }

        // Filter orders that don't have a rider assigned yet (client-side filtering)
        final allOrders = snapshot.data!.docs;
        final availableOrders = allOrders.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final riderEmail = data['rider_email'];
          return riderEmail == null || riderEmail.toString().isEmpty;
        }).toList();

        // Sort by order_date manually (descending)
        availableOrders.sort((a, b) {
          final aDate = (a.data() as Map<String, dynamic>)['order_date'] as Timestamp?;
          final bDate = (b.data() as Map<String, dynamic>)['order_date'] as Timestamp?;
          if (aDate == null || bDate == null) return 0;
          return bDate.compareTo(aDate);
        });

        if (availableOrders.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: availableOrders.length,
            itemBuilder: (context, index) {
              final doc = availableOrders[index];
              final data = doc.data() as Map<String, dynamic>;
              final orderId = doc.id;

              return _buildOrderCard(context, orderId, data, riderEmail);
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
            Icons.delivery_dining,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Available Orders',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new deliveries',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    String orderId,
    Map<String, dynamic> data,
    String riderEmail,
  ) {
    final productName = data['name'] ?? 'Unknown Product';
    final quantity = data['quantity'] ?? 1;
    final totalPrice = (data['total_price'] ?? 0).toDouble();
    final imageUrl = ImageUtils.normalizeImageUrl(
      data['image'],
      fallback: ImageUtils.productPlaceholder,
    );
    
    final customerEmail = data['email'] ?? '';
    final deliveryAddress = data['delivery_address'] ?? 'No address';
    final orderDate = (data['order_date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final formattedDate = DateFormat('MMM dd, yyyy hh:mm a').format(orderDate);

    // Show estimated earnings (will be calculated accurately when accepting)
    final shippingFee = 38.0;
    final estimatedCommission = 10.0; // Placeholder, actual will be calculated on accept
    final estimatedEarnings = shippingFee + estimatedCommission;

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
                // Product Image
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

                // Order Details
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
                          [if (color.isNotEmpty) color, if (size.isNotEmpty) size]
                              .join(' • '),
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

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981)),
                      SizedBox(width: 4),
                      Text(
                        'Ready',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Delivery Info
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    deliveryAddress,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    customerEmail,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Earnings and Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimated Earnings',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '₱${estimatedEarnings.toStringAsFixed(2)}+',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    Text(
                      'Based on distance',
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
                      onPressed: () => _acceptOrder(context, orderId, riderEmail),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
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
              formattedDate,
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

  Future<void> _acceptOrder(
    BuildContext context,
    String orderId,
    String riderEmail,
  ) async {
    // Get rider's current location
    try {
      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission is required to accept orders'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable location permission in settings'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Show loading dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Getting your location...'),
              ],
            ),
          ),
        );
      }

      // Get current position with timeout
      final Position riderPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Get order data to extract delivery address
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();

      if (!orderDoc.exists) {
        if (context.mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      final deliveryAddress = orderData['delivery_address'] as String?;

      if (deliveryAddress == null || deliveryAddress.isEmpty) {
        if (context.mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Delivery address not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Geocode delivery address to get coordinates with timeout
      List<Location> locations = [];
      try {
        locations = await locationFromAddress(deliveryAddress)
            .timeout(const Duration(seconds: 10));
      } catch (e) {
        print('Geocoding error: $e');
      }
      
      double distanceInKm = 0;
      double distanceCommission = 0;
      double shippingFee = 38.0;
      double totalEarnings = shippingFee;

      if (locations.isNotEmpty) {
        final deliveryLocation = locations.first;

        // Calculate distance in meters
        final distanceInMeters = Geolocator.distanceBetween(
          riderPosition.latitude,
          riderPosition.longitude,
          deliveryLocation.latitude,
          deliveryLocation.longitude,
        );

        // Convert to kilometers
        distanceInKm = distanceInMeters / 1000;

        // Calculate commission: ₱10 per 3km
        distanceCommission = (distanceInKm / 3) * 10;
        totalEarnings = shippingFee + distanceCommission;
      }

      if (context.mounted) {
        Navigator.pop(context); // Close loading

        // Show confirmation with distance and earnings
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Accept Delivery'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Delivery Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 20, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          deliveryAddress,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        if (distanceInKm > 0) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Distance:', style: TextStyle(fontWeight: FontWeight.w600)),
                              Text(
                                '${distanceInKm.toStringAsFixed(2)} km',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Base Fee:'),
                            Text('₱${shippingFee.toStringAsFixed(2)}'),
                          ],
                        ),
                        if (distanceCommission > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Distance Fee:'),
                              Text('₱${distanceCommission.toStringAsFixed(2)}'),
                            ],
                          ),
                        ],
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Your Earnings:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(
                              '₱${totalEarnings.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF10B981),
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Accept'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          // Show loading again for update
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(child: CircularProgressIndicator()),
          );

          try {
            // Update order with rider info and distance-based commission
            await FirebaseFirestore.instance
                .collection('orders')
                .doc(orderId)
                .update({
              'status': 'Shipping',
              'rider_email': riderEmail,
              'rider_location_lat': riderPosition.latitude,
              'rider_location_lng': riderPosition.longitude,
              'delivery_distance_km': distanceInKm,
              'distance_commission': distanceCommission,
              'rider_total_earnings': totalEarnings,
              'accepted_at': FieldValue.serverTimestamp(),
            });

            if (context.mounted) {
              Navigator.pop(context); // Close loading
              
              // Show detailed earnings breakdown
              await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Order Accepted!', style: TextStyle(fontSize: 20)),
                      ),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF10B981).withOpacity(0.1),
                                const Color(0xFF10B981).withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Your Earnings Breakdown',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildEarningsRow('Base Shipping Fee', shippingFee),
                              if (distanceInKm > 0) ...[
                                const SizedBox(height: 8),
                                _buildEarningsRow(
                                  'Distance Fee (${distanceInKm.toStringAsFixed(2)} km)',
                                  distanceCommission,
                                  subtitle: '₱10 per 3km',
                                ),
                              ],
                              const Divider(height: 24, thickness: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Earnings',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  Text(
                                    '₱${totalEarnings.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Color(0xFF3B82F6), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Start delivery now! You\'ll receive payment after marking as delivered.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Start Delivery'),
                    ),
                  ],
                ),
              );
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      distanceInKm > 0 
                        ? 'Order accepted! Distance: ${distanceInKm.toStringAsFixed(2)} km'
                        : 'Order accepted!'
                    ),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            }
          } catch (e) {
            if (context.mounted) {
              Navigator.pop(context); // Close loading
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error accepting order: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        // Try to close any open dialogs
        Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildEarningsRow(String label, double amount, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '₱${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ),
      ],
    );
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
