import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/cloudinary_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  
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
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (images.isNotEmpty) {
        setState(() {
          _images = images.take(5).toList(); // Limit to 5 images
        });
        print('Picked ${images.length} images');
        for (var img in images) {
          print('Image path: ${img.path}');
        }
      }
    } catch (e) {
      print('Error picking images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddVariantDialog() {
    String? selectedColor;
    String? selectedSize;
    int stock = 0;

    final colors = [
      'Red', 'Orange', 'Yellow', 'Green', 'Blue', 'Purple',
      'Black', 'White', 'Brown', 'Pink', 'Gray', 'Multicolor', 'Mixed'
    ];

    final sizes = [
      'Newborn', '0-3 months', '3-6 months', '6-9 months', '9-12 months',
      '12-18 months', '18-24 months', '2T', '3T', '4T', '5T',
      'Small', 'Medium', 'Large', 'One Size'
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Variant'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedColor,
                  decoration: const InputDecoration(
                    labelText: 'Color',
                    border: OutlineInputBorder(),
                  ),
                  items: colors.map((color) {
                    return DropdownMenuItem(value: color, child: Text(color));
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedColor = value);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedSize,
                  decoration: const InputDecoration(
                    labelText: 'Size',
                    border: OutlineInputBorder(),
                  ),
                  items: sizes.map((size) {
                    return DropdownMenuItem(value: size, child: Text(size));
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedSize = value);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Stock Quantity',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    stock = int.tryParse(value) ?? 0;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedColor == null || selectedSize == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select both color and size'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                // Check for duplicate
                final exists = _variants.any((v) =>
                    v['color'] == selectedColor && v['size'] == selectedSize);

                if (exists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Variant "$selectedColor - $selectedSize" already exists'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                setState(() {
                  _variants.add({
                    'color': selectedColor!,
                    'size': selectedSize!,
                    'stock': stock,
                  });
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Variant added successfully'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitProduct() async {
    print('=== SUBMIT PRODUCT CALLED ===');
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
        const SnackBar(
          content: Text('Please add at least one variant'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_images.isEmpty) {
      print('No images added');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one product image'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final totalStock = _variants.fold<int>(0, (sum, v) => sum + (v['stock'] as int));
    print('Total stock: $totalStock');
    
    if (totalStock <= 0) {
      print('Total stock is 0');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Total stock must be greater than 0'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    print('All validations passed, starting submission...');
    setState(() => _isSubmitting = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final sellerEmail = authService.currentUser?.email;

      if (sellerEmail == null) {
        throw Exception('User not authenticated');
      }

      print('=== STARTING IMAGE UPLOAD ===');
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

      // Generate product ID
      final productId = 'P${DateTime.now().millisecondsSinceEpoch}';

      // Prepare product data with proper variant structure
      final productData = {
        'product_id': productId,
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text),
        'image_url': imageUrls.first,
        'image_urls': imageUrls,
        'seller_email': sellerEmail,
        'stock': totalStock,
        'variants': _variants, // Store variants array
        'created_at': FieldValue.serverTimestamp(),
        'sales': 0,
      };

      print('Saving product to Firestore...');

      // Add to Firestore
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .set(productData);

      print('Product saved successfully!');

      if (mounted) {
        // Hide uploading message
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );

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
      }
    } catch (e) {
      print('Error adding product: $e');
      if (mounted) {
        // Hide uploading message
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding product: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        title: const Text('Add Product'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Basic Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.shopping_bag),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Please enter product name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Please enter description' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedCategory = value);
                      },
                      validator: (value) =>
                          value == null ? 'Please select a category' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price (₱)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Please enter price';
                        if (double.tryParse(value!) == null) return 'Invalid price';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Images Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Product Images',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Add Images'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_images.isEmpty)
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                'No images selected',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _images.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(_images[index].path),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 100,
                                        height: 100,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _images.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Variants Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Product Variants',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _showAddVariantDialog,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Variant'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_variants.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'No variants added yet',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _variants.length,
                        itemBuilder: (context, index) {
                          final variant = _variants[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: Colors.grey[50],
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF7C3AED),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                '${variant['color']} - ${variant['size']}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text('Stock: ${variant['stock']}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _variants.removeAt(index);
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    if (_variants.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Stock:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${_variants.fold<int>(0, (sum, v) => sum + (v['stock'] as int))} units',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Add Product',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
