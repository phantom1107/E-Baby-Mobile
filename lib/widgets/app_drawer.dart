import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Color(0xFF7C3AED)),
                ),
                const SizedBox(height: 10),
                Text(
                  user != null
                      ? '${user.firstName} ${user.lastName}'
                      : 'Guest',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user?.email ?? 'Not logged in',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pushReplacementNamed(context, '/'),
          ),
          const Divider(),
          if (authService.isLoggedIn) ...[
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () => Navigator.pushNamed(context, '/profile'),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: const Text('Orders'),
              onTap: () => Navigator.pushNamed(context, '/orders'),
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Wishlist'),
              onTap: () => Navigator.pushNamed(context, '/wishlist'),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Cart'),
              onTap: () => Navigator.pushNamed(context, '/cart'),
            ),
            if (user?.userType == 'Seller') ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('Seller Dashboard'),
                onTap: () => Navigator.pushNamed(context, '/seller_dashboard'),
              ),
              ListTile(
                leading: const Icon(Icons.inventory),
                title: const Text('My Products'),
                onTap: () => Navigator.pushNamed(context, '/seller_products'),
              ),
            ],
            if (user?.userType == 'Rider') ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('Rider Dashboard'),
                onTap: () => Navigator.pushNamed(context, '/rider_dashboard'),
              ),
            ],
            if (user?.userType == 'Admin') ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Admin Dashboard'),
                onTap: () => Navigator.pushNamed(context, '/admin_dashboard'),
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('User Management'),
                onTap: () =>
                    Navigator.pushNamed(context, '/admin_user_management'),
              ),
            ],
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                authService.logout();
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Login'),
              onTap: () => Navigator.pushNamed(context, '/auth'),
            ),
          ],
        ],
      ),
    );
  }
}
