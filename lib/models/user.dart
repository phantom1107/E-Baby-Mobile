class User {
  /// Firebase Auth uid (or legacy numeric id as string).
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String address;
  final String userType;
  final String? profilePic;
  final String? bannerImage;
  final String status;
  final String? banReason;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.userType,
    this.profilePic,
    this.bannerImage,
    required this.status,
    this.banReason,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Prefer *_url fields if present (Cloudinary), fall back to legacy fields.
    final profilePic = json['profile_pic_url'] ?? json['profile_pic'];
    final bannerImage = json['banner_image_url'] ?? json['banner_image'];

    return User(
      id: json['id']?.toString() ?? json['uid']?.toString() ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      address: json['address'] ?? '',
      userType: json['user_type'] ?? 'Buyer',
      profilePic: profilePic,
      bannerImage: bannerImage,
      status: json['status'] ?? 'active',
      banReason: json['ban_reason'],
    );
  }

  /// From Firestore document (document id as uid + data).
  factory User.fromFirestore(String uid, Map<String, dynamic> data) {
    final profilePic = data['profile_pic_url'] ?? data['profile_pic'];
    final bannerImage = data['banner_image_url'] ?? data['banner_image'];

    return User(
      id: uid,
      firstName: data['first_name'] ?? '',
      lastName: data['last_name'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phone_number'] ?? '',
      address: data['address'] ?? '',
      userType: data['user_type'] ?? 'Buyer',
      profilePic: profilePic,
      bannerImage: bannerImage,
      status: data['status'] ?? 'active',
      banReason: data['ban_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
      'address': address,
      'user_type': userType,
      // Keep legacy field names for compatibility; value will usually be a URL.
      'profile_pic': profilePic,
      'banner_image': bannerImage,
      'status': status,
      'ban_reason': banReason,
    };
  }
}
