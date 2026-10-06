import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class TipService extends ChangeNotifier {
  static const _ids = {'tip_small', 'tip_medium', 'tip_large'};

  final _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  List<ProductDetails> products = [];
  bool available = false;

  bool loading = true;
  String? buyingId; // id du produit en cours d'achat

  final _onThanks = StreamController<void>.broadcast();
  Stream<void> get onThanks => _onThanks.stream;

  Future<void> init() async {
    available = await _iap.isAvailable();
    if (!available) {
      loading = false;
      notifyListeners();
      return;
    } 

    // À brancher AVANT tout achat : les transactions restées
    // en attente d'une session précédente arrivent ici.
    _sub = _iap.purchaseStream.listen(
      _handle,
      onDone: () => _sub?.cancel(),
      onError: (e) => print('purchaseStream: $e'),
    );

    final rep = await _iap.queryProductDetails(_ids);
    if (rep.error != null) print('query: ${rep.error}');
    products = rep.productDetails
      ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
    loading = false;
    notifyListeners();
  }

  Future<void> buy(ProductDetails p) async {
    buyingId = p.id;
    notifyListeners();
    try {
      await _iap.buyConsumable(purchaseParam: PurchaseParam(productDetails: p));
    } catch (e) {
      buyingId = null;
      notifyListeners();
    }
  }

  Future<void> _handle(List<PurchaseDetails> achats) async {
    for (final a in achats) {
      if (a.status != PurchaseStatus.pending) {
        buyingId = null;
        notifyListeners();
      }
      if (a.status == PurchaseStatus.purchased ||
          a.status == PurchaseStatus.restored) {
        _onThanks.add(null);
      }
      // Obligatoire dans tous les cas terminaux, y compris error.
      if (a.pendingCompletePurchase) {
        await _iap.completePurchase(a);
      }
    }
  }

  void dispose() {
    _sub?.cancel();
    _onThanks.close();
  }
}