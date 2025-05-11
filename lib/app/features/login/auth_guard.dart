import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:score_board/app/features/login/cubit/login_cubit.dart';
import 'package:score_board/router/app_router.gr.dart';
import 'package:score_board/utils/constants.dart';

class AuthGuard extends AutoRouteGuard {

  // Constructor is now empty as dependencies are handled internally
  AuthGuard();
  // Instantiate FirebaseAuth and FlutterSecureStorage directly
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Using the static methods from LoginCubit to ensure key consistency
  Future<String?> _getUserToken() async {
    return LoginCubit.getUserToken(storage: _secureStorage);
  }

  Future<String?> _getUserId() async {
    return LoginCubit.getUserId(storage: _secureStorage);
  }

  @override
  Future<void> onNavigation(NavigationResolver resolver, StackRouter router) async {
    final String? storedToken = await _getUserToken();
    final String? storedUserId = await _getUserId();
    final User? currentFirebaseUser = _firebaseAuth.currentUser;

    if (storedToken != null && storedUserId != null && currentFirebaseUser != null) {
      // We have a token, a user ID in storage, and Firebase has an active user.
      // Verify that the stored user ID matches the current Firebase user's UID.
      if (currentFirebaseUser.uid == storedUserId) {
        // IDs match. Now, try to refresh the token to ensure it's still valid.
        // This is a good practice to catch expired/revoked tokens.
        try {
          await currentFirebaseUser.getIdToken(true); // true forces a refresh
          resolver.next(true); // Token is valid, proceed with navigation
          return;
        } catch (e) {
          // Token refresh failed (e.g., token expired, user disabled, network issue).
          // The session is no longer valid.
          // Clear stored credentials and redirect to login.
          await _secureStorage.delete(key: AppConstants.userTokenKey); // Use key from LoginCubit
          await _secureStorage.delete(key: AppConstants.userIdKey);   // Use key from LoginCubit
          // Fall through to redirect logic
        }
      } else {
        // Mismatch between stored user ID and Firebase's current user UID.
        // This indicates stale storage. Clear it and redirect.
          await _secureStorage.delete(key: AppConstants.userTokenKey); // Use key from LoginCubit
          await _secureStorage.delete(key: AppConstants.userIdKey);   // Use key from LoginCubit
        // Fall through to redirect logic
      }
    } else {
      // No token, no stored user ID, or no current Firebase user.
      // This means the user is not authenticated or storage is inconsistent.
      // If there's any partial data, clear it to be safe.
      if (storedToken != null || storedUserId != null) {
          await _secureStorage.delete(key: AppConstants.userTokenKey); // Use key from LoginCubit
          await _secureStorage.delete(key: AppConstants.userIdKey);   // Use key from LoginCubit
      }
      // Fall through to redirect logic
    }

    // If any check above fails and doesn't return, redirect to login.
    // The `replaceAll` method clears the navigation stack and pushes LoginRoute.
    // Ensure LoginRoute is correctly imported from your router.gr.dart
    await router.replaceAll([const LoginRoute()]);
    resolver.next(false); // Stop the current navigation
  }
}