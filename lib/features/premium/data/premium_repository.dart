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

  Future<List<ProductDetails>> loadProducts() async {
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
    await _purchases.restorePurchases();
    await _functions.httpsCallable('restoreEntitlementsIfNeeded').call();
    await _analytics.logEvent('purchase_restored');
  }

  Future<void> buyProduct(ProductDetails product) => _purchases.buy(product);
}
