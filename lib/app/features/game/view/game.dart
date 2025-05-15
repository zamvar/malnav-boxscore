import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:score_board/app/commons/game_log.dart';
import 'package:score_board/app/commons/models/player_model.dart';
import 'package:score_board/app/commons/models/team_model.dart';
import 'package:score_board/app/commons/play_by_play.dart';
import 'package:score_board/app/commons/score_board.dart';
import 'package:score_board/app/features/game/cubit/game_cubit.dart';
import 'package:score_board/app/features/game/cubit/game_state.dart';
import 'package:score_board/app/features/game/view/game_controls.dart'; // Assuming GameLogEntryModal is here

@RoutePage()
class ScoreboardGameRoute extends StatelessWidget {
  const ScoreboardGameRoute({
    @PathParam('gameId') required this.gameId,
    super.key,
  });
  final String gameId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GameScoreboardCubit()..loadGameAndTeams(gameId),
      child: ScoreboardGamePage(
        gameId: gameId,
      ), // Pass gameId to ScoreboardGamePage
    );
  }
}

class ScoreboardGamePage extends StatelessWidget {
  // Added gameId field

  const ScoreboardGamePage({required this.gameId, super.key});
  final String gameId; // Updated constructor
  // MOVE TO THIS TO separate file
  Widget _buildPlayerList(
    BuildContext context,
    TeamDetails team,
    bool isHomeTeam,
    GameScoreboardState gameState,
  ) {
    final List<Player> onCourtPlayersForThisTeam =
        (team.id == gameState.homeTeam?.id)
            ? gameState.homePlayersOnCourt
            : gameState.awayPlayersOnCourt;
    final List<Player> rosterToList = team.players;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border(
            right: isHomeTeam
                ? BorderSide(color: Colors.grey.shade300, width: 1)
                : BorderSide.none,
            left: !isHomeTeam
                ? BorderSide(color: Colors.grey.shade300, width: 1)
                : BorderSide.none,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isHomeTeam ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(
                team.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: isHomeTeam ? TextAlign.left : TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: rosterToList.length,
                itemBuilder: (context, index) {
                  final player = rosterToList[index];
                  bool isOnCourt =
                      onCourtPlayersForThisTeam.any((p) => p.id == player.id);
                  return ListTile(
                    dense: true,
                    leading: isHomeTeam
                        ? Text(
                            player.jerseyNumber,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isOnCourt
                                  ? Theme.of(context).primaryColorLight
                                  : Colors.grey,
                            ),
                          )
                        : null,
                    title: Text(
                      player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isOnCourt ? Colors.white : Colors.grey.shade400,
                        fontWeight:
                            isOnCourt ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                    trailing: !isHomeTeam
                        ? Text(
                            player.jerseyNumber,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isOnCourt
                                  ? Theme.of(context).primaryColorDark
                                  : Colors.grey,
                            ),
                          )
                        : null,
                    onTap: () {
                      _showGameLogEntryModal(
                        context,
                        player,
                        gameState,
                        gameId, // Pass the gameId from the page
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // move this to separate file/widget
  Widget _buildQuarterlyScoresTable(
    BuildContext context,
    GameScoreboardState state,
  ) {
    final Map<String, List<int>> quarterlyScoresData = {
      state.homeTeam?.name ?? 'Home': state.homeTeamQuarterScores,
      state.awayTeam?.name ?? 'Away': state.awayTeamQuarterScores,
    };

    int maxQuartersInvolved = 0;
    if (state.homeTeamQuarterScores.isNotEmpty) {
      maxQuartersInvolved = state.homeTeamQuarterScores.length;
    }
    if (state.awayTeamQuarterScores.isNotEmpty &&
        state.awayTeamQuarterScores.length > maxQuartersInvolved) {
      maxQuartersInvolved = state.awayTeamQuarterScores.length;
    }
    // Ensure we display at least 4 quarter columns, plus any overtime.
    int displayColumnCount = maxQuartersInvolved > 4 ? maxQuartersInvolved : 4;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Team',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                for (int i = 1; i <= 4; i++)
                  SizedBox(
                    width: 30,
                    child: Center(
                      child: Text(
                        'Q$i',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(
                  width: 35,
                  child: Center(
                    child: Text(
                      'T',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            ...quarterlyScoresData.entries.map((entry) {
              final teamName = entry.key;
              final scores = entry
                  .value; // This is List<int> from state (e.g., state.homeTeamQuarterScores)
              List<Widget> scoreWidgets = [];

              for (int i = 0; i < displayColumnCount; i++) {
                String scoreToDisplay = '-';
                // Check if there's a score for this quarter (index i)
                if (i < scores.length) {
                  // Display score if game is completed OR if this quarter is current or past
                  if (state.gamePlayStatus == GamePlayStatus.completed ||
                      (i + 1) <= state.currentQuarter) {
                    scoreToDisplay = scores[i].toString();
                  }
                }
                scoreWidgets.add(
                  SizedBox(
                    width: 30,
                    child: Center(child: Text(scoreToDisplay)),
                  ),
                );
              }

              // Use the total score from the state for accuracy
              int finalTotal = (teamName == (state.homeTeam?.name ?? 'Home'))
                  ? state.homeScore
                  : state.awayScore;

              scoreWidgets.add(
                SizedBox(
                  width: 35,
                  child: Center(
                    child: Text(
                      finalTotal.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(teamName, overflow: TextOverflow.ellipsis),
                    ),
                    ...scoreWidgets,
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameScoreboardCubit, GameScoreboardState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title:
                Text(state.gameData?['name'] as String? ?? 'Live Scoreboard'),
            backgroundColor: Theme.of(context).primaryColorDark,
            foregroundColor: Colors.white,
            leading: AutoRouter.of(context).canPop()
                ? const AutoLeadingButton()
                : null,
          ),
          body: Builder(
            builder: (scaffoldContext) {
              if (state.loadingStatus == GameLoadingStatus.loading &&
                  state.homeTeam == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.loadingStatus == GameLoadingStatus.error &&
                  state.homeTeam == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        state.error ?? 'An unknown error occurred.',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          // Use gameId from the state for retry, which was set when cubit was initialized
                          if (state.gameId != null &&
                              state.gameId!.isNotEmpty) {
                            context
                                .read<GameScoreboardCubit>()
                                .loadGameAndTeams(state.gameId!);
                          } else {
                            // This fallback should ideally not be needed if gameId is always in state after loadGameAndTeams is called
                            ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Error: Game ID not available for retry in state.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              if (state.homeTeam == null || state.awayTeam == null) {
                return const Center(
                  child: Text(
                    'Team data could not be loaded. Ensure teams and game exist in Firestore.',
                  ),
                );
              }

              // Main layout
              return LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 650) {
                    return SingleChildScrollView(
                      // Added SingleChildScrollView
                      child: Column(
                        // mainAxisSize: MainAxisSize.min, // Optional, if content might be shorter than screen
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          // Scoreboard Center - give it a defined height or let it size intrinsically
                          SizedBox(
                            height: 350, // User's preferred height
                            child: ScoreboardCenterDisplay(
                              homeTeamName: state.homeTeam?.name ?? 'Home',
                              awayTeamName: state.awayTeam?.name ?? 'Away',
                              homeScore: state.homeScore,
                              awayScore: state.awayScore,
                              gameStatusDisplay: state
                                  .gameStatusDisplay, // e.g., "Q1 - 10:32", "Halftime", "Final"
                              gameClock: state
                                  .gameClock, // e.g., "10:32" (might be part of gameStatusDisplay)
                            ),
                          ),
                          _buildQuarterlyScoresTable(context, state),
                          Text(
                            'Play by Play',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            height: 200,
                            child: PlayByPlayWidget(
                              awayTeamId: state.awayTeam!.id,
                              homeTeamId: state.homeTeam!.id,
                              awayTeamName: state.awayTeam!.name,
                              homeTeamName: state.homeTeam!.name,
                              gameLogs: state.gameLogs,
                            ),
                          ),
                          const GameControlsWidget(), // You would place your GameControlsWidget here

                          // Player Lists Row - give it a defined height
                          SizedBox(
                            height:
                                300, // Example height, adjust as needed for player lists
                            child: Row(
                              children: <Widget>[
                                _buildPlayerList(
                                  context,
                                  state.homeTeam!,
                                  true,
                                  state,
                                ),
                                _buildPlayerList(
                                  context,
                                  state.awayTeam!,
                                  false,
                                  state,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _buildPlayerList(context, state.homeTeam!, true, state),
                        Expanded(
                          // Make center column flexible
                          flex: 2, // As before
                          child: Column(
                            children: [
                              Expanded(
                                flex: 2,
                                child: ScoreboardCenterDisplay(
                                  homeTeamName: state.homeTeam?.name ?? 'Home',
                                  awayTeamName: state.awayTeam?.name ?? 'Away',
                                  homeScore: state.homeScore,
                                  awayScore: state.awayScore,
                                  gameStatusDisplay: state
                                      .gameStatusDisplay, // e.g., "Q1 - 10:32", "Halftime", "Final"
                                  gameClock: state
                                      .gameClock, // e.g., "10:32" (might be part of gameStatusDisplay)
                                ),
                              ),
                              _buildQuarterlyScoresTable(context, state),
                              Expanded(
                                child: PlayByPlayWidget(
                                  awayTeamId: state.awayTeam!.id,
                                  homeTeamId: state.homeTeam!.id,
                                  awayTeamName: state.awayTeam!.name,
                                  homeTeamName: state.homeTeam!.name,
                                  gameLogs: state.gameLogs,
                                ),
                              ),
                              // Add GameControlsWid,get here for wider view
                              const GameControlsWidget(), // Add this
                              // You might want to add a Spacer or adjust layout if needed
                            ],
                          ),
                        ),
                        _buildPlayerList(
                          context,
                          state.awayTeam!,
                          false,
                          state,
                        ),
                      ],
                    );
                  }
                },
              );
            },
          ),
        );
      },
    );
  }

  void _showGameLogEntryModal(
    BuildContext context,
    Player playerForLog,
    GameScoreboardState currentState,
    String gameIdFromPage, // Added gameId as a direct parameter
  ) {
    if (currentState.homeTeam == null || currentState.awayTeam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Team data not fully loaded for modal.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    List<Player> resolvedPlayerInFocusTeamRoster;
    List<Player> resolvedOpponentTeamRoster;

    if (playerForLog.teamId == currentState.homeTeam!.id) {
      resolvedPlayerInFocusTeamRoster = currentState.homeTeam!.players;
      resolvedOpponentTeamRoster = currentState.awayTeam!.players;
    } else if (playerForLog.teamId == currentState.awayTeam!.id) {
      resolvedPlayerInFocusTeamRoster = currentState.awayTeam!.players;
      resolvedOpponentTeamRoster = currentState.homeTeam!.players;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Player team ID mismatch for modal.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final List<Player> allOnCourt = [
      ...currentState.homePlayersOnCourt,
      ...currentState.awayPlayersOnCourt,
    ];

    if (allOnCourt.isEmpty &&
        (currentState.homeTeam!.players.isNotEmpty ||
            currentState.awayTeam!.players.isNotEmpty)) {
      debugPrint(
        'ScoreboardPage: Warning - allPlayersOnCourt in state is empty but team rosters are not. Modal player selectors might be incomplete for on-court specific actions.',
      );
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return GameLogEntryModal(
          playerInFocus: playerForLog,
          gameQuarter: currentState.gameStatusDisplay.split(' - ').first,
          gameClock: currentState.gameClock,
          playerInFocusTeamRoster: resolvedPlayerInFocusTeamRoster,
          opponentTeamRoster: resolvedOpponentTeamRoster,
          allPlayersOnCourt: allOnCourt,
          onLogConfirm: (logData) {
            // Use gameIdFromPage passed directly to this method
            if (gameIdFromPage.isNotEmpty) {
              context
                  .read<GameScoreboardCubit>()
                  .addLogEntry(gameIdFromPage, logData);
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(
                  content: Text(
                    'Log for ${logData['player']?['playerName']} - ${logData['actionType']} confirmed! Processing...',
                  ),
                  backgroundColor: Colors.blue,
                ),
              );
            } else {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(
                  content: Text('Error: Game ID not available to save log.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
      },
    );
  }
}
