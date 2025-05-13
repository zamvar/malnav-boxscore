// Assuming your Team and Player models/helper classes are defined.
// If not, we can define simple ones here or import them.

// Simplified Player model for display in roster
class Player {
  Player({
    required this.id,
    required this.name,
    required this.jerseyNumber,
    required this.teamId,
  });

  // Factory constructor to create a Player instance from a map
  factory Player.fromMap(Map<String, dynamic> map, String documentId) {
    return Player(
      id: map['playerId'] as String? ??
          '', // Use documentId passed to the factory, or map['id'] if preferred
      name: map['playerName'] as String? ??
          map['name'] as String? ??
          'Unknown Player', // Check for both playerName and name
      jerseyNumber: map['jerseyNumber'] as String? ?? '--',
      teamId: documentId,
    );
  }

  factory Player.fromPlayerMapInTeam(
      Map<String, dynamic> map, String defaultTeamId,) {
    return Player(
      id: map['playerId'] as String? ?? 'unknown_player_id',
      name: map['playerName'] as String? ?? 'Unknown Player',
      jerseyNumber: map['jerseyNumber'] as String? ?? '--',
      teamId: map['teamId'] as String? ??
          defaultTeamId, // Use defaultTeamId if not in map
    );
  }
  final String id;
  final String name;
  final String jerseyNumber;
  String teamId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Player && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return '$name (#$jerseyNumber)';
  }
}
