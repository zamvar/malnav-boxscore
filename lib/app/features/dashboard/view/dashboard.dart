import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Assuming your LoginRoute is here for navigation after logout
// Adjust path as per your project structure
// You might not need LoginRoute if logout functionality is fully removed for UI-only.
// For now, I'll keep it for the logout button's navigation intent.
import 'package:score_board/router/app_router.gr.dart';
import 'package:score_board/utils/constants.dart';

@RoutePage()
class DashboardRoute extends StatelessWidget {
  const DashboardRoute({super.key});

  @override
  Widget build(BuildContext context) {
    // No BlocProvider needed as this is UI-only
    return const DashboardPage();
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _username;
  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final storedUsername =
        await _secureStorage.read(key: AppConstants.userUsernameKey);
    if (mounted) {
      setState(() {
        _username = storedUsername;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Static mock data for ongoing games
    final List<String> mockOngoingGames = [
      'Game 1: Team Alpha vs Team Bravo',
      'Game 2: Phoenixes vs Griffins',
      'Game 3: Titans Challenge Cup Final',
    ];

    // Static mock data for game history
    final List<String> mockGameHistory = [
      'Yesterday: Team Alpha vs Team Charlie (5-2)',
      'May 7: Phoenixes vs Serpents (3-3)',
      'May 5: Titans vs Olympians (1-0)',
      'May 3: Knights vs Warriors (4-1)',
      'May 1: Dragons vs Elementals (2-2)',
    ];
    final String appBarTitle = _username != null && _username!.isNotEmpty
        ? "$_username's Scoreboard"
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
            onPressed: () {
              // Placeholder for logout action
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Logout action triggered (UI Only). Navigating to Login...',),),
              );
              AutoRouter.of(context).replaceAll([const LoginRoute()]);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Placeholder for refresh action
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dashboard refreshed (UI Only)')),
          );
          await Future.delayed(const Duration(seconds: 1)); // Simulate a delay
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            // Welcome Message (Static)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                'Welcome back!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600, color: Colors.indigo[700],),
              ),
            ),

            // Start a New Game Button
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
                      fontSize: 18, fontWeight: FontWeight.bold,),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),),
                  elevation: 5,
                ),
                onPressed: () {
                  context.router.push(const GameLobbyRoute());
                  // Placeholder for navigation or action
                  // AutoRouter.of(context).push(const StartGameRoute());
                },
              ),
            ),

            // Manage Teams Card
            _buildDashboardCard(context,
                icon: Icons.group_work_outlined,
                title: 'Manage Teams',
                subtitle: 'Create, edit, and view your teams.',
                color: Colors.teal.shade600, onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Navigate to Manage Teams (UI Only)'),),
              );
              // AutoRouter.of(context).push(const ManageTeamsRoute());
            },),
            const SizedBox(height: 16),

            // Ongoing Games Card (using static mock data)
            _buildOngoingGamesCard(context, mockOngoingGames),

            const SizedBox(height: 16),
            // Game History Card (updated)
            _buildGameHistoryCard(context, mockGameHistory),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required Color color,
      VoidCallback? onTap,}) {
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
                Icon(Icons.arrow_forward_ios,
                    color: Colors.grey.shade400, size: 18,),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOngoingGamesCard(BuildContext context, List<String> games) {
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
                    color: Colors.lightBlue.shade600.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.sports_soccer_outlined,
                      size: 30, color: Colors.lightBlue.shade700,),
                ),
                const SizedBox(width: 16),
                Text(
                  'Ongoing Games',
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
                    'No ongoing games right now.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: games.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(Icons.circle,
                        size: 10, color: Colors.green.shade600,),
                    title: Text(games[index]),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Tapped on ${games[index]} (UI Only)'),),
                      );
                      // AutoRouter.of(context).push(GameDetailsRoute(gameId: games[index]));
                    },
                  );
                },
              ),
            if (games.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('View All Ongoing Games (UI Only)'),),
                      );
                      // AutoRouter.of(context).push(const AllOngoingGamesRoute());
                    },
                    child: Text('View All',
                        style: TextStyle(color: Colors.indigo[700]),),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // New Widget for Game History Card
  Widget _buildGameHistoryCard(BuildContext context, List<String> gameHistory) {
    // Determine how many items to show initially
    final int itemsToShow = gameHistory.length > 3 ? 3 : gameHistory.length;
    final bool showViewAllButton = gameHistory.length > 3;

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
                    color: Colors.deepPurple.shade600.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.history_edu_outlined,
                      size: 30, color: Colors.deepPurple.shade700,),
                ),
                const SizedBox(width: 16),
                Text(
                  'Game History',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (gameHistory.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'No game history available yet.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: itemsToShow, // Show only the first few items
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(Icons.check_circle_outline,
                        size: 20, color: Colors.grey.shade500,),
                    title: Text(gameHistory[index]),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.grey,),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Tapped on ${gameHistory[index]} (UI Only)',),),
                      );
                      // AutoRouter.of(context).push(GameDetailsRoute(gameId: gameHistory[index]));
                    },
                  );
                },
              ),
            if (showViewAllButton)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('View All Game History (UI Only)'),),
                      );
                      // AutoRouter.of(context).push(const AllGameHistoryRoute());
                    },
                    child: Text('View All',
                        style: TextStyle(color: Colors.indigo[700]),),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
