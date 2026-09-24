import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ApiService _apiService = ApiService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final User? firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        try {
          await _fetchUserProfile(firebaseUser.uid);
        } catch (e) {
          debugPrint('checkAuthStatus fetch error: $e');
        }
      }
    } catch (e) {
      debugPrint('checkAuthStatus error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        try {
          await _fetchUserProfile(credential.user!.uid);
        } catch (e) {
          debugPrint('signIn fetch error: $e');
        }
        _errorMessage = null;
        notifyListeners();
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException code: ${e.code}, message: ${e.message}');
      _errorMessage = _getErrorMessage(e.code, e.message);
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Unexpected signIn error: $e');
      _errorMessage = 'An unexpected error occurred: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String prn,
    required String rollNumber,
    required DateTime dateOfBirth,
    required String division,
    required String department,
    required String mobileNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final String prnTrimmed = prn.trim().toUpperCase();
    final String rollTrimmed = rollNumber.trim();

    try {
      // 1. Mandatory Student Verification (API first, then direct Firestore fallback)
      bool isVerified = false;
      String? verificationError;

      try {
        isVerified = await _apiService.verifyStudent(
          prnTrimmed,
          dateOfBirth,
          rollNumber: rollTrimmed,
        );
        if (!isVerified) {
          verificationError = 'Access denied. Student details not found in official college records.';
        }
      } catch (e) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        // If the server API returned an explicit verification rejection message, enforce it:
        if (errorMsg.contains('registered') ||
            errorMsg.contains('Access denied') ||
            errorMsg.contains('match') ||
            errorMsg.contains('PRN') ||
            errorMsg.contains('Roll')) {
          verificationError = errorMsg;
        } else {
          // If the API server is unreachable (e.g. running inside APK without remote host),
          // query Cloud Firestore directly as a fallback.
          debugPrint('API verification unreachable ($e). Checking Cloud Firestore directly...');
          try {
            final docSnap = await _firestore.collection('students').doc(prnTrimmed).get();
            if (!docSnap.exists) {
              verificationError = 'Access denied. PRN "$prnTrimmed" is not found in official college records.';
            } else {
              final data = docSnap.data();
              if (data != null) {
                final dbRoll = data['rollNum']?.toString().trim();
                final isReg = data['isRegistered'] == true ||
                    data['isRegistered']?.toString().toLowerCase() == 'true';

                if (isReg) {
                  verificationError = 'This student account (PRN: $prnTrimmed) is already registered. Please log in.';
                } else if (dbRoll != null && dbRoll.isNotEmpty && dbRoll != rollTrimmed) {
                  verificationError = 'Roll Number ($rollTrimmed) does not match official college records for PRN $prnTrimmed.';
                } else {
                  isVerified = true;
                }
              } else {
                verificationError = 'Invalid student record format in college database.';
              }
            }
          } catch (fsErr) {
            debugPrint('Direct Firestore verification error: $fsErr');
            final fsStr = fsErr.toString();
            if (fsStr.contains('permission-denied') || fsStr.contains('PERMISSION_DENIED')) {
              verificationError = 'Firestore Security Error: Public read access to the "students" collection is denied. Please update your Firestore Security Rules in Firebase Console to allow "read: if true" on /students/{prn}.';
            } else {
              verificationError = 'Student verification service unavailable: ${fsStr.replaceAll('Exception: ', '')}';
            }
          }
        }
      }

      // STRICT CHECK: If student verification failed, STOP IMMEDIATELY.
      if (!isVerified || verificationError != null) {
        _errorMessage = verificationError ?? 'Student verification failed. Please check your PRN and Roll Number.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 2. Create Firebase Auth user
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        try {
          await credential.user!.updateDisplayName(name);
        } catch (_) {}

        final userData = {
          'id': credential.user!.uid,
          'name': name,
          'email': email,
          'prn': prnTrimmed,
          'rollNumber': rollTrimmed,
          'rollNum': rollTrimmed,
          'dateOfBirth': dateOfBirth.toIso8601String(),
          'division': division,
          'department': department,
          'mobileNumber': mobileNumber,
          'createdAt': DateTime.now().toIso8601String(),
        };

        // Save profile via API or directly to Firestore
        try {
          await _apiService.createUser(userData);
        } catch (e) {
          debugPrint('API createUser failed, saving to Firestore: $e');
          await _firestore
              .collection('users')
              .doc(credential.user!.uid)
              .set(userData, SetOptions(merge: true));
        }

        // Mark student PRN as registered in Firestore so it cannot be reused
        try {
          await _firestore
              .collection('students')
              .doc(prnTrimmed)
              .set({'isRegistered': true}, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Failed to update PRN isRegistered status: $e');
        }

        await _fetchUserProfile(credential.user!.uid);
        _errorMessage = null;
        notifyListeners();
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException code: ${e.code}, message: ${e.message}');
      _errorMessage = _getErrorMessage(e.code, e.message);
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Unexpected signUp error: $e');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _fetchUserProfile(String userId) async {
    try {
      final userData = await _apiService.getUserProfile(userId);
      _currentUser = UserModel.fromJson(userData);
    } catch (e) {
      debugPrint('API getUserProfile failed ($e), trying Firestore directly...');
      final docSnap = await _firestore.collection('users').doc(userId).get();
      if (docSnap.exists && docSnap.data() != null) {
        _currentUser = UserModel.fromJson(docSnap.data()!);
      } else {
        rethrow;
      }
    }
  }

  String _getErrorMessage(String code, [String? message]) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email. Please Sign Up first.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-credential':
        return 'Invalid email or password. If you haven\'t created an account yet, please tap Sign Up below.';
      case 'email-already-in-use':
        return 'An account already exists with this email. Please log in.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'The password is too weak. Must be at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/Password sign-in is not enabled in Firebase Console. Please enable it in Firebase Console -> Authentication -> Sign-in method.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return message ?? 'Authentication error ($code). Please try again.';
    }
  }
}

