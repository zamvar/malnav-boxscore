import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:score_board/app/features/lobby/cubit/lobby_state.dart'; // For listEquals and immutable

class LobbyCubit extends Cubit<LobbyState> {
  LobbyCubit() : super(const LobbyState());
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> fetchTeams() async {
    emit(state.copyWith(status: LobbyStatus.loadingTeams, clearError: true));
    try {
      final QuerySnapshot teamSnapshot =
          await _firestore.collection('teams').orderBy('name').get();

      final List<Team> fetchedTeams = teamSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        return Team(
          id: doc.id,
          name: data?['name'] as String? ?? 'Unnamed Team (ID: ${doc.id})',
        );
      }).toList();

      emit(state.copyWith(
        status: LobbyStatus.teamsLoaded,
        teams: fetchedTeams,
      ),);
    } catch (e) {
      emit(
        state.copyWith(
          status: LobbyStatus.error,
          error: 'Failed to load teams: ${e.toString()}',
        ),
      );
      debugPrint('Error fetching teams: $e');
    }
  }

  // Helper function to sanitize team names for use in game names/IDs
  String _sanitizeTeamNameForId(String teamName) {
    return teamName.replaceAll(' ', '_').toLowerCase();
  }

  Future<void> createGame({
    required String homeTeamId,
    required String awayTeamId,
    required String homeTeamName, // Display name of home team
    required String awayTeamName, // Display name of away team
    String? customGameName,
  }) async {
    emit(state.copyWith(
        status: LobbyStatus.creatingGame,
        clearError: true,
        clearCreatedGameId: true,),);
    try {
      String finalGameName;

      if (customGameName != null && customGameName.trim().isNotEmpty) {
        finalGameName = customGameName.trim();
      } else {
        // Sanitize team names for the generated name
        final String sanitizedHomeTeamName =
            _sanitizeTeamNameForId(homeTeamName);
        final String sanitizedAwayTeamName =
            _sanitizeTeamNameForId(awayTeamName);

        // Query to count existing matchups
        // Matchup 1: homeTeamId vs awayTeamId
        final QuerySnapshot matchup1Snapshot = await _firestore
            .collection('games')
            .where('homeTeamId', isEqualTo: homeTeamId)
            .where('awayTeamId', isEqualTo: awayTeamId)
            .get();

        // Matchup 2: awayTeamId vs homeTeamId (teams swapped)
        final QuerySnapshot matchup2Snapshot = await _firestore
            .collection('games')
            .where('homeTeamId', isEqualTo: awayTeamId)
            .where('awayTeamId', isEqualTo: homeTeamId)
            .get();

        final int existingMatchups =
            matchup1Snapshot.docs.length + matchup2Snapshot.docs.length;
        final int gameNumber = existingMatchups + 1;

        finalGameName =
            '${sanitizedHomeTeamName}_vs_${sanitizedAwayTeamName}_game$gameNumber';
      }

      // Prepare game document based on your defined structure
      final newGameData = {
        'name': finalGameName, // Use the generated or custom name
        'gameType': 'basketball',
        'homeTeamId': homeTeamId,
        'awayTeamId': awayTeamId,
        'homeTeamScore': 0,
        'awayTeamScore': 0,
        'status': 'scheduled', // Initial status
        'scheduledTime': FieldValue.serverTimestamp(),
        'actualStartTime': null,
        'actualEndTime': null,
        'currentQuarter': 1,
        'location': '',
        'gameLogs': [],
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      final DocumentReference gameDocRef =
          _firestore.collection('games').doc(finalGameName);

      await gameDocRef.set(newGameData);

      emit(
        state.copyWith(
          status: LobbyStatus.gameCreated,
          createdGameId: finalGameName,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LobbyStatus.error,
          error: 'Failed to create game: ${e.toString()}',
        ),
      );
      debugPrint('Error creating game: $e');
    }
  }
}
