import 'package:flutter/material.dart';

// Assuming your GameScoreboardState is defined elsewhere and provides these fields.
// For this standalone widget, we'll define them as direct parameters.
class ScoreboardCenterDisplay extends StatelessWidget {
  final String homeTeamName;
  final String awayTeamName;
  final int homeScore;
  final int awayScore;
  final String gameStatusDisplay;
  final String gameClock;
  final String? homeTeamLogoUrl; // Added for logo
  final String? awayTeamLogoUrl; // Added for logo

  const ScoreboardCenterDisplay({
    super.key,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeScore,
    required this.awayScore,
    required this.gameStatusDisplay,
    required this.gameClock,
    this.homeTeamLogoUrl,
    this.awayTeamLogoUrl,
  });

  Widget _buildScoreWithLogo(
      BuildContext context, int score, String? logoUrl, IconData defaultIcon) {
    final ThemeData theme = Theme.of(context);
    return Expanded(
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          if (logoUrl != null && logoUrl.isNotEmpty)
            Positioned.fill(
              child: Opacity(
                opacity: 0.08,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.network(
                    logoUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (BuildContext context, Widget child,
                        ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print("Error loading logo: $logoUrl, Error: $error");
                      return Icon(defaultIcon,
                          size: 60,
                          color: Colors.grey.shade700.withOpacity(0.5));
                    },
                  ),
                ),
              ),
            )
          else
            Positioned.fill(
              child: Opacity(
                opacity: 0.08,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.network(
                      'https://png.pngtree.com/png-clipart/20230527/original/pngtree-basketball-logo-png-image_9171255.png',
                      height: 120,
                    ),
                  ),
                ),
              ),
            ),
          Text(
            '$score',
            textAlign: TextAlign.center,
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: Text(
                  homeTeamName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  awayTeamName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildScoreWithLogo(
                    context, homeScore, homeTeamLogoUrl, Icons.shield_outlined),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('-',
                      style: theme.textTheme.displaySmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                _buildScoreWithLogo(context, awayScore, awayTeamLogoUrl,
                    Icons.sports_kabaddi_outlined),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(gameStatusDisplay, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          if (!gameStatusDisplay.contains(gameClock) &&
              (gameStatusDisplay.startsWith("Q") ||
                  gameStatusDisplay.startsWith("OT")))
            Text(gameClock, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
