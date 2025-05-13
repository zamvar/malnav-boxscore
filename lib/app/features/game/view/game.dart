import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Assuming your Team and Player models/helper classes are defined.
// If not, we can define simple ones here or import them.

// Simplified Player model for display in roster
class Player {

  const Player({
    required this.id,
    required this.name,
    required this.jerseyNumber,
    required this.teamId,
  });

  // Factory constructor to create a Player instance from a map
  factory Player.fromMap(Map<String, dynamic> map, String documentId) {
    return Player(
      id: documentId, // Use documentId passed to the factory, or map['id'] if preferred
      name: map['playerName'] as String? ?? map['name'] as String? ?? 'Unknown Player', // Check for both playerName and name
      jerseyNumber: map['jerseyNumber'] as String? ?? '--',
      teamId: map['teamId'] as String? ?? '', // Assuming teamId might be in the map or derived
    );
  }

  // Example: If player data is a sub-collection or an array within a team document
  // and the 'id' is a field within the player map itself.
  factory Player.fromPlayerMapInTeam(Map<String, dynamic> map, String defaultTeamId) {
    return Player(
      id: map['playerId'] as String? ?? 'unknown_player_id',
      name: map['playerName'] as String? ?? 'Unknown Player',
      jerseyNumber: map['jerseyNumber'] as String? ?? '--',
      teamId: map['teamId'] as String? ?? defaultTeamId, // Use defaultTeamId if not in map
    );
  }
  final String id;
  final String name;
  final String jerseyNumber;
  final String teamId;


  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Player &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return '$name (#$jerseyNumber)';
  }
}


// Simplified Team model for fetching and display
class TeamDetails {
  TeamDetails({
    required this.id,
    required this.name,
    required this.players,
  });
  final String id;
  final String name;
  final List<Player> players;
}

@RoutePage()
class ScoreboardGameRoute extends StatelessWidget {
  // Potentially pass team IDs if not directly fetched via gameId, but game doc should have them
  // final String homeTeamId;
  // final String awayTeamId;

  const ScoreboardGameRoute({
    @PathParam('gameId') required this.gameId,
    super.key,
    // required this.homeTeamId,
    // required this.awayTeamId,
  });
  final String gameId;

  @override
  Widget build(BuildContext context) {
    return ScoreboardGamePage(gameId: gameId);
  }
}

class ScoreboardGamePage extends StatefulWidget {
  const ScoreboardGamePage({required this.gameId, super.key});
  final String gameId;

  @override
  State<ScoreboardGamePage> createState() => _ScoreboardGamePageState();
}

class _ScoreboardGamePageState extends State<ScoreboardGamePage> {
  TeamDetails? _homeTeam;
  TeamDetails? _awayTeam;
  Map<String, dynamic>? _gameData; // To store game details like scores, quarter

  bool _isLoading = true;
  String? _error;

  // Mock game state for UI display - in a real app, this comes from gameData/gameLogs
  int _homeScore = 0;
  int _awayScore = 0;
  int _currentQuarter = 1;
  final String _gameClock = '12:00';
  String _gameStatus = 'Q1'; // e.g., "Q1", "Halftime", "Final"

  @override
  void initState() {
    super.initState();
    _fetchGameAndTeamData();
  }

  Future<void> _fetchGameAndTeamData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Fetch Game Data
      final DocumentSnapshot gameDocSnapshot = await FirebaseFirestore.instance
          .collection('games')
          .doc(widget.gameId)
          .get();

      if (!gameDocSnapshot.exists) {
        throw Exception('Game not found!');
      }
      _gameData = gameDocSnapshot.data() as Map<String, dynamic>?;
      if (_gameData == null) {
        throw Exception('Game data is empty or invalid!');
      }

      final String homeTeamId = _gameData!['homeTeamId'] as String;
      final String awayTeamId = _gameData!['awayTeamId'] as String;

      // 2. Fetch Home Team Data
      final DocumentSnapshot homeTeamDocSnapshot = await FirebaseFirestore
          .instance
          .collection('teams')
          .doc(homeTeamId)
          .get();
      if (!homeTeamDocSnapshot.exists) throw Exception('Home team not found!');
      final homeTeamMap = homeTeamDocSnapshot.data()! as Map<String, dynamic>;
      _homeTeam = TeamDetails(
        id: homeTeamDocSnapshot.id,
        name: homeTeamMap['name'] as String? ?? 'Home Team',
        players: (homeTeamMap['players'] as List<dynamic>? ?? [])
            .map(
              (playerMap) => Player.fromMap(playerMap as Map<String, dynamic>,homeTeamDocSnapshot.id),
            )
            .toList(),
      );

      // 3. Fetch Away Team Data
      final DocumentSnapshot awayTeamDocSnapshot = await FirebaseFirestore
          .instance
          .collection('teams')
          .doc(awayTeamId)
          .get();
      if (!awayTeamDocSnapshot.exists) throw Exception('Away team not found!');
      final awayTeamMap = awayTeamDocSnapshot.data()! as Map<String, dynamic>;
      _awayTeam = TeamDetails(
        id: awayTeamDocSnapshot.id,
        name: awayTeamMap['name'] as String? ?? 'Away Team',
        players: (awayTeamMap['players'] as List<dynamic>? ?? [])
            .map(
              (playerMap) => Player.fromMap(playerMap as Map<String, dynamic>,homeTeamDocSnapshot.id),
            )
            .toList(),
      );

      // 4. Update scores and game state from _gameData (or calculate from logs)
      // For this UI version, we'll use the top-level scores if available,
      // otherwise, the mock scores will persist.
      // In a real app, you'd listen to gameLogs and calculate or use live scores.
      if (mounted) {
        setState(() {
          _homeScore = _gameData!['homeTeamScore'] as int? ?? _homeScore;
          _awayScore = _gameData!['awayTeamScore'] as int? ?? _awayScore;
          _currentQuarter =
              _gameData!['currentQuarter'] as int? ?? _currentQuarter;
          _gameStatus = _deriveGameStatus(
            _gameData!['status'] as String?,
            _currentQuarter,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading game data: ${e.toString()}';
          _isLoading = false;
        });
      }
      debugPrint('Error: $e');
    }
  }

  String _deriveGameStatus(String? statusFromDb, int quarter) {
    if (statusFromDb == 'completed') return 'Final';
    if (statusFromDb == 'halftime') return 'Halftime';
    if (statusFromDb != null && statusFromDb.startsWith('live_q')) {
      return 'Q$quarter';
    }
    if (statusFromDb == 'scheduled') return 'Scheduled';
    return 'Q$quarter'; // Default
  }

  Widget _buildPlayerList(TeamDetails team, bool isHomeTeam) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(
                team.name,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: isHomeTeam ? TextAlign.left : TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: team.players.length,
                itemBuilder: (context, index) {
                  final player = team.players[index];
                  return ListTile(
                    dense: true,
                    leading: Text(
                      player.jerseyNumber,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColorDark,
                      ),
                    ),
                    title: Text(
                      player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // subtitle: Text('PTS: X AST: Y REB: Z'), // Placeholder for player stats
                    onTap: () {
                      // Action when player is tapped, e.g., show detailed stats or substitute
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('${player.name} tapped (UI Only)'),
                        ),
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

  Widget _buildScoreboardCenter() {
    // Mock data, replace with actual game data from _gameData or stream
    final String homeTeamName = _homeTeam?.name ?? 'Home';
    final String awayTeamName = _awayTeam?.name ?? 'Away';

    return Expanded(
      flex: 2, // Give more space to the center scoreboard
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Team Names and Scores
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: Text(
                    homeTeamName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8), // Spacer
                Expanded(
                  child: Text(
                    awayTeamName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: Text(
                    '$_homeScore',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '-',
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    '$_awayScore',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Game Status (Quarter, Time)
            Text(
              _gameStatus, // e.g., "Q1", "Halftime", "Final"
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _gameClock, // e.g., "10:34"
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),

            // Placeholder for Game Controls / Log Entry
            if (_gameData?['status'] != 'completed' &&
                _gameData?['status'] != 'cancelled')
              // Place "Add Game Log" button here
              ElevatedButton.icon(
                icon: const Icon(Icons.add_comment_outlined),
                label: const Text('Add Game Log'),
                onPressed: () {
                  // Navigate to a page or show a dialog to add a new game log entry
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Add Game Log tapped (UI Only)'),
                    ),
                  );
                },
              ),

            _buildQuarterlyScoresTable(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuarterlyScoresTable() {
    // This would be populated from game logs or a specific field in gameData
    // For now, using mock data.
    final Map<String, List<int>> quarterlyScores = {
      _homeTeam?.name ?? 'Home': [22, 29, 29, 22], // Q1, Q2, Q3, Q4
      _awayTeam?.name ?? 'Away': [28, 28, 27, 19],
    };
    // In a real app, you'd calculate this based on currentQuarter and game status
    int quartersToDisplay = _currentQuarter > 4 ? 4 : _currentQuarter;
    if (_gameData?['status'] == 'completed') quartersToDisplay = 4;

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
            ...quarterlyScores.entries.map((entry) {
              final teamName = entry.key;
              final scores = entry.value;
              int total = 0;
              final List<Widget> scoreWidgets = [];
              for (int i = 0; i < 4; i++) {
                final int score = (i < scores.length && i < quartersToDisplay)
                    ? scores[i]
                    : 0;
                total += score;
                scoreWidgets.add(
                  SizedBox(
                    width: 30,
                    child: Center(
                      child: Text(
                        (i < quartersToDisplay ||
                                _gameData?['status'] == 'completed')
                            ? score.toString()
                            : '-',
                      ),
                    ),
                  ),
                );
              }
              scoreWidgets.add(
                SizedBox(
                  width: 35,
                  child: Center(
                    child: Text(
                      total.toString(),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_gameData?['name'] as String? ?? 'Live Scoreboard'),
        backgroundColor: Theme.of(context).primaryColorDark, // Example color
        foregroundColor: Colors.white,
        leading:
            AutoRouter.of(context).canPop() ? const AutoLeadingButton() : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _fetchGameAndTeamData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : (_homeTeam == null || _awayTeam == null)
                  ? const Center(
                      child: Text('Team data could not be loaded.'),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 600) {
                          // Phone viewport
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              _buildScoreboardCenter(), // Scoreboard at the top
                              Expanded(
                                child: Row(
                                  // Players lists side-by-side
                                  children: <Widget>[
                                    _buildPlayerList(_homeTeam!, true),
                                    _buildPlayerList(_awayTeam!, false)
                                  ],
                                ),
                              ),
                            ],
                          );
                        } else {
                          // Wider viewport (tablet/desktop)
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _buildPlayerList(
                                  _homeTeam!, true), // Home team on the left
                              _buildScoreboardCenter(), // Scoreboard in the middle
                              _buildPlayerList(
                                  _awayTeam!, false), // Away team on the right
                            ],
                          );
                        }
                      },
                    ),
    );
  }
}
