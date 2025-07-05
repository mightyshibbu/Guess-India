import 'package:flutter/material.dart';
import 'package:party_charades/models/deck.dart';
import 'package:party_charades/screens/settings_screen.dart';
import 'package:party_charades/screens/deck_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  static const routeName = '/home';
  
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isPortrait = screenSize.height > screenSize.width;
    final crossAxisCount = isPortrait ? 2 : 3;
    final aspectRatio = isPortrait ? 1.2 : 1.5;

    final List<Deck> decks = [
      Deck(
        id: '1',
        title: 'Movies',
        description: 'Guess famous movie titles',
        icon: Icons.movie,
        color: const Color(0xFFFF6B6B),
      ),
      Deck(
        id: '2',
        title: 'Animals',
        description: 'All creatures great and small',
        icon: Icons.pets,
        color: const Color(0xFF4ECDC4),
      ),
      Deck(
        id: '3',
        title: 'Actions',
        description: 'Act it out!',
        icon: Icons.directions_run,
        color: const Color(0xFF45B7D1),
      ),
      Deck(
        id: '4',
        title: 'Food',
        description: 'Yummy treats and dishes',
        icon: Icons.restaurant,
        color: const Color(0xFF96CEB4),
      ),
      Deck(
        id: '5',
        title: 'Professions',
        description: 'Guess the job titles',
        icon: Icons.work,
        color: const Color(0xFFFFEEAD),
      ),
      Deck(
        id: '6',
        title: 'Sports',
        description: 'Athletic activities',
        icon: Icons.sports_soccer,
        color: const Color(0xFFFFD166),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Party Charades',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black87),
            onPressed: () {
              Navigator.pushNamed(context, SettingsScreen.routeName);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose a category',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select a deck to start playing',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: aspectRatio,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: decks.length,
                  itemBuilder: (context, index) {
                    final deck = decks[index];
                    return _buildDeckCard(deck, context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeckCard(Deck deck, BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pushNamed(
            context,
            DeckDetailScreen.routeName,
            arguments: {'deck': deck},
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: deck.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: deck.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  deck.icon,
                  size: 32,
                  color: deck.color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                deck.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${deck.words.length} words',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
