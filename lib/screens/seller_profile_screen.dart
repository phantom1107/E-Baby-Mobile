import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';

class SellerProfileScreen extends StatefulWidget {
  final String sellerEmail;
  final String? sellerName;

  const SellerProfileScreen({
    super.key,
    required this.sellerEmail,
    this.sellerName,
  });

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  Map<String, dynamic>? sellerData;
  List<Product> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSellerData();
  }

  Future<void> _loadSellerData() async {
    setState(() => isLoading = true);
    try {
      // Load seller information
      final sellerQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.sellerEmail)
          .limit(1)
          .get();

      if (sellerQuery.docs.isNotEmpty) {
        sellerData = sellerQuery.docs.first.data();
      }

      // Load seller's products
      final productsQuery = await FirebaseFirestore.instance
          .collection('products')
          .where('seller_email', isEqualTo: widget.sellerEmail)
          .get();

      products = productsQuery.docs
          .map((doc) => Product.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error loading seller data: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sellerName = sellerData != null
        ? '${sellerData!['first_name'] ?? ''} ${sellerData!['last_name'] ?? ''}'.trim()
        : widget.sellerName ?? 'Seller';

    return Scaffold(
      appBar: AppBar(
        title: Text(sellerName),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSellerData,
              child: CustomScrollView(
                slivers: [
                  // Seller Info Header
                  SliverToBoxAdapter(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: const Color(0xFF7C3AED),
                            child: Text(
                              sellerName.isNotEmpty ? sellerName[0].toUpperCase() : 'S',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            sellerName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.sellerEmail,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatCard(
                                'Products',
                                products.length.toString(),
                                Icons.inventory,
                              ),
                              _buildStatCard(
                                'Total Sales',
                                products.fold(0, (sum, p) => sum + p.sales).toString(),
                                Icons.shopping_bag,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Products Section
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Products (${products.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Products Grid
                  products.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No Products Yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return ProductCard(product: products[index]);
                              },
                              childCount: products.length,
                            ),
                          ),
                        ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 20),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF7C3AED), size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
