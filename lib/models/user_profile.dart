class UserProfile {
  final String id;
  final String? email;
  final String? displayName;
  final String? phoneNumber;
  final DateTime? updatedAt;
  final String? defaultWalletId;

  UserProfile({
    required this.id,
    this.email,
    this.displayName,
    this.phoneNumber,
    this.updatedAt,
    this.defaultWalletId,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['display_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      defaultWalletId: json['default_wallet_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'phone_number': phoneNumber,
      'updated_at': updatedAt?.toIso8601String(),
      'default_wallet_id': defaultWalletId,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? phoneNumber,
    DateTime? updatedAt,
    String? defaultWalletId,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      updatedAt: updatedAt ?? this.updatedAt,
      defaultWalletId: defaultWalletId ?? this.defaultWalletId,
    );
  }
}
