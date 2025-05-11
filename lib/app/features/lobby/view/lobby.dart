import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:score_board/app/features/lobby/cubit/lobby_cubit.dart';
import 'package:score_board/app/features/lobby/cubit/lobby_state.dart';
import 'package:score_board/router/app_router.gr.dart';

@RoutePage()
class GameLobbyRoute extends StatelessWidget {
  const GameLobbyRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          LobbyCubit()..fetchTeams(), // Fetch teams when Cubit is created
      child: const GameLobbyPage(),
    );
  }
}

class GameLobbyPage extends StatefulWidget {
  const GameLobbyPage({super.key});

  @override
  State<GameLobbyPage> createState() => _GameLobbyPageState();
}

class _GameLobbyPageState extends State<GameLobbyPage> {
  String? _selectedTeam1Id;
  String? _selectedTeam2Id;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _gameNameController = TextEditingController();

  @override
  void dispose() {
    _gameNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const String gameType = 'Basketball';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Lobby - Setup'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        leading:
            AutoRouter.of(context).canPop() ? const AutoLeadingButton() : null,
      ),
      body: BlocConsumer<LobbyCubit, LobbyState>(
        listener: (context, state) {
          if (state.status == LobbyStatus.error && state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.redAccent,
              ),
            );
          } else if (state.status == LobbyStatus.gameCreated &&
              state.createdGameId != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Game created successfully! ID: ${state.createdGameId}',
                ),
                backgroundColor: Colors.green,
              ),
            );
            // Navigate to the scoreboard page
            // Ensure ScoreboardGameRoute is correctly defined and imported
            AutoRouter.of(context)
                .push(ScoreboardGameRoute(gameId: state.createdGameId!));
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Configure New Basketball Game',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sports_basketball,
                          color: Theme.of(context).primaryColorDark,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          gameType,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  if (state.status == LobbyStatus.loadingTeams)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (state.status == LobbyStatus.error &&
                      state.teams.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            Text(
                              state.error ??
                                  'An unknown error occurred while loading teams.',
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () =>
                                  context.read<LobbyCubit>().fetchTeams(),
                              child: const Text('Retry Loading Teams'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (state.teams.isEmpty &&
                      state.status != LobbyStatus.loadingTeams)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            const Text(
                              'No teams found. Please add teams first via the admin script.',
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () =>
                                  context.read<LobbyCubit>().fetchTeams(),
                              child: const Text('Refresh Teams List'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // Only show dropdowns and create button if teams are loaded or there was an error but some teams might still be there
                    // Team 1 Dropdown
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Select Home Team',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.group),
                      ),
                      value: _selectedTeam1Id,
                      hint: const Text('Choose home team'),
                      isExpanded: true,
                      items: state.teams
                          .where((team) => team.id != _selectedTeam2Id)
                          .map((Team team) {
                        return DropdownMenuItem<String>(
                          value: team.id,
                          child:
                              Text(team.name, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedTeam1Id = newValue;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Please select Home Team' : null,
                    ),
                    const SizedBox(height: 20),

                    // Team 2 Dropdown
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Select Away Team',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.group_add),
                      ),
                      value: _selectedTeam2Id,
                      hint: const Text('Choose away team'),
                      isExpanded: true,
                      items: state.teams
                          .where((team) => team.id != _selectedTeam1Id)
                          .map((Team team) {
                        return DropdownMenuItem<String>(
                          value: team.id,
                          child:
                              Text(team.name, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedTeam2Id = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null) return 'Please select Away Team';
                        if (value == _selectedTeam1Id) {
                          return 'Away Team cannot be the same as Home Team';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    TextFormField(
                      controller: _gameNameController,
                      decoration: InputDecoration(
                        labelText: 'Game Name / Description (Optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.label_important_outline),
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (state.status == LobbyStatus.creatingGame)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        icon: const Icon(Icons.play_circle_fill_outlined),
                        label: const Text('Create Game & Proceed'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            if (_selectedTeam1Id == null ||
                                _selectedTeam2Id == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please select both teams.'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }
                            // Find team names for default game name generation
                            final homeTeam = state.teams.firstWhere(
                              (t) => t.id == _selectedTeam1Id,
                              orElse: () =>
                                  const Team(id: '', name: 'Unknown Home'),
                            );
                            final awayTeam = state.teams.firstWhere(
                              (t) => t.id == _selectedTeam2Id,
                              orElse: () =>
                                  const Team(id: '', name: 'Unknown Away'),
                            );

                            context.read<LobbyCubit>().createGame(
                                  homeTeamId: _selectedTeam1Id!,
                                  awayTeamId: _selectedTeam2Id!,
                                  homeTeamName: homeTeam.name,
                                  awayTeamName: awayTeam.name,
                                  customGameName: _gameNameController.text,
                                );
                          }
                        },
                      ),
                  ],
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: state.status == LobbyStatus.creatingGame
                        ? null
                        : () {
                            AutoRouter.of(context).pop();
                          },
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
