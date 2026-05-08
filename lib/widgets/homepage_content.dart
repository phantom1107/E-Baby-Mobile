import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../widgets/product_card.dart';
import '../widgets/gradient_text.dart';
import '../screens/main_navigation_screen.dart';

class HomepageContent extends StatefulWidget {
  const HomepageContent({super.key});

  @override
  State<HomepageContent> createState() => _HomepageContentState();
}

class _HomepageContentState extends State<HomepageContent> {
  List<Product> featuredProducts = [];
  List<Product> newArrivals = [];
  bool isLoading = true;
  int currentCarouselIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> carouselItems = [
    {
      'image': 'assets/images/carousel/carousel1.jpg',
      'title': 'Premium Baby Clothes',
      'subtitle': 'Soft, comfortable, and stylish',
    },
    {
      'image': 'assets/images/carousel/carousel2.jpg',
      'title': 'Educational Toys',
      'subtitle': 'Fun and learning combined',
    },
    {
      'image': 'assets/images/carousel/carousel3.jpg',
      'title': 'Nursery Furniture',
      'subtitle': 'Safe and beautiful',
    },
  ];

  final List<Map<String, dynamic>> categories = [
    {'name': 'Baby Clothes & Accessories', 'icon': Icons.child_care},
    {'name': 'Toys & Games', 'icon': Icons.toys},
    {'name': 'Educational Materials', 'icon': Icons.book},
    {'name': 'Strollers & Gear', 'icon': Icons.stroller},
    {'name': 'Nursery Furniture', 'icon': Icons.bed},
    {'name': 'Safety and Health', 'icon': Icons.health_and_safety},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final featured = await ProductService.getFeaturedProducts();
      final arrivals = await ProductService.getNewArrivals();
      if (mounted) {
        setState(() {
          featuredProducts = featured;
          newArrivals = arrivals;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        elevation: 0,
        automaticallyImplyLeading: false, // Remove back arrow
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo/ebaby_logo.png',
              height: 32,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.baby_changing_station,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'E-Baby',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: Colors.white, size: 28),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  // Navigate to main navigation with profile tab (index 4)
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainNavigationScreen(initialIndex: 4),
                    ),
                    (route) => false,
                  );
                  break;
                case 'orders':
                  // Navigate to main navigation with orders tab (index 3)
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainNavigationScreen(initialIndex: 3),
                    ),
                    (route) => false,
                  );
                  break;
                case 'logout':
                  authService.logout();
                  break;
                case 'login':
                  Navigator.pushNamed(context, '/auth');
                  break;
              }
            },
            itemBuilder: (context) => [
              if (authService.isLoggedIn) ...[
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 20),
                      SizedBox(width: 8),
                      Text('Profile'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'orders',
                  child: Row(
                    children: [
                      Icon(Icons.shopping_bag, size: 20),
                      SizedBox(width: 8),
                      Text('Orders'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Logout', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ] else ...[
                const PopupMenuItem(
                  value: 'login',
                  child: Row(
                    children: [
                      Icon(Icons.login, size: 20),
                      SizedBox(width: 8),
                      Text('Login'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),
                    _buildCarousel(),
                    _buildCategoriesSection(),
                    _buildFeaturedSection(),
                    if (newArrivals.isNotEmpty) _buildNewArrivalsSection(),
                    const SizedBox(height: 80), // Space for bottom nav
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: const Color(0xFF7C3AED),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search for baby products...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            suffixIcon: IconButton(
              icon: const Icon(Icons.search, color: Color(0xFF7C3AED)),
              onPressed: () {
                if (_searchController.text.isNotEmpty) {
                  Navigator.pushNamed(
                    context,
                    '/search_results',
                    arguments: {'query': _searchController.text},
                  );
                }
              },
            ),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              Navigator.pushNamed(
                context,
                '/search_results',
                arguments: {'query': value},
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildCarousel() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 200,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 4),
        enlargeCenterPage: true,
        viewportFraction: 0.9,
        onPageChanged: (index, reason) {
          setState(() => currentCarouselIndex = index);
        },
      ),
      items: carouselItems.map((item) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      item['image']!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['subtitle']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildCategoriesSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shop by Category',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return InkWell(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/search_results',
                    arguments: {'category': category['name']},
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        category['icon'] as IconData,
                        size: 32,
                        color: const Color(0xFF7C3AED),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category['name'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GradientText(
            'Featured Products',
            colors: [Color(0xFF7C3AED), Color(0xFFD97706)],
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 4),
          Text(
            'Handpicked selections from our best sellers',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          featuredProducts.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No featured products available'),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: featuredProducts.length,
                  itemBuilder: (context, index) {
                    return ProductCard(product: featuredProducts[index]);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildNewArrivalsSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GradientText(
            'New Arrivals',
            colors: [Color(0xFF7C3AED), Color(0xFFD97706)],
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 4),
          Text(
            'Latest products just added',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: newArrivals.length,
            itemBuilder: (context, index) {
              return ProductCard(product: newArrivals[index]);
            },
          ),
        ],
      ),
    );
  }
}
