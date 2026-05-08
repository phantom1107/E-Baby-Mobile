import 'package:flutter/material.dart';

class Footer extends StatefulWidget {
  const Footer({super.key});

  @override
  State<Footer> createState() => _FooterState();
}

class _FooterState extends State<Footer> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1F3A),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main footer content - responsive grid
              Wrap(
                spacing: 24,
                runSpacing: 32,
                children: [
                  // Brand section
                  _buildBrandSection(),
                  // Quick Links
                  _buildQuickLinksSection(),
                  // Get in Touch
                  _buildGetInTouchSection(),
                  // Newsletter
                  _buildNewsletterSection(),
                ],
              ),
              const SizedBox(height: 32),
              const Divider(color: Color(0xFF2D3548), height: 1),
              const SizedBox(height: 20),
              // Bottom footer
              _buildBottomFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandSection() {
    return SizedBox(
      width: MediaQuery.of(context).size.width < 600 ? double.infinity : 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo and brand name (local asset, no database)
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/logo/ebaby_logo.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEC1C24), Color(0xFFF39200)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'e',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'E-Baby',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Your premier destination for quality baby products from trusted sellers.',
            style: TextStyle(
              color: Color(0xFFB0B8C8),
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          // Social icons
          Row(
            children: [
              _buildSocialIcon(Icons.facebook),
              const SizedBox(width: 12),
              _buildSocialIcon(Icons.camera_alt),
              const SizedBox(width: 12),
              _buildSocialIcon(Icons.tag),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF2D3548),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Icon(
        icon,
        color: const Color(0xFFEC1C24),
        size: 18,
      ),
    );
  }

  Widget _buildQuickLinksSection() {
    return SizedBox(
      width: MediaQuery.of(context).size.width < 600 ? double.infinity : 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'QUICK LINKS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEC1C24), Color(0xFFF39200)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          _buildFooterLink('About Us'),
          const SizedBox(height: 12),
          _buildFooterLink('Contact Us'),
          const SizedBox(height: 12),
          _buildFooterLink('FAQ'),
          const SizedBox(height: 12),
          _buildFooterLink('Shipping Info'),
        ],
      ),
    );
  }

  Widget _buildGetInTouchSection() {
    return SizedBox(
      width: MediaQuery.of(context).size.width < 600 ? double.infinity : 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GET IN TOUCH',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEC1C24), Color(0xFFF39200)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          _buildContactItem(
            icon: Icons.email_outlined,
            text: 'ebabyservices@gmail.com',
          ),
          const SizedBox(height: 16),
          _buildContactItem(
            icon: Icons.phone_outlined,
            text: '+63 965 133 7681',
          ),
          const SizedBox(height: 16),
          _buildContactItem(
            icon: Icons.location_on_outlined,
            text: 'Philippines',
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xFFEC1C24),
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFB0B8C8),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewsletterSection() {
    return SizedBox(
      width: MediaQuery.of(context).size.width < 600 ? double.infinity : 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NEWSLETTER',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEC1C24), Color(0xFFF39200)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Subscribe for updates and exclusive offers',
            style: TextStyle(
              color: Color(0xFFB0B8C8),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: 'Your email',
              hintStyle: const TextStyle(color: Color(0xFF5A6478)),
              filled: true,
              fillColor: const Color(0xFF2D3548),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                // Handle subscription
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thank you for subscribing!')),
                );
                _emailController.clear();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC1C24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                'Subscribe',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFB0B8C8),
          fontSize: 13,
          height: 1.8,
        ),
      ),
    );
  }

  Widget _buildBottomFooter() {
    return Column(
      children: [
        if (MediaQuery.of(context).size.width < 600)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '© 2025 E-Baby. All rights reserved.',
                style: TextStyle(
                  color: Color(0xFF5A6478),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                children: [
                  _buildBottomLink('Privacy Policy'),
                  _buildBottomLink('Terms & Conditions'),
                  _buildBottomLink('Cookie Policy'),
                ],
              ),
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '© 2025 E-Baby. All rights reserved.',
                style: TextStyle(
                  color: Color(0xFF5A6478),
                  fontSize: 12,
                ),
              ),
              Row(
                children: [
                  _buildBottomLink('Privacy Policy'),
                  const SizedBox(width: 24),
                  _buildBottomLink('Terms & Conditions'),
                  const SizedBox(width: 24),
                  _buildBottomLink('Cookie Policy'),
                ],
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildBottomLink(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF5A6478),
        fontSize: 12,
      ),
    );
  }
}
