import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../services/notification_service.dart';

class SafetyButtonScreen extends StatefulWidget {
  const SafetyButtonScreen({super.key});

  @override
  State<SafetyButtonScreen> createState() => _SafetyButtonScreenState();
}

class _SafetyButtonScreenState extends State<SafetyButtonScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
  bool _isTriggering = false;

  Future<void> _triggerEmergency() async {
    if (_isTriggering) return;
    
    setState(() {
      _isTriggering = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login to trigger emergency signal')),
          );
        }
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are permanently denied')),
          );
        }
        return;
      }

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final lat = position.latitude;
      final lng = position.longitude;
      final mapsUrl = "https://www.google.com/maps?q=$lat,$lng";

      // Store emergency event in Firestore
      final eventRef = await _firestore.collection('emergency_events').add({
        'senderUid': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'location': GeoPoint(lat, lng),
        'mapsUrl': mapsUrl,
        'notified': false,
      });

      // Send notifications to trusted contacts
      await _notificationService.sendEmergencyNotification(eventRef.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency signal sent! Trusted contacts have been notified.'),
            duration: Duration(seconds: 3),
          ),
        );
        
        // Navigate back to home after showing the message
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error triggering emergency: $e')),
        );
      }
    } finally {
      setState(() {
        _isTriggering = false;
      });
    }
  }
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Signal"),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red.shade50,
              Colors.red.shade100,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'EMERGENCY SIGNAL',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Press the button below to send\nan emergency alert to your trusted contacts',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 40),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTriggering ? Colors.red.shade900 : Colors.red.shade600,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(80),
                    elevation: _isTriggering ? 12 : 8,
                    shadowColor: Colors.red,
                  ),
                  onPressed: _isTriggering ? null : _triggerEmergency,
                  child: _isTriggering
                      ? const SizedBox(
                          width: 64,
                          height: 64,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 4,
                          ),
                        )
                      : const Icon(
                          Icons.warning_amber,
                          size: 64,
                          color: Colors.white,
                        ),
                ),
              ),
              const SizedBox(height: 40),
              if (_isTriggering)
                const Text(
                  'Sending emergency signal...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
