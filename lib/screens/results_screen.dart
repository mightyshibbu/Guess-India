import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:party_charades/models/deck.dart';
import 'package:party_charades/screens/deck_detail_screen.dart';
import 'package:party_charades/screens/home_screen.dart';
import 'results_screen_helpers.dart';
// _buildTeamResultColumn is imported at the top-level and used as a top-level function.

class ResultsScreen extends StatelessWidget {
  static const routeName = '/results';
  
  const ResultsScreen({super.key});

  void _shareResults(int score, int correctCount, int totalWords) {
    final text = 'I scored $score points in Party Charades! Got $correctCount out of $totalWords words correct. Can you beat my score?';
    Share.share(text, subject: 'My Party Charades Score');
  }
  
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
  
  Widget _buildWordResult(String word, bool isCorrect) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isCorrect ? Icons.check_circle : Icons.cancel,
          color: isCorrect ? Colors.green : Colors.red,
        ),
        title: Text(
          word,
          style: TextStyle(
            decoration: isCorrect ? null : TextDecoration.lineThrough,
          ),
        ),
        trailing: Text(
          isCorrect ? 'Correct' : 'Skipped',
          style: TextStyle(
            color: isCorrect ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isPortrait = screenSize.height > screenSize.width;
    
    // Get arguments from route
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final int score = args?['score'] ?? 0;
    final int correctCount = args?['correctCount'] ?? 0;
    final int skippedCount = args?['skippedCount'] ?? 0;
    final Map<String, bool> wordResults = Map<String, bool>.from(args?['wordResults'] ?? {});
    final Deck deck = args?['deck'] as Deck? ?? Deck(
      id: '0',
      title: 'Unknown Deck',
      description: 'No description',
      icon: Icons.help_outline,
      color: const Color(0xFF45B7D1),
    );
    final int teamNumber = args?['teamNumber'] ?? 1;
    final int? team1Score = args?['team1Score'] as int?;
    final int duration = args?['duration'] ?? 60;
    final String gameMode = args?['gameMode'] ?? 'single';
    final Map<String, bool>? team1WordResults = args?['team1WordResults'] != null ? Map<String, bool>.from(args?['team1WordResults']) : null;

    final totalWords = wordResults.length;
    const int scorePerWord = 10;
    final accuracy = totalWords > 0 ? (correctCount / totalWords * 100).toInt() : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareResults(score, correctCount, totalWords),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (gameMode == 'team' && teamNumber == 2 && team1WordResults != null)
              // Side-by-side results for Team A and Team B
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Team A
                  Expanded(
                    child: buildTeamResultColumn(
                      context,
                      'Team A',
                      team1Score ?? 0,
                      team1WordResults,
                      theme,
                      Colors.blue,
                    ),
                  ),
                  // Divider
                  Container(
                    width: 2,
                    height: 260,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: Colors.grey[400],
                  ),
                  // Team B
                  Expanded(
                    child: buildTeamResultColumn(
                      context,
                      'Team B',
                      score,
                      wordResults,
                      theme,
                      Colors.red,
                    ),
                  ),
                ],
              )
              else ...[
                // Team Info
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    gameMode == 'team'
                        ? (teamNumber == 1 ? 'Team A Results' : 'Team B Results')
                        : 'Results',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: gameMode == 'team'
                          ? (teamNumber == 1 ? Colors.blue : Colors.red)
                          : Colors.deepPurple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Score Summary
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Your Score',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$score',
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem(
                              'Correct',
                              '$correctCount',
                              Icons.check_circle,
                              Colors.green,
                            ),
                            _buildStatItem(
                              'Skipped',
                              '$skippedCount',
                              Icons.cancel,
                              Colors.orange,
                            ),
                            _buildStatItem(
                              'Accuracy',
                              '$accuracy%',
                              Icons.percent,
                              Colors.blue,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Word Results
                Text(
                  'Word Results',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...wordResults.entries.map((entry) => _buildWordResult(entry.key, entry.value)),
              ],
              const SizedBox(height: 24),
              if (gameMode == 'team' && teamNumber == 1)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                            context,
                            '/game',
                            arguments: {
                              'deck': deck,
                              'duration': duration,
                              'teamNumber': 2,
                              'gameMode': gameMode,
                              'team1Score': score,
                              'team1WordResults': wordResults,
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Start Team B Game'),
                      ),
                    ),
                  ],
                )
              else if (gameMode == 'team' && teamNumber == 2 && team1WordResults != null)
                const SizedBox.shrink() // No action buttons after both teams played
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                            context,
                            DeckDetailScreen.routeName,
                            arguments: {'deck': deck},
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: theme.primaryColor),
                        ),
                        child: Text(
                          'Play Again',
                          style: TextStyle(color: theme.primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/home',
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Home'),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
                