import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminRegistrationRequestsScreen extends StatefulWidget {
  const AdminRegistrationRequestsScreen({super.key});

  @override
  State<AdminRegistrationRequestsScreen> createState() =>
      _AdminRegistrationRequestsScreenState();
}

class _AdminRegistrationRequestsScreenState
    extends State<AdminRegistrationRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.grey[200],
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF7C3AED),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF7C3AED),
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Buyers'),
              Tab(text: 'Sellers'),
              Tab(text: 'Riders'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRequestList(null),
              _buildRequestList('Buyer'),
              _buildRequestList('Seller'),
              _buildRequestList('Rider'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequestList(String? userType) {
    return StreamBuilder<List<QuerySnapshot>>(
      stream: _getCombinedRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return _buildEmptyState();
        }

        List<Map<String, dynamic>> allRequests = [];
        
        for (var querySnapshot in snapshot.data!) {
          for (var doc in querySnapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status']?.toString() ?? '';
            
            if (status == 'Pending') {
              allRequests.add({
                'id': doc.id,
                'data': data,
                'collection': _getCollectionFromDoc(doc),
              });
            }
          }
        }

        if (userType != null) {
          allRequests = allRequests.where((req) {
            final collection = req['collection'] as String;
            return collection.contains(userType.toLowerCase());
          }).toList();
        }

        if (allRequests.isEmpty) {
          return _buildEmptyState();
        }

        allRequests.sort((a, b) {
          final aDate = (a['data']['created_at'] as Timestamp?)?.toDate();
          final bDate = (b['data']['created_at'] as Timestamp?)?.toDate();
          if (aDate == null || bDate == null) return 0;
          return bDate.compareTo(aDate);
        });

        return RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allRequests.length,
            itemBuilder: (context, index) {
              final request = allRequests[index];
              return _buildRequestCard(
                request['id'] as String,
                request['data'] as Map<String, dynamic>,
                request['collection'] as String,
              );
            },
          ),
        );
      },
    );
  }

  Stream<List<QuerySnapshot>> _getCombinedRequestsStream() {
    return Stream.periodic(const Duration(seconds: 2)).asyncMap((_) async {
      final sellerSnapshot = await _firestore
          .collection('seller_requests')
          .where('status', isEqualTo: 'Pending')
          .get();
      final riderSnapshot = await _firestore
          .collection('rider_requests')
          .where('status', isEqualTo: 'Pending')
          .get();
      final buyerSnapshot = await _firestore
          .collection('buyer_requests')
          .where('status', isEqualTo: 'Pending')
          .get();
      return [sellerSnapshot, riderSnapshot, buyerSnapshot];
    }).asBroadcastStream();
  }

  String _getCollectionFromDoc(DocumentSnapshot doc) {
    return doc.reference.parent.id;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Pending Requests',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'All registration requests have been processed',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(
    String requestId,
    Map<String, dynamic> data,
    String collection,
  ) {
    final firstName = data['first_name'] ?? '';
    final lastName = data['last_name'] ?? '';
    final email = data['email'] ?? '';
    final phoneNumber = data['phone_number'] ?? '';
    final address = data['address'] ?? '';
    final documentId = data['document_id'] ?? '';
    final bir = data['bir'] ?? '';
    final createdAt = (data['created_at'] as Timestamp?)?.toDate();

    String userType = 'Buyer';
    Color typeColor = const Color(0xFF3B82F6);
    
    if (collection.contains('seller')) {
      userType = 'Seller';
      typeColor = const Color(0xFF10B981);
    } else if (collection.contains('rider')) {
      userType = 'Rider';
      typeColor = const Color(0xFFF59E0B);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: typeColor,
                  radius: 24,
                  child: Text(
                    firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$firstName $lastName',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          userType,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: typeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildDetailRow(Icons.email, 'Email', email),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.phone, 'Phone', phoneNumber),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.location_on, 'Address', address),
            
            if (documentId.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.badge, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ID Document',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ElevatedButton.icon(
                          onPressed: () => _viewDocument(documentId, 'ID Document'),
                          icon: const Icon(Icons.visibility, size: 16),
                          label: const Text('View ID'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            
            if (bir.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.business, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BIR Document',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ElevatedButton.icon(
                          onPressed: () => _viewDocument(bir, 'BIR Document'),
                          icon: const Icon(Icons.visibility, size: 16),
                          label: const Text('View BIR'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            if (createdAt != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.calendar_today,
                'Requested',
                _formatDate(createdAt),
              ),
            ],

            const Divider(height: 24),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showApproveDialog(requestId, collection, '$firstName $lastName'),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(requestId, collection, '$firstName $lastName'),
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _viewDocument(String documentUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.image, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      documentUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Failed to load document',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'URL: $documentUrl',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pinch to zoom • Drag to pan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showApproveDialog(String requestId, String collection, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Approve Request'),
        content: Text('Are you sure you want to approve "$userName"\'s registration request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _approveRequest(requestId, collection);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(String requestId, String collection, String userName) {
    final TextEditingController customReasonController = TextEditingController();
    String? selectedReason;
    
    final List<String> rejectionReasons = [
      'Invalid or unclear ID document',
      'Incomplete information provided',
      'Suspicious or fraudulent activity detected',
      'Does not meet age requirements',
      'Duplicate registration attempt',
      'Other (specify below)',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Reject Request'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Are you sure you want to reject "$userName"\'s registration request?'),
                const SizedBox(height: 16),
                const Text(
                  'Reason for rejection:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ...rejectionReasons.map((reason) {
                  return RadioListTile<String>(
                    title: Text(reason, style: const TextStyle(fontSize: 13)),
                    value: reason,
                    groupValue: selectedReason,
                    activeColor: const Color(0xFF7C3AED),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedReason = value;
                      });
                    },
                  );
                }).toList(),
                if (selectedReason == 'Other (specify below)') ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: customReasonController,
                    decoration: const InputDecoration(
                      labelText: 'Custom reason',
                      border: OutlineInputBorder(),
                      hintText: 'Enter rejection reason...',
                    ),
                    maxLines: 3,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedReason == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a reason for rejection'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                if (selectedReason == 'Other (specify below)' && customReasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a custom reason'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                final reason = selectedReason == 'Other (specify below)'
                    ? customReasonController.text.trim()
                    : selectedReason!;
                
                Navigator.pop(context);
                await _rejectRequest(requestId, collection, userName, reason);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveRequest(String requestId, String collection) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Approving request...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final requestDoc = await _firestore.collection(collection).doc(requestId).get();
      
      if (!requestDoc.exists) {
        throw Exception('Request not found');
      }

      final requestData = requestDoc.data()!;
      final email = requestData['email'] ?? '';
      final firstName = requestData['first_name'] ?? '';

      String userType = 'Buyer';
      if (collection.contains('seller')) {
        userType = 'Seller';
      } else if (collection.contains('rider')) {
        userType = 'Rider';
      }

      final userData = {
        'first_name': requestData['first_name'] ?? '',
        'last_name': requestData['last_name'] ?? '',
        'email': requestData['email'] ?? '',
        'phone_number': requestData['phone_number'] ?? '',
        'address': requestData['address'] ?? '',
        'password': requestData['password'] ?? '',
        'user_type': userType,
        'status': 'active',
        'created_at': FieldValue.serverTimestamp(),
      };

      if (requestData.containsKey('document_id')) {
        userData['document_id'] = requestData['document_id'];
      }
      if (requestData.containsKey('bir') && userType == 'Seller') {
        userData['bir'] = requestData['bir'];
      }

      await _firestore.collection('users').add(userData);
      await _firestore.collection(collection).doc(requestId).delete();
      await _sendApprovalEmail(email, firstName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request approved and email sent'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendApprovalEmail(String email, String firstName) async {
    try {
      const publicKey = 'HpkmGoJSHy_VNHuqx';
      const privateKey = 'IeHIBlvHW5On0UjX5mA2W';
      const serviceId = 'service_97ze6i8';
      const templateId = 'template_jsefmwj';

      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'accessToken': privateKey,
          'template_params': {
            'to_email': email,
            'to_name': firstName,
            'header_color_1': '#10B981',
            'header_color_2': '#059669',
            'header_title': '✅ Registration Approved!',
            'header_subtitle': 'Welcome to E-Baby',
            'main_message': 'Congratulations! Your registration application for E-Baby has been approved.',
            'box_border_color': '#10B981',
            'box_bg_color': '#F0FDF4',
            'box_text_color': '#10B981',
            'box_message': '🎉 Welcome to E-Baby!',
            'additional_message': 'You can now log in to your account using your registered email and password.',
            'closing_message': 'We\'re excited to have you as part of our community!',
          },
        }),
      );

      if (response.statusCode == 200) {
        print('Approval email sent to $email');
      } else {
        print('Failed to send approval email: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending approval email: $e');
    }
  }

  Future<void> _rejectRequest(String requestId, String collection, String userName, String reason) async {
    try {
      final requestDoc = await _firestore.collection(collection).doc(requestId).get();
      
      if (!requestDoc.exists) {
        throw Exception('Request not found');
      }

      final requestData = requestDoc.data()!;
      final email = requestData['email'] ?? '';
      final firstName = requestData['first_name'] ?? '';

      await _firestore.collection(collection).doc(requestId).update({
        'status': 'Rejected',
        'rejection_reason': reason,
        'rejected_at': FieldValue.serverTimestamp(),
      });

      await _sendRejectionEmail(email, firstName, reason);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request rejected and email sent'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendRejectionEmail(String email, String firstName, String reason) async {
    try {
      const publicKey = 'HpkmGoJSHy_VNHuqx';
      const privateKey = 'IeHIBlvHW5On0UjX5mA2W';
      const serviceId = 'service_97ze6i8';
      const templateId = 'template_jsefmwj';

      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'accessToken': privateKey,
          'template_params': {
            'to_email': email,
            'to_name': firstName,
            'header_color_1': '#F59E0B',
            'header_color_2': '#D97706',
            'header_title': 'Registration Status Update',
            'header_subtitle': 'E-Baby Application',
            'main_message': 'We regret to inform you that your registration application for E-Baby has been rejected.',
            'box_border_color': '#F59E0B',
            'box_bg_color': '#FEF3C7',
            'box_text_color': '#92400E',
            'box_message': 'Reason: $reason',
            'additional_message': 'If you believe this was a mistake or would like to reapply, please contact our support team or submit a new registration with the correct information.',
            'closing_message': 'Thank you for your interest in E-Baby.',
          },
        }),
      );

      if (response.statusCode == 200) {
        print('Rejection email sent to $email');
      } else {
        print('Failed to send rejection email: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending rejection email: $e');
    }
  }
}
