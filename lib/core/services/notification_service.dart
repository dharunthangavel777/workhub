import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:qwok/core/constants/api_constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static String get _baseUrl => ApiConstants.apiBaseUrl;

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 1. Request Permissions
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permissions');
    }

    // 2. Setup Local Notifications (for Foreground)
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(initSettings);

    // 3. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // 4. Handle Background/Terminated state clicks
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification clicked: ${message.data}');
      _handleNotificationClick(message);
    });

    // 5. Handle initial message (when app is launched from terminated state)
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(initialMessage);
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    final String? category = message.data['category'];
    final Map<String, dynamic> data = message.data;

    // We assume there's a Global Navigator Key set up. 
    // If not, we'll need to provide one or use a navigation service.
    // For now, I'll implement the logic assuming we can navigate.

    debugPrint('Handling click for category: $category');

    switch (category) {
      case 'chat_message':
        final chatId = data['chatId'];
        if (chatId != null) {
          // Navigator.of(context).pushNamed('/chat', arguments: chatId);
          debugPrint('Navigating to Chat: $chatId');
        }
        break;
      case 'bid_approved':
      case 'application_status':
        final projectId = data['projectId'];
        if (projectId != null) {
          debugPrint('Navigating to Project Details: $projectId');
        }
        break;
      case 'withdrawal_pending':
      case 'payout_initiated':
      case 'payout_settled':
      case 'payout_failed':
        debugPrint('Navigating to Transaction History');
        break;
      case 'dispute_raised':
      case 'dispute_resolved':
        final projectId = data['projectId'];
        if (projectId != null) {
          debugPrint('Navigating to Dispute Resolution: $projectId');
        }
        break;
      default:
        debugPrint('Unknown category or no specific route for $category');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'workhub_notifications',
            'WorkHub Notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: message.data.toString(),
      );
    }
  }

  Future<String?> getToken() async {
    return await _fcm.getToken();
  }

  Future<void> saveTokenToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? token = await getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('FCM Token saved to Firestore');
      }
    }
  }

  // Send a notification by writing to Firestore AND calling the Vercel API
  Future<void> sendNotification({
    required String recipientId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? category,
  }) async {
    // 1. Audit/History: Write to Firestore
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'recipientId': recipientId,
        'senderId': FirebaseAuth.instance.currentUser?.uid,
        'title': title,
        'body': body,
        'data': data ?? {},
        'category': category,
        'status':
            'pending', // Will stay pending if no trigger, but that's fine for history
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error saving notification to Firestore: $e");
    }

    // 2. Actual Push: Call Vercel API
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final token = await user.getIdToken();
      debugPrint("Sending push notification via Vercel API...");

      final response = await http.post(
        Uri.parse('$_baseUrl/sendPushNotification'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'recipientId': recipientId,
          'title': title,
          'body': body,
          'data': data,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("Push notification sent successfully.");
      } else {
        debugPrint("Failed to send push notification: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error calling Vercel API: $e");
    }
  }
}



