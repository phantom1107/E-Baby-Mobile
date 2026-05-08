import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // E-Baby Logo
                  SizedBox(
                    height: 80,
                    child: Image.asset(
                      'assets/images/logo/ebaby_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Welcome heading
                  const Text(
                    'Welcome to E-Baby!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  const Text(
                    'Discover premium baby products from trusted sellers',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Member Benefits Box
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      border: const Border(
                        left: BorderSide(
                          color: Color(0xFF7C3AED),
                          width: 4,
                        ),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Member Benefits:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildBenefit(
                          icon: Icons.favorite_border,
                          text: 'Save your favorite products to a wishlist',
                        ),
                        const SizedBox(height: 12),
                        _buildBenefit(
                          icon: Icons.shopping_cart_outlined,
                          text: 'Manage your shopping cart seamlessly',
                        ),
                        const SizedBox(height: 12),
                        _buildBenefit(
                          icon: Icons.local_shipping_outlined,
                          text: 'Track your orders in real-time',
                        ),
                        const SizedBox(height: 12),
                        _buildBenefit(
                          icon: Icons.loyalty,
                          text: 'Exclusive deals for registered members',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Sign In Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/auth'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login, size: 20, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/auth'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add, size: 20, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Register',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Continue as Guest Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pushNamed(context, '/home'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFDDD),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close, size: 20, color: Colors.black54),
                          SizedBox(width: 8),
                          Text(
                            'Continue as Guest',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefit({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xFF7C3AED),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF555555),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
