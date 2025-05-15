// dashboard_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:score_board/app/features/dashboard/cubit/dashboard_state.dart';
import 'package:score_board/utils/constants.dart'; // For AppConstants.userUsernameKey

class DashboardCubit extends Cubit<DashboardState> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DashboardCubit() : super(const DashboardState());

  Future<String?> _fetchTeamName(String teamId) async {
    if (teamId.isEmpty) return "Unknown Team";
    try {
      final teamDoc = await _firestore.collection('teams').doc(teamId).get();
      if (teamDoc.exists) {
        return teamDoc.data()?['name'] as String? ?? "Unnamed Team";
      }
    } catch (e) {
      print("Error fetching team name for $teamId: $e");
    }
    return "Team ID: $teamId"; // Fallback if name not found
  }

  Future<void> loadDashboardData() async {
    emit(state.copyWith(status: DashboardStatus.loading, clearError: true));
    try {
      // Load username
      final storedUsername =
          await _secureStorage.read(key: AppConstants.userUsernameKey);

      // Fetch games
      final QuerySnapshot gamesSnapshot = await _firestore
          .collection('games')
          .orderBy('scheduledTime', descending: true) // Fetch newest first
          .limit(20) // Limit for performance, adjust as needed
          .get();

      List<GameOverview> ongoing = [];
      List<GameOverview> history = [];

      Set<String> teamIdsToFetch = {};
      for (final doc in gamesSnapshot.docs) {
        final data = doc.data()! as Map<String, dynamic>;
        final String homeTeamId = data['homeTeamId'] as String? ?? '';
        final String awayTeamId = data['awayTeamId'] as String? ?? '';
        if (homeTeamId.isNotEmpty) teamIdsToFetch.add(homeTeamId);
        if (awayTeamId.isNotEmpty) teamIdsToFetch.add(awayTeamId);
      }

      Map<String, String> teamNamesMap = {};
      if (teamIdsToFetch.isNotEmpty) {
        for (final String teamId in teamIdsToFetch) {
          // Ensure null safety for team name fetching
          teamNamesMap[teamId] =
              await _fetchTeamName(teamId) ?? "Error Fetching Name";
        }
      }

      for (final doc in gamesSnapshot.docs) {
        final data = doc.data()! as Map<String, dynamic>;
        // Use GamePlayStatus.fromString to convert Firestore string to enum
        final GamePlayStatus gameStatus =
            GamePlayStatus.fromString(data['status'] as String?);

        final String homeTeamId = data['homeTeamId'] as String? ?? '';
        final String awayTeamId = data['awayTeamId'] as String? ?? '';

        final String homeTeamName = teamNamesMap[homeTeamId] ?? 'Home Team';
        final String awayTeamName = teamNamesMap[awayTeamId] ?? 'Away Team';

        final overview = GameOverview(
          id: doc.id,
          name: data['name'] as String? ?? 'Unnamed Game',
          homeTeamName: homeTeamName,
          awayTeamName: awayTeamName,
          homeScore: data['homeTeamScore'] as int? ?? 0,
          awayScore: data['awayTeamScore'] as int? ?? 0,
          status: gameStatus, // Use the GamePlayStatus enum
          scheduledTime: data['scheduledTime'] as Timestamp?,
        );

        // Categorize based on the GamePlayStatus enum
        if (gameStatus == GamePlayStatus.liveQ1 ||
            gameStatus == GamePlayStatus.liveQ2 ||
            gameStatus == GamePlayStatus.halftime ||
            gameStatus == GamePlayStatus.liveQ3 ||
            gameStatus == GamePlayStatus.liveQ4 ||
            gameStatus == GamePlayStatus.liveOT ||
            gameStatus == GamePlayStatus.scheduled) {
          ongoing.add(overview);
        } else if (gameStatus == GamePlayStatus.completed ||
            gameStatus == GamePlayStatus.cancelled ||
            gameStatus == GamePlayStatus.postponed) {
          history.add(overview);
        }
        // GamePlayStatus.unknown games will be ignored by this logic
      }

      // Sort ongoing games: live games first, then scheduled
      ongoing.sort((a, b) {
        bool aIsConsideredLive = a.status != GamePlayStatus.scheduled &&
            a.status != GamePlayStatus.completed &&
            a.status != GamePlayStatus.cancelled &&
            a.status != GamePlayStatus.postponed &&
            a.status != GamePlayStatus.unknown;
        bool bIsConsideredLive = b.status != GamePlayStatus.scheduled &&
            b.status != GamePlayStatus.completed &&
            b.status != GamePlayStatus.cancelled &&
            b.status != GamePlayStatus.postponed &&
            b.status != GamePlayStatus.unknown;

        bool aIsScheduled = a.status == GamePlayStatus.scheduled;
        bool bIsScheduled = b.status == GamePlayStatus.scheduled;

        if (aIsConsideredLive && !bIsConsideredLive)
          return -1; // Live games first
        if (!aIsConsideredLive && bIsConsideredLive) return 1;

        if (aIsConsideredLive && bIsConsideredLive) {
          return (b.scheduledTime ?? Timestamp(0, 0)).compareTo(
              a.scheduledTime ?? Timestamp(0, 0)); // Newest live first
        }

        if (aIsScheduled && bIsScheduled) {
          // Both scheduled
          return (a.scheduledTime ?? Timestamp.now()).compareTo(
              b.scheduledTime ?? Timestamp.now()); // Closest upcoming first
        }
        if (aIsScheduled)
          return -1; // Scheduled before other non-live types (if any)
        if (bIsScheduled) return 1;

        return (b.scheduledTime ?? Timestamp(0, 0))
            .compareTo(a.scheduledTime ?? Timestamp(0, 0));
      });

      emit(
        state.copyWith(
          status: DashboardStatus.success,
          username: storedUsername,
          ongoingGames: ongoing,
          gameHistory: history,
        ),
      );
    } catch (e, s) {
      print('DashboardCubit: Error loading dashboard data: $e');
      print('DashboardCubit: Stacktrace: $s');
      emit(
        state.copyWith(
          status: DashboardStatus.failure,
          error: 'Failed to load dashboard data: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> clearDashboardDataOnLogout() async {
    emit(const DashboardState());
  }
}
