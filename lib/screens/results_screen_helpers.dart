import 'package:flutter/material.dart';

Widget buildTeamResultColumn(
  BuildContext context,
  String teamLabel,
  int score,
  Map<String, bool> wordResults,
  ThemeData theme,
  Color color,
) {
  final correctWords = wordResults.entries.where((e) => e.value).map((e) => e.key).toList();
  final wrongWords = wordResults.entries.where((e) => !e.value).map((e) => e.key).toList();
  final accuracy = wordResults.isNotEmpty ? (correctWords.length / wordResults.length * 100).toInt() : 0;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        teamLabel,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            children: [
              Text(
                'Score: $score',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text('Accuracy: $accuracy%', style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
      const SizedBox(height: 10),
      Text('Correct:', style: theme.textTheme.labelLarge?.copyWith(color: Colors.green)),
      ...correctWords.map((word) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            const Icon(Icons.check, color: Colors.green, size: 18),
            const SizedBox(width: 6),
            Expanded(child: Text(word, style: theme.textTheme.bodyMedium)),
          ],
        ),
      )),
      const SizedBox(height: 6),
      Text('Skipped:', style: theme.textTheme.labelLarge?.copyWith(color: Colors.orange)),
      ...wrongWords.map((word) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            const Icon(Icons.cancel, color: Colors.orange, size: 18),
            const SizedBox(width: 6),
            Expanded(child: Text(word, style: theme.textTheme.bodyMedium)),
          ],
        ),
      )),
    ],
  );
}
