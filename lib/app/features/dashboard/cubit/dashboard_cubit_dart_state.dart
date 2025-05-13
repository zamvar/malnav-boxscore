// --- Dashboard Cubit and State (Simple Mock) ---
// For a real dashboard, this would fetch and manage dashboard data.
import 'package:flutter/widgets.dart';

enum DashboardStatus { initial, loading, success, failure }

@immutable
class DashboardState {
  // Add any dashboard-specific data here, e.g.,
  // final DashboardData dashboardData;

  const DashboardState({
    this.status = DashboardStatus.initial,
    this.error,
    // this.dashboardData = const DashboardData.empty(),
  });
  final DashboardStatus status;
  final String? error;

  DashboardState copyWith({
    DashboardStatus? status,
    String? error,
    // DashboardData? dashboardData,
  }) {
    return DashboardState(
      status: status ?? this.status,
      error: error ?? this.error,
      // dashboardData: dashboardData ?? this.dashboardData,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DashboardState &&
        other.status == status &&
        other.error == error;
    // other.dashboardData == dashboardData;
  }

  @override
  int get hashCode =>
      status.hashCode ^ error.hashCode; // ^ dashboardData.hashCode;
}
