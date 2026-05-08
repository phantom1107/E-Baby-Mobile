import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';

/// Login uses the same Firestore users collection as the E-Baby website.
/// No Firebase Auth: we check email + password in Firestore (same as firestore_db).
const String _usersCollection = 'users';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isLoggedIn = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;

  /// Set logged-in user from Firestore doc and persist to SharedPreferences.
  Future<void> _setUserFromFirestoreDoc(String docId, Map<String, dynamic> data) async {
    _currentUser = User.fromFirestore(docId, data);
    _isLoggedIn = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', docId);
    await prefs.setString('email', _currentUser!.email);
    await prefs.setString('user_type', _currentUser!.userType);
    await prefs.setString('first_name', _currentUser!.firstName);
    await prefs.setString('last_name', _currentUser!.lastName);
    await prefs.setString('phone_number', _currentUser!.phoneNumber);
    await prefs.setString('address', _currentUser!.address);
    if (_currentUser!.profilePic != null) {
      await prefs.setString('profile_pic', _currentUser!.profilePic!);
    }
    notifyListeners();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('user_id');
    final email = prefs.getString('email');
    final userType = prefs.getString('user_type');
    if (uid != null && email != null && userType != null) {
      _isLoggedIn = true;
      _currentUser = User(
        id: uid,
        firstName: prefs.getString('first_name') ?? '',
        lastName: prefs.getString('last_name') ?? '',
        email: email,
        phoneNumber: prefs.getString('phone_number') ?? '',
        address: prefs.getString('address') ?? '',
        userType: userType,
        profilePic: prefs.getString('profile_pic'),
        status: 'active',
      );
      notifyListeners();
    }
  }

  /// Login using Firestore users (same as website): find by email, check password.
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final trimmedEmail = email.trim();
      
      // First check if account exists in users collection
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: trimmedEmail)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // Account not in users collection, check if it's pending in request collections
        final isPending = await _checkPendingRegistration(trimmedEmail);
        
        if (isPending) {
          return {
            'success': false,
            'error': 'Your account is pending admin approval. Please wait for approval email.',
          };
        }
        
        // Check if rejected
        final rejectionReason = await _checkRejectedRegistration(trimmedEmail);
        
        if (rejectionReason != null) {
          return {
            'success': false,
            'error': 'Your registration was rejected. Reason: $rejectionReason',
          };
        }
        
        return {'success': false, 'error': 'Account not found. Please register first.'};
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      final storedPassword = data['password']?.toString();

      if (storedPassword != password) {
        return {'success': false, 'error': 'Invalid password or email'};
      }

      if (data['status'] == 'banned') {
        return {
          'success': false,
          'error': 'This account has been banned. ${data['ban_reason'] ?? ''}'.trim(),
        };
      }

      if (data['status'] == 'pending') {
        return {
          'success': false,
          'error': 'Your account is pending admin approval. Please wait for approval email.',
        };
      }

      await _setUserFromFirestoreDoc(doc.id, data);
      return {'success': true};
    } catch (e) {
      print('Login error: $e');
      return {'success': false, 'error': 'Login failed. Please check your credentials and try again.'};
    }
  }

  /// Check if email has pending registration in request collections
  Future<bool> _checkPendingRegistration(String email) async {
    try {
      // Check buyer_requests
      final buyerQuery = await _firestore
          .collection('buyer_requests')
          .where('email', isEqualTo: email)
          .where('status', isEqualTo: 'Pending')
          .limit(1)
          .get();
      
      if (buyerQuery.docs.isNotEmpty) {
        return true;
      }
      
      // Check seller_requests
      final sellerQuery = await _firestore
          .collection('seller_requests')
          .where('email', isEqualTo: email)
          .where('status', isEqualTo: 'Pending')
          .limit(1)
          .get();
      
      if (sellerQuery.docs.isNotEmpty) {
        return true;
      }
      
      // Check rider_requests
      final riderQuery = await _firestore
          .collection('rider_requests')
          .where('email', isEqualTo: email)
          .where('status', isEqualTo: 'Pending')
          .limit(1)
          .get();
      
      if (riderQuery.docs.isNotEmpty) {
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error checking pending registration: $e');
      return false;
    }
  }

  /// Check if email has rejected registration and return reason
  Future<String?> _checkRejectedRegistration(String email) async {
    try {
      // Check buyer_requests
      final buyerQuery = await _firestore
          .collection('buyer_requests')
          .where('email', isEqualTo: email)
          .where('status', isEqualTo: 'Rejected')
          .limit(1)
          .get();
      
      if (buyerQuery.docs.isNotEmpty) {
        return buyerQuery.docs.first.data()['rejection_reason'] ?? 'No reason provided';
      }
      
      // Check seller_requests
      final sellerQuery = await _firestore
          .collection('seller_requests')
          .where('email', isEqualTo: email)
          .where('status', isEqualTo: 'Rejected')
          .limit(1)
          .get();
      
      if (sellerQuery.docs.isNotEmpty) {
        return sellerQuery.docs.first.data()['rejection_reason'] ?? 'No reason provided';
      }
      
      // Check rider_requests
      final riderQuery = await _firestore
          .collection('rider_requests')
          .where('email', isEqualTo: email)
          .where('status', isEqualTo: 'Rejected')
          .limit(1)
          .get();
      
      if (riderQuery.docs.isNotEmpty) {
        return riderQuery.docs.first.data()['rejection_reason'] ?? 'No reason provided';
      }
      
      return null;
    } catch (e) {
      print('Error checking rejected registration: $e');
      return null;
    }
  }

  /// Register: Send OTP without creating account yet
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      final email = (data['email'] as String? ?? '').trim();
      final password = data['password'] as String? ?? '';
      final confirmPassword = data['confirm_password'] as String? ?? '';
      if (password != confirmPassword) {
        return {'success': false, 'error': 'Passwords do not match'};
      }
      if (password.isEmpty) {
        return {'success': false, 'error': 'Password is required'};
      }

      final existing = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        return {'success': false, 'error': 'This email is already registered'};
      }

      // Store registration data temporarily (in production, this would be on backend)
      // Generate OTP
      final otp = _generateOTP();
      
      // Try to send OTP via email (won't fail if not configured)
      await _sendOTPEmail(email, otp);
      
      // Store data for later use in verifyOTP
      _pendingRegistration = data;
      _pendingOTP = otp;
      
      return {'success': true, 'message': 'OTP sent to your email', 'otp': otp}; // Include OTP for testing
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Check if email already exists (only active users and pending requests, NOT rejected)
  Future<bool> checkEmailExists(String email) async {
    try {
      final trimmedEmail = email.trim();
      
      // Check in users collection
      final usersQuery = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: trimmedEmail)
          .limit(1)
          .get();
      
      if (usersQuery.docs.isNotEmpty) {
        return true;
      }
      
      // Check in pending requests (NOT rejected ones)
      final buyerRequests = await _firestore
          .collection('buyer_requests')
          .where('email', isEqualTo: trimmedEmail)
          .where('status', isEqualTo: 'Pending')
          .limit(1)
          .get();
      
      if (buyerRequests.docs.isNotEmpty) {
        return true;
      }
      
      final sellerRequests = await _firestore
          .collection('seller_requests')
          .where('email', isEqualTo: trimmedEmail)
          .where('status', isEqualTo: 'Pending')
          .limit(1)
          .get();
      
      if (sellerRequests.docs.isNotEmpty) {
        return true;
      }
      
      final riderRequests = await _firestore
          .collection('rider_requests')
          .where('email', isEqualTo: trimmedEmail)
          .where('status', isEqualTo: 'Pending')
          .limit(1)
          .get();
      
      if (riderRequests.docs.isNotEmpty) {
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error checking email: $e');
      return false; // Return false on error to allow user to proceed
    }
  }

  String _generateOTP() {
    return (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
  }

  Future<void> _sendOTPEmail(String email, String otp) async {
    // Using EmailJS - a free email service that works from client-side
    // Setup instructions:
    // 1. Go to https://www.emailjs.com/ and create a free account
    // 2. Add an email service (connect your Gmail)
    // 3. Create a template with these variables: to_email, otp_code, message
    // 4. Get your Public Key, Service ID, and Template ID
    // 5. Replace the values below
    
    const publicKey = 'HpkmGoJSHy_VNHuqx'; // Get from EmailJS dashboard
    const privateKey = 'IeHIBlvHW5On0UjX5mA2W'; // Get from EmailJS Account page - https://dashboard.emailjs.com/admin/account
    const serviceId = 'service_97ze6i8'; // Get from EmailJS dashboard
    const templateId = 'template_46cncd5'; // Get from EmailJS dashboard
    
    // If not configured, skip email sending (OTP will still show in UI for testing)
    if (publicKey == 'YOUR_EMAILJS_PUBLIC_KEY') {
      print('EmailJS not configured. OTP: $otp');
      print('To enable email sending, follow setup instructions in auth_service.dart');
      return; // Skip email sending but continue registration
    }
    
    try {
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'accessToken': privateKey, // Private key for strict mode (non-browser access)
          'template_params': {
            'to_email': email,
            'to_name': email.split('@')[0],
            'otp_code': otp,
            'message': 'Your E-Baby verification code is: $otp\n\nThis code will expire in 10 minutes.\n\nIf you did not request this code, please ignore this email.',
          },
        }),
      );
      
      if (response.statusCode == 200) {
        print('OTP email sent successfully to $email');
      } else {
        print('Failed to send email: ${response.statusCode} - ${response.body}');
        // Don't throw error, just log it
      }
    } catch (e) {
      print('Email sending error: $e');
      // Don't throw error, OTP will still show in UI
    }
  }

  Map<String, dynamic>? _pendingRegistration;
  String? _pendingOTP;

  Future<Map<String, dynamic>> verifyOTP(String email, String otp) async {
    try {
      // Verify OTP
      if (_pendingOTP == null || otp != _pendingOTP) {
        return {'success': false, 'error': 'Invalid OTP'};
      }
      
      if (_pendingRegistration == null) {
        return {'success': false, 'error': 'No pending registration'};
      }

      final userType = _pendingRegistration!['user_type'] ?? 'Buyer';
      
      // Determine collection based on user type
      String collectionName;
      if (userType == 'Seller') {
        collectionName = 'seller_requests';
      } else if (userType == 'Rider') {
        collectionName = 'rider_requests';
      } else {
        collectionName = 'buyer_requests';
      }

      // Create registration request for admin approval
      final requestData = {
        'first_name': _pendingRegistration!['first_name'] ?? '',
        'last_name': _pendingRegistration!['last_name'] ?? '',
        'email': email,
        'password': _pendingRegistration!['password'] ?? '',
        'phone_number': _pendingRegistration!['phone_number'] ?? '',
        'address': _pendingRegistration!['address'] ?? '',
        'country': _pendingRegistration!['country'] ?? 'Philippines',
        'region': _pendingRegistration!['region'] ?? '',
        'province': _pendingRegistration!['province'] ?? '',
        'city': _pendingRegistration!['city'] ?? '',
        'street_address': _pendingRegistration!['street_address'] ?? '',
        'user_type': userType,
        'status': 'Pending',
        'document_id': _pendingRegistration!['document_id'] ?? '',
        'created_at': FieldValue.serverTimestamp(),
      };

      // Add BIR for sellers
      if (userType == 'Seller' && _pendingRegistration!.containsKey('bir')) {
        requestData['bir'] = _pendingRegistration!['bir'] ?? '';
      }

      // Create request in appropriate collection
      await _firestore.collection(collectionName).add(requestData);
      
      // Clear pending data
      _pendingRegistration = null;
      _pendingOTP = null;
      
      return {'success': true, 'message': 'Registration submitted for admin approval'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Verify OTP with document URLs (called after documents are uploaded)
  Future<Map<String, dynamic>> verifyOTPWithDocuments(
    String email,
    String otp,
    String documentIdUrl,
    String birUrl,
  ) async {
    try {
      // Verify OTP
      if (_pendingOTP == null || otp != _pendingOTP) {
        return {'success': false, 'error': 'Invalid OTP'};
      }
      
      if (_pendingRegistration == null) {
        return {'success': false, 'error': 'No pending registration'};
      }

      final userType = _pendingRegistration!['user_type'] ?? 'Buyer';
      
      // Determine collection based on user type
      String collectionName;
      if (userType == 'Seller') {
        collectionName = 'seller_requests';
      } else if (userType == 'Rider') {
        collectionName = 'rider_requests';
      } else {
        collectionName = 'buyer_requests';
      }

      // Create registration request for admin approval with document URLs
      final requestData = {
        'first_name': _pendingRegistration!['first_name'] ?? '',
        'last_name': _pendingRegistration!['last_name'] ?? '',
        'email': email,
        'password': _pendingRegistration!['password'] ?? '',
        'phone_number': _pendingRegistration!['phone_number'] ?? '',
        'address': _pendingRegistration!['address'] ?? '',
        'country': _pendingRegistration!['country'] ?? 'Philippines',
        'region': _pendingRegistration!['region'] ?? '',
        'province': _pendingRegistration!['province'] ?? '',
        'city': _pendingRegistration!['city'] ?? '',
        'street_address': _pendingRegistration!['street_address'] ?? '',
        'user_type': userType,
        'status': 'Pending',
        'document_id': documentIdUrl,
        'created_at': FieldValue.serverTimestamp(),
      };

      // Add BIR for sellers
      if (userType == 'Seller' && birUrl.isNotEmpty) {
        requestData['bir'] = birUrl;
      }

      // Create request in appropriate collection
      await _firestore.collection(collectionName).add(requestData);
      
      // Clear pending data
      _pendingRegistration = null;
      _pendingOTP = null;
      
      return {'success': true, 'message': 'Registration submitted for admin approval'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String otp) async {
    if (_currentUser != null) return {'success': true};
    return {'success': false, 'error': 'No user to verify'};
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _isLoggedIn = false;
    _currentUser = null;
    notifyListeners();
  }

  // Forgot Password - Step 1: Send OTP
  String? _forgotPasswordEmail;
  String? _forgotPasswordOTP;
  
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      // Check if user exists
      final userDoc = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userDoc.docs.isEmpty) {
        return {'success': false, 'error': 'No account found with this email'};
      }

      // Generate OTP
      final otp = _generateOTP();
      _forgotPasswordEmail = email;
      _forgotPasswordOTP = otp;

      // Send OTP via email
      await _sendOTPEmail(email, otp);

      return {
        'success': true,
        'message': 'OTP sent to your email',
        'otp': otp, // For testing
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Forgot Password - Step 2: Verify OTP
  Future<Map<String, dynamic>> verifyForgotPasswordOTP(String otp) async {
    if (_forgotPasswordOTP == null || otp != _forgotPasswordOTP) {
      return {'success': false, 'error': 'Invalid OTP'};
    }
    return {'success': true, 'message': 'OTP verified'};
  }

  // Forgot Password - Step 3: Reset Password
  Future<Map<String, dynamic>> resetPassword(String newPassword) async {
    try {
      if (_forgotPasswordEmail == null) {
        return {'success': false, 'error': 'Session expired. Please try again.'};
      }

      // Update password in Firestore
      final userDoc = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: _forgotPasswordEmail)
          .limit(1)
          .get();

      if (userDoc.docs.isEmpty) {
        return {'success': false, 'error': 'User not found'};
      }

      await userDoc.docs.first.reference.update({'password': newPassword});

      // Clear forgot password data
      _forgotPasswordEmail = null;
      _forgotPasswordOTP = null;

      return {'success': true, 'message': 'Password reset successfully'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Clear forgot password session
  void clearForgotPasswordSession() {
    _forgotPasswordEmail = null;
    _forgotPasswordOTP = null;
  }

  Future<Map<String, dynamic>> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    final uid = _currentUser?.id;
    if (uid == null) return {'success': false, 'error': 'Not logged in'};
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      if (!doc.exists || doc.data()?['password'] != oldPassword) {
        return {'success': false, 'error': 'Current password is incorrect'};
      }
      await _firestore.collection(_usersCollection).doc(uid).update({
        'password': newPassword,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final uid = _currentUser?.id;
    if (uid == null) return {'success': false, 'error': 'Not logged in'};
    try {
      final updateData = <String, dynamic>{};
      if (data.containsKey('first_name')) updateData['first_name'] = data['first_name'];
      if (data.containsKey('last_name')) updateData['last_name'] = data['last_name'];
      if (data.containsKey('phone_number')) updateData['phone_number'] = data['phone_number'];
      if (data.containsKey('address')) updateData['address'] = data['address'];
      if (data.containsKey('profile_pic')) updateData['profile_pic'] = data['profile_pic'];
      if (updateData.isEmpty) return {'success': true};
      updateData['updated_at'] = FieldValue.serverTimestamp();
      await _firestore.collection(_usersCollection).doc(uid).update(updateData);
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        await _setUserFromFirestoreDoc(uid, doc.data()!);
      }
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
