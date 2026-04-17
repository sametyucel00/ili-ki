class AppUser {
  const AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.provider,
    required this.authType,
    required this.isGuest,
    required this.isLinked,
    required this.createdAt,
    required this.lastLoginAt,
    required this.linkedAt,
    required this.language,
    required this.planType,
    required this.creditBalance,
    required this.isOnboarded,
    required this.subscriptionStatus,
    required this.subscriptionPlatform,
    required this.subscriptionExpiryDate,
    required this.notificationEnabled,
    required this.deletedAt,
  });

  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final String provider;
  final String authType;
  final bool isGuest;
  final bool isLinked;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final DateTime? linkedAt;
  final String language;
  final String planType;
  final int creditBalance;
  final bool isOnboarded;
  final String subscriptionStatus;
  final String? subscriptionPlatform;
  final DateTime? subscriptionExpiryDate;
  final bool notificationEnabled;
  final DateTime? deletedAt;

  bool get isPremium {
    final hasPremiumState =
        planType == 'premium' || subscriptionStatus == 'active';
    final expiry = subscriptionExpiryDate;
    return hasPremiumState && expiry != null && expiry.isAfter(DateTime.now());
  }

  AppUser copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoUrl,
    String? provider,
    String? authType,
    bool? isGuest,
    bool? isLinked,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    DateTime? linkedAt,
    String? language,
    String? planType,
    int? creditBalance,
    bool? isOnboarded,
    String? subscriptionStatus,
    String? subscriptionPlatform,
    DateTime? subscriptionExpiryDate,
    bool? notificationEnabled,
    DateTime? deletedAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      provider: provider ?? this.provider,
      authType: authType ?? this.authType,
      isGuest: isGuest ?? this.isGuest,
      isLinked: isLinked ?? this.isLinked,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      linkedAt: linkedAt ?? this.linkedAt,
      language: language ?? this.language,
      planType: planType ?? this.planType,
      creditBalance: creditBalance ?? this.creditBalance,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionPlatform: subscriptionPlatform ?? this.subscriptionPlatform,
      subscriptionExpiryDate:
          subscriptionExpiryDate ?? this.subscriptionExpiryDate,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoURL': photoUrl,
      'provider': provider,
      'authType': authType,
      'isGuest': isGuest,
      'isLinked': isLinked,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'linkedAt': linkedAt?.toIso8601String(),
      'language': language,
      'planType': planType,
      'creditBalance': creditBalance,
      'isOnboarded': isOnboarded,
      'subscriptionStatus': subscriptionStatus,
      'subscriptionPlatform': subscriptionPlatform,
      'subscriptionExpiryDate': subscriptionExpiryDate?.toIso8601String(),
      'notificationEnabled': notificationEnabled,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    DateTime? ts(dynamic value) {
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return AppUser(
      uid: (map['uid'] as String?) ?? '',
      displayName: map['displayName'] as String?,
      email: map['email'] as String?,
      photoUrl: map['photoURL'] as String?,
      provider: (map['provider'] as String?) ?? 'local',
      authType: (map['authType'] as String?) ?? 'local',
      isGuest: (map['isGuest'] as bool?) ?? false,
      isLinked: (map['isLinked'] as bool?) ?? false,
      createdAt: ts(map['createdAt']) ?? DateTime.now(),
      lastLoginAt: ts(map['lastLoginAt']) ?? DateTime.now(),
      linkedAt: ts(map['linkedAt']),
      language: (map['language'] as String?) ?? 'tr',
      planType: (map['planType'] as String?) ?? 'free',
      creditBalance: (map['creditBalance'] as num?)?.toInt() ?? 0,
      isOnboarded: (map['isOnboarded'] as bool?) ?? false,
      subscriptionStatus: (map['subscriptionStatus'] as String?) ?? 'inactive',
      subscriptionPlatform: map['subscriptionPlatform'] as String?,
      subscriptionExpiryDate: ts(map['subscriptionExpiryDate']),
      notificationEnabled: (map['notificationEnabled'] as bool?) ?? false,
      deletedAt: ts(map['deletedAt']),
    );
  }
}
