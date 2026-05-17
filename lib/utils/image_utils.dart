/// Utility functions for handling image URLs consistently across the app
class ImageUtils {
  /// Normalize image URL to handle Cloudinary URLs and local paths
  /// 
  /// Handles:
  /// - Protocol-relative URLs (//res.cloudinary.com/...)
  /// - Relative URLs without protocol
  /// - Already complete URLs (http:// or https://)
  /// 
  /// Returns a complete HTTPS URL
  static String normalizeImageUrl(String? imageUrl, {String fallback = ''}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return fallback;
    }

    // Already a complete URL
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    // Protocol-relative URL (Cloudinary)
    if (imageUrl.startsWith('//')) {
      return 'https:$imageUrl';
    }

    // Relative URL without protocol - assume HTTPS
    if (!imageUrl.startsWith('/')) {
      return 'https://$imageUrl';
    }

    // Local path - return as is (should be handled by backend)
    return imageUrl;
  }

  /// Get a placeholder image URL
  static String get placeholder => 'https://via.placeholder.com/150';

  /// Get a product placeholder image URL
  static String get productPlaceholder => 'https://via.placeholder.com/300x300/FFB6C1/FFFFFF?text=Product';

  /// Get a profile placeholder image URL
  static String get profilePlaceholder => 'https://via.placeholder.com/150/FFB6C1/FFFFFF?text=User';
}
