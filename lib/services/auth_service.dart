import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  Future<User?> signup(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = cred.user;
      if (user != null) {
        // Create user document in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'trustedContacts': [],
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Create email hash document for trusted parent verification
        await _createEmailHashDocument(user.email!);
      }
      
      return user;
    } catch (e) {
      print('Signup Error: $e');
      return null;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      
      if (user != null) {
        // Check if user document exists, if not create it
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        if (!userDoc.exists) {
          // Create user document in Firestore
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'trustedContacts': [],
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Create email hash document for trusted parent verification
          await _createEmailHashDocument(user.email!);
        }
      }
      
      return user;
    } catch (e) {
      print('Google Sign-In Error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Create email hash document for trusted parent verification
  Future<void> _createEmailHashDocument(String email) async {
    try {
      // Hash the email for privacy (lowercase for consistency)
      final emailBytes = utf8.encode(email.toLowerCase());
      final emailHash = sha256.convert(emailBytes).toString();
      
      // Create document in user_emails collection (empty document for maximum privacy)
      await _firestore.collection('user_emails').doc(emailHash).set({});
      
      print('Created email hash document for: ${email.toLowerCase()}');
    } catch (e) {
      print('Error creating email hash document: $e');
    }
  }
}
