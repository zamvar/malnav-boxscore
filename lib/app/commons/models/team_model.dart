// Simplified Team model for fetching and display
import 'package:score_board/app/commons/models/player_model.dart';

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
