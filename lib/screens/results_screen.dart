import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:party_charades/models/deck.dart';
import 'package:party_charades/screens/deck_detail_screen.dart';
import 'package:party_charades/screens/home_screen.dart';

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
              
              const SizedBox(height: 24),
              
              // Action Buttons
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
                          HomeScreen.routeName,
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: theme.primaryColor,
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
                