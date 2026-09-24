import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
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
        // Try to fetch user profile from backend
        try {
          await _fetchUserProfile(firebaseUser.uid);
        } catch (e) {
          // Backend unavailable - create temporary user profile
          _currentUser = UserModel(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? (firebaseUser.email?.split('@').first ?? 'User'),
            email: firebaseUser.email ?? '',
            prn: 'TEMP-PRN',
            dateOfBirth: DateTime.now().subtract(const Duration(days: 7300)),
            division: 'A',
            department: 'Computer',
            mobileNumber: firebaseUser.phoneNumber ?? '0000000000',
            createdAt: DateTime.now(),
          );
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
        // Try to fetch user profile from backend
        try {
          await _fetchUserProfile(credential.user!.uid);
        } catch (e) {
          // Backend unavailable - create temporary user profile
          _currentUser = UserModel(
            id: credential.user!.uid,
            name: credential.user!.displayName ?? (email.split('@').first),
            email: credential.user!.email ?? email,
            prn: 'TEMP-PRN',
            dateOfBirth: DateTime.now().subtract(const Duration(days: 7300)),
            division: 'A',
            department: 'Computer',
            mobileNumber: credential.user!.phoneNumber ?? '0000000000',
            createdAt: DateTime.now(),
          );
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

    try {
      // Try to verify student with backend
      try {
        final bool isVerified = await _apiService.verifyStudent(
          prn,
          dateOfBirth,
          rollNumber: rollNumber,
        );
        if (!isVerified) {
          _errorMessage = 'Student verification failed. Please check your PRN, Roll Number, and DOB.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } catch (e) {
        final errorStr = e.toString().replaceAll('Exception: ', '');
        if (errorStr.contains('registered') ||
            errorStr.contains('Access denied') ||
            errorStr.contains('match') ||
            errorStr.contains('PRN') ||
            errorStr.contains('Roll')) {
          _errorMessage = errorStr;
          _isLoading = false;
          notifyListeners();
          return false;
        }
        debugPrint('Student verification error (handled): $e');
      }

      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update Firebase display name
        try {
          await credential.user!.updateDisplayName(name);
        } catch (_) {}

        // Try to save user to backend
        try {
          final userData = {
            'id': credential.user!.uid,
            'name': name,
            'email': email,
            'prn': prn,
            'rollNumber': rollNumber,
            'rollNum': rollNumber,
            'dateOfBirth': dateOfBirth.toIso8601String(),
            'division': division,
            'department': department,
            'mobileNumber': mobileNumber,
            'createdAt': DateTime.now().toIso8601String(),
          };
          await _apiService.createUser(userData);
          await _fetchUserProfile(credential.user!.uid);
        } catch (e) {
          // Backend unavailable - create temporary user profile
          _currentUser = UserModel(
            id: credential.user!.uid,
            name: name,
            email: email,
            prn: prn,
            rollNumber: rollNumber,
            dateOfBirth: dateOfBirth,
            division: division,
            department: department,
            mobileNumber: mobileNumber,
            createdAt: DateTime.now(),
          );
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
      debugPrint('Unexpected signUp error: $e');
      _errorMessage = e.toString();
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
    final userData = await _apiService.getUserProfile(userId);
    _currentUser = UserModel.fromJson(userData);
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
