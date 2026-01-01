import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _oneSignalUserId;
  
  // OneSignal REST API Key (from .env file)
  static final String _oneSignalApiKey = dotenv.env['ONESIGNAL_API_KEY'] ?? 
      String.fromEnvironment('ONESIGNAL_API_KEY', defaultValue: 'YOUR_ONESIGNAL_REST_API_KEY');
  // OneSignal App ID (from .env file)
  static final String _appId = dotenv.env['ONESIGNAL_APP_ID'] ?? 
      String.fromEnvironment('ONESIGNAL_APP_ID', defaultValue: 'YOUR_ONESIGNAL_APP_ID');

  // Initialize OneSignal
  Future<void> initializeNotifications() async {
    try {
      // Initialize OneSignal
      OneSignal.initialize(_appId);
      
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

        // Check for and send any queued notifications for this user
        print('User logged in: ${user.uid}');
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

      if (!eventDoc.exists) {
        print('Emergency event not found: $emergencyEventId');
        return;
      }

      final eventData = eventDoc.data() as Map<String, dynamic>?;
      if (eventData == null) {
        print('Emergency event data is null: $emergencyEventId');
        return;
      }

      final senderUid = eventData['senderUid']?.toString() ?? '';
      if (senderUid.isEmpty) {
        print('Sender UID is empty in emergency event: $emergencyEventId');
        return;
      }

      // Get the sender's trusted contacts
      final senderDoc = await _firestore.collection('users').doc(senderUid).get();
      if (!senderDoc.exists) {
        print('Sender document not found: $senderUid');
        return;
      }

      final senderData = senderDoc.data() as Map<String, dynamic>?;
      if (senderData == null) {
        print('Sender data is null: $senderUid');
        return;
      }

      final trustedContactsList = senderData['trustedContacts'] as List<dynamic>?;
      final trustedContacts = trustedContactsList
          ?.map((contact) => contact as Map<String, dynamic>?)
          .where((contact) => contact != null)
          .cast<Map<String, dynamic>>()
          .toList() ?? [];

      print('Found ${trustedContacts.length} trusted contacts for sender: $senderUid');

      // Process each trusted contact
      for (final contact in trustedContacts) {
        final email = contact['email']?.toString();
        if (email == null || email.isEmpty) {
          print('Skipping contact with empty email');
          continue;
        }
        
        // Find user with this email
        final userQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (userQuery.docs.isEmpty) {
          print('No user found for email: $email');
          continue;
        }

        final contactUserDoc = userQuery.docs.first;
        final contactData = contactUserDoc.data();
        final oneSignalId = contactData['oneSignalId']?.toString();
        final contactUid = contactUserDoc.id;

        print('Processing notification for user: $contactUid (email: $email)');

        // Create user-specific notification record for secure access
        try {
          await _firestore
              .collection('user_notifications')
              .doc(contactUid)
              .collection('notifications')
              .doc(emergencyEventId)
              .set({
                'id': emergencyEventId,
                'senderUid': senderUid,
                'timestamp': eventData['timestamp'] ?? FieldValue.serverTimestamp(),
                'location': eventData['location'] ?? GeoPoint(0, 0),
                'mapsUrl': eventData['mapsUrl'] ?? '',
                'notified': true,
                'recipientUid': contactUid,
                'recipientEmail': email,
                'createdAt': FieldValue.serverTimestamp(),
              });
          print('Created user notification record for: $contactUid');
        } catch (e) {
          print('Error creating user notification record: $e');
        }

        if (oneSignalId != null && oneSignalId.isNotEmpty) {
          // User has OneSignal ID - send high priority notification immediately
          print('Sending emergency notification to $email (Player ID: $oneSignalId)');
          await _sendHighPriorityEmergencyNotification(
            oneSignalId,
            emergencyEventId,
            senderUid,
          );
        } else {
          // User doesn't have OneSignal ID - skip (no queuing needed)
          print('User $email is offline - skipping notification');
        }
      }
    } catch (e) {
      print('Error sending emergency notification: $e');
    }
  }
  // Send high priority emergency notification via OneSignal REST API
  Future<void> _sendHighPriorityEmergencyNotification(
    String playerId,
    String emergencyEventId,
    String senderUid,
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
          'headings': {'en': '🚨 EMERGENCY ALERT'},
          'contents': {'en': 'Emergency signal triggered! Tap to view location and details.'},
          'data': {
            'type': 'emergency',
            'emergencyEventId': emergencyEventId,
            'senderUid': senderUid,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            'priority': 'high',
          },
          'priority': 10, // Highest priority
          'ttl': 3600, // Time to live: 1 hour
          'android_channel_id': 'emergency_alerts',
          'android_accent_color': 'FF0000',
          'android_led_color': 'FF0000',
          'android_sound': 'emergency',
          'ios_sound': 'emergency.caf',
        }),
      );
      
      if (response.statusCode == 200) {
        print('High priority emergency notification sent to $playerId');
      } else {
        print('Failed to send emergency notification: ${response.body}');
      }
    } catch (e) {
      print('Error sending high priority emergency notification: $e');
    }
  }

  // Get user's OneSignal Player ID
  String? getOneSignalId() {
    return _oneSignalUserId;
  }
}
