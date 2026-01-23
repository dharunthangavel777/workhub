import 'package:flutter/material.dart';
import 'package:work_hub/data/models/ad_model.dart';
import 'package:work_hub/logic/services/ad_service.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:work_hub/data/services/storage_service.dart';

class AdProvider with ChangeNotifier {
  final AdService _adService = AdService();
  final StorageService _storageService = StorageService();

  List<AdModel> _ownerAds = [];
  bool _isLoading = false;
  String? _error;

  List<AdModel> get ownerAds => _ownerAds;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch Ads for Current Owner
  Future<void> fetchOwnerAds(String ownerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _adService.getAdsByOwner(ownerId).listen((ads) {
        _ownerAds = ads;
        _isLoading = false;
        notifyListeners();
      }, onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Active Ads for Workers
  List<AdModel> _activeAds = [];
  List<AdModel> get activeAds => _activeAds;

  Future<void> fetchActiveAds() async {
    // _isLoading = true; // Don't block whole UI for background ad fetch
    try {
      _activeAds = await _adService.getActiveAds();
      notifyListeners();
    } catch (e) {
      print("Error fetching active ads: $e");
    }
  }

  // Create Campaign
  Future<void> createCampaign({
    required String ownerId,
    required File videoFile,
    required String caption,
    required String ctaLabel,
    required String ctaLink,
    required double budget,
    required int durationDays,
    required String username,
    required String userPhotoUrl,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Upload Video
      final String fileName = 'ad_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final String? videoUrl =
          await _storageService.uploadFile('ads/$ownerId/$fileName', videoFile);

      if (videoUrl == null) {
        throw Exception("Failed to upload video file.");
      }

      // Placeholder thumbnail (Optional: Generate real thumbnail if feasible, otherwise use placeholder)
      String thumbnailUrl = "https://via.placeholder.com/150";

      final String adId = const Uuid().v4();
      final DateTime now = DateTime.now();

      final newAd = AdModel(
        id: adId,
        ownerId: ownerId,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        caption: caption,
        ctaLabel: ctaLabel,
        ctaLink: ctaLink,
        status: 'pending',
        totalBudget: budget,
        remainingBudget: budget,
        startDate: now,
        endDate: now.add(Duration(days: durationDays)),
        createdAt: now,
        username: username,
        userPhotoUrl: userPhotoUrl,
      );

      await _adService.createAd(newAd);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void logImpression(String adId) {
    _adService.incrementAdView(adId);
  }

  void logClick(String adId) {
    _adService.incrementAdClick(adId);
  }
}
