import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  // Replace these with your Cloudinary credentials
  static const String cloudName = 'dvjiadqok'; // Get from website .env
  static const String uploadPreset = 'ebaby_uploads'; // You'll need to create this
  
  static final CloudinaryPublic _cloudinary = CloudinaryPublic(
    cloudName,
    uploadPreset,
    cache: false,
  );

  /// Upload profile picture to Cloudinary
  static Future<String> uploadProfilePic(File imageFile, String userEmail) async {
    try {
      print('CloudinaryService: Uploading profile picture for $userEmail');
      
      // Add timestamp to force new file instead of overwriting
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final publicId = 'profile_${userEmail.replaceAll('@', '_').replaceAll('.', '_')}_$timestamp';
      
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'ebaby/profile_pics',
          publicId: publicId,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      
      print('CloudinaryService: Profile picture uploaded successfully');
      return response.secureUrl;
    } catch (e) {
      print('CloudinaryService: Error uploading profile pic: $e');
      
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        throw Exception('Cloudinary authentication failed. Check your cloud name and upload preset.');
      } else if (e.toString().contains('404')) {
        throw Exception('Upload preset not found. Make sure "ebaby_uploads" preset exists.');
      } else if (e.toString().contains('network')) {
        throw Exception('Network error. Check your internet connection.');
      } else {
        throw Exception('Profile picture upload failed: ${e.toString()}');
      }
    }
  }

  /// Upload banner image to Cloudinary
  static Future<String> uploadBanner(File imageFile, String userEmail) async {
    try {
      print('CloudinaryService: Uploading banner for $userEmail');
      
      // Add timestamp to force new file instead of overwriting
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final publicId = 'banner_${userEmail.replaceAll('@', '_').replaceAll('.', '_')}_$timestamp';
      
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'ebaby/banners',
          publicId: publicId,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      
      print('CloudinaryService: Banner uploaded successfully');
      return response.secureUrl;
    } catch (e) {
      print('CloudinaryService: Error uploading banner: $e');
      
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        throw Exception('Cloudinary authentication failed. Check your cloud name and upload preset.');
      } else if (e.toString().contains('404')) {
        throw Exception('Upload preset not found. Make sure "ebaby_uploads" preset exists.');
      } else if (e.toString().contains('network')) {
        throw Exception('Network error. Check your internet connection.');
      } else {
        throw Exception('Banner upload failed: ${e.toString()}');
      }
    }
  }

  /// Upload product image to Cloudinary - EXACT SAME AS PROFILE PIC
  static Future<String> uploadProductImage(File imageFile, String productId) async {
    try {
      print('CloudinaryService: Uploading product image for $productId');
      
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'ebaby/products',
          publicId: 'product_${productId}_${DateTime.now().millisecondsSinceEpoch}',
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      
      print('CloudinaryService: Product image uploaded successfully');
      print('CloudinaryService: URL: ${response.secureUrl}');
      return response.secureUrl;
    } catch (e) {
      print('CloudinaryService: Error uploading product image: $e');
      
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        throw Exception('Cloudinary authentication failed. Check your cloud name and upload preset.');
      } else if (e.toString().contains('404')) {
        throw Exception('Upload preset not found. Make sure "ebaby_uploads" preset exists.');
      } else if (e.toString().contains('network')) {
        throw Exception('Network error. Check your internet connection.');
      } else {
        throw Exception('Product image upload failed: ${e.toString()}');
      }
    }
  }
}
