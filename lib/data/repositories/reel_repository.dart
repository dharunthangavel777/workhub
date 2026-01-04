import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reel_model.dart';
import '../models/reel_comment_model.dart';

class ReelRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch Reels
  Future<List<ReelModel>> getReels() async {
    final snapshot = await _firestore
        .collection('reels')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => ReelModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Fetch User's Reels
  Future<List<ReelModel>> getUserReels(String userId) async {
    final snapshot = await _firestore
        .collection('reels')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => ReelModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Like Reel
  Future<void> likeReel(String reelId, String userId) async {
    await _firestore.collection('reels').doc(reelId).update({
      'likesCount': FieldValue.increment(1),
      'likedBy': FieldValue.arrayUnion([userId]),
    });
  }

  // Unlike Reel
  Future<void> unlikeReel(String reelId, String userId) async {
    await _firestore.collection('reels').doc(reelId).update({
      'likesCount': FieldValue.increment(-1),
      'likedBy': FieldValue.arrayRemove([userId]),
    });
  }

  // Add Comment
  Future<void> addComment(String reelId, ReelCommentModel comment) async {
    await _firestore
        .collection('reels')
        .doc(reelId)
        .collection('comments')
        .add(comment.toMap());
  }

  // Get Comments
  Stream<List<ReelCommentModel>> getComments(String reelId) {
    return _firestore
        .collection('reels')
        .doc(reelId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReelCommentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Create Reel
  Future<void> createReel(ReelModel reel) async {
    await _firestore.collection('reels').add(reel.toMap());
  }

  // Delete Reel
  Future<void> deleteReel(String reelId) async {
    await _firestore.collection('reels').doc(reelId).delete();
  }
}
