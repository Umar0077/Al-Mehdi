/// Model for OAuth (Apple/Google) user data stored in Firestore
/// This is used to persist name and email across sessions since
/// Apple/Google may not return this data on subsequent logins
class OAuthUserData {
  final String uid;
  final String email;
  final String fullName;
  final String provider; // 'apple' or 'google'
  final String? appleUserId; // For Apple Sign In
  final DateTime createdAt;
  final DateTime lastUpdatedAt;

  const OAuthUserData({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.provider,
    this.appleUserId,
    required this.createdAt,
    required this.lastUpdatedAt,
  });

  /// Convert to map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'provider': provider,
      if (appleUserId != null) 'appleUserId': appleUserId,
      'createdAt': createdAt,
      'lastUpdatedAt': lastUpdatedAt,
    };
  }

  /// Create from Firestore document
  factory OAuthUserData.fromFirestore(Map<String, dynamic> data) {
    return OAuthUserData(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      provider: data['provider'] ?? '',
      appleUserId: data['appleUserId'],
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      lastUpdatedAt: data['lastUpdatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  /// Copy with method for updating fields
  OAuthUserData copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? provider,
    String? appleUserId,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
  }) {
    return OAuthUserData(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      provider: provider ?? this.provider,
      appleUserId: appleUserId ?? this.appleUserId,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}
