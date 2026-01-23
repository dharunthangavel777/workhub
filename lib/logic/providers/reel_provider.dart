import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:work_hub/data/models/reel_model.dart';
import 'package:work_hub/data/models/reel_comment_model.dart';
import 'package:work_hub/data/repositories/reel_repository.dart';
import 'package:work_hub/data/services/storage_service.dart';
import 'package:work_hub/data/models/user_model.dart';

class ReelProvider extends ChangeNotifier {
  final ReelRepository _repository = ReelRepository();
  final StorageService _storage = StorageService();

  List<ReelModel> _reels = [];
  List<ReelModel> get reels => _reels;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Fetch all reels
  Future<void> fetchReels() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reels = await _repository.getReels();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Like / Unlike
  Future<void> toggleLike(String reelId, UserModel user) async {
    final reelIndex = _reels.indexWhere((r) => r.id == reelId);
    if (reelIndex == -1) return;

    final reel = _reels[reelIndex];
    final isLiked = reel.likedBy.contains(user.uid);

    try {
      if (isLiked) {
        // Optimistic UI update
        _reels[reelIndex] = reel.copyWith(
          likesCount: reel.likesCount - 1,
          likedBy: reel.likedBy.where((id) => id != user.uid).toList(),
        );
        notifyListeners();
        await _repository.unlikeReel(reelId, user.uid);
      } else {
        // Optimistic UI update
        _reels[reelIndex] = reel.copyWith(
          likesCount: reel.likesCount + 1,
          likedBy: [...reel.likedBy, user.uid],
        );
        notifyListeners();
        await _repository.likeReel(reelId, user.uid);
      }
    } catch (e) {
      // Revert on error
      _reels[reelIndex] = reel;
      notifyListeners();
      debugPrint("Toggle Like Error: $e");
    }
  }

  // Add Comment
  Future<void> addComment(String reelId, String text, UserModel user) async {
    final comment = ReelCommentModel(
      id: '', // Firestore sets this
      userId: user.uid,
      text: text,
      createdAt: DateTime.now(),
      username: user.displayName,
      userPhotoUrl: user.photoURL,
    );

    try {
      await _repository.addComment(reelId, comment);
    } catch (e) {
      debugPrint("Add Comment Error: $e");
    }
  }

  // Get Comments Stream
  Stream<List<ReelCommentModel>> getComments(String reelId) {
    return _repository.getComments(reelId);
  }

  // Upload Reel
  Future<bool> uploadReel(
      File videoFile, String caption, UserModel user) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Upload to Supabase Storage
      final fileName = 'reel_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final path = 'reels/${user.uid}/$fileName';
      final videoUrl = await _storage.uploadFile(path, videoFile);

      if (videoUrl == null) throw Exception("Failed to upload video");

      // 2. Save metadata to Firestore
      final reel = ReelModel(
        id: '',
        userId: user.uid,
        videoUrl: videoUrl,
        caption: caption,
        createdAt: DateTime.now(),
        username: user.displayName,
        userPhotoUrl: user.photoURL,
      );

      await _repository.createReel(reel);
      await fetchReels(); // Refresh feed
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete Reel
  Future<void> deleteReel(String reelId) async {
    try {
      await _repository.deleteReel(reelId);
      _reels.removeWhere((r) => r.id == reelId);
      notifyListeners();
    } catch (e) {
      debugPrint("Delete Reel Error: $e");
    }
  }
}
