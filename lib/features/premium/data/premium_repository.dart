import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iliski_kocu_ai/core/services/analytics_service.dart';
import 'package:iliski_kocu_ai/core/services/local_cache_service.dart';
import 'package:iliski_kocu_ai/core/services/purchases_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PremiumRepository {
  PremiumRepository({
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
    required LocalCacheService cache,
    required PurchasesService purchases,
    required AnalyticsService analytics,
  })  : _firestore = firestore,
        _functions = functions,
        _cache = cache,
        _purchases = purchases,
        _analytics = analytics;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final LocalCacheService _cache;
  final PurchasesService _purchases;
  final AnalyticsService _analytics;

  bool get useAndroidPurchaseSimulation => _purchases.useAndroidPurchaseSimulation;

  Future<List<ProductDetails>> loadProducts() async {
    if (useAndroidPurchaseSimulation) {
      final available = await _purchases.isAvailable();
      if (!available) {
        return _debugProducts;
      }
      final storeProducts = await _purchases.getProducts();
      return storeProducts.isEmpty ? _debugProducts : storeProducts;
    }

    final available = await _purchases.isAvailable();
    if (!available) {
      return [];
    }
    return _purchases.getProducts();
  }

  void attachPurchaseListener() {
    _purchases.attachPurchaseListener((purchase) async {
      await _functions.httpsCallable('verifySubscription').call({
        'platform': purchase.verificationData.source,
        'productId': purchase.productID,
        'purchaseId': purchase.purchaseID,
      });
    });
  }

  Future<void> restore() async {
    if (useAndroidPurchaseSimulation) {
      await _analytics.logEvent('purchase_restored', {'mode': 'android_simulation'});
      await _functions.httpsCallable('restoreEntitlementsIfNeeded').call();
      return;
    }

    await _purchases.restorePurchases();
    await _functions.httpsCallable('restoreEntitlementsIfNeeded').call();
    await _analytics.logEvent('purchase_restored');
  }

  Future<void> buyProduct(ProductDetails product) async {
    if (useAndroidPurchaseSimulation) {
      await _analytics.logEvent('purchase_started', {
        'product_id': product.id,
        'mode': 'android_simulation',
      });
      try {
        await _functions.httpsCallable('completeDebugPurchase').call({
          'productId': product.id,
        });
      } catch (_) {
        await _applyLocalSimulation(product.id);
      }
      await _analytics.logEvent('purchase_completed', {
        'product_id': product.id,
        'mode': 'android_simulation',
      });
      return;
    }

    await _purchases.buy(product);
  }

  Future<void> grantRewardedCredit() async {
    await _functions.httpsCallable('grantRewardedAdCredit').call();
    await _analytics.logEvent('rewarded_credit_granted');
  }

  Future<void> _applyLocalSimulation(String productId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return;
    }

    final userRef = _firestore.collection('users').doc(uid);
    final snap = await userRef.get();
    final data = snap.data() ?? <String, dynamic>{};
    final currentCredits = (data['creditBalance'] as num?)?.toInt() ?? 0;

    if (productId == 'com.hisle.app.premium.monthly' || productId == 'com.hisle.app.premium.yearly') {
      await _cache.setLocalPremiumActive();
      final expiryDate = DateTime.now().add(
        Duration(days: productId.endsWith('.yearly') ? 365 : 31),
      );
      try {
        await userRef.update({
          'planType': 'premium',
          'subscriptionStatus': 'active',
          'subscriptionPlatform': 'android_debug',
          'subscriptionExpiryDate': Timestamp.fromDate(expiryDate),
        });
      } catch (_) {}
      return;
    }

    final creditPackMap = <String, int>{
      'com.hisle.app.credits.10': 10,
      'com.hisle.app.credits.50': 50,
    };
    final amount = creditPackMap[productId];
    if (amount == null) {
      return;
    }
    await _cache.addLocalCredits(fallbackBalance: currentCredits, amount: amount);
    try {
      await userRef.update({
        'creditBalance': currentCredits + amount,
      });
    } catch (_) {}
  }

  List<ProductDetails> get _debugProducts => [
        ProductDetails(
          id: 'com.hisle.app.premium.monthly',
          title: 'Premium Aylık (Android test modu)',
          description: 'Butona bastığında anında premium aktif olur.',
          price: 'Test satın al',
          rawPrice: 0,
          currencyCode: 'TRY',
          currencySymbol: '₺',
        ),
        ProductDetails(
          id: 'com.hisle.app.premium.yearly',
          title: 'Premium Yıllık (Android test modu)',
          description: 'Yıllık paketi mağaza beklemeden denetle.',
          price: 'Test satın al',
          rawPrice: 0,
          currencyCode: 'TRY',
          currencySymbol: '₺',
        ),
        ProductDetails(
          id: 'com.hisle.app.credits.10',
          title: '10 Kredi (Android test modu)',
          description: 'Butona bastığında hesabına 10 kredi eklenir.',
          price: 'Test ekle',
          rawPrice: 0,
          currencyCode: 'TRY',
          currencySymbol: '₺',
        ),
        ProductDetails(
          id: 'com.hisle.app.credits.50',
          title: '50 Kredi (Android test modu)',
          description: 'Butona bastığında hesabına 50 kredi eklenir.',
          price: 'Test ekle',
          rawPrice: 0,
          currencyCode: 'TRY',
          currencySymbol: '₺',
        ),
      ];
}
