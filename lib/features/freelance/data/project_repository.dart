import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:qwok/core/constants/api_constants.dart';
import 'package:qwok/features/job/domain/models/job.dart';
import 'package:qwok/features/freelance/models/time_entry.dart';
import 'package:qwok/features/common/dispute/models/dispute.dart';
import 'package:qwok/core/services/storage_service.dart';
import 'package:qwok/core/services/notification_service.dart';

class ProjectRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storage = StorageService();

  Stream<List<Job>> getProjectPostsStream() {
    return _firestore.collection('project_posts').snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Job.fromMap(doc.id, doc.data(), postType: 'project'))
          .where((post) => post.status == 'approved' || post.status == 'pending')
          .toList();
      // Sort in memory to avoid composite index requirements
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> submitBid(
    String projectId,
    String userId,
    Map<String, dynamic> bidData,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");
      final token = await user.getIdToken();

      final response = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}/submitBid'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'projectId': projectId,
          'bidData': bidData,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? "Bid submission failed");
      }

      debugPrint(
          "Bid submitted successfully for project $projectId by user $userId");
    } catch (e) {
      debugPrint("Submit Bid Error: $e");
      throw Exception("Failed to submit bid: $e");
    }
  }

  Stream<List<Map<String, dynamic>>> getWorkerProjectsStream(String userId) {
    return _firestore
        .collection('projects')
        .where('workerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> updateProject(
    String projectId,
    Map<String, dynamic> updates,
  ) async {
    await _firestore.collection('projects').doc(projectId).update(updates);
  }

  Future<void> uploadProjectFile({
    required String projectId,
    required File file,
    required String fileName,
    required String userId,
    required String userName,
  }) async {
    try {
      final path =
          'projects/$projectId/shared_files/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      final downloadUrl = await _storage.uploadFile(path, file);

      if (downloadUrl == null) throw Exception("Failed to upload file");

      final fileMetadata = {
        'name': fileName,
        'url': downloadUrl,
        'size': await file.length(),
        'uploadedBy': userId,
        'uploadedByName': userName,
        'uploadedAt': DateTime.now().millisecondsSinceEpoch,
        'storagePath': path,
      };

      await _firestore.collection('projects').doc(projectId).update({
        'sharedFiles': FieldValue.arrayUnion([fileMetadata]),
      });

      debugPrint("File uploaded successfully to project $projectId: $fileName");
    } catch (e) {
      debugPrint("Upload Project File Error: $e");
      throw Exception("Failed to upload file: $e");
    }
  }

  Future<void> deleteProjectFile({
    required String projectId,
    required Map<String, dynamic> fileMetadata,
  }) async {
    try {
      final storagePath = fileMetadata['storagePath'];
      if (storagePath != null) {
        await _storage.deleteFile(storagePath);
      }

      await _firestore.collection('projects').doc(projectId).update({
        'sharedFiles': FieldValue.arrayRemove([fileMetadata]),
      });

      debugPrint("File deleted successfully from project $projectId");
    } catch (e) {
      debugPrint("Delete Project File Error: $e");
      throw Exception("Failed to delete file: $e");
    }
  }

  Future<void> logTimeEntry(String projectId, TimeEntry entry) async {
    try {
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('time_entries')
          .doc(entry.id.isEmpty ? null : entry.id)
          .set(entry.toMap());
    } catch (e) {
      throw Exception("Failed to log time entry: $e");
    }
  }

  Stream<List<TimeEntry>> getTimeEntriesStream(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('time_entries')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TimeEntry.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> updateTimeEntryStatus(
    String projectId,
    String entryId,
    TimeEntryStatus status, {
    String? rejectionReason,
  }) async {
    try {
      final updates = {
        'status': status.name,
        if (status == TimeEntryStatus.approved) 'approvedAt': Timestamp.now(),
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
      };

      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('time_entries')
          .doc(entryId)
          .update(updates);
    } catch (e) {
      throw Exception("Failed to update time entry status: $e");
    }
  }

  Future<void> raiseDispute(DisputeInfo dispute) async {
    await _firestore
        .collection('disputes')
        .doc(dispute.id)
        .set(dispute.toMap());

    final projectDoc =
        await _firestore.collection('projects').doc(dispute.projectId).get();
    final workerId = projectDoc.data()?['workerId'];
    final ownerId = projectDoc.data()?['ownerId'];
    final recipientId = (dispute.raisedBy == ownerId) ? workerId : ownerId;

    if (recipientId != null) {
      NotificationService().sendNotification(
        recipientId: recipientId,
        title: 'Dispute Raised',
        body: 'A dispute has been opened for your project: ${dispute.reason}',
        category: 'dispute_raised',
        data: {'projectId': dispute.projectId, 'disputeId': dispute.id},
      );
    }
  }

  Stream<List<DisputeInfo>> getDisputesStream(String projectId) {
    return _firestore
        .collection('disputes')
        .where('projectId', isEqualTo: projectId)
        .orderBy('raisedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return DisputeInfo.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Stream<List<DisputeInfo>> getAllDisputesStream() {
    return _firestore
        .collection('disputes')
        .orderBy('raisedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return DisputeInfo.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<String> uploadDisputeFile({
    required String projectId,
    required File file,
    required String fileName,
  }) async {
    try {
      final path =
          'disputes/$projectId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      final downloadUrl = await _storage.uploadFile(path, file);

      if (downloadUrl == null) throw Exception("Failed to upload evidence");

      return downloadUrl;
    } catch (e) {
      throw Exception("Failed to upload evidence: $e");
    }
  }
}



