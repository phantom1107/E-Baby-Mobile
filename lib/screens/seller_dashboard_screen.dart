import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/product_management_service.dart';
import '../services/cloudinary_service.dart';
import 'seller_order_list_screen.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  int _selectedIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard, 'title': 'Dashboard'},
    {'icon': Icons.inventory, 'title': 'My Products'},
    {'icon': Icons.add_box, 'title': 'Add Product'},
    {'icon': Icons.shopping_bag, 'title': 'Orders'},
    {'icon': Icons.analytics, 'title': 'Sales Report'},
    {'icon': Icons.person, 'title': 'Profile'},
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    
    return WillPopScope(
      onWillPop: () async {
        // Prevent back navigation - stay on dashboard
        return false;
      },
      child: Scaffold(
        appBar: isMobile ? AppBar(
          backgroundColor: const Color(0xFF7C3AED),
          foregroundColor: Colors.white,
          title: const Text('Seller Portal'),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () => _showLogoutDialog(context),
            ),
          ],
        ) : null,
        drawer: isMobile ? _buildDrawer() : null,
        body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final authService = Provider.of<AuthService>(context, listen: false);
                await authService.logout();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDrawer() {
    final authService = Provider.of<AuthService>(context);
    final userEmail = authService.currentUser?.email ?? 'Seller';

    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
          ),
        ),
        child: Column(
          children: [
            SafeArea(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.store, color: Colors.white, size: 48),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Seller Portal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      userEmail,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(color: Colors.white24),
            Expanded(
              child: ListView.builder(
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final item = _menuItems[index];
                  final isSelected = _selectedIndex == index;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF10b981).withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: Icon(
                        item['icon'],
                        color: isSelected ? const Color(0xFF10b981) : Colors.white70,
                      ),
                      title: Text(
                        item['title'],
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF10b981) : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        setState(() => _selectedIndex = index);
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context); // Close drawer first
                _showLogoutDialog(context);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    final authService = Provider.of<AuthService>(context);
    final userEmail = authService.currentUser?.email ?? 'Seller';

    return Row(
      children: [
        Container(
          width: 250,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1a1a2e), Color(0xFF16213e)], // DARK PURPLE THEME
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.store, color: Colors.white, size: 48),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Seller Portal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      userEmail,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24),
              Expanded(
                child: ListView.builder(
                  itemCount: _menuItems.length,
                  itemBuilder: (context, index) {
                    final item = _menuItems[index];
                    final isSelected = _selectedIndex == index;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF10b981).withOpacity(0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: Icon(
                          item['icon'],
                          color: isSelected ? const Color(0xFF10b981) : Colors.white70,
                        ),
                        title: Text(
                          item['title'],
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF10b981) : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        onTap: () => setState(() => _selectedIndex = index),
                      ),
                    );
                  },
                ),
              ),
              const Divider(color: Colors.white24),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () => _showLogoutDialog(context),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _menuItems[_selectedIndex]['title'],
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Manage your store and products',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.red),
                      onPressed: () => _showLogoutDialog(context),
                    ),
                    const CircleAvatar(
                      backgroundColor: Color(0xFF10b981),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _menuItems[_selectedIndex]['title'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const CircleAvatar(
                backgroundColor: Color(0xFF10b981),
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildMyProducts();
      case 2:
        return _buildAddProduct();
      case 3:
        return const SellerOrderListScreen(); // Use the separate screen
      case 4:
        return _buildSalesReport();
      case 5:
        return _buildProfile();
      default:
        return const Center(child: Text('Coming Soon'));
    }
  }

  Widget _buildDashboard() {
    final authService = Provider.of<AuthService>(context);
    final sellerEmail = authService.currentUser?.email;

    if (sellerEmail == null) {
      return const Center(child: Text('Please login'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('products')
          .where('seller_email', isEqualTo: sellerEmail)
          .snapshots(),
      builder: (context, productSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('orders')
              .where('seller_email', isEqualTo: sellerEmail)
              .snapshots(),
          builder: (context, orderSnapshot) {
            int totalProducts = 0;
            double totalRevenue = 0;
            int totalItemsSold = 0;
            int pendingOrders = 0;
            double todayRevenue = 0;
            int todayOrders = 0;

            if (productSnapshot.hasData) {
              totalProducts = productSnapshot.data!.docs.length;
            }

            if (orderSnapshot.hasData) {
              final now = DateTime.now();
              final todayStart = DateTime(now.year, now.month, now.day);

              for (var doc in orderSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status']?.toString().toLowerCase() ?? '';
                final price = (data['total_price'] ?? 0).toDouble();
                final quantity = (data['quantity'] ?? 1) as int;

                if (status == 'received') {
                  totalRevenue += price;
                  totalItemsSold += quantity;

                  // Check if order is from today
                  final orderDate = (data['order_date'] as Timestamp?)?.toDate();
                  if (orderDate != null && orderDate.isAfter(todayStart)) {
                    todayRevenue += price;
                    todayOrders++;
                  }
                } else if (status == 'pending' || status == 'preparing') {
                  pendingOrders++;
                }
              }
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Key Metrics
                  const Text(
                    'Key Metrics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: MediaQuery.of(context).size.width < 600 ? 1.2 : 1.5,
                    children: [
                      _buildStatCard(
                        'Total Revenue',
                        '₱${totalRevenue.toStringAsFixed(2)}',
                        Icons.money_rounded,
                        const Color(0xFF10b981),
                        'All-time',
                      ),
                      _buildStatCard(
                        'Items Sold',
                        totalItemsSold.toString(),
                        Icons.shopping_bag,
                        const Color(0xFF3b82f6),
                        'All-time',
                      ),
                      _buildStatCard(
                        'Total Products',
                        totalProducts.toString(),
                        Icons.inventory,
                        const Color(0xFF8b5cf6),
                        'Active',
                      ),
                      _buildStatCard(
                        'Pending Orders',
                        pendingOrders.toString(),
                        Icons.pending,
                        const Color(0xFFf59e0b),
                        'Awaiting Action',
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Today's Performance
                  const Text(
                    "Today's Performance",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width < 600 ? 1 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: MediaQuery.of(context).size.width < 600 ? 3 : 3,
                    children: [
                      _buildHighlightCard(
                        'Revenue (Today)',
                        '₱${todayRevenue.toStringAsFixed(2)}',
                        Icons.trending_up,
                        const Color(0xFF10b981),
                        'Real-time',
                      ),
                      _buildHighlightCard(
                        'Orders (Today)',
                        todayOrders.toString(),
                        Icons.shopping_cart,
                        const Color(0xFF3b82f6),
                        'Real-time',
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyProducts() {
    final authService = Provider.of<AuthService>(context);
    final sellerEmail = authService.currentUser?.email;

    if (sellerEmail == null) {
      return const Center(child: Text('Please login'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('products')
          .where('seller_email', isEqualTo: sellerEmail)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No products yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your first product to get started',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        final products = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index].data() as Map<String, dynamic>;
            final productId = products[index].id;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product['image_url'] ?? '',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image),
                    ),
                  ),
                ),
                title: Text(
                  product['name'] ?? 'Unnamed Product',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('₱${(product['price'] ?? 0).toStringAsFixed(2)}'),
                    Text('Stock: ${product['stock'] ?? 0}'),
                    Text(
                      'Sales: ${product['sales'] ?? 0}',
                      style: const TextStyle(color: Color(0xFF10b981)),
                    ),
                  ],
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteProduct(productId);
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteProduct(String productId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('products').doc(productId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildAddProduct() {
    return AddProductForm();
  }

  Widget _buildOrders() {
    final authService = Provider.of<AuthService>(context);
    final sellerEmail = authService.currentUser?.email;

    if (sellerEmail == null) {
      return const Center(child: Text('Please login'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('orders')
          .where('seller_email', isEqualTo: sellerEmail)
          .orderBy('order_date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No orders yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final orders = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index].data() as Map<String, dynamic>;
            final orderId = orders[index].id;
            final status = order['status']?.toString().toLowerCase() ?? 'pending';
            
            Color statusColor;
            switch (status) {
              case 'received':
                statusColor = const Color(0xFF10b981);
                break;
              case 'cancelled':
                statusColor = const Color(0xFFEF4444);
                break;
              case 'preparing':
              case 'prepared':
                statusColor = const Color(0xFFF59E0B);
                break;
              default:
                statusColor = const Color(0xFF3B82F6);
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.shopping_bag, color: statusColor),
                ),
                title: Text(
                  'Order #${orderId.substring(0, 8)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('₱${(order['total_price'] ?? 0).toStringAsFixed(2)}'),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOrderDetail('Product', order['product_name'] ?? 'N/A'),
                        _buildOrderDetail('Quantity', '${order['quantity'] ?? 1}'),
                        _buildOrderDetail('Buyer', order['buyer_email'] ?? 'N/A'),
                        _buildOrderDetail('Address', order['address'] ?? 'N/A'),
                        if (order['color'] != null && order['color'].toString().isNotEmpty)
                          _buildOrderDetail('Color', order['color']),
                        if (order['size'] != null && order['size'].toString().isNotEmpty)
                          _buildOrderDetail('Size', order['size']),
                        const SizedBox(height: 12),
                        if (status == 'pending')
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _updateOrderStatus(orderId, 'preparing'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10b981),
                                  ),
                                  child: const Text('Accept'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _updateOrderStatus(orderId, 'cancelled'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                            ],
                          ),
                        if (status == 'preparing')
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _updateOrderStatus(orderId, 'prepared'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10b981),
                              ),
                              child: const Text('Mark as Prepared'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOrderDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updated_at': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSalesReport() {
    final authService = Provider.of<AuthService>(context);
    final sellerEmail = authService.currentUser?.email;

    if (sellerEmail == null) {
      return const Center(child: Text('Please login'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('orders')
          .where('seller_email', isEqualTo: sellerEmail)
          .where('status', isEqualTo: 'received')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        double totalRevenue = 0;
        int totalOrders = 0;
        int totalItems = 0;
        Map<String, double> productSales = {};

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final price = (data['total_price'] ?? 0).toDouble();
            final quantity = (data['quantity'] ?? 1) as int;
            final productName = data['product_name'] ?? 'Unknown';

            totalRevenue += price;
            totalOrders++;
            totalItems += quantity;

            productSales[productName] = (productSales[productName] ?? 0) + price;
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sales Summary',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                'Total Revenue',
                '₱${totalRevenue.toStringAsFixed(2)}',
                Icons.money_rounded,
                const Color(0xFF10b981),
                'All completed orders',
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                'Total Orders',
                totalOrders.toString(),
                Icons.shopping_bag,
                const Color(0xFF3b82f6),
                'Completed orders',
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                'Items Sold',
                totalItems.toString(),
                Icons.inventory,
                const Color(0xFF8b5cf6),
                'Total items',
              ),
              const SizedBox(height: 24),
              const Text(
                'Top Products',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (productSales.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No sales data yet'),
                  ),
                )
              else
                ...productSales.entries.map((entry) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.trending_up, color: Color(0xFF10b981)),
                      title: Text(entry.key),
                      trailing: Text(
                        '₱${entry.value.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10b981),
                        ),
                      ),
                    ),
                  );
                }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfile() {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    if (user == null) {
      return const Center(child: Text('Please login'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: const Color(0xFF10b981),
            child: user.profilePic != null
                ? ClipOval(
                    child: Image.network(
                      user.profilePic!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  )
                : const Icon(Icons.person, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            '${user.firstName} ${user.lastName}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10b981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user.userType,
              style: const TextStyle(
                color: Color(0xFF10b981),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildProfileField('Email', user.email, Icons.email),
          _buildProfileField('Phone', user.phoneNumber, Icons.phone),
          _buildProfileField('Address', user.address, Icons.location_on),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to edit profile
                Navigator.pushNamed(context, '/profile');
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10b981),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField(String label, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF10b981)),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// Add Product Form Widget
class AddProductForm extends StatefulWidget {
  const AddProductForm({super.key});

  @override
  State<AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends State<AddProductForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  String? _selectedCategory;
  final List<String> _categories = [
    'Baby Clothes & Accessories',
    'Toys & Games',
    'Educational Materials',
    'Strollers & Gear',
    'Nursery Furniture',
    'Safety and Health',
  ];
  
  final List<Map<String, dynamic>> _variants = [];
  String? _selectedColor;
  String? _selectedSize;
  int _variantStock = 0;
  
  final List<String> _colors = [
    'Red', 'Orange', 'Yellow', 'Green', 'Blue', 'Purple',
    'Black', 'White', 'Brown', 'Pink', 'Gray', 'Multicolor', 'Mixed'
  ];
  
  // Sizes matching website seller dashboard
  final List<String> _sizes = [
    'Newborn', '0-3 months', '3-6 months', '6-9 months', '9-12 months',
    '12-18 months', '18-24 months', '2T', '3T', '4T', '5T',
    'Small', 'Medium', 'Large', 'One Size'
  ];
  
  List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _images = images;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  void _addVariant() {
    if (_selectedColor == null || _selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both color and size')),
      );
      return;
    }
    
    // Check for duplicate
    final exists = _variants.any((v) =>
        v['color'] == _selectedColor && v['size'] == _selectedSize);
    
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Variant "$_selectedColor - $_selectedSize" already exists')),
      );
      return;
    }
    
    setState(() {
      _variants.add({
        'color': _selectedColor!,
        'size': _selectedSize!,
        'stock': _variantStock,
      });
      _selectedColor = null;
      _selectedSize = null;
      _variantStock = 0;
    });
  }

  void _removeVariant(int index) {
    setState(() {
      _variants.removeAt(index);
    });
  }

  void _updateVariantStock(int index, int stock) {
    setState(() {
      _variants[index]['stock'] = stock;
    });
  }

  Future<void> _submitProduct() async {
    print('=== SELLER DASHBOARD: SUBMIT PRODUCT CALLED ===');
    print('Form valid: ${_formKey.currentState!.validate()}');
    print('Variants count: ${_variants.length}');
    print('Images count: ${_images.length}');
    
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }
    
    if (_variants.isEmpty) {
      print('No variants added');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one variant')),
      );
      return;
    }
    
    if (_images.isEmpty) {
      print('No images added');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product image')),
      );
      return;
    }
    
    final totalStock = _variants.fold<int>(0, (sum, v) => sum + (v['stock'] as int));
    print('Total stock: $totalStock');
    
    if (totalStock <= 0) {
      print('Total stock is 0');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Total stock must be greater than 0')),
      );
      return;
    }

    print('All validations passed, starting submission...');
    setState(() {
      _isSubmitting = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final sellerEmail = authService.currentUser?.email;
      
      if (sellerEmail == null) {
        throw Exception('User not authenticated');
      }

      print('=== STARTING IMAGE UPLOAD TO CLOUDINARY ===');
      print('Images to upload: ${_images.length}');
      
      // Upload images to Cloudinary
      final List<String> imageUrls = [];
      
      for (int i = 0; i < _images.length; i++) {
        final image = _images[i];
        print('--- Image ${i + 1}/${_images.length} ---');
        print('Path: ${image.path}');
        print('Name: ${image.name}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Uploading image ${i + 1}/${_images.length}...'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        
        try {
          // Convert XFile to File
          final File imageFile = File(image.path);
          print('Created File object');
          
          // Upload to Cloudinary
          print('Calling CloudinaryService.uploadProductImage...');
          final url = await CloudinaryService.uploadProductImage(
            imageFile,
            'temp_${DateTime.now().millisecondsSinceEpoch}',
          );
          
          print('✓ Upload SUCCESS! URL: $url');
          imageUrls.add(url);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image ${i + 1} uploaded!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 1),
              ),
            );
          }
        } catch (e) {
          print('✗ Upload FAILED: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload image ${i + 1}: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          throw e;
        }
      }

      print('=== ALL UPLOADS COMPLETE ===');
      print('Total URLs: ${imageUrls.length}');
      
      if (imageUrls.isEmpty) {
        print('ERROR: No images uploaded!');
        throw Exception('No images were uploaded successfully');
      }
      
      final productId = 'P${DateTime.now().millisecondsSinceEpoch}${(1000 + (9999 - 1000) * (DateTime.now().microsecond / 1000000)).toInt()}';
      
      print('Creating product with ID: $productId');
      
      final productData = {
        'product_id': productId,
        'name': _nameController.text,
        'category': _selectedCategory,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'image_url': imageUrls.first,
        'image_urls': imageUrls,
        'seller_email': sellerEmail,
        'stock': totalStock,
        'variants': _variants,
        'created_at': FieldValue.serverTimestamp(),
        'sales': 0,
      };

      print('Saving product to Firestore...');
      final productService = ProductManagementService();
      final result = await productService.addProduct(productData);
      
      if (result['success']) {
        print('Product saved successfully!');
        
        if (mounted) {
          // Hide uploading message
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        // Reset form
        _formKey.currentState!.reset();
        setState(() {
          _nameController.clear();
          _descriptionController.clear();
          _priceController.clear();
          _selectedCategory = null;
          _variants.clear();
          _images.clear();
        });
      } else {
        throw Exception(result['error'] ?? 'Failed to add product');
      }
    } catch (e) {
      print('Error adding product: $e');
      if (mounted) {
        // Hide uploading message
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Information Section
            _buildSectionHeader('Basic Information'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nameController,
              label: 'Product Name',
              hint: 'Enter product name',
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter product name' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Enter product description',
              maxLines: 3,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter description' : null,
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Category',
              value: _selectedCategory,
              items: _categories,
              onChanged: (value) => setState(() => _selectedCategory = value),
              validator: (value) =>
                  value == null ? 'Please select a category' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _priceController,
              label: 'Price (PHP)',
              hint: 'Enter price',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please enter price';
                if (double.tryParse(value!) == null) return 'Invalid price';
                return null;
              },
            ),
            
            const SizedBox(height: 32),
            
            // Variants Section
            _buildSectionHeader('Product Variants'),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            label: 'Color',
                            value: _selectedColor,
                            items: _colors,
                            onChanged: (value) => setState(() => _selectedColor = value),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown(
                            label: 'Size',
                            value: _selectedSize,
                            items: _sizes,
                            onChanged: (value) => setState(() => _selectedSize = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      label: 'Stock Quantity',
                      hint: 'Enter stock',
                      keyboardType: TextInputType.number,
                      initialValue: _variantStock.toString(),
                      onChanged: (value) =>
                          _variantStock = int.tryParse(value) ?? 0,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addVariant,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Variant'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10b981),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Variants Table
            if (_variants.isNotEmpty) ...[
              Card(
                elevation: 2,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      child: Row(
                        children: const [
                          Expanded(child: Text('Color', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(child: Text('Size', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(child: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold))),
                          SizedBox(width: 48),
                        ],
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _variants.length,
                      itemBuilder: (context, index) {
                        final variant = _variants[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey[200]!),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.pink[50],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    variant['color'].toString(),
                                    style: TextStyle(color: Colors.pink[700]),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    variant['size'],
                                    style: TextStyle(color: Colors.blue[700]),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: variant['stock'].toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) => _updateVariantStock(
                                      index, int.tryParse(value) ?? 0),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeVariant(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Total Stock: ${_variants.fold<int>(0, (sum, v) => sum + (v['stock'] as int))}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Images Section
            _buildSectionHeader('Product Images'),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: InkWell(
                onTap: _pickImages,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.cloud_upload,
                        size: 48,
                        color: Colors.blue[300],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Drop your images here, or browse',
                        style: TextStyle(fontSize: 16),
                      ),
                      const Text(
                        'JPEG, PNG formats are allowed',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            if (_images.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_images[index].path),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_images.length} image(s) selected',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Submit Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            _formKey.currentState!.reset();
                            setState(() {
                              _nameController.clear();
                              _descriptionController.clear();
                              _priceController.clear();
                              _selectedCategory = null;
                              _variants.clear();
                              _images.clear();
                            });
                          },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10b981),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Add Product'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    String? label,
    String? hint,
    String? initialValue,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          validator: validator,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDropdown({
    String? label,
    String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ))
              .toList(),
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }
}

