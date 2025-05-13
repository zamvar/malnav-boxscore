import 'package:flutter/foundation.dart';
import 'package:score_board/app/commons/models/player_model.dart';
import 'package:score_board/app/commons/models/team_model.dart';

enum GameLoadingStatus { initial, loading, success, error }

enum GamePlayStatus { scheduled, live, halftime, completed, cancelled }

// Player and TeamDetails models are assumed to be imported in 'game_scoreboard_cubit.dart'
// and thus available here due to the 'part of' directive.
// If not, you would import them:
// import 'package:score_board/app/commons/models/player_model.dart';
// import 'package:score_board/app/commons/models/team_model.dart';

@immutable
class GameScoreboardState {

  const GameScoreboardState({
    this.gameId,
    this.loadingStatus = GameLoadingStatus.initial,
    this.gamePlayStatus = GamePlayStatus.scheduled,
    this.gameData,
    this.homeTeam,
    this.awayTeam,
    this.homeScore = 0,
    this.awayScore = 0,
    this.homeTeamQuarterScores = const [0, 0, 0, 0], // Default to 4 quarters
    this.awayTeamQuarterScores = const [0, 0, 0, 0], // Default to 4 quarters
    this.currentQuarter = 1,
    this.gameClock = '12:00',
    this.gameStatusDisplay = 'Scheduled',
    this.gameLogs = const [],
    this.homePlayersOnCourt = const [],
    this.awayPlayersOnCourt = const [],
    this.error,
  });
  final String? gameId;
  final GameLoadingStatus loadingStatus;
  final GamePlayStatus gamePlayStatus;
  final Map<String, dynamic>? gameData; // Raw game document data
  final TeamDetails? homeTeam;
  final TeamDetails? awayTeam;
  final int homeScore; // Total score
  final int awayScore; // Total score
  final List<int> homeTeamQuarterScores; // Scores per quarter for home team
  final List<int> awayTeamQuarterScores; // Scores per quarter for away team
  final int currentQuarter;
  final String gameClock;
  final String gameStatusDisplay;
  final List<Map<String, dynamic>> gameLogs;
  final List<Player> homePlayersOnCourt;
  final List<Player> awayPlayersOnCourt;
  final String? error;

  GameScoreboardState copyWith({
    String? gameId,
    GameLoadingStatus? loadingStatus,
    GamePlayStatus? gamePlayStatus,
    Map<String, dynamic>? gameData,
    TeamDetails? homeTeam,
    TeamDetails? awayTeam,
    int? homeScore,
    int? awayScore,
    List<int>? homeTeamQuarterScores,
    List<int>? awayTeamQuarterScores,
    int? currentQuarter,
    String? gameClock,
    String? gameStatusDisplay,
    List<Map<String, dynamic>>? gameLogs,
    List<Player>? homePlayersOnCourt,
    List<Player>? awayPlayersOnCourt,
    String? error,
    bool clearError = false,
  }) {
    return GameScoreboardState(
      gameId: gameId ?? this.gameId,
      loadingStatus: loadingStatus ?? this.loadingStatus,
      gamePlayStatus: gamePlayStatus ?? this.gamePlayStatus,
      gameData: gameData ?? this.gameData,
      homeTeam: homeTeam ?? this.homeTeam,
      awayTeam: awayTeam ?? this.awayTeam,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      homeTeamQuarterScores:
          homeTeamQuarterScores ?? this.homeTeamQuarterScores,
      awayTeamQuarterScores:
          awayTeamQuarterScores ?? this.awayTeamQuarterScores,
      currentQuarter: currentQuarter ?? this.currentQuarter,
      gameClock: gameClock ?? this.gameClock,
      gameStatusDisplay: gameStatusDisplay ?? this.gameStatusDisplay,
      gameLogs: gameLogs ?? this.gameLogs,
      homePlayersOnCourt: homePlayersOnCourt ?? this.homePlayersOnCourt,
      awayPlayersOnCourt: awayPlayersOnCourt ?? this.awayPlayersOnCourt,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameScoreboardState &&
        other.gameId == gameId &&
        other.loadingStatus == loadingStatus &&
        other.gamePlayStatus == gamePlayStatus &&
        mapEquals(other.gameData, gameData) &&
        other.homeTeam == homeTeam &&
        other.awayTeam == awayTeam &&
        other.homeScore == homeScore &&
        other.awayScore == awayScore &&
        listEquals(other.homeTeamQuarterScores, homeTeamQuarterScores) &&
        listEquals(other.awayTeamQuarterScores, awayTeamQuarterScores) &&
        other.currentQuarter == currentQuarter &&
        other.gameClock == gameClock &&
        other.gameStatusDisplay == gameStatusDisplay &&
        listEquals(other.gameLogs, gameLogs) &&
        listEquals(other.homePlayersOnCourt, homePlayersOnCourt) &&
        listEquals(other.awayPlayersOnCourt, awayPlayersOnCourt) &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(
        gameId,
        loadingStatus,
        gamePlayStatus,
        gameData,
        homeTeam,
        awayTeam,
        homeScore,
        awayScore,
        Object.hashAll(homeTeamQuarterScores),
        Object.hashAll(awayTeamQuarterScores),
        currentQuarter,
        gameClock,
        gameStatusDisplay,
        Object.hashAll(gameLogs),
        Object.hashAll(homePlayersOnCourt),
        Object.hashAll(awayPlayersOnCourt),
        error,
      );

  @override
  String toString() {
    return 'GameScoreboardState(gameId: $gameId, loadingStatus: $loadingStatus, gamePlayStatus: $gamePlayStatus, home: ${homeTeam?.name ?? 'N/A'} $homeScore (Q: $homeTeamQuarterScores), away: ${awayTeam?.name ?? 'N/A'} $awayScore (Q: $awayTeamQuarterScores), Qtr: $currentQuarter, clock: $gameClock, statusDisplay: $gameStatusDisplay, logs: ${gameLogs.length}, error: $error)';
  }
}
