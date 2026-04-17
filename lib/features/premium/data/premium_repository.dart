import 'package:iliski_kocu_ai/core/services/analytics_service.dart';
import 'package:iliski_kocu_ai/core/services/local_cache_service.dart';
import 'package:iliski_kocu_ai/core/services/purchases_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PurchaseFeedback {
  const PurchaseFeedback({
    required this.message,
    this.didChangeEntitlement = false,
  });

  final String message;
  final bool didChangeEntitlement;
}

class PurchaseHistoryItem {
  const PurchaseHistoryItem({
    required this.title,
    required this.note,
    required this.createdAt,
  });

  final String title;
  final String note;
  final DateTime createdAt;

  factory PurchaseHistoryItem.fromMap(Map<String, dynamic> map) {
    return PurchaseHistoryItem(
      title: (map['title'] as String?) ?? 'İşlem',
      note: (map['note'] as String?) ?? '',
      createdAt: DateTime.tryParse((map['createdAt'] as String?) ?? '') ?? DateTime.now(),
    );
  }
}

class PremiumRepository {
  PremiumRepository({
    required LocalCacheService cache,
    required PurchasesService purchases,
    required AnalyticsService analytics,
  })  : _cache = cache,
        _purchases = purchases,
        _analytics = analytics;

  final LocalCacheService _cache;
  final PurchasesService _purchases;
  final AnalyticsService _analytics;

  bool get useAndroidPurchaseSimulation => _purchases.useAndroidPurchaseSimulation;

  Future<List<ProductDetails>> loadProducts() async {
    if (useAndroidPurchaseSimulation) {
      final available = await _purchases.isAvailable().timeout(
        const Duration(seconds: 3),
        onTimeout: () => false,
      );
      if (!available) {
        return _debugProducts;
      }
      final storeProducts = await _purchases.getProducts().timeout(
        const Duration(seconds: 6),
        onTimeout: () => <ProductDetails>[],
      );
      return storeProducts.isEmpty ? _debugProducts : storeProducts;
    }

    final available = await _purchases.isAvailable().timeout(
      const Duration(seconds: 3),
      onTimeout: () => false,
    );
    if (!available) {
      return [];
    }
    return _purchases.getProducts().timeout(
      const Duration(seconds: 8),
      onTimeout: () => <ProductDetails>[],
    );
  }

  void attachPurchaseListener() {
    _purchases.attachPurchaseListener((purchase) async {
      await _applyLocalPurchase(purchase.productID);
    });
  }

  Future<PurchaseFeedback> restore() async {
    if (useAndroidPurchaseSimulation) {
      await _analytics.logEvent('purchase_restored', {'mode': 'android_simulation'});
      return const PurchaseFeedback(message: 'Satın alımlar kontrol edildi.');
    }

    await _purchases.restorePurchases();
    await _analytics.logEvent('purchase_restored');
    return const PurchaseFeedback(message: 'Satın alımları geri yükleme başlatıldı.');
  }

  Future<PurchaseFeedback> buyProduct(ProductDetails product) async {
    if (useAndroidPurchaseSimulation) {
      await _analytics.logEvent('purchase_started', {
        'product_id': product.id,
        'mode': 'android_simulation',
      });
      final feedback = await _applyLocalPurchase(product.id);
      await _analytics.logEvent('purchase_completed', {
        'product_id': product.id,
        'mode': 'android_simulation',
      });
      return feedback;
    }

    await _purchases.buy(product);
    return const PurchaseFeedback(message: 'Satın alma akışı başlatıldı.');
  }

  Future<void> grantRewardedCredit() async {
    final current = await _cache.getLocalCreditBalance() ?? 1;
    await _cache.addLocalCredits(fallbackBalance: current, amount: 1);
    await _recordHistory(
      title: 'Reklam ödülü',
      note: '1 kredi eklendi.',
    );
    await _analytics.logEvent('rewarded_credit_granted');
  }

  Future<List<PurchaseHistoryItem>> loadPurchaseHistory() async {
    final values = await _cache.readPurchaseHistory();
    return values.map(PurchaseHistoryItem.fromMap).toList();
  }

  Future<PurchaseFeedback> _applyLocalPurchase(String productId) async {
    if (productId == 'com.hisle.app.premium.monthly' || productId == 'com.hisle.app.premium.yearly') {
      final currentProductId = await _cache.getLocalPremiumProductId();
      if (currentProductId == productId) {
        return PurchaseFeedback(
          message: '${_planTitle(productId)} zaten aktif.',
          didChangeEntitlement: false,
        );
      }

      final expiryDate = DateTime.now().add(
        Duration(days: productId.endsWith('.yearly') ? 365 : 31),
      );
      await _cache.setLocalPremiumActive(
        expiryDate: expiryDate,
        productId: productId,
      );

      final didChangePlan = currentProductId != null && currentProductId != productId;
      final message = didChangePlan
          ? 'Paketin ${_planTitle(productId)} olarak güncellendi.'
          : '${_planTitle(productId)} aktif edildi.';
      await _recordHistory(
        title: _planTitle(productId),
        note: message,
      );
      return PurchaseFeedback(
        message: didChangePlan
            ? 'Paketin ${_planTitle(productId)} olarak güncellendi.'
            : '${_planTitle(productId)} aktif edildi.',
        didChangeEntitlement: true,
      );
    }

    final creditPackMap = <String, int>{
      'com.hisle.app.credits.10': 10,
      'com.hisle.app.credits.50': 50,
    };
    final amount = creditPackMap[productId];
    if (amount == null) {
      return const PurchaseFeedback(message: 'Paket tanınmadı.');
    }
    final currentCredits = await _cache.getLocalCreditBalance() ?? 1;
    await _cache.addLocalCredits(fallbackBalance: currentCredits, amount: amount);
    await _recordHistory(
      title: '$amount Kredi',
      note: '$amount kredi hesabına eklendi.',
    );
    return PurchaseFeedback(
      message: '$amount kredi hesabına eklendi.',
      didChangeEntitlement: true,
    );
  }

  String _planTitle(String productId) {
    if (productId.endsWith('.yearly')) {
      return 'Premium Yıllık';
    }
    return 'Premium Aylık';
  }

  Future<void> _recordHistory({
    required String title,
    required String note,
  }) {
    return _cache.appendPurchaseHistory({
      'title': title,
      'note': note,
      'createdAt': DateTime.now().toIso8601String(),
    });
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
