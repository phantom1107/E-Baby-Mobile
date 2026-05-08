import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';

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
    final imageUrl = data['image'] ?? '';
    final customerEmail = data['email'] ?? '';
    final deliveryAddress = data['delivery_address'] ?? 'No address';
    final orderDate = (data['order_date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final formattedDate = DateFormat('MMM dd, yyyy hh:mm a').format(orderDate);

    // Calculate delivery earnings: ₱38 shipping + ₱10 per ₱2000 of subtotal
    final subtotal = (data['subtotal'] ?? 0).toDouble();
    final shippingFee = 38.0; // Static shipping fee
    final commission = (subtotal / 2000) * 10; // ₱10 per ₱2000
    final totalEarnings = shippingFee + commission;

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
                    if (commission > 0 || shippingFee > 0)
                      Text(
                        '₱${shippingFee.toStringAsFixed(2)} + ₱${commission.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Accept Delivery'),
        content: const Text('Are you sure you want to accept this delivery?'),
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
      try {
        // Update order status to Shipping (matching website logic) and assign rider
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .update({
          'status': 'Shipping',
          'rider_email': riderEmail,
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order accepted! Start delivery now.'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
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
}
