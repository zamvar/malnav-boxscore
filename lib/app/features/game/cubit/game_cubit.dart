import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// For listEquals, mapEquals, mapHash
import 'package:score_board/app/commons/models/player_model.dart';
import 'package:score_board/app/commons/models/team_model.dart';
import 'package:score_board/app/features/game/cubit/game_state.dart';

class GameScoreboardCubit extends Cubit<GameScoreboardState> {
  GameScoreboardCubit() : super(const GameScoreboardState());
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _gameSubscription;

  List<Player> _currentHomePlayersOnCourt = [];
  List<Player> _currentAwayPlayersOnCourt = [];

  Future<void> loadGameAndTeams(String gameId) async {
    if (isClosed) return;
    emit(
      state.copyWith(
        gameId: gameId,
        loadingStatus: GameLoadingStatus.loading,
        clearError: true,
      ),
    );
    print('GameScoreboardCubit: Loading game and teams for gameId: $gameId');

    try {
      DocumentSnapshot gameDocSnapshot =
          await _firestore.collection('games').doc(gameId).get();
      if (!gameDocSnapshot.exists || gameDocSnapshot.data() == null) {
        print('GameScoreboardCubit: Game not found for gameId: $gameId');
        emit(
          state.copyWith(
            loadingStatus: GameLoadingStatus.error,
            error: 'Game not found.',
          ),
        );
        return;
      }
      final initialGameData = gameDocSnapshot.data()! as Map<String, dynamic>;
      final String homeTeamId = initialGameData['homeTeamId'] as String;
      final String awayTeamId = initialGameData['awayTeamId'] as String;
      print(
        'GameScoreboardCubit: HomeTeamId: $homeTeamId, AwayTeamId: $awayTeamId',
      );

      final homeTeamDetails = await _fetchTeamDetails(homeTeamId);
      final awayTeamDetails = await _fetchTeamDetails(awayTeamId);

      if (homeTeamDetails == null || awayTeamDetails == null) {
        print(
          'GameScoreboardCubit: One or both teams not found. Home: ${homeTeamDetails?.name}, Away: ${awayTeamDetails?.name}',
        );
        emit(
          state.copyWith(
            loadingStatus: GameLoadingStatus.error,
            error: 'One or both teams not found.',
          ),
        );
        return;
      }
      print(
        'GameScoreboardCubit: Home Team fetched: ${homeTeamDetails.name}, Away Team fetched: ${awayTeamDetails.name}',
      );

      _currentHomePlayersOnCourt = homeTeamDetails.players.take(5).toList();
      _currentAwayPlayersOnCourt = awayTeamDetails.players.take(5).toList();
      print(
        'GameScoreboardCubit: Initial home on court: ${_currentHomePlayersOnCourt.length}, away on court: ${_currentAwayPlayersOnCourt.length}',
      );

      await _processGameData(initialGameData, homeTeamDetails, awayTeamDetails);

      await _gameSubscription?.cancel();
      _gameSubscription =
          _firestore.collection('games').doc(gameId).snapshots().listen(
        (snapshot) async {
          if (isClosed) return;
          if (snapshot.exists && snapshot.data() != null) {
            print('GameScoreboardCubit: Game document updated (stream).');
            await _processGameData(
              snapshot.data()!,
              state.homeTeam ?? homeTeamDetails,
              state.awayTeam ?? awayTeamDetails,
            );
          } else {
            print(
              'GameScoreboardCubit: Game document disappeared or became null (stream).',
            );
            emit(
              state.copyWith(
                loadingStatus: GameLoadingStatus.error,
                error: 'Game data disappeared.',
              ),
            );
          }
        },
        onError: (error) {
          if (isClosed) return;
          print('GameScoreboardCubit: Error listening to game updates: $error');
          emit(
            state.copyWith(
              loadingStatus: GameLoadingStatus.error,
              error: 'Error listening to game updates: $error',
            ),
          );
        },
      );
    } catch (e, s) {
      if (isClosed) return;
      print('GameScoreboardCubit: Failed to load game: $e\nStack: $s');
      emit(
        state.copyWith(
          loadingStatus: GameLoadingStatus.error,
          error: 'Failed to load game: ${e.toString()}',
        ),
      );
    }
  }

  Future<TeamDetails?> _fetchTeamDetails(String teamId) async {
    try {
      DocumentSnapshot teamDocSnapshot =
          await _firestore.collection('teams').doc(teamId).get();
      if (!teamDocSnapshot.exists || teamDocSnapshot.data() == null) {
        print('GameScoreboardCubit: Team document not found for ID: $teamId');
        return null;
      }
      final teamMap = teamDocSnapshot.data()! as Map<String, dynamic>;
      return TeamDetails(
        id: teamDocSnapshot.id,
        name: teamMap['name'] as String? ?? 'Unknown Team',
        players: (teamMap['players'] as List<dynamic>? ?? [])
            .map(
              (playerMap) => Player.fromPlayerMapInTeam(
                playerMap as Map<String, dynamic>,
                teamDocSnapshot.id,
              ),
            )
            .toList(),
      );
    } catch (e) {
      print('GameScoreboardCubit: Error fetching team $teamId: $e');
      return null;
    }
  }

  Future<void> _processGameData(
    Map<String, dynamic> gameData,
    TeamDetails homeTeam,
    TeamDetails awayTeam,
  ) async {
    if (isClosed) return;
    print(
      "GameScoreboardCubit: Processing game data. Logs count: ${(gameData['gameLogs'] as List<dynamic>? ?? []).length}",
    );

    final List<dynamic> gameLogsDynamic =
        gameData['gameLogs'] as List<dynamic>? ?? [];
    final List<Map<String, dynamic>> gameLogs =
        gameLogsDynamic.cast<Map<String, dynamic>>();

    int calculatedHomeScore = 0;
    int calculatedAwayScore = 0;
    List<int> homeQuarterScores = List.filled(4, 0, growable: true);
    List<int> awayQuarterScores = List.filled(4, 0, growable: true);

    for (final log in gameLogs) {
      String? logTeamId = log['teamId'] as String?;
      String actionType = log['actionType'] as String? ?? '';
      int points = log['points'] as int? ?? 0;

      // --- Robust Quarter Parsing ---
      int logQuarter = 0;
      final dynamic quarterData = log['quarter'];
      if (quarterData is int) {
        logQuarter = quarterData;
      } else if (quarterData is String) {
        // Attempt to parse string, removing non-digit characters like "Q"
        logQuarter =
            int.tryParse(quarterData.replaceAll(RegExp('[^0-9]'), '')) ?? 0;
      }
      // --- End of Robust Quarter Parsing ---

      if (logTeamId != null) {
        bool isScoringAction = actionType == 'FIELD_GOAL_MADE' ||
            (actionType == 'FREE_THROW_ATTEMPT' &&
                (log['details']?['isMade'] == true));

        if (isScoringAction) {
          if (logTeamId == homeTeam.id) {
            calculatedHomeScore += points;
            if (logQuarter > 0) {
              // Ensure list is long enough for the quarter (e.g., for OT)
              while (homeQuarterScores.length < logQuarter) {
                homeQuarterScores.add(0);
              }
              homeQuarterScores[logQuarter - 1] += points;
            }
          } else if (logTeamId == awayTeam.id) {
            calculatedAwayScore += points;
            if (logQuarter > 0) {
              while (awayQuarterScores.length < logQuarter) {
                awayQuarterScores.add(0);
              }
              awayQuarterScores[logQuarter - 1] += points;
            }
          }
        }
      }
    }
    print(
      'GameScoreboardCubit: Calculated Scores - Home: $calculatedHomeScore, Away: $calculatedAwayScore',
    );
    print('GameScoreboardCubit: Home Quarter Scores: $homeQuarterScores');
    print('GameScoreboardCubit: Away Quarter Scores: $awayQuarterScores');

    if (state.gameId != null && state.gameId!.isNotEmpty) {
      try {
        final currentDbHomeScore = gameData['homeTeamScore'] as int?;
        final currentDbAwayScore = gameData['awayTeamScore'] as int?;

        if (currentDbHomeScore != calculatedHomeScore ||
            currentDbAwayScore != calculatedAwayScore) {
          print(
            'GameScoreboardCubit: Updating Firestore scores for game ${state.gameId} to H: $calculatedHomeScore, A: $calculatedAwayScore',
          );
          await _firestore.collection('games').doc(state.gameId).update({
            'homeTeamScore': calculatedHomeScore,
            'awayTeamScore': calculatedAwayScore,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        print(
          'GameScoreboardCubit: Error updating scores in Firestore for game ${state.gameId}: $e',
        );
      }
    }

    List<Player> processedHomeOnCourt = homeTeam.players.take(5).toList();
    List<Player> processedAwayOnCourt = awayTeam.players.take(5).toList();

    for (final log in gameLogs) {
      final String? logActionType = log['actionType'] as String?;
      if ((logActionType == 'SUBSTITUTION_IN' ||
              logActionType == 'SUBSTITUTION_OUT') &&
          log['details'] != null) {
        final details = log['details'] as Map<String, dynamic>;
        final playerEnteringMap =
            details['playerEntering'] as Map<String, dynamic>?;
        final playerLeavingMap =
            details['playerLeaving'] as Map<String, dynamic>?;

        if (playerEnteringMap != null && playerLeavingMap != null) {
          final String eventTeamId = log['teamId'] as String? ?? '';

          final Player playerEntering =
              Player.fromPlayerMapInTeam(playerEnteringMap, eventTeamId);
          final Player playerLeaving =
              Player.fromPlayerMapInTeam(playerLeavingMap, eventTeamId);

          if (eventTeamId == homeTeam.id) {
            processedHomeOnCourt.removeWhere((p) => p.id == playerLeaving.id);
            if (!processedHomeOnCourt.any((p) => p.id == playerEntering.id)) {
              processedHomeOnCourt.add(playerEntering);
            }
          } else if (eventTeamId == awayTeam.id) {
            processedAwayOnCourt.removeWhere((p) => p.id == playerLeaving.id);
            if (!processedAwayOnCourt.any((p) => p.id == playerEntering.id)) {
              processedAwayOnCourt.add(playerEntering);
            }
          }
        }
      }
    }
    _currentHomePlayersOnCourt = processedHomeOnCourt;
    _currentAwayPlayersOnCourt = processedAwayOnCourt;

    final int currentQuarterFromData = gameData['currentQuarter'] as int? ?? 1;
    final String statusFromDb = gameData['status'] as String? ?? 'scheduled';
    final String gameClockFromData =
        gameData['gameClock'] as String? ?? state.gameClock;
    final String gameStatusDisplay = _deriveGameStatusDisplay(
      statusFromDb,
      currentQuarterFromData,
      gameClockFromData,
    );
    final GamePlayStatus gamePlayStatus = _deriveGamePlayStatus(statusFromDb);

    emit(
      state.copyWith(
        loadingStatus: GameLoadingStatus.success,
        gamePlayStatus: gamePlayStatus,
        gameData: gameData,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        homeScore: calculatedHomeScore,
        awayScore: calculatedAwayScore,
        homeTeamQuarterScores: homeQuarterScores,
        awayTeamQuarterScores: awayQuarterScores,
        currentQuarter:
            currentQuarterFromData, // Use currentQuarter from gameData
        gameClock: gameClockFromData,
        gameStatusDisplay: gameStatusDisplay,
        gameLogs: gameLogs,
        homePlayersOnCourt: _currentHomePlayersOnCourt,
        awayPlayersOnCourt: _currentAwayPlayersOnCourt,
        clearError: true,
      ),
    );
  }

  String _deriveGameStatusDisplay(
    String statusFromDb,
    int quarter,
    String clock,
  ) {
    switch (statusFromDb) {
      case 'scheduled':
        return 'Scheduled';
      case 'completed':
        return 'Final';
      case 'cancelled':
        return 'Cancelled';
      case 'halftime':
        return 'Halftime';
      default:
        return 'Q$quarter - $clock';
    }
  }

  GamePlayStatus _deriveGamePlayStatus(String statusFromDb) {
    switch (statusFromDb) {
      case 'scheduled':
        return GamePlayStatus.scheduled;
      case 'completed':
        return GamePlayStatus.completed;
      case 'cancelled':
        return GamePlayStatus.cancelled;
      case 'halftime':
        return GamePlayStatus.halftime;
      default:
        return GamePlayStatus.live;
    }
  }

  Future<void> addLogEntry(String gameId, Map<String, dynamic> logData) async {
    if (isClosed) return;
    print(
      'GameScoreboardCubit: Adding log entry to gameId: $gameId, Log: $logData',
    );

    try {
      final Map<String, dynamic> logWithClientTimestamp = {
        ...logData,
        'timestamp': Timestamp.now(),
      };

      await _firestore.collection('games').doc(gameId).update({
        'gameLogs': FieldValue.arrayUnion([logWithClientTimestamp]),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      print('GameScoreboardCubit: Log entry added successfully.');
    } catch (e) {
      if (isClosed) return;
      print('GameScoreboardCubit: Failed to add log: $e');
      emit(state.copyWith(error: 'Failed to add log: ${e.toString()}'));
    }
  }

  Future<void> updateGameClock(String gameId, String newClock) async {
    if (isClosed) return;
    emit(state.copyWith(gameClock: newClock));
    print('GameScoreboardCubit: Game clock updated to $newClock (local state)');
  }

  Future<void> advanceQuarter(String gameId, int nextQuarter) async {
    if (isClosed) return;
    emit(state.copyWith(loadingStatus: GameLoadingStatus.loading));
    try {
      String newStatus = 'live_q$nextQuarter';
      if (nextQuarter > 4) {
        newStatus = 'live_ot${nextQuarter - 4}';
      }

      await _firestore.collection('games').doc(gameId).update({
        'currentQuarter': nextQuarter,
        'status': newStatus,
        'gameClock': '12:00',
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      print(
        'GameScoreboardCubit: Advanced to quarter $nextQuarter for game $gameId',
      );
    } catch (e) {
      if (isClosed) return;
      print('GameScoreboardCubit: Error advancing quarter: $e');
      emit(
        state.copyWith(
          error: 'Failed to advance quarter: $e',
          loadingStatus: GameLoadingStatus.error,
        ),
      );
    }
  }

  Future<void> updateGameStatus(
    String gameId,
    String newStatus, {
    int? newQuarter,
  }) async {
    if (isClosed) return;

    emit(state.copyWith(loadingStatus: GameLoadingStatus.loading));

    try {
      Map<String, dynamic> updateData = {
        'status': newStatus,
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      if (newQuarter != null) {
        updateData['currentQuarter'] = newQuarter;
      }
      if (newStatus == 'completed' || newStatus == 'halftime') {
        updateData['gameClock'] = '00:00';
      }

      await _firestore.collection('games').doc(gameId).update(updateData);
      print(
        'GameScoreboardCubit: Game status updated to $newStatus for game $gameId',
      );
    } catch (e) {
      if (isClosed) return;
      print('GameScoreboardCubit: Error updating game status: $e');
      emit(
        state.copyWith(
          error: 'Failed to update game status: $e',
          loadingStatus: GameLoadingStatus.error,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    print('GameScoreboardCubit: Closing and cancelling subscriptions.');
    _gameSubscription?.cancel();
    return super.close();
  }
}
