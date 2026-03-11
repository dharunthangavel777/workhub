import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../job/domain/models/ad_model.dart';
import 'dart:async';

class AdService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // -- Real Ad Logic (Campaigns) --

  Stream<List<AdModel>> getAdsByOwner(String ownerId) {
    return _firestore
        .collection('ads')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AdModel.fromMap(doc.data())).toList();
    });
  }

  Future<List<AdModel>> getActiveAds() async {
    final now = DateTime.now();
    // Note: Composite index required for 'status' + 'endDate'
    final snapshot = await _firestore
        .collection('ads')
        .where('status', isEqualTo: 'active')
        .where('endDate', isGreaterThan: now)
        .get();

    return snapshot.docs.map((doc) => AdModel.fromMap(doc.data())).toList();
  }

  Future<void> createAd(AdModel ad) async {
    await _firestore.collection('ads').doc(ad.id).set(ad.toMap());
  }

  Future<void> incrementAdView(String adId) async {
    await _firestore.collection('ads').doc(adId).update({
      'views': FieldValue.increment(1),
    });
  }

  Future<void> incrementAdClick(String adId) async {
    await _firestore.collection('ads').doc(adId).update({
      'clicks': FieldValue.increment(1),
    });
  }

  // -- Placeholder Logic (AdMob/etc) --
  // Kept if needed by other parts of the app, though ad_controller logic seems to prefer the above.

  bool _isAdLoaded = false;
  bool get isAdLoaded => _isAdLoaded;

  Future<void> loadInterstitialAd() async {
    await Future.delayed(const Duration(seconds: 1));
    _isAdLoaded = true;
    notifyListeners();
  }

  Future<void> showInterstitialAd(VoidCallback onComplete) async {
    if (_isAdLoaded) {
      _isAdLoaded = false;
      onComplete();
    } else {
      await loadInterstitialAd();
      onComplete();
    }
  }
}



