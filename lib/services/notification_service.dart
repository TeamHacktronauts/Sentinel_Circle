import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _oneSignalUserId;
  
  // OneSignal REST API Key (get this from OneSignal Dashboard > Settings > Keys & IDs)
  static const String _oneSignalApiKey = 'YOUR_ONESIGNAL_REST_API_KEY';
  static const String _appId = '79f23d2b-5e1a-4e67-824d-218381c8ddb9';

  // Initialize OneSignal
  Future<void> initializeNotifications() async {
    try {
      // Initialize OneSignal
      OneSignal.initialize('79f23d2b-5e1a-4e67-824d-218381c8ddb9');
      
      // Request permission
      await OneSignal.Notifications.requestPermission(true);
      
      // Get OneSignal player ID
      final deviceState = await OneSignal.User.getOnesignalId();
      if (deviceState != null) {
        _oneSignalUserId = deviceState;
        await _saveOneSignalId(_oneSignalUserId!);
        print('OneSignal Player ID: $_oneSignalUserId');
      }
      
      // Set notification handlers
      OneSignal.Notifications.addClickListener((event) {
        print('Notification clicked: ${event.notification.title}');
        _handleNotificationOpened(event);
      });
      
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        print('Notification received in foreground: ${event.notification.title}');
        event.preventDefault();
        event.notification.display();
      });
      
    } catch (e) {
      print('Error initializing OneSignal: $e');
    }
  }


  // Save OneSignal Player ID to Firestore
  Future<void> _saveOneSignalId(String playerId) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = _firestore.collection('users').doc(user.uid);
        
        // Check if document exists, if not create it
        final docSnapshot = await userDoc.get();
        
        if (docSnapshot.exists) {
          await userDoc.update({
            'oneSignalId': playerId,
            'tokenUpdatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          await userDoc.set({
            'uid': user.uid,
            'email': user.email,
            'oneSignalId': playerId,
            'tokenUpdatedAt': FieldValue.serverTimestamp(),
            'trustedContacts': [],
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print('Error saving OneSignal ID: $e');
    }
  }

  // Handle notification opened
  void _handleNotificationOpened(OSNotificationClickEvent event) {
    final notification = event.notification;
    print('Notification opened: ${notification.title}');
    
    // You can navigate to specific screens based on notification data
    if (notification.additionalData != null) {
      final data = notification.additionalData!;
      print('Additional data: $data');
      
      // Handle emergency notification
      if (data['type'] == 'emergency') {
        // Navigate to emergency screen
        // Get the navigator key from your app and use it to navigate
      }
    }
  }

  // Send emergency notification to trusted contacts using OneSignal
  Future<void> sendEmergencyNotification(String emergencyEventId) async {
    try {
      // Get the emergency event details
      final eventDoc = await _firestore
          .collection('emergency_events')
          .doc(emergencyEventId)
          .get();

      if (!eventDoc.exists) return;

      final eventData = eventDoc.data() as Map<String, dynamic>?;
      if (eventData == null) return;

      final senderUid = eventData['senderUid']?.toString() ?? '';
      if (senderUid.isEmpty) return;

      // Get the sender's trusted contacts
      final senderDoc = await _firestore.collection('users').doc(senderUid).get();
      if (!senderDoc.exists) return;

      final senderData = senderDoc.data() as Map<String, dynamic>?;
      if (senderData == null) return;

      final trustedContactsList = senderData['trustedContacts'] as List<dynamic>?;
      final trustedContacts = trustedContactsList
          ?.map((contact) => contact as Map<String, dynamic>?)
          .where((contact) => contact != null)
          .cast<Map<String, dynamic>>()
          .toList() ?? [];

      // Find OneSignal IDs for trusted contacts
      for (final contact in trustedContacts) {
        final email = contact['email']?.toString();
        if (email == null || email.isEmpty) continue;
        
        // Find user with this email
        final userQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (userQuery.docs.isEmpty) continue;

        final contactUserDoc = userQuery.docs.first;
        final contactData = contactUserDoc.data();
        final oneSignalId = contactData['oneSignalId']?.toString();

        if (oneSignalId != null && oneSignalId.isNotEmpty) {
          // Send notification via OneSignal
          await _sendOneSignalNotification(
            oneSignalId,
            'Emergency Alert',
            'Emergency signal triggered. Location available.',
            {
              'type': 'emergency',
              'emergencyEventId': emergencyEventId,
              'senderUid': senderUid,
              'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            },
          );
        }
      }
    } catch (e) {
      print('Error sending emergency notification: $e');
    }
  }
  // Send notification via OneSignal REST API
  Future<void> _sendOneSignalNotification(
    String playerId,
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    try {
      final url = Uri.parse('https://onesignal.com/api/v1/notifications');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $_oneSignalApiKey',
        },
        body: jsonEncode({
          'app_id': _appId,
          'include_player_ids': [playerId],
          'headings': {'en': title},
          'contents': {'en': body},
          'data': data,
        }),
      );
      
      if (response.statusCode == 200) {
        print('OneSignal notification sent to $playerId');
      } else {
        print('Failed to send notification: ${response.body}');
      }
    } catch (e) {
      print('Error sending OneSignal notification: $e');
    }
  }

  // Get user's OneSignal Player ID
  String? getOneSignalId() {
    return _oneSignalUserId;
  }
}
