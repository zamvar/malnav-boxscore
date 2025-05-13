import 'package:flutter/foundation.dart';

@immutable
class Team {
  const Team({required this.id, required this.name});
  final String id;
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Team && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Team(id: $id, name: $name)';
}

enum LobbyStatus {
  initial,
  loadingTeams,
  teamsLoaded,
  creatingGame,
  gameCreated,
  error
}

@immutable
class LobbyState {
  // To pass to the scoreboard route

  const LobbyState({
    this.status = LobbyStatus.initial,
    this.teams = const [],
    this.error,
    this.createdGameId,
  });
  final LobbyStatus status;
  final List<Team> teams;
  final String? error;
  final String? createdGameId;

  LobbyState copyWith({
    LobbyStatus? status,
    List<Team>? teams,
    String? error,
    bool clearError = false,
    String? createdGameId,
    bool clearCreatedGameId = false,
  }) {
    return LobbyState(
      status: status ?? this.status,
      teams: teams ?? this.teams,
      error: clearError ? null : (error ?? this.error),
      createdGameId:
          clearCreatedGameId ? null : (createdGameId ?? this.createdGameId),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LobbyState &&
        other.status == status &&
        listEquals(other.teams, teams) &&
        other.error == error &&
        other.createdGameId == createdGameId;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        Object.hashAll(teams) ^ // More robust for list
        error.hashCode ^
        createdGameId.hashCode;
  }

  @override
  String toString() {
    return 'LobbyState(status: $status, teams: ${teams.length} teams, error: $error, createdGameId: $createdGameId)';
  }
}
