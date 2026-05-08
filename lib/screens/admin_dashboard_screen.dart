import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'admin_user_management_screen.dart';
import 'admin_registration_requests_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard, 'title': 'Dashboard'},
    {'icon': Icons.people, 'title': 'User Management'},
    {'icon': Icons.person_add, 'title': 'Registration Requests'},
    {'icon': Icons.store, 'title': 'Seller Products'},
    {'icon': Icons.picture_as_pdf, 'title': 'Reports'},
    {'icon': Icons.receipt_long, 'title': 'Order Report'},
    {'icon': Icons.flag, 'title': 'Reported Accounts'},
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: isMobile ? AppBar(
          backgroundColor: const Color(0xFF7C3AED),
          foregroundColor: Colors.white,
          title: const Text('Admin Portal'),
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
                      child: const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Admin Portal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'System Administrator',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
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
                      color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: Icon(
                        item['icon'],
                        color: Colors.white,
                      ),
                      title: Text(
                        item['title'],
                        style: TextStyle(
                          color: Colors.white,
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
              leading: const Icon(Icons.logout, color: Colors.white),
              title: const Text('Logout', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
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
    return Row(
      children: [
        Container(
          width: 250,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
            ),
          ),
          child: _buildDrawer(),
        ),
        Expanded(child: _buildContent()),
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
                backgroundColor: Color(0xFF7C3AED),
                child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
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
        return const AdminUserManagementScreen();
      case 2:
        return const AdminRegistrationRequestsScreen();
      case 3:
        return _buildComingSoon('Seller Products');
      case 4:
        return _buildComingSoon('Reports');
      case 5:
        return _buildComingSoon('Order Report');
      case 6:
        return _buildComingSoon('Reported Accounts');
      default:
        return _buildComingSoon('Unknown Section');
    }
  }

  Widget _buildComingSoon(String feature) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            '$feature',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This feature is coming soon!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'re working hard to bring this to you.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, userSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('orders').snapshots(),
          builder: (context, orderSnapshot) {
            int totalBuyers = 0;
            int totalSellers = 0;
            int totalRiders = 0;
            int pendingRequests = 0;
            double totalRevenue = 0;
            double todayRevenue = 0;
            int totalOrders = 0;
            int todayOrders = 0;

            if (userSnapshot.hasData) {
              for (var doc in userSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final userType = data['user_type']?.toString() ?? '';
                final status = data['status']?.toString() ?? '';

                if (status == 'pending') {
                  pendingRequests++;
                } else if (status == 'active') {
                  if (userType == 'Buyer') totalBuyers++;
                  else if (userType == 'Seller') totalSellers++;
                  else if (userType == 'Rider') totalRiders++;
                }
              }
            }

            if (orderSnapshot.hasData) {
              final now = DateTime.now();
              final todayStart = DateTime(now.year, now.month, now.day);

              for (var doc in orderSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status']?.toString() ?? '';

                if (status == 'Received') {
                  totalOrders++;
                  final price = (data['total_price'] ?? 0).toDouble();
                  totalRevenue += price;

                  final orderDate = (data['order_date'] as Timestamp?)?.toDate();
                  if (orderDate != null && orderDate.isAfter(todayStart)) {
                    todayRevenue += price;
                    todayOrders++;
                  }
                }
              }
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'System Overview',
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
                        'Total Buyers',
                        totalBuyers.toString(),
                        Icons.shopping_bag,
                        const Color(0xFF3B82F6),
                        'Active users',
                      ),
                      _buildStatCard(
                        'Total Sellers',
                        totalSellers.toString(),
                        Icons.store,
                        const Color(0xFF10B981),
                        'Active sellers',
                      ),
                      _buildStatCard(
                        'Total Riders',
                        totalRiders.toString(),
                        Icons.motorcycle,
                        const Color(0xFFF59E0B),
                        'Active riders',
                      ),
                      _buildStatCard(
                        'Pending Requests',
                        pendingRequests.toString(),
                        Icons.pending,
                        const Color(0xFFEF4444),
                        'Awaiting approval',
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Revenue & Orders',
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
                        'Revenue Today',
                        '₱${todayRevenue.toStringAsFixed(2)}',
                        Icons.trending_up,
                        const Color(0xFF10B981),
                        '$todayOrders orders',
                      ),
                      _buildHighlightCard(
                        'Total Revenue',
                        '₱${totalRevenue.toStringAsFixed(2)}',
                        Icons.account_balance_wallet,
                        const Color(0xFF7C3AED),
                        '$totalOrders orders',
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
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
}
