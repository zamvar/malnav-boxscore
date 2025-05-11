// login_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:score_board/app/features/login/cubit/login_state.dart';

import 'package:score_board/utils/constants.dart';

class LoginCubit extends Cubit<LoginState> {
  // Constructor no longer needs parameters for these instances
  LoginCubit() : super(const LoginState());

  // Instantiate FirebaseAuth and FlutterSecureStorage directly
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage(); // Initial state with default status (initial)
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Firestore instance

  Future<void> _fetchAndStoreUserDetails(User user) async {
    try {
      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      String role = 'view'; // Default role
      String username = 'N/A'; // Default username

      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()! as Map<String, dynamic>;
        debugPrint('User data fetched from Firestore: ${data.toString()}');
        role = data['role'] as String;
        username = data['username'] as String;
      } else {
        debugPrint('User document does not exist or is empty.');
      }

      final String? idToken = await user.getIdToken();
      if (idToken != null) {
        await _secureStorage.write(
            key: AppConstants.userTokenKey, value: idToken,);
        await _secureStorage.write(
            key: AppConstants.userIdKey, value: user.uid,);
        await _secureStorage.write(key: AppConstants.userRoleKey, value: role);
        await _secureStorage.write(
            key: AppConstants.userUsernameKey, value: username,);

        emit(state.copyWith(
          status: LoginStatus.success,
          userId: user.uid,
          token: idToken,
          role: role,
          username: username,
          error: null,
        ),);
      } else {
        emit(state.copyWith(
          status: LoginStatus.failure,
          error: 'Failed to retrieve user token. Please try again.',
        ),);
      }
    } catch (e) {
      // Handle Firestore read error or other errors during detail fetching
      emit(state.copyWith(
        status: LoginStatus.failure,
        error: 'Error fetching user details: ${e.toString()}',
      ),);
    }
  }

  Future<void> loginWithEmailAndPassword(String email, String password) async {
    emit(state.copyWith(status: LoginStatus.loading));
    try {
      final UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final User? user = userCredential.user;

      if (user != null) {
        await _fetchAndStoreUserDetails(
          user,
        );
      } else {
        emit(state.copyWith(
          status: LoginStatus.failure,
          error: 'Login successful, but user data is unavailable.',
        ),);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An unknown error occurred during login.';
      if (e.code == 'user-not-found') {
        errorMessage =
            'No user found for that email. Please check your email or sign up.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password. Please try again.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is badly formatted.';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'This user account has been disabled.';
      } else if (e.code == 'network-request-failed') {
        errorMessage =
            'Network error. Please check your internet connection and try again.';
      } else {
        errorMessage = e.message ?? 'Login failed. Please try again.';
      }
      emit(state.copyWith(status: LoginStatus.failure, error: errorMessage));
    } catch (e) {
      emit(state.copyWith(
        status: LoginStatus.failure,
        error: 'An unexpected error occurred: ${e.toString()}',
      ),);
    }
  }

  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    emit(state.copyWith(status: LoginStatus.loading));
    try {
      final UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final User? user = userCredential.user;
      if (user != null) {
        await _fetchAndStoreUserDetails(
          user,
        );
      } else {
        emit(state.copyWith(
          status: LoginStatus.failure,
          error: 'Sign up failed. Could not create user.',
        ),);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An unknown error occurred during sign up.';
      if (e.code == 'weak-password') {
        errorMessage =
            'The password provided is too weak (must be at least 6 characters).';
      } else if (e.code == 'email-already-in-use') {
        errorMessage =
            'An account already exists for that email. Please try logging in.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is badly formatted.';
      } else {
        errorMessage = e.message ?? 'Sign up failed. Please try again.';
      }
      emit(state.copyWith(status: LoginStatus.failure, error: errorMessage));
    } catch (e) {
      emit(state.copyWith(
        status: LoginStatus.failure,
        error: 'An unexpected error occurred during sign up: ${e.toString()}',
      ),);
    }
  }

  Future<void> checkCurrentUser() async {
    emit(state.copyWith(status: LoginStatus.loading));
    try {
      final String? token =
          await _secureStorage.read(key: AppConstants.userTokenKey);
      final String? userId =
          await _secureStorage.read(key: AppConstants.userIdKey);
      final User? currentUserFromFirebaseAuth = _firebaseAuth.currentUser;

      if (token != null &&
          userId != null &&
          currentUserFromFirebaseAuth != null) {
        if (currentUserFromFirebaseAuth.uid == userId) {
          try {
            final String? refreshedToken =
                await currentUserFromFirebaseAuth.getIdToken(true);
            if (refreshedToken != null) {
              await _secureStorage.write(
                  key: AppConstants.userTokenKey, value: refreshedToken,);
              emit(state.copyWith(
                status: LoginStatus.success,
                userId: currentUserFromFirebaseAuth.uid,
                token: refreshedToken,
                error: null,
              ),);
            } else {
              await logout(); // Emits initial state
            }
          } catch (e) {
            await logout(); // Emits initial state
          }
        } else {
          await logout(); // Emits initial state
        }
      } else {
        if (currentUserFromFirebaseAuth != null ||
            token != null ||
            userId != null) {
          await logout(); // Emits initial state
        } else {
          emit(const LoginState()); // Back to truly initial state
        }
      }
    } catch (e) {
      emit(state.copyWith(
        status: LoginStatus.failure,
        error: 'Error checking user status: $e',
      ),);
      await logout(); // Emits initial state
    }
  }

  Future<void> logout() async {
    // No loading state for logout, it should be quick
    try {
      await _firebaseAuth.signOut();
      await _secureStorage.delete(key: AppConstants.userTokenKey);
      await _secureStorage.delete(key: AppConstants.userIdKey);
      emit(const LoginState()); // Reset to initial state
    } catch (e) {
      await _secureStorage.delete(key: AppConstants.userTokenKey);
      await _secureStorage.delete(key: AppConstants.userIdKey);
      emit(const LoginState(
          status: LoginStatus.initial,
          error: 'Error during logout, session cleared.',),);
      // Optionally log the error e
    }
  }

  static Future<String?> getUserToken(
      {required FlutterSecureStorage storage,}) async {
    return storage.read(key: AppConstants.userTokenKey);
  }

  static Future<String?> getUserId({FlutterSecureStorage? storage}) async {
    // ADDED THIS METHOD
    final secureStorage = storage ?? const FlutterSecureStorage();
    return secureStorage.read(
        key: AppConstants.userIdKey,); // Use public key
  }
}

// Enum to represent the different statuses of the login process
