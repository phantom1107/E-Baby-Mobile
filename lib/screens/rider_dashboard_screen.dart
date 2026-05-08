import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'rider_available_orders_screen.dart';
import 'rider_my_deliveries_screen.dart';
import 'rider_earnings_screen.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  int _selectedIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard, 'title': 'Dashboard'},
    {'icon': Icons.delivery_dining, 'title': 'Available Orders'},
    {'icon': Icons.local_shipping, 'title': 'My Deliveries'},
    {'icon': Icons.money, 'title': 'Earnings'},
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
          title: const Text('Rider Portal'),
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
    final userEmail = authService.currentUser?.email ?? 'Rider';

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
                      child: const Icon(Icons.motorcycle, color: Colors.white, size: 48),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Rider Portal',
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
                child: Icon(Icons.motorcycle, color: Colors.white, size: 20),
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
        return const RiderAvailableOrdersScreen();
      case 2:
        return const RiderMyDeliveriesScreen();
      case 3:
        return const RiderEarningsScreen();
      default:
        return const Center(child: Text('Coming Soon'));
    }
  }

  Widget _buildDashboard() {
    final authService = Provider.of<AuthService>(context);
    final riderEmail = authService.currentUser?.email;

    if (riderEmail == null) {
      return const Center(child: Text('Please login'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('rider_earnings')
          .where('rider_email', isEqualTo: riderEmail)
          .where('status', isEqualTo: 'Completed')
          .snapshots(),
      builder: (context, earningsSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('orders')
              .where('rider_email', isEqualTo: riderEmail)
              .snapshots(),
          builder: (context, riderOrderSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('orders')
                  .where('status', isEqualTo: 'Prepared')
                  .snapshots(),
              builder: (context, availableSnapshot) {
                int totalDeliveries = 0;
                int availableOrders = 0;
                int activeDeliveries = 0;
                double totalEarnings = 0;
                double todayEarnings = 0;

                // Count available orders (Prepared status with no rider)
                if (availableSnapshot.hasData) {
                  availableOrders = availableSnapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final riderEmail = data['rider_email'];
                    return riderEmail == null || riderEmail.toString().isEmpty;
                  }).length;
                }

                // Count deliveries
                if (riderOrderSnapshot.hasData) {
                  for (var doc in riderOrderSnapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status']?.toString() ?? '';

                    if (status == 'Delivered') {
                      totalDeliveries++;
                    } else if (status == 'Shipping') {
                      activeDeliveries++;
                    }
                  }
                }

                // Calculate earnings from rider_earnings collection
                if (earningsSnapshot.hasData) {
                  final now = DateTime.now();
                  final todayStart = DateTime(now.year, now.month, now.day);

                  for (var doc in earningsSnapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final earned = (data['total_earned'] ?? 0).toDouble();
                    totalEarnings += earned;

                    // Check if today
                    final date = (data['date'] as Timestamp?)?.toDate();
                    if (date != null && date.isAfter(todayStart)) {
                      todayEarnings += earned;
                    }
                  }
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                            'Total Deliveries',
                            totalDeliveries.toString(),
                            Icons.check_circle,
                            const Color(0xFF10B981),
                            'Completed',
                          ),
                          _buildStatCard(
                            'Available Orders',
                            availableOrders.toString(),
                            Icons.delivery_dining,
                            const Color(0xFFF59E0B),
                            'Ready to pickup',
                          ),
                          _buildStatCard(
                            'Active Deliveries',
                            activeDeliveries.toString(),
                            Icons.local_shipping,
                            const Color(0xFF3B82F6),
                            'In progress',
                          ),
                          _buildStatCard(
                            'Total Earnings',
                            '₱${totalEarnings.toStringAsFixed(2)}',
                            Icons.money,
                            const Color(0xFF7C3AED),
                            'All-time',
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        "Today's Performance",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF10B981).withOpacity(0.1),
                                const Color(0xFF10B981).withOpacity(0.05),
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
                                  color: const Color(0xFF10B981),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.trending_up,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Earnings Today',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₱${todayEarnings.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Real-time',
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
                      ),
                    ],
                  ),
                );
              },
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
}
