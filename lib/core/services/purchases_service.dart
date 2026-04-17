import 'dart:async';

import 'package:iliski_kocu_ai/core/config/env.dart';
import 'package:iliski_kocu_ai/core/services/analytics_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PurchasesService {
  PurchasesService(this._analytics) : _inAppPurchase = InAppPurchase.instance;

  final AnalyticsService _analytics;
  final InAppPurchase _inAppPurchase;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool get useAndroidPurchaseSimulation => Env.useAndroidPurchaseSimulation;

  Future<bool> isAvailable() => _inAppPurchase.isAvailable();

  Future<List<ProductDetails>> getProducts() async {
    final response = await _inAppPurchase.queryProductDetails(Env.premiumProductIds.toSet());
    return response.productDetails;
  }

  void attachPurchaseListener(Future<void> Function(PurchaseDetails) onPurchase) {
    _subscription ??= _inAppPurchase.purchaseStream.listen((purchases) async {
      for (final purchase in purchases) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          await _analytics.logEvent('purchase_completed', {'product_id': purchase.productID});
          await onPurchase(purchase);
        }
        if (purchase.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchase);
        }
      }
    });
  }

  Future<void> restorePurchases() async {
    await _analytics.logEvent('purchase_started', {'source': 'restore'});
    await _inAppPurchase.restorePurchases();
  }

  Future<void> buy(ProductDetails product) async {
    await _analytics.logEvent('purchase_started', {'product_id': product.id});
    final param = PurchaseParam(productDetails: product);
    if (product.id.contains('.credits.')) {
      await _inAppPurchase.buyConsumable(purchaseParam: param);
    } else {
      await _inAppPurchase.buyNonConsumable(purchaseParam: param);
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
