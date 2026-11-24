import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../app/app_state.dart';

/// ID produk Cipher Pro di Google Play Console (jenis: produk dalam aplikasi,
/// sekali beli). Bikin produk dengan ID yang sama persis di Play Console.
const kProProductId = 'cipher_pro';

/// Ngurus pembelian Cipher Pro lewat Google Play Billing.
/// Status Pro nempel ke akun Google, jadi bisa dipulihkan di HP mana aja.
class ProService extends ChangeNotifier {
  ProService._();
  static final instance = ProService._();

  final _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  AppState? _state;

  bool loading = true;
  bool storeAvailable = false;
  bool busy = false;
  ProductDetails? product;
  String? error;

  Future<void> init(AppState state) async {
    _state = state;
    if (_sub != null) return;
    _sub = _iap.purchaseStream.listen(
      _onPurchases,
      onError: (Object e) {
        error = 'stream';
        busy = false;
        notifyListeners();
      },
    );
    await refresh();
  }

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      storeAvailable = await _iap.isAvailable();
      if (storeAvailable) {
        final res = await _iap.queryProductDetails({kProProductId});
        product = res.productDetails.isEmpty ? null : res.productDetails.first;
      }
    } catch (_) {
      storeAvailable = false;
    }
    loading = false;
    notifyListeners();
  }

  Future<void> buy() async {
    final p = product;
    if (p == null) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: p));
    } catch (_) {
      busy = false;
      error = 'buy';
      notifyListeners();
    }
  }

  Future<void> restore() async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      await _iap.restorePurchases();
    } catch (_) {
      error = 'restore';
    }
    // hasil pulihan datang lewat stream; kasih jeda biar UI gak nyangkut
    Future<void>.delayed(const Duration(seconds: 4), () {
      if (busy) {
        busy = false;
        notifyListeners();
      }
    });
    notifyListeners();
  }

  Future<void> _onPurchases(List<PurchaseDetails> list) async {
    for (final p in list) {
      if (p.productID == kProProductId) {
        switch (p.status) {
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            await _state?.setPro(true);
            busy = false;
          case PurchaseStatus.error:
            error = 'buy';
            busy = false;
          case PurchaseStatus.canceled:
            busy = false;
          case PurchaseStatus.pending:
            busy = true;
        }
      }
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
    notifyListeners();
  }
}
