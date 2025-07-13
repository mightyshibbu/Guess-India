import 'package:flutter/material.dart';
import 'package:party_charades/models/deck.dart';
import 'package:party_charades/screens/settings_screen.dart';
import 'package:party_charades/screens/deck_detail_screen.dart';

import 'dart:convert';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Deck> decks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDecks();
  }

  Future<void> _loadDecks() async {
    final String wordsJson = await rootBundle.loadString('assets/words.json');
    final Map<String, dynamic> wordsData = json.decode(wordsJson);

    setState(() {
      decks = [
        Deck(
          id: '1',
          title: 'Movies',
          description: 'Guess famous movie titles',
          icon: Icons.movie,
          color: const Color(0xFFFF6B6B),
          words: List<String>.from(wordsData['movies'] ?? []),
        ),
        Deck(
          id: '2',
          title: 'Animals',
          description: 'All creatures great and small',
          icon: Icons.pets,
          color: const Color(0xFF4ECDC4),
          words: List<String>.from(wordsData['animals'] ?? []),
        ),
        Deck(
          id: '3',
          title: 'Actions',
          description: 'Act it out!',
          icon: Icons.directions_run,
          color: const Color(0xFF45B7D1),
          words: List<String>.from(wordsData['action'] ?? []),
        ),
        Deck(
          id: '4',
          title: 'Food',
          description: 'Yummy treats and dishes',
          icon: Icons.restaurant,
          color: const Color(0xFF96CEB4),
          words: List<String>.from(wordsData['food'] ?? []),
        ),
        Deck(
          id: '5',
          title: 'Professions',
          description: 'Guess the job titles',
          icon: Icons.work,
          color: const Color(0xFFFFEEAD),
          words: List<String>.from(wordsData['profession'] ?? []),
        ),
        Deck(
          id: '6',
          title: 'Sports',
          description: 'Athletic activities',
          icon: Icons.sports_soccer,
          color: const Color(0xFFFFD166),
          words: List<String>.from(wordsData['sports'] ?? []),
        ),
        Deck(
          id: '7',
          title: 'Science',
          description: 'Scientific terms and discoveries',
          icon: Icons.science,
          color: const Color(0xFF8E44AD),
          words: List<String>.from(wordsData['sciences'] ?? []),
        ),
        Deck(
          id: '8',
          title: 'Geography',
          description: 'Countries, capitals, and landmarks',
          icon: Icons.public,
          color: const Color(0xFF3498DB),
          words: List<String>.from(wordsData['geography'] ?? []),
        ),
        Deck(
          id: '9',
          title: 'Music',
          description: 'Songs, artists, and instruments',
          icon: Icons.music_note,
          color: const Color(0xFF2ECC71),
          words: List<String>.from(wordsData['music'] ?? []),
        ),
        Deck(
          id: '10',
          title: 'History',
          description: 'Historical events and figures',
          icon: Icons.history_edu,
          color: const Color(0xFFE67E22),
          words: List<String>.from(wordsData['history'] ?? []),
        ),
      ];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isPortrait = screenSize.height > screenSize.width;
    final crossAxisCount = isPortrait ? 2 : 3;
    final aspectRatio = isPortrait ? 1.2 : 1.5;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                  padding: const EdgeInsets.only(bottom: 8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: aspectRatio,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: decks.length,
                  itemBuilder: (context, index) {
                    final deck = decks[index];
                    return _buildDeckCard(deck, context);
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Bottom Button Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _HomeBottomButton(label: 'VIP', icon: Icons.star, onTap: () {}),
                  _HomeBottomButton(label: 'DECK', icon: Icons.layers, onTap: () {}),
                  _HomeBottomButton(label: 'CUSTOM', icon: Icons.edit, onTap: () {}),
                ],
              ),
              const SizedBox(height: 12),
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
        child: SizedBox(
          height: 150,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: deck.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: deck.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    deck.icon,
                    size: 28,
                    color: deck.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  deck.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${deck.words.length} words',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _HomeBottomButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _HomeBottomButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          splashColor: Theme.of(context).primaryColor.withOpacity(0.2),
          highlightColor: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.black87, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
