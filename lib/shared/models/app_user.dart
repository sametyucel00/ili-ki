import 'package:cloud_firestore/cloud_firestore.dart';

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

  bool get isPremium => planType == 'premium' || subscriptionStatus == 'active';

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
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'linkedAt': linkedAt == null ? null : Timestamp.fromDate(linkedAt!),
      'language': language,
      'planType': planType,
      'creditBalance': creditBalance,
      'isOnboarded': isOnboarded,
      'subscriptionStatus': subscriptionStatus,
      'subscriptionPlatform': subscriptionPlatform,
      'subscriptionExpiryDate': subscriptionExpiryDate == null
          ? null
          : Timestamp.fromDate(subscriptionExpiryDate!),
      'notificationEnabled': notificationEnabled,
      'deletedAt': deletedAt == null ? null : Timestamp.fromDate(deletedAt!),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    DateTime? ts(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return AppUser(
      uid: map['uid'] as String,
      displayName: map['displayName'] as String?,
      email: map['email'] as String?,
      photoUrl: map['photoURL'] as String?,
      provider: (map['provider'] as String?) ?? 'anonymous',
      authType: (map['authType'] as String?) ?? 'anonymous',
      isGuest: (map['isGuest'] as bool?) ?? true,
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
