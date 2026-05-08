import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/firestore_repository.dart';

class VariantSelectorSheet extends StatefulWidget {
  final Product product;

  const VariantSelectorSheet({super.key, required this.product});

  @override
  State<VariantSelectorSheet> createState() => _VariantSelectorSheetState();
}

class _VariantSelectorSheetState extends State<VariantSelectorSheet> {
  List<ProductVariant> variants = [];
  bool isLoading = true;
  String? selectedColor;
  String? selectedSize;
  ProductVariant? selectedVariant;
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    _loadVariants();
  }

  Future<void> _loadVariants() async {
    setState(() => isLoading = true);
    try {
      // Load product document to get variants array
      final doc = await FirestoreRepository.productsRef.doc(widget.product.productId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        
        // Load variants from the product document's variants array
        if (data['variants'] != null && data['variants'] is List) {
          variants = (data['variants'] as List).map((variantData) {
            return ProductVariant(
              id: '${widget.product.productId}_${variantData['color']}_${variantData['size']}',
              productId: widget.product.productId,
              color: variantData['color']?.toString() ?? '',
              size: variantData['size']?.toString() ?? '',
              stock: int.tryParse(variantData['stock']?.toString() ?? '0') ?? 0,
            );
          }).toList();
        }

        // Auto-select first variant if available
        if (variants.isNotEmpty) {
          selectedColor = variants.first.color;
          selectedSize = variants.first.size;
          _updateSelectedVariant();
        }
      }
    } catch (e) {
      print('Error loading variants: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _updateSelectedVariant() {
    if (selectedColor != null && selectedSize != null) {
      try {
        selectedVariant = variants.firstWhere(
          (v) => v.color == selectedColor && v.size == selectedSize,
        );
        // Reset quantity if it exceeds new variant stock
        if (quantity > selectedVariant!.stock) {
          quantity = selectedVariant!.stock > 0 ? 1 : 0;
        }
      } catch (_) {
        selectedVariant = null;
      }
    }
  }

  List<String> get availableColors {
    return variants.map((v) => v.color).toSet().toList();
  }

  List<String> get availableSizes {
    if (selectedColor == null) return [];
    return variants
        .where((v) => v.color == selectedColor)
        .map((v) => v.size)
        .toSet()
        .toList();
  }

  Future<void> _addToCart() async {
    if (selectedVariant == null) {
      _showMessage('Please select color and size', isError: true);
      return;
    }

    if (selectedVariant!.stock < quantity) {
      _showMessage('Not enough stock available', isError: true);
      return;
    }

    if (quantity <= 0) {
      _showMessage('Please select quantity', isError: true);
      return;
    }

    final cartService = Provider.of<CartService>(context, listen: false);
    final result = await cartService.addToCart({
      'product_id': widget.product.productId,
      'name': widget.product.name,
      'price': widget.product.price,
      'quantity': quantity,
      'color': selectedColor!,
      'size': selectedSize!,
      'image': widget.product.image,
      'seller_email': widget.product.sellerEmail,
    });

    if (!mounted) return;

    if (result['success']) {
      Navigator.pop(context);
      _showMessage(result['message'] ?? 'Added to cart', isError: false);
    } else {
      _showMessage(result['error'] ?? 'Failed to add to cart', isError: true);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.product.image,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₱${widget.product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  if (isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (variants.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No variants available'),
                      ),
                    )
                  else ...[
                    // Color selector
                    if (availableColors.isNotEmpty) ...[
                      const Text(
                        'Color',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableColors.map((color) {
                          final isSelected = selectedColor == color;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedColor = color;
                                selectedSize = null;
                                _updateSelectedVariant();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF7C3AED)
                                    : Colors.white,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF7C3AED)
                                      : Colors.grey[300]!,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                color,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Size selector
                    if (availableSizes.isNotEmpty) ...[
                      const Text(
                        'Size',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableSizes.map((size) {
                          final isSelected = selectedSize == size;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedSize = size;
                                _updateSelectedVariant();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF7C3AED)
                                    : Colors.white,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF7C3AED)
                                      : Colors.grey[300]!,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                size,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Stock info
                    if (selectedVariant != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selectedVariant!.stock > 0
                              ? const Color(0xFF10B981).withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selectedVariant!.stock > 0
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: selectedVariant!.stock > 0
                                  ? const Color(0xFF10B981)
                                  : Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              selectedVariant!.stock > 0
                                  ? 'Stock: ${selectedVariant!.stock} available'
                                  : 'Out of stock',
                              style: TextStyle(
                                color: selectedVariant!.stock > 0
                                    ? const Color(0xFF10B981)
                                    : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Quantity selector
                    if (selectedVariant != null && selectedVariant!.stock > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Quantity',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 18),
                                  onPressed: quantity > 1
                                      ? () => setState(() => quantity--)
                                      : null,
                                  color: const Color(0xFF7C3AED),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    '$quantity',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 18),
                                  onPressed: quantity < selectedVariant!.stock
                                      ? () => setState(() => quantity++)
                                      : null,
                                  color: const Color(0xFF7C3AED),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Add to cart button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: selectedVariant != null &&
                                selectedVariant!.stock > 0
                            ? _addToCart
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        child: const Text(
                          'Add to Cart',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
