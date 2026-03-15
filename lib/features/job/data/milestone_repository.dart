import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:qwok/core/constants/api_constants.dart';
import 'package:qwok/features/freelance/models/milestone.dart';

class MilestoneRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createMilestone(String projectId, Milestone milestone) async {
    final ref = _firestore
        .collection('projects')
        .doc(projectId)
        .collection('milestones')
        .doc();

    await ref.set(milestone.copyWith(id: ref.id).toMap());
  }

  Stream<List<Milestone>> getMilestonesStream(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('milestones')
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Milestone.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> submitMilestoneWork(
    String projectId,
    String milestoneId,
    String note,
    List<String> links,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");
      final token = await user.getIdToken();

      final response = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}/submitMilestone'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'projectId': projectId,
          'milestoneId': milestoneId,
          'note': note,
          'links': links,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? "Milestone submission failed");
      }
    } catch (e) {
      debugPrint("Submit Milestone Error: $e");
      throw Exception("Failed to submit milestone work: $e");
    }
  }

  Future<void> approveMilestone(String projectId, String milestoneId) async {
    try {
      final milestoneRef = _firestore
          .collection('projects')
          .doc(projectId)
          .collection('milestones')
          .doc(milestoneId);

      final milestoneDoc = await milestoneRef.get();
      if (!milestoneDoc.exists) throw Exception("Milestone not found");
      final amount = (milestoneDoc.data()?['amount'] ?? 0.0).toDouble();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");
      final token = await user.getIdToken();

      final response = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}/releasePayment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'projectId': projectId,
          'amount': amount,
          'milestoneId': milestoneId,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? "Payment release failed");
      }
    } catch (e) {
      debugPrint("Approve Milestone Error: $e");
      throw Exception("Failed to approve milestone: $e");
    }
  }

  Future<void> updateMilestoneAgreedStatus(
    String projectId,
    String milestoneId,
    bool agreed,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");
      final token = await user.getIdToken();

      final response = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}/agreeToMilestone'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'projectId': projectId,
          'milestoneId': milestoneId,
          'agreed': agreed,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? "Agreement failed");
      }
    } catch (e) {
      debugPrint("Update Agreement Error: $e");
      throw Exception("Failed to update agreement: $e");
    }
  }

  Future<void> rejectMilestone(
      String projectId, String milestoneId, String reason) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");
      final token = await user.getIdToken();

      final response = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}/rejectMilestone'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'projectId': projectId,
          'milestoneId': milestoneId,
          'reason': reason,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? "Rejection failed");
      }
    } catch (e) {
      debugPrint("Reject Milestone Error: $e");
      throw Exception("Failed to reject milestone: $e");
    }
  }
}



