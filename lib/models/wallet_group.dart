class WalletGroup {
  final String id;
  final String userId;
  final String name;
  final List<String> walletIds;
  final DateTime? createdAt;

  WalletGroup({
    required this.id,
    required this.userId,
    required this.name,
    required this.walletIds,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {'user_id': userId, 'name': name};
  }

  factory WalletGroup.fromJson(
    Map<String, dynamic> json, {
    List<String> walletIds = const [],
  }) {
    return WalletGroup(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      walletIds: walletIds,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}
