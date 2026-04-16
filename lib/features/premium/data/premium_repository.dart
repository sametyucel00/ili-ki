import 'package:cloud_functions/cloud_functions.dart';
import 'package:iliski_kocu_ai/core/services/analytics_service.dart';
import 'package:iliski_kocu_ai/core/services/purchases_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PremiumRepository {
  PremiumRepository({
    required FirebaseFunctions functions,
    required PurchasesService purchases,
    required AnalyticsService analytics,
  })  : _functions = functions,
        _purchases = purchases,
        _analytics = analytics;

  final FirebaseFunctions _functions;
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
      await _functions.httpsCallable('completeDebugPurchase').call({
        'productId': product.id,
      });
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
