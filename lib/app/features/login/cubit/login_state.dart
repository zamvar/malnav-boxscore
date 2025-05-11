import 'package:flutter/widgets.dart';

enum LoginStatus { initial, loading, success, failure }

@immutable
class LoginState {

  // Constructor with a default status of initial
  const LoginState({
    this.status = LoginStatus.initial,
    this.userId,
    this.token,
    this.role,
    this.username,
    this.error,
  });
  final LoginStatus status;
  final String? userId;
  final String? token;

  final String? error;
  final String? role;
  final String? username;

  // copyWith method to easily create a new state from an existing one
  LoginState copyWith({
    LoginStatus? status,
    String? userId,
    String? token,
    
    String? role,
    String? username,
    String? error,
    bool clearError = false, // Utility to explicitly clear error
  }) {
    return LoginState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      token: token ?? this.token,

      error: clearError ? null : error ?? this.error,
      role: role ?? this.role,
      username: username ?? this.username,
    );
  }

  // Override == and hashCode for proper state comparison, especially in tests
  // or when using BlocListener/BlocBuilder with `buildWhen` or `listenWhen`.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LoginState &&
        other.status == status &&
        other.userId == userId &&
        other.token == token &&
        
        other.role == role &&
        other.username == username &&
        other.error == error;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        userId.hashCode ^
        token.hashCode ^
        
        role.hashCode ^
        username.hashCode ^
        error.hashCode;
  }

  @override
  String toString() {
    return 'LoginState(status: $status, userId: $userId, token: $token, error: $error)';
  }
}