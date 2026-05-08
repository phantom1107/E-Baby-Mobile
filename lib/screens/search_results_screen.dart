import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../widgets/product_card.dart';

class SearchResultsScreen extends StatefulWidget {
  final String? initialQuery;
  final String? category;

  const SearchResultsScreen({
    super.key,
    this.initialQuery,
    this.category,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String _sortBy = 'name'; // name, price_low, price_high, newest
  double _minPrice = 0;
  double _maxPrice = 10000;
  double _currentMinPrice = 0;
  double _currentMaxPrice = 10000;
  Set<String> _selectedCategories = {}; // Changed to Set for multi-select

  final List<String> _categories = [
    'Baby Clothes & Accessories',
    'Toys & Games',
    'Educational Materials',
    'Strollers & Gear',
    'Nursery Furniture',
    'Safety and Health',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery ?? '';
    if (widget.category != null) {
      _selectedCategories.add(widget.category!);
    }
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      List<Product> products;
      
      if (_selectedCategories.isNotEmpty) {
        // Load products from all selected categories
        Set<Product> allCategoryProducts = {};
        for (String category in _selectedCategories) {
          final categoryProducts = await ProductService.getProductsByCategory(category);
          allCategoryProducts.addAll(categoryProducts);
        }
        products = allCategoryProducts.toList();
      } else if (_searchController.text.isNotEmpty) {
        products = await ProductService.searchProducts(_searchController.text);
      } else {
        products = await ProductService.getFeaturedProducts();
      }

      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      print('Error loading products: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        // Price filter
        if (product.price < _currentMinPrice || product.price > _currentMaxPrice) {
          return false;
        }
        
        // Category filter - check if product category is in selected categories
        if (_selectedCategories.isNotEmpty) {
          if (!_selectedCategories.contains(product.category)) {
            return false;
          }
        }
        
        return true;
      }).toList();

      // Apply sorting
      _applySorting();
    });
  }

  void _applySorting() {
    switch (_sortBy) {
      case 'name':
        _filteredProducts.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'price_low':
        _filteredProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        _filteredProducts.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'newest':
        _filteredProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
  }

  void _showFilterDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          _currentMinPrice = _minPrice;
                          _currentMaxPrice = _maxPrice;
                          _selectedCategories.clear();
                        });
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Filter content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Price Range
                    const Text(
                      'Price Range',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text('₱${_currentMinPrice.toInt()}'),
                        const Spacer(),
                        Text('₱${_currentMaxPrice.toInt()}'),
                      ],
                    ),
                    RangeSlider(
                      values: RangeValues(_currentMinPrice, _currentMaxPrice),
                      min: _minPrice,
                      max: _maxPrice,
                      divisions: 100,
                      activeColor: const Color(0xFF7C3AED),
                      onChanged: (values) {
                        setModalState(() {
                          _currentMinPrice = values.start;
                          _currentMaxPrice = values.end;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    // Category (Multi-select)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Categories',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_selectedCategories.isNotEmpty)
                          Text(
                            '${_selectedCategories.length} selected',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7C3AED),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((category) {
                        final isSelected = _selectedCategories.contains(category);
                        return FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                _selectedCategories.add(category);
                              } else {
                                _selectedCategories.remove(category);
                              }
                            });
                          },
                          selectedColor: const Color(0xFF7C3AED).withOpacity(0.2),
                          checkmarkColor: const Color(0xFF7C3AED),
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFF7C3AED) : Colors.black87,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              // Apply button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _applyFilters();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
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
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Sort By',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          _buildSortOption('Name (A-Z)', 'name'),
          _buildSortOption('Price: Low to High', 'price_low'),
          _buildSortOption('Price: High to Low', 'price_high'),
          _buildSortOption('Newest First', 'newest'),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSortOption(String label, String value) {
    final isSelected = _sortBy == value;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? const Color(0xFF7C3AED) : Colors.black87,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: Color(0xFF7C3AED))
          : null,
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
        _applyFilters();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search for baby products...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      _searchController.clear();
                      _loadProducts();
                    },
                  )
                : null,
          ),
          onSubmitted: (value) => _loadProducts(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter and Sort bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showFilterDrawer,
                    icon: const Icon(Icons.filter_list, size: 20),
                    label: Text(
                      _selectedCategories.isNotEmpty
                          ? '${_selectedCategories.length} ${_selectedCategories.length == 1 ? 'Category' : 'Categories'}'
                          : 'Filter',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7C3AED),
                      side: const BorderSide(color: Color(0xFF7C3AED)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showSortOptions,
                    icon: const Icon(Icons.sort, size: 20),
                    label: const Text('Sort'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7C3AED),
                      side: const BorderSide(color: Color(0xFF7C3AED)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Results count
          if (!_isLoading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.grey[100],
              child: Text(
                '${_filteredProducts.length} ${_filteredProducts.length == 1 ? 'result' : 'results'} found',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
            ),
          // Products grid
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Searching products...',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : _filteredProducts.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadProducts,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            return ProductCard(product: _filteredProducts[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'No Products Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Try adjusting your search or filters',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _selectedCategories.clear();
                  _currentMinPrice = _minPrice;
                  _currentMaxPrice = _maxPrice;
                });
                _loadProducts();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Clear Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
