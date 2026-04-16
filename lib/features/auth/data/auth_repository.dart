import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:iliski_kocu_ai/core/errors/app_exception.dart';
import 'package:iliski_kocu_ai/core/services/analytics_service.dart';
import 'package:iliski_kocu_ai/core/services/local_cache_service.dart';
import 'package:iliski_kocu_ai/shared/models/app_user.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthRepository {
  AuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
    required AnalyticsService analytics,
    required LocalCacheService cache,
  })  : _auth = auth,
        _firestore = firestore,
        _functions = functions,
        _analytics = analytics,
        _cache = cache;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final AnalyticsService _analytics;
  final LocalCacheService _cache;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<AppUser> bootstrapSession() async {
    User? user = _auth.currentUser;
    if (user == null) {
      final credential = await _auth.signInAnonymously();
      user = credential.user;
      await _analytics.logEvent('guest_session_created');
    }
    if (user == null) {
      throw const AppException('Misafir oturumu başlatılamadı.', code: 'anonymous_failed');
    }
    final document = _firestore.collection('users').doc(user.uid);
    final snapshot = await document.get();
    final now = DateTime.now();
    if (!snapshot.exists) {
      await document.set(
        AppUser(
          uid: user.uid,
          displayName: null,
          email: null,
          photoUrl: null,
          provider: 'anonymous',
          authType: 'anonymous',
          isGuest: true,
          isLinked: false,
          createdAt: now,
          lastLoginAt: now,
          linkedAt: null,
          language: 'tr',
          planType: 'free',
          creditBalance: 1,
          isOnboarded: false,
          subscriptionStatus: 'inactive',
          subscriptionPlatform: null,
          subscriptionExpiryDate: null,
          notificationEnabled: false,
          deletedAt: null,
        ).toMap(),
      );
    } else {
      final existingData = snapshot.data()!;
      final shouldGrantStarterLocally =
          (existingData['creditBalance'] as num?)?.toInt() == 0 &&
          ((existingData['isOnboarded'] as bool?) ?? false) == false;
      await document.update({
        'lastLoginAt': Timestamp.fromDate(now),
        if (shouldGrantStarterLocally) 'creditBalance': 1,
      });
    }
    final fresh = await document.get();
    return AppUser.fromMap(fresh.data()!);
  }

  Future<void> markOnboardingCompleted() async {
    await _cache.markOnboardingSeen();
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _firestore.collection('users').doc(uid).update({'isOnboarded': true});
    }
    await _analytics.logEvent('onboarding_completed');
  }

  Future<bool> isOnboardingSeen() => _cache.isOnboardingSeen();

  Future<AppUser> getCurrentProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const AppException('Oturum bulunamadı.', code: 'missing_session');
    }
    final snapshot = await _firestore.collection('users').doc(uid).get();
    return AppUser.fromMap(snapshot.data()!);
  }

  Future<void> linkWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw const AppException('Google ile giriş iptal edildi.', code: 'google_cancelled');
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await _linkCredential(credential, provider: 'google');
  }

  Future<void> linkWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    );
    final oauth = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );
    await _linkCredential(oauth, provider: 'apple');
  }

  Future<void> linkWithEmail(String email, String password) async {
    await _linkCredential(
      EmailAuthProvider.credential(email: email, password: password),
      provider: 'email',
    );
  }

  Future<void> _linkCredential(AuthCredential credential, {required String provider}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AppException('Bağlanacak aktif oturum bulunamadı.', code: 'missing_session');
    }
    await user.linkWithCredential(credential);
    await _functions.httpsCallable('grantLinkReward').call();
    await _analytics.logEvent('account_link_completed', {'provider': provider});
    await _analytics.logEvent('sign_in_completed', {'provider': provider});
  }

  Future<void> deleteAllData() async {
    await _functions.httpsCallable('deleteUserData').call();
    await _cache.clearAll();
  }

  Future<void> deleteAccount() async {
    await deleteAllData();
    await _auth.currentUser?.delete();
  }

  Future<void> signOutGuestAware() async {
    await _cache.clearAll();
    await _auth.signOut();
  }

  Future<void> updateDisplayName(String displayName) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const AppException('Aktif oturum bulunamadı.', code: 'missing_session');
    }
    await _firestore.collection('users').doc(uid).update({
      'displayName': displayName.trim(),
    });
  }
}
