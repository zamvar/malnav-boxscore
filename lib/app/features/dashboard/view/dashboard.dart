import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:score_board/app/features/dashboard/cubit/dashboard_cubit.dart';
// Import your updated Cubit and State
// Ensure these paths are correct for your project structure

import 'package:score_board/app/features/dashboard/cubit/dashboard_state.dart';
// For logout navigation and constants/routes
import 'package:score_board/router/app_router.gr.dart';
// AppConstants.userUsernameKey is used within the DashboardCubit, no need to import here
// if it's solely for the cubit's internal use with secure_storage.

@RoutePage()
class DashboardRoute extends StatelessWidget {
  const DashboardRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardCubit()
        ..loadDashboardData(), // Load data when Cubit is created
      child: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  // Logout logic should ideally be in an AuthCubit and triggered globally.
  // This is a simplified version for UI demonstration.
  Future<void> _handleLogout(BuildContext context) async {
    // If DashboardCubit needs to clear its specific state on logout:
    // context.read<DashboardCubit>().clearDashboardDataOnLogout();

    // Actual sign-out and navigation (ideally from AuthCubit)
    // For this example, direct navigation:
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logging out...'),
        backgroundColor: Colors.orangeAccent,
      ),
    );
    // Ensure LoginRoute is correctly defined in your AppRouter
    AutoRouter.of(context).replaceAll([const LoginRoute()]);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        final String appBarTitle =
            state.username != null && state.username!.isNotEmpty
                ? "${state.username}'s Scoreboard"
                : 'My Scoreboard';

        return Scaffold(
          appBar: AppBar(
            title: Text(appBarTitle),
            backgroundColor: Colors.indigo[800],
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
                onPressed: () => _handleLogout(context),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              // Trigger data reload from the Cubit
              await context.read<DashboardCubit>().loadDashboardData();
            },
            child: Builder(
                // Use Builder to get a new context for ScaffoldMessenger if needed inside ListView
                builder: (BuildContext listContext) {
              // Show loading indicator only if it's the initial load (no data yet)
              if (state.status == DashboardStatus.loading &&
                  state.ongoingGames.isEmpty &&
                  state.gameHistory.isEmpty &&
                  state.username == null) {
                return const Center(child: CircularProgressIndicator());
              }
              // Show error message if initial load failed
              if (state.status == DashboardStatus.failure &&
                  state.ongoingGames.isEmpty &&
                  state.gameHistory.isEmpty &&
                  state.username == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.error ?? "Failed to load dashboard.",
                            style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => context
                              .read<DashboardCubit>()
                              .loadDashboardData(),
                          child: const Text("Retry"),
                        )
                      ],
                    ),
                  ),
                );
              }

              // Main content ListView
              return ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      state.username != null && state.username!.isNotEmpty
                          ? 'Welcome back, ${state.username}!'
                          : 'Welcome back!',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.indigo[700],
                              ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle_outline, size: 28),
                      label: const Text('Start a New Game'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                      ),
                      onPressed: () {
                        // Ensure GameLobbyRoute is defined in your AppRouter
                        AutoRouter.of(context).push(const GameLobbyRoute());
                      },
                    ),
                  ),
                  _buildDashboardCard(
                    // Generic card for actions like "Manage Teams"
                    context,
                    icon: Icons.group_work_outlined,
                    title: 'Manage Teams',
                    subtitle: 'Create, edit, and view your teams.',
                    color: Colors.teal.shade600,
                    onTap: () {
                      ScaffoldMessenger.of(listContext).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Navigate to Manage Teams (Not Implemented)')),
                      );
                      // Example: AutoRouter.of(context).push(const ManageTeamsRoute());
                    },
                  ),
                  const SizedBox(height: 16),
                  // Use state.ongoingGames and state.gameHistory from the Cubit
                  _buildGameListCard(
                    context: context,
                    title: 'Ongoing Games',
                    titleIcon: Icons.sports_basketball_outlined,
                    titleIconColor: Colors.lightBlue.shade700,
                    games: state.ongoingGames, // From Cubit state
                    emptyListMessage: 'No ongoing games right now.',
                    onViewAllTap: () {
                      ScaffoldMessenger.of(listContext).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'View All Ongoing Games (Not Implemented)')),
                      );
                      // Example: AutoRouter.of(context).push(const AllOngoingGamesRoute());
                    },
                    scaffoldListContext: listContext,
                  ),
                  const SizedBox(height: 16),
                  _buildGameListCard(
                    context: context,
                    title: 'Game History',
                    titleIcon: Icons.history_edu_outlined,
                    titleIconColor: Colors.deepPurple.shade700,
                    games: state.gameHistory, // From Cubit state
                    emptyListMessage: 'No game history available yet.',
                    onViewAllTap: () {
                      ScaffoldMessenger.of(listContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'View All Game History (Not Implemented)',
                          ),
                        ),
                      );
                      // Example: AutoRouter.of(context).push(const AllGameHistoryRoute());
                    },
                    scaffoldListContext: listContext,
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  // Generic card for static actions like "Manage Teams"
  Widget _buildDashboardCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey.shade700, fontSize: 14),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Generic card builder for lists of games (Ongoing or History)
  Widget _buildGameListCard({
    required BuildContext context,
    required String title,
    required IconData titleIcon,
    required Color titleIconColor,
    required List<GameOverview> games, // Takes List<GameOverview>
    required String emptyListMessage,
    required VoidCallback onViewAllTap,
    required BuildContext scaffoldListContext,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: titleIconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(titleIcon, size: 30, color: titleIconColor),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (games.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    emptyListMessage,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: title == 'Game History'
                    ? (games.length > 3 ? 3 : games.length)
                    : games.length,
                itemBuilder: (context, index) {
                  final game = games[index];
                  final formattedTime = game.scheduledTime != null
                      ? DateFormat('MMM d, yyyy - hh:mm a')
                          .format(game.scheduledTime!.toDate().toLocal())
                      : 'Date N/A';
                  return ListTile(
                    title: Text(
                      '${game.homeTeamName} ${game.homeScore} vs ${game.awayTeamName} ${game.awayScore}',
                    ),
                    subtitle: Text(
                        'Status: ${game.status.displayValue} ($formattedTime)'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigate to game details
                      navigateToGame(context, game, title);
                    },
                  );
                },
              ),
            if ((title == 'Game History' && games.length > 3) ||
                (title == 'Ongoing Games' &&
                    games.isNotEmpty &&
                    games.length >
                        3)) // Show "View All" if more than 3 for ongoing too
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onViewAllTap,
                    child: Text(
                      'View All',
                      style: TextStyle(color: Colors.indigo[700]),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void navigateToGame(BuildContext context, GameOverview game, String title) {
    // Ensure ScoreboardGameRoute is defined and imported from your router
    if (title == 'Game History') {
      AutoRouter.of(context).push(PublicGameRoute(gameId: game.id));
    } else {
      AutoRouter.of(context).push(ScoreboardGameRoute(gameId: game.id));
    }
    // AutoRouter.of(context)
    //     .push(ScoreboardGameRoute(gameId: game.id));
  }
}
