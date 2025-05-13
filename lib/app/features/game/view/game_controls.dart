import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:score_board/app/features/game/cubit/game_cubit.dart';
import 'package:score_board/app/features/game/cubit/game_state.dart';

class GameControlsWidget extends StatelessWidget {
  const GameControlsWidget({super.key});

  void _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(title.contains('End Game') ? 'End Game' : 'Confirm'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onConfirm();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameScoreboardCubit, GameScoreboardState>(
      builder: (context, state) {
        if (state.loadingStatus == GameLoadingStatus.loading &&
            state.gameId == null) {
          // GameId not yet loaded in state, or initial loading before game data is available
          return const SizedBox.shrink(); // Or a disabled placeholder
        }
        if (state.gameId == null || state.gameId!.isEmpty) {
          return const Center(
            child: Text('Game ID not available for controls.'),
          );
        }

        final gameId = state.gameId!;
        final cubit = context.read<GameScoreboardCubit>();
        final currentQuarter = state.currentQuarter;
        final gamePlayStatus = state.gamePlayStatus;

        bool canAdvanceQuarter = false;
        String nextQuarterActionText = 'Next Quarter';

        if (gamePlayStatus == GamePlayStatus.scheduled) {
          canAdvanceQuarter = true;
          nextQuarterActionText = 'Start Game (Q1)';
        } else if (gamePlayStatus == GamePlayStatus.live) {
          if (currentQuarter == 1) {
            canAdvanceQuarter = true;
            nextQuarterActionText = 'End Q1 / Start Q2';
          } else if (currentQuarter == 2) {
            canAdvanceQuarter = true;
            nextQuarterActionText = 'End Q2 / Halftime';
          } else if (currentQuarter == 3) {
            canAdvanceQuarter = true;
            nextQuarterActionText = 'End Q3 / Start Q4';
          } else if (currentQuarter == 4) {
            canAdvanceQuarter = true;
            // After Q4, it could be OT or End Game
            nextQuarterActionText =
                'End Q4 / Proceed'; // User might then choose OT or Final
          } else if (currentQuarter >= 5) {
            // Overtime
            canAdvanceQuarter = true;
            nextQuarterActionText = 'End OT${currentQuarter - 4} / Next OT';
          }
        } else if (gamePlayStatus == GamePlayStatus.halftime) {
          canAdvanceQuarter = true;
          nextQuarterActionText = 'Start Q3';
        }

        // ignore: omit_local_variable_types
        bool canEndGame = gamePlayStatus != GamePlayStatus.completed &&
            gamePlayStatus != GamePlayStatus.cancelled;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Game Controls',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Current Status: ${state.gameStatusDisplay}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                if (canAdvanceQuarter)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.skip_next_rounded),
                    label: Text(nextQuarterActionText),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      _showConfirmationDialog(
                        context: context,
                        title: 'Confirm Action',
                        content:
                            'Are you sure you want to proceed to: $nextQuarterActionText?',
                        onConfirm: () {
                          int nextQ = currentQuarter;
                          String nextStatus = state.gameData?['status']
                                  as String? ??
                              GamePlayStatus.live.toString().split('.').last;

                          if (gamePlayStatus == GamePlayStatus.scheduled) {
                            nextQ = 1;
                            nextStatus = 'live_q1';
                            cubit.updateGameStatus(
                              gameId,
                              nextStatus,
                              newQuarter: nextQ,
                            );
                          } else if (gamePlayStatus == GamePlayStatus.live) {
                            if (currentQuarter == 1) {
                              nextQ = 2;
                              nextStatus = 'live_q2';
                            } else if (currentQuarter == 2) {
                              nextQ = 3;
                              nextStatus = 'halftime';
                            } // Go to halftime
                            else if (currentQuarter == 3) {
                              nextQ = 4;
                              nextStatus = 'live_q4';
                            } else if (currentQuarter == 4) {
                              // After Q4, typically an admin decides if it's OT or Final
                              // For simplicity, this button could trigger "End Game" or you add an "Start OT" button
                              // Here, let's assume it means the game might go to OT or end.
                              // We'll just prompt to end game. A more complex UI would have an OT option.
                              _showConfirmationDialog(
                                context: context,
                                title: 'End Game or Overtime?',
                                content:
                                    'The 4th quarter is ending. Do you want to end the game or proceed to overtime (if scores are tied)? For now, this will mark the game as completed.',
                                onConfirm: () => cubit.updateGameStatus(
                                  gameId,
                                  'completed',
                                  newQuarter: 4,
                                ),
                              );
                              return; // Don't call advanceQuarter directly
                            } else {
                              // Overtime
                              nextQ = currentQuarter + 1;
                              nextStatus = 'live_ot${nextQ - 4}';
                            }
                            cubit.advanceQuarter(
                              gameId,
                              nextQ,
                            ); // advanceQuarter also updates status
                          } else if (gamePlayStatus ==
                              GamePlayStatus.halftime) {
                            nextQ = 3;
                            nextStatus = 'live_q3';
                            cubit.updateGameStatus(
                              gameId,
                              nextStatus,
                              newQuarter: nextQ,
                            );
                          }
                        },
                      );
                    },
                  ),
                if (canAdvanceQuarter) const SizedBox(height: 10),
                if (canEndGame)
                  ElevatedButton.icon(
                    icon: const Icon(
                      Icons.sports_score_rounded,
                      color: Colors.white,
                    ),
                    label: const Text('End Game Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      _showConfirmationDialog(
                        context: context,
                        title: 'Confirm End Game',
                        content:
                            'Are you sure you want to end this game? This action cannot be undone.',
                        onConfirm: () {
                          cubit.updateGameStatus(
                            gameId,
                            'completed',
                            newQuarter: currentQuarter,
                          );
                        },
                      );
                    },
                  ),
                // This would require methods in the Cubit like startGameClock, stopGameClock, setGameClock
              ],
            ),
          ),
        );
      },
    );
  }
}
