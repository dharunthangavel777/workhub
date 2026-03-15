import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:qwok/core/constants/api_constants.dart';
import 'package:qwok/features/profile/domain/models/rating.dart';

class RatingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitRating(Rating rating) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");
      final token = await user.getIdToken();

      final response = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}/submitRating'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'targetUserId': rating.ratedUser,
          'projectId': rating.projectId,
          'rating': rating.score,
          'review': rating.review,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? "Rating submission failed");
      }

      debugPrint("Rating submitted successfully for ${rating.ratedUser}");
    } catch (e) {
      debugPrint("Submit Rating Error: $e");
      throw Exception("Failed to submit rating: $e");
    }
  }

  Future<Rating?> getRatingById(String ratingId) async {
    try {
      final doc = await _firestore.collection('ratings').doc(ratingId).get();
      if (doc.exists && doc.data() != null) {
        return Rating.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Rating?> getRatingByProjectAndRole(
      String projectId, String raterRole) async {
    try {
      final snapshot = await _firestore
          .collection('ratings')
          .where('projectId', isEqualTo: projectId)
          .where('raterRole', isEqualTo: raterRole)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return Rating.fromMap(doc.id, doc.data());
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Stream<List<Rating>> getReviewsStream(String userId) {
    return _firestore
        .collection('ratings')
        .where('ratedUser', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Rating.fromMap(doc.id, doc.data()))
          .toList();
    });
  }
}



