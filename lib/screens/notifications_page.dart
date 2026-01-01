import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/notification_service.dart';

class EmergencyAlert {
  final String id;
  final String senderUid;
  final Timestamp timestamp;
  final GeoPoint location;
  final String mapsUrl;
  final bool notified;

  EmergencyAlert({
    required this.id,
    required this.senderUid,
    required this.timestamp,
    required this.location,
    required this.mapsUrl,
    required this.notified,
  });

  factory EmergencyAlert.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return EmergencyAlert(
        id: doc.id,
        senderUid: '',
        timestamp: Timestamp.now(),
        location: GeoPoint(0, 0),
        mapsUrl: '',
        notified: false,
      );
    }
    
    return EmergencyAlert(
      id: doc.id,
      senderUid: data['senderUid']?.toString() ?? '',
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
      location: data['location'] as GeoPoint? ?? GeoPoint(0, 0),
      mapsUrl: data['mapsUrl']?.toString() ?? '',
      notified: data['notified'] as bool? ?? false,
    );
  }

  DateTime get dateTime => timestamp.toDate();
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
  List<EmergencyAlert> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmergencyAlerts();
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    // Listen for incoming FCM messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received notification in notifications page');
      // Refresh the list when new notification arrives
      _loadEmergencyAlerts();
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification opened app');
      _loadEmergencyAlerts();
    });
  }

  Future<void> _loadEmergencyAlerts() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Get user's email to find emergency events where they are a trusted contact
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        final userData = userDoc.data() as Map<String, dynamic>?;
        
        if (userData != null) {
          final userEmail = userData['email']?.toString() ?? '';
          
          if (userEmail.isNotEmpty) {
            // First try to get user-specific notifications (new secure approach)
            try {
              final userNotificationsSnapshot = await _firestore
                  .collection('user_notifications')
                  .doc(user.uid)
                  .collection('notifications')
                  .orderBy('timestamp', descending: true)
                  .limit(50)
                  .get();
              
              if (userNotificationsSnapshot.docs.isNotEmpty) {
                final alerts = userNotificationsSnapshot.docs
                    .map((doc) => EmergencyAlert.fromFirestore(doc))
                    .toList();
                
                setState(() {
                  _alerts = alerts;
                  _isLoading = false;
                });
                return;
              }
            } catch (e) {
              print('User notifications not available, falling back to filtered approach: $e');
            }
            
            // Fallback: Query all emergency events and filter for trusted contacts (for admin app compatibility)
            final snapshot = await _firestore
                .collection('emergency_events')
                .orderBy('timestamp', descending: true)
                .limit(50)
                .get();
            
            // Filter events where the current user is a trusted contact of the sender
            final filteredAlerts = <EmergencyAlert>[];
            
            for (final doc in snapshot.docs) {
              final alert = EmergencyAlert.fromFirestore(doc);
              
              // Get the sender's trusted contacts to check if current user is included
              final senderDoc = await _firestore.collection('users').doc(alert.senderUid).get();
              final senderData = senderDoc.data() as Map<String, dynamic>?;
              
              if (senderData != null) {
                final trustedContactsList = senderData['trustedContacts'] as List<dynamic>?;
                final trustedContacts = trustedContactsList
                    ?.map((contact) => contact as Map<String, dynamic>?)
                    .where((contact) => contact != null)
                    .cast<Map<String, dynamic>>()
                    .toList() ?? [];
                
                // Check if current user's email is in the trusted contacts
                final isTrustedContact = trustedContacts.any((contact) {
                  final contactEmail = contact['email']?.toString() ?? '';
                  return contactEmail.toLowerCase() == userEmail.toLowerCase();
                });
                
                if (isTrustedContact) {
                  filteredAlerts.add(alert);
                }
              }
            }
            
            setState(() {
              _alerts = filteredAlerts;
              _isLoading = false;
            });
          } else {
            setState(() {
              _alerts = [];
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notifications: $e')),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatDate(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Notifications'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEmergencyAlerts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alerts.isEmpty
              ? _buildEmptyState()
              : _buildAlertsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Emergency Alerts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Emergency alerts from trusted contacts will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _alerts.length,
      itemBuilder: (context, index) {
        final alert = _alerts[index];
        return _buildAlertCard(alert);
      },
    );
  }

  Widget _buildAlertCard(EmergencyAlert alert) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [theme.cardColor, theme.cardColor.withOpacity(0.8)]
            : [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(isDark ? 0.2 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.red.withOpacity(isDark ? 0.3 : 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _showAlertDetails(alert);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade400, Colors.red.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emergency,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark 
                                ? Colors.red.withOpacity(0.2)
                                : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'EMERGENCY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: theme.iconTheme.color?.withOpacity(0.6),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Emergency Alert',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.titleMedium?.color,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDateTime(alert.dateTime),
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.textTheme.bodySmall?.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAlertDetails(EmergencyAlert alert) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 20,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark 
                ? [theme.cardColor, theme.cardColor.withOpacity(0.8)]
                : [Colors.white, Colors.grey.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.red.withOpacity(isDark ? 0.4 : 0.3),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade500, Colors.red.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.emergency,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emergency Alert',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Urgent attention required',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content Section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date and Time Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark 
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark 
                            ? Colors.blue.withOpacity(0.3)
                            : Colors.blue.shade200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Colors.blue.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Date & Time',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.textTheme.bodySmall?.color,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(alert.dateTime),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textTheme.titleMedium?.color,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Time',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.textTheme.bodySmall?.color,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(alert.dateTime),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textTheme.titleMedium?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Location Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark 
                            ? Colors.green.withOpacity(0.3)
                            : Colors.green.shade200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.green.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Location',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Latitude',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.textTheme.bodySmall?.color,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      alert.location.latitude.toStringAsFixed(6),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: theme.textTheme.titleMedium?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Longitude',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.textTheme.bodySmall?.color,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      alert.location.longitude.toStringAsFixed(6),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: theme.textTheme.titleMedium?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            final lat = alert.location.latitude;
                            final lng = alert.location.longitude;
                            final coordinates = '$lat,$lng';
                            
                            await Clipboard.setData(ClipboardData(text: coordinates));
                            
                            if (mounted) {
                              Navigator.pop(context); // Close dialog first
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text('Coordinates copied! Open Google Maps and paste.'),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.green.shade600,
                                  duration: const Duration(seconds: 4),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              Navigator.pop(context); // Close dialog first
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.error, color: Colors.white),
                                      const SizedBox(width: 8),
                                      const Text('Error copying coordinates'),
                                    ],
                                  ),
                                  backgroundColor: Colors.red.shade600,
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.map, size: 20),
                        label: const Text(
                          'View on Google Maps',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
