import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';

class RiderPastDeliveriesScreen extends StatelessWidget {
  const RiderPastDeliveriesScreen({super.key});

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
          .where('status', whereIn: ['Delivered', 'Received'])
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
            Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Past Deliveries',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Your completed deliveries will appear here',
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
    final formattedDate = DateFormat('MMM dd, yyyy').format(orderDate);
    final status = data['status'] ?? 'Delivered';

    // Get distance-based commission from order data
    final distanceKm = (data['delivery_distance_km'] ?? 0).toDouble();
    final distanceCommission = (data['distance_commission'] ?? 0).toDouble();
    final shippingFee = 38.0;
    final totalEarnings = (data['rider_total_earnings'] ?? (shippingFee + distanceCommission)).toDouble();
    
    final color = data['color'] ?? '';
    final size = data['size'] ?? '';
    final deliveryPhoto = data['delivery_photo'] ?? '';

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
                    color: status == 'Received' 
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        status == 'Received' ? Icons.check_circle : Icons.local_shipping,
                        size: 14,
                        color: status == 'Received' ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: status == 'Received' ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    deliveryAddress,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Earned',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '₱${totalEarnings.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    if (distanceKm > 0)
                      Text(
                        '${distanceKm.toStringAsFixed(2)} km',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (deliveryPhoto.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => _viewDeliveryPhoto(context, deliveryPhoto),
                        icon: const Icon(Icons.photo, size: 16),
                        label: const Text('View Photo', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _viewDeliveryPhoto(BuildContext context, String photoUrl) {
    String cleanPhotoUrl = photoUrl;
    if (cleanPhotoUrl.startsWith('//')) {
      cleanPhotoUrl = 'https:$cleanPhotoUrl';
    } else if (!cleanPhotoUrl.startsWith('http')) {
      cleanPhotoUrl = 'https://$cleanPhotoUrl';
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Delivery Photo'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            InteractiveViewer(
              child: Image.network(
                cleanPhotoUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.image_not_supported),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
