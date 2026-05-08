import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';

class SellerOrderListScreen extends StatefulWidget {
  const SellerOrderListScreen({super.key});

  @override
  State<SellerOrderListScreen> createState() => _SellerOrderListScreenState();
}

class _SellerOrderListScreenState extends State<SellerOrderListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final sellerEmail = authService.currentUser?.email;

    if (sellerEmail == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF7C3AED),
          foregroundColor: Colors.white,
          title: const Text('Orders'),
        ),
        body: const Center(child: Text('Please login')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        title: const Text('Orders'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersList(sellerEmail, null),
          _buildOrdersList(sellerEmail, ['Pending', 'Preparing']),
          _buildOrdersList(sellerEmail, ['Prepared', 'Out for Delivery']),
          _buildOrdersList(sellerEmail, ['Received', 'Cancelled']),
        ],
      ),
    );
  }

  Widget _buildOrdersList(String sellerEmail, List<String>? statusFilter) {
    print('=== SELLER ORDERS DEBUG ===');
    print('Seller Email: $sellerEmail');
    print('Status Filter: $statusFilter');
    print('Building StreamBuilder...');
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('seller_email', isEqualTo: sellerEmail)
          .snapshots(),
      builder: (context, snapshot) {
        print('StreamBuilder triggered!');
        print('Connection State: ${snapshot.connectionState}');
        print('Has Error: ${snapshot.hasError}');
        print('Has Data: ${snapshot.hasData}');
        
        if (snapshot.hasError) {
          print('ERROR: ${snapshot.error}');
          
          // If error is about missing index, show helpful message
          if (snapshot.error.toString().contains('index')) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning, size: 60, color: Colors.orange),
                    const SizedBox(height: 16),
                    const Text(
                      'Firestore Index Required',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Click the link in the console to create the index',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {});
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          print('Waiting for data...');
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          print('No data in snapshot!');
          return _buildEmptyState();
        }

        var orders = snapshot.data!.docs;
        print('Total orders found: ${orders.length}');
        
        if (orders.isEmpty) {
          print('Orders list is empty!');
          return _buildEmptyState();
        }
        
        // Print first order for debugging
        if (orders.isNotEmpty) {
          final firstOrder = orders.first.data() as Map<String, dynamic>;
          print('First order seller_email: ${firstOrder['seller_email']}');
          print('First order data: ${firstOrder.keys.toList()}');
        }

        // Sort by order_date manually (since we removed orderBy from query)
        orders.sort((a, b) {
          final aDate = (a.data() as Map<String, dynamic>)['order_date'] as Timestamp?;
          final bDate = (b.data() as Map<String, dynamic>)['order_date'] as Timestamp?;
          if (aDate == null || bDate == null) return 0;
          return bDate.compareTo(aDate); // Descending order
        });

        // Filter by status if specified
        if (statusFilter != null) {
          orders = orders.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = (data['status'] ?? '').toString();
            return statusFilter.any((s) => s.toLowerCase() == status.toLowerCase());
          }).toList();
          print('After status filter: ${orders.length} orders');
        }

        if (orders.isEmpty) {
          print('No orders after filtering!');
          return _buildEmptyState();
        }
        
        print('Rendering ${orders.length} orders...');

        return RefreshIndicator(
          onRefresh: () async {
            // Refresh is handled by StreamBuilder
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final doc = orders[index];
              final data = doc.data() as Map<String, dynamic>;
              final orderId = doc.id;

              return _buildOrderCard(orderId, data);
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
            Icons.shopping_bag_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No orders yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(String orderId, Map<String, dynamic> data) {
    final productName = data['name'] ?? 'Unknown Product';
    final quantity = data['quantity'] ?? 1;
    final totalPrice = (data['total_price'] ?? 0).toDouble();
    final status = (data['status'] ?? 'Pending').toString();
    final imageUrl = data['image'] ?? '';
    final buyerEmail = data['email'] ?? '';
    final deliveryAddress = data['delivery_address'] ?? 'No address';
    
    final orderDate = (data['order_date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final formattedDate = DateFormat('MMM dd, yyyy hh:mm a').format(orderDate);

    final color = data['color'] ?? '';
    final size = data['size'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showOrderDetails(orderId, data),
        borderRadius: BorderRadius.circular(12),
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
                          'Qty: $quantity × ₱${(totalPrice / quantity).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status Badge
                  _buildStatusBadge(status),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '₱${totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                    ],
                  ),
                  if (_canUpdateStatus(status))
                    ElevatedButton(
                      onPressed: () => _updateOrderStatus(orderId, status),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Text(_getNextStatusAction(status)),
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
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        icon = Icons.pending;
        break;
      case 'preparing':
        color = Colors.blue;
        icon = Icons.kitchen;
        break;
      case 'prepared':
        color = const Color(0xFF10B981);
        icon = Icons.check_circle;
        break;
      case 'out for delivery':
        color = Colors.purple;
        icon = Icons.local_shipping;
        break;
      case 'received':
        color = const Color(0xFF10B981);
        icon = Icons.done_all;
        break;
      case 'cancelled':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  bool _canUpdateStatus(String status) {
    return ['Pending', 'Preparing'].contains(status);
  }

  String _getNextStatusAction(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Start Preparing';
      case 'preparing':
        return 'Mark as Prepared';
      default:
        return 'Update';
    }
  }

  Future<void> _updateOrderStatus(String orderId, String currentStatus) async {
    String newStatus;
    switch (currentStatus.toLowerCase()) {
      case 'pending':
        newStatus = 'Preparing';
        break;
      case 'preparing':
        newStatus = 'Prepared';
        break;
      default:
        return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to $newStatus'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showOrderDetails(String orderId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Order Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '#${orderId.substring(0, 8)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  _buildDetailRow('Product', data['name'] ?? 'Unknown'),
                  _buildDetailRow('Quantity', '${data['quantity'] ?? 1}'),
                  if (data['color'] != null && data['color'].toString().isNotEmpty)
                    _buildDetailRow('Color', data['color']),
                  if (data['size'] != null && data['size'].toString().isNotEmpty)
                    _buildDetailRow('Size', data['size']),
                  _buildDetailRow('Price', '₱${((data['total_price'] ?? 0) / (data['quantity'] ?? 1)).toStringAsFixed(2)}'),
                  _buildDetailRow('Subtotal', '₱${(data['subtotal'] ?? 0).toStringAsFixed(2)}'),
                  _buildDetailRow('Shipping', '₱${(data['shipping_fee'] ?? 0).toStringAsFixed(2)}'),
                  _buildDetailRow('Tax', '₱${(data['tax'] ?? 0).toStringAsFixed(2)}'),
                  const Divider(height: 24),
                  _buildDetailRow(
                    'Total',
                    '₱${(data['total_price'] ?? 0).toStringAsFixed(2)}',
                    isBold: true,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow('Customer', data['email'] ?? 'Unknown'),
                  _buildDetailRow('Delivery Address', data['delivery_address'] ?? 'No address'),
                  _buildDetailRow('Payment Method', data['payment_method'] ?? 'COD'),
                  _buildDetailRow('Status', data['status'] ?? 'Pending'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
