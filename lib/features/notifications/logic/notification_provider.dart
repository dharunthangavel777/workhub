import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;

  int get unreadCount => _notifications.where((n) => n.status == 'pending' || n.status == 'unread').length;

  NotificationProvider() {
    _listenToNotifications();
  }

  void _listenToNotifications() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        _notifications = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      FirebaseFirestore.instance
          .collection('notifications')
          .where('recipientId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
        _notifications = snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList();
        _isLoading = false;
        notifyListeners();
      });
    });
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'status': 'read'});
    } catch (e) {
      debugPrint("Error marking notification as read: \$e");
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final batch = FirebaseFirestore.instance.batch();
      final unreadDocs = await FirebaseFirestore.instance
          .collection('notifications')
          .where('recipientId', isEqualTo: user.uid)
          .where('status', isNotEqualTo: 'read')
          .get();

      if (unreadDocs.docs.isEmpty) return;

      for (var doc in unreadDocs.docs) {
        batch.update(doc.reference, {'status': 'read'});
      }
      await batch.commit();
    } catch (e) {
      debugPrint("Error marking all as read: \$e");
    }
  }
}
