import 'package:flutter/material.dart';
import 'package:party_charades/models/deck.dart';
import 'package:party_charades/screens/game_screen.dart';

class DeckDetailScreen extends StatefulWidget {
  static const routeName = '/deck-detail';
  
  const DeckDetailScreen({super.key});

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> with SingleTickerProviderStateMixin {
  int _selectedDuration = 60; // Default duration in seconds
  late Deck _deck;
  final List<int> _durationOptions = [30, 45, 60, 90, 120];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );
    
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuart,
      ),
    );
    
    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Extract deck from route arguments
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && args['deck'] != null) {
      _deck = args['deck'] as Deck;
    } else if (args is Deck) {
      _deck = args;
    } else {
      // Fallback to a default deck if none provided
      _deck = Deck(
        id: '0',
        title: 'Default',
        description: 'Default deck',
        icon: Icons.category,
        color: const Color(0xFF45B7D1),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _startGame() {
    if (!mounted) return;
    
    Navigator.pushNamed(
      context,
      GameScreen.routeName,
      arguments: {
        'deck': _deck,
        'duration': _selectedDuration,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isPortrait = screenSize.height > screenSize.width;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deck Details'),
        elevation: 0,
      ),
      body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200.0,
              pinned: true,
              backgroundColor: _deck.color.withOpacity(0.1),
              elevation: 0,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.black87),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  _deck.title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _deck.color.withOpacity(0.1),
                        _deck.color.withOpacity(0.3),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _deck.icon,
                      size: 80,
                      color: _deck.color,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value * (1 - _animationController.value)),
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Deck Info Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _deck.color.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _deck.icon,
                                      size: 32,
                                      color: _deck.color,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _deck.title,
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_deck.words.length} words',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _deck.description,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Duration Selector
                    Text(
                      'Game Duration',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDurationSelector(),
                    
                    const SizedBox(height: 40),
                    
                    // Start Game Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _startGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _deck.color,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Start Game',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDurationSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _durationOptions.map((duration) {
          final isSelected = duration == _selectedDuration;
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ChoiceChip(
              label: Text(
                '$duration\nsec',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedDuration = duration;
                  });
                }
              },
              backgroundColor: Colors.grey[200],
              selectedColor: _deck.color,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: isSelected ? 2 : 0,
            ),
          );
        }).toList(),
      ),
    );
  }
}
