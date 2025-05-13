import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp type
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting, add intl: ^0.19.0 to pubspec.yaml

// Assuming your Player model is accessible, e.g., from a common models file.
// If not, you might need to pass more detailed player info or adjust.
// For this example, we'll assume the log structure has player names embedded.

class PlayByPlayWidget extends StatelessWidget {

  const PlayByPlayWidget({
    required this.gameLogs, required this.homeTeamName, required this.awayTeamName, required this.homeTeamId, required this.awayTeamId, super.key,
  });
  final List<Map<String, dynamic>> gameLogs;
  final String homeTeamName; // To display team context for timeouts etc.
  final String awayTeamName; // To display team context for timeouts etc.
  final String homeTeamId;
  final String awayTeamId;

  String _formatTimestamp(dynamic timestampData) {
    if (timestampData == null) return 'N/A';
    Timestamp timestamp;
    if (timestampData is Timestamp) {
      timestamp = timestampData;
    } else if (timestampData is String) {
      try {
        DateTime dt = DateTime.parse(timestampData);
        return DateFormat('HH:mm:ss').format(dt.toLocal());
      } catch (e) {
        return 'Invalid Time';
      }
    } else {
      return 'Unknown Time';
    }
    return DateFormat('HH:mm:ss').format(timestamp.toDate().toLocal());
  }

  Widget _buildLogEntry(BuildContext context, Map<String, dynamic> log) {
    final String actionType = log['actionType'] as String? ?? 'UNKNOWN_ACTION';
    final Map<String, dynamic> playerMap =
        log['player'] as Map<String, dynamic>? ?? {};
    final String playerName =
        playerMap['playerName'] as String? ?? 'Unknown Player';
    final String playerJersey = playerMap['jerseyNumber'] as String? ?? '';
    final String playerDisplayName =
        playerJersey.isNotEmpty ? '$playerName (#$playerJersey)' : playerName;

    final Map<String, dynamic> details =
        log['details'] as Map<String, dynamic>? ?? {};
    final int points = log['points'] as int? ?? 0;
    final String gameTime = log['gameTime'] as String? ?? '--:--';

    // --- Robust Quarter Parsing ---
    int quarter = 0; // Default value
    final dynamic quarterData = log['quarter'];
    if (quarterData is int) {
      quarter = quarterData;
    } else if (quarterData is String) {
      // Attempt to parse string, removing non-digit characters like "Q", "OT"
      quarter =
          int.tryParse(quarterData.replaceAll(RegExp('[^0-9]'), '')) ?? 0;
    }
    // --- End of Robust Quarter Parsing ---

    final String timestampStr = _formatTimestamp(log['timestamp']);
    final String logTeamId = log['teamId'] as String? ?? '';

    String teamNameForLog = '';
    if (logTeamId == homeTeamId) {
      teamNameForLog = homeTeamName;
    } else if (logTeamId == awayTeamId) {
      teamNameForLog = awayTeamName;
    }

    String description = '';

    switch (actionType) {
      case 'QUARTER_START':
        description = quarter > 4
            ? 'Overtime ${quarter - 4} started.'
            : 'Quarter $quarter started.';
      case 'QUARTER_END':
        description = quarter > 4
            ? 'End of Overtime ${quarter - 4}.'
            : 'End of Quarter $quarter.';
      case 'GAME_START':
        description = 'Game Started.';
      case 'GAME_END':
        description = 'Game Ended.';
      case 'FIELD_GOAL_MADE':
        final String shotType = details['shotType'] as String? ?? 'shot';
        description = '$playerDisplayName made a $points-point $shotType.';
        if (details['isAssist'] == true && details['assistingPlayer'] != null) {
          final assistingPlayerMap =
              details['assistingPlayer'] as Map<String, dynamic>;
          final String assistingPlayerName =
              assistingPlayerMap['playerName'] as String? ?? 'N/A';
          description += ' Assist by $assistingPlayerName.';
        }
      case 'FIELD_GOAL_MISSED':
        final String shotType = details['shotType'] as String? ?? 'shot';
        description = '$playerDisplayName missed a $shotType.';
        if (details['isBlock'] == true && details['blockingPlayer'] != null) {
          final blockingPlayerMap =
              details['blockingPlayer'] as Map<String, dynamic>;
          final String blockingPlayerName =
              blockingPlayerMap['playerName'] as String? ?? 'N/A';
          description += ' Blocked by $blockingPlayerName.';
        }
      case 'FREE_THROW_ATTEMPT':
        final bool isMade = details['isMade'] as bool? ?? false;
        final int attemptNum = details['attemptNumber'] as int? ?? 1;
        final int totalAttempts = details['totalAttempts'] as int? ?? 1;
        description =
            '$playerDisplayName ${isMade ? "made" : "missed"} free throw ($attemptNum of $totalAttempts).';
      case 'FOUL_COMMITTED':
        final String foulType = details['foulType'] as String? ?? 'foul';
        description = '$playerDisplayName committed a $foulType foul.';
        if (details['fouledPlayer'] != null) {
          final fouledPlayerMap =
              details['fouledPlayer'] as Map<String, dynamic>;
          final String fouledPlayerName =
              fouledPlayerMap['playerName'] as String? ?? 'N/A';
          description += ' On $fouledPlayerName.';
        }
        if (details['isShootingFoul'] == true &&
            details['ftsAwarded'] != null) {
          description += ' ${details['ftsAwarded']} FTs awarded.';
        }
      case 'TURNOVER':
        final String turnoverType =
            details['turnoverType'] as String? ?? 'turnover';
        description = '$playerDisplayName: $turnoverType.';
        if (details['stolenByPlayer'] != null) {
          final stolenByMap = details['stolenByPlayer'] as Map<String, dynamic>;
          final String stolenByName =
              stolenByMap['playerName'] as String? ?? 'N/A';
          description += ' Stolen by $stolenByName.';
        }
      case 'REBOUND':
        final String reboundType = details['reboundType'] as String? ?? '';
        description = '$playerDisplayName: $reboundType Rebound.';
      case 'SUBSTITUTION_IN':
        final playerEnteringMap =
            details['playerEntering'] as Map<String, dynamic>? ?? playerMap;
        final playerLeavingMap =
            details['playerLeaving'] as Map<String, dynamic>?;
        final String enteringName =
            playerEnteringMap['playerName'] as String? ?? 'N/A';
        if (playerLeavingMap != null) {
          final String leavingName =
              playerLeavingMap['playerName'] as String? ?? 'N/A';
          description =
              '$enteringName enters for $leavingName ($teamNameForLog).';
        } else {
          description = '$enteringName enters the game ($teamNameForLog).';
        }
      case 'SUBSTITUTION_OUT':
        final playerLeavingMap =
            details['playerLeaving'] as Map<String, dynamic>? ?? playerMap;
        final playerEnteringMap =
            details['playerEntering'] as Map<String, dynamic>?;
        final String leavingName =
            playerLeavingMap['playerName'] as String? ?? 'N/A';
        if (playerEnteringMap != null) {
          final String enteringName =
              playerEnteringMap['playerName'] as String? ?? 'N/A';
          description =
              '$leavingName leaves, $enteringName enters ($teamNameForLog).';
        } else {
          description = '$leavingName leaves the game ($teamNameForLog).';
        }
      case 'TIMEOUT_CALLED':
        final String timeoutType =
            details['timeoutType'] as String? ?? 'timeout';
        description = '$timeoutType called by $teamNameForLog.';
      default:
        description = 'Unknown action: $actionType for $playerDisplayName';
    }

    String quarterText = '';
    if (quarter > 0 && quarter <= 4) {
      quarterText = 'Q$quarter';
    } else if (quarter > 4) {
      quarterText = 'OT${quarter - 4}';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: ListTile(
        dense: true,
        leading: SizedBox(
          width: 60, // Adjust width as needed
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(gameTime,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.bold),),
              if (quarterText.isNotEmpty)
                Text(quarterText, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        title: Text(description),
        subtitle: Text('Actual time: $timestampStr',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey.shade600),),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (gameLogs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No game events logged yet.',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),),
        ),
      );
    }

    final List<Map<String, dynamic>> reversedLogs =
        List.from(gameLogs.reversed);

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: reversedLogs.length,
      itemBuilder: (context, index) {
        return _buildLogEntry(context, reversedLogs[index]);
      },
    );
  }
}
