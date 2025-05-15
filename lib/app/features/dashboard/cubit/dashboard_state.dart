// dashboard_cubit_dart_state.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp

// Assuming this is the correct path for your cubit
// part 'dashboard_cubit.dart';

// Enum for the status of a game
enum GamePlayStatus {
  scheduled,
  liveQ1,
  liveQ2,
  halftime,
  liveQ3,
  liveQ4,
  liveOT, // For any overtime period
  completed,
  cancelled,
  postponed,
  unknown; // Fallback

  // Helper to convert from Firestore string status to enum
  static GamePlayStatus fromString(String? statusString) {
    if (statusString == null) return GamePlayStatus.unknown;
    switch (statusString.toLowerCase()) {
      case 'scheduled':
        return GamePlayStatus.scheduled;
      case 'live_q1':
        return GamePlayStatus.liveQ1;
      case 'live_q2':
        return GamePlayStatus.liveQ2;
      case 'halftime':
        return GamePlayStatus.halftime;
      case 'live_q3':
        return GamePlayStatus.liveQ3;
      case 'live_q4':
        return GamePlayStatus.liveQ4;
      case 'live_ot': // Assuming a generic "live_ot" for any OT
      case 'live_ot1':
      case 'live_ot2': // Add more specific OT if needed
        return GamePlayStatus.liveOT;
      case 'completed':
        return GamePlayStatus.completed;
      case 'cancelled':
        return GamePlayStatus.cancelled;
      case 'postponed':
        return GamePlayStatus.postponed;
      default:
        return GamePlayStatus.unknown;
    }
  }

  // Helper to get a user-friendly display string
  String get displayValue {
    switch (this) {
      case GamePlayStatus.scheduled:
        return 'Scheduled';
      case GamePlayStatus.liveQ1:
        return 'Quarter 1';
      case GamePlayStatus.liveQ2:
        return 'Quarter 2';
      case GamePlayStatus.halftime:
        return 'Halftime';
      case GamePlayStatus.liveQ3:
        return 'Quarter 3';
      case GamePlayStatus.liveQ4:
        return 'Quarter 4';
      case GamePlayStatus.liveOT:
        return 'Overtime'; // You might want to append the OT number if available
      case GamePlayStatus.completed:
        return 'Final';
      case GamePlayStatus.cancelled:
        return 'Cancelled';
      case GamePlayStatus.postponed:
        return 'Postponed';
      case GamePlayStatus.unknown:
      default:
        return 'Unknown';
    }
  }
}

// Simple model for displaying game overviews on the dashboard
@immutable
class GameOverview {
  const GameOverview({
    required this.id,
    required this.name,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeScore,
    required this.awayScore,
    required this.status, // Now expects GamePlayStatus
    this.scheduledTime,
  });
  final String id;
  final String name;
  final String homeTeamName;
  final String awayTeamName;
  final int homeScore;
  final int awayScore;
  final GamePlayStatus status; // Changed from String to GamePlayStatus
  final Timestamp? scheduledTime;

  // For easier debugging
  @override
  String toString() {
    return 'GameOverview(id: $id, name: $name, status: ${status.displayValue})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GameOverview &&
        other.id == id &&
        other.name == name &&
        other.homeTeamName == homeTeamName &&
        other.awayTeamName == awayTeamName &&
        other.homeScore == homeScore &&
        other.awayScore == awayScore &&
        other.status == status && // Compare enum directly
        other.scheduledTime == scheduledTime;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        homeTeamName.hashCode ^
        awayTeamName.hashCode ^
        homeScore.hashCode ^
        awayScore.hashCode ^
        status.hashCode ^ // Hash enum directly
        scheduledTime.hashCode;
  }
}

enum DashboardStatus { initial, loading, success, failure }

@immutable
class DashboardState {
  const DashboardState({
    this.status = DashboardStatus.initial,
    this.username,
    this.ongoingGames = const [],
    this.gameHistory = const [],
    this.error,
  });
  final DashboardStatus status;
  final String? username;
  final List<GameOverview> ongoingGames;
  final List<GameOverview> gameHistory;
  final String? error;

  DashboardState copyWith({
    DashboardStatus? status,
    String? username,
    List<GameOverview>? ongoingGames,
    List<GameOverview>? gameHistory,
    String? error,
    bool clearError = false,
  }) {
    return DashboardState(
      status: status ?? this.status,
      username: username ?? this.username,
      ongoingGames: ongoingGames ?? this.ongoingGames,
      gameHistory: gameHistory ?? this.gameHistory,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DashboardState &&
        other.status == status &&
        other.username == username &&
        listEquals(other.ongoingGames, ongoingGames) &&
        listEquals(other.gameHistory, gameHistory) &&
        other.error == error;
  }

  @override
  int get hashCode =>
      status.hashCode ^
      username.hashCode ^
      Object.hashAll(ongoingGames) ^
      Object.hashAll(gameHistory) ^
      error.hashCode;

  @override
  String toString() {
    return 'DashboardState(status: $status, username: $username, ongoing: ${ongoingGames.length}, history: ${gameHistory.length} error: $error)';
  }
}
