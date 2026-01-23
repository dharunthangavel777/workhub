import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:work_hub/data/models/ad_model.dart';

class AdService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'ads';

  // Create a new Ad Campaign
  Future<void> createAd(AdModel ad) async {
    try {
      await _firestore.collection(_collection).doc(ad.id).set(ad.toMap());
    } catch (e) {
      throw Exception('Failed to create ad: $e');
    }
  }

  // Fetch Ads for a specific Owner
  Stream<List<AdModel>> getAdsByOwner(String ownerId) {
    return _firestore
        .collection(_collection)
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AdModel.fromMap(doc.data())).toList();
    });
  }

  // Fetch Active Ads for Feed Injection (Worker View)
  Future<List<AdModel>> getActiveAds({int limit = 5}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'active')
          // .where('remainingBudget', isGreaterThan: 0) // Compound index might be needed
          // .orderBy('createdAt', descending: true) // Removed to avoid index requirement for now
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => AdModel.fromMap(doc.data())).toList();
    } catch (e) {
      print("Error fetching active ads: $e");
      return [];
    }
  }

  // Fetch Pending Ads for Admin Review
  Future<List<AdModel>> getPendingAds() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs.map((doc) => AdModel.fromMap(doc.data())).toList();
    } catch (e) {
      print("Error fetching pending ads: $e");
      return [];
    }
  }

  // Update Ad Status (Approve/Reject/Pause)
  Future<void> updateAdStatus(String adId, String status,
      {String? rejectionReason}) async {
    try {
      final Map<String, dynamic> data = {'status': status};
      if (rejectionReason != null && status == 'rejected') {
        data['rejectionReason'] = rejectionReason;
      }
      await _firestore.collection(_collection).doc(adId).update(data);
    } catch (e) {
      throw Exception('Failed to update ad status: $e');
    }
  }

  // Track Ad Metrics (View)
  Future<void> incrementAdView(String adId) async {
    try {
      await _firestore.collection(_collection).doc(adId).update({
        'metrics.views': FieldValue.increment(1),
        // 'budget.remaining': FieldValue.increment(-0.5), // Example cost per view logic if needed
      });
    } catch (e) {
      print("Error incrementing ad view: $e");
    }
  }

  // Track Ad Click
  Future<void> incrementAdClick(String adId) async {
    try {
      await _firestore.collection(_collection).doc(adId).update({
        'metrics.clicks': FieldValue.increment(1),
      });
    } catch (e) {
      print("Error incrementing ad click: $e");
    }
  }

  // Toggle Like
  Future<void> toggleLikeAd(String adId, String userId, bool isLiked) async {
    // This would require a subcollection for likes to be robust,
    // but for simplicity we'll just increment the counter for now
    // or assume local state handling + firestore increment.
    // For a real app, use a 'likes' subcollection.
    try {
      await _firestore.collection(_collection).doc(adId).update({
        'metrics.likes': FieldValue.increment(isLiked ? 1 : -1),
      });
    } catch (e) {
      print("Error toggling like: $e");
    }
  }
}
