import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:party_charades/models/deck.dart';
import 'package:party_charades/screens/results_screen.dart';

class GameScreen extends StatefulWidget {
  static const routeName = '/game';
  
  const GameScreen({super.key});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  // Game state
  late final Deck _deck;
  late final int _duration;
  final List<String> _words = [];
  String _currentWord = '';
  int _score = 0;
  int _correctCount = 0;
  int _skippedCount = 0;
  final List<String> _remainingWords = [];
  
  // Game timing
  late Timer _gameTimer;
  late Timer _countdownTimer;
  int _timeRemaining = 0;
  
  // Game status
  bool _isGameStarted = false;
  bool _isGameOver = false;
  bool _isCountdown = false;
  int _countdownValue = 3;
  
  // Tilt feedback state
  bool _isTiltedUp = false;
  bool _isTiltedDown = false;
  DateTime? _lastTiltTime;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  
  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSoundOn = true;
  
  // Results
  final Map<String, bool> _wordResults = {}; // word -> isCorrect
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeGame();
  }
  
  @override
  void dispose() {
    _gameTimer.cancel();
    _countdownTimer.cancel();
    _accelerometerSubscription?.cancel();
    _audioPlayer.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  void _initializeGame() {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _deck = args['deck'] as Deck;
    _duration = args['duration'] as int;
    _timeRemaining = _duration;
    _words.addAll(_deck.words);
    _remainingWords.addAll(_deck.words);
    _startCountdown();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // No need to reinitialize here as we're already doing it in initState
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pauseGame();
    } else if (state == AppLifecycleState.resumed) {
      _resumeGame();
    }
  }

  void _initGame() {
    _startCountdown();
    _setupSensors();
  }

  void _startCountdown() {
    setState(() {
      _isCountdown = true;
      _countdownValue = 3;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownValue > 1) {
        setState(() {
          _countdownValue--;
        });
      } else {
        _countdownTimer.cancel();
        _startGame();
      }
    });
  }

  void _startGame() {
    setState(() {
      _isCountdown = false;
      _isGameStarted = true;
      _isGameOver = false;
      _timeRemaining = _duration;
      _score = 0;
      _correctCount = 0;
      _skippedCount = 0;
      _wordResults.clear();
      _remainingWords.clear();
      _remainingWords.addAll(_deck.words..shuffle());
      _nextWord();
    });

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
      } else {
        _endGame();
      }
    });

    // Start listening to accelerometer
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      _onAccelerometerEvent(event);
    });
  }

  void _setupSensors() {
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      _onAccelerometerEvent(event);
    });
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    // Simple tilt detection using Z-axis (when holding phone to forehead)
    // Z axis: -10 (flat) to 10 (upside down)
    // We'll consider tilt up when Z < -5 and tilt down when Z > 5
    if (!_isGameStarted || _isCountdown || _isGameOver) return;
    
    final double z = event.z;
    final now = DateTime.now();
    
    // Debounce to prevent multiple rapid triggers
    if (_lastTiltTime != null && now.difference(_lastTiltTime!) < const Duration(milliseconds: 500)) {
      return;
    }
    
    if (z < -5) {
      // Tilt up - Correct
      setState(() {
        _isTiltedUp = true;
        _isTiltedDown = false;
      });
      _onCorrect();
      _lastTiltTime = now;
      
      // Reset tilt feedback after animation
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _isTiltedUp = false;
          });
        }
      });
    } else if (z > 5) {
      // Tilt down - Skip
      setState(() {
        _isTiltedDown = true;
        _isTiltedUp = false;
      });
      _onSkip();
      _lastTiltTime = now;
      
      // Reset tilt feedback after animation
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _isTiltedDown = false;
          });
        }
      });
    } else {
      // Reset tilt state when device is level
      if (_isTiltedUp || _isTiltedDown) {
        setState(() {
          _isTiltedUp = false;
          _isTiltedDown = false;
        });
      }
    }
  }

  Future<void> _playSound(String sound) async {
    if (!_isSoundOn) return;
    
    try {
      await _audioPlayer.play(AssetSource('sounds/$sound.mp3'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  void _onCorrect() {
    _playSound('correct');
    setState(() {
      _score += 10;
      _correctCount++;
      _wordResults[_currentWord] = true;
    });
    _nextWord();
  }

  void _onSkip() {
    _playSound('skip');
    setState(() {
      _skippedCount++;
    });
    _nextWord();
  }

  void _nextWord() {
    if (_remainingWords.isNotEmpty) {
      _currentWord = _remainingWords.removeLast();
      _wordResults[_currentWord] = false;
    } else {
      _endGame();
    }
  }

  void _endGame() {
    _gameTimer.cancel();
    setState(() {
      _isGameOver = true;
      _isGameStarted = false;
    });
    
    // Navigate to results screen after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        ResultsScreen.routeName,
        arguments: {
          'score': _score,
          'correctCount': _correctCount,
          'skippedCount': _skippedCount,
          'wordResults': _wordResults,
          'deck': _deck,
        },
      );
    });
  }

  void _pauseGame() {
    if (_isGameStarted && !_isGameOver) {
      _gameTimer.cancel();
    }
  }

  void _resumeGame() {
    if (_isGameStarted && !_isGameOver) {
      _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        
        setState(() {
          if (_timeRemaining > 0) {
            _timeRemaining--;
          } else {
            _endGame();
          }
        });
      });
    }
  }

  // end of _resumeGame

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isPortrait = screenSize.height > screenSize.width;
    
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Party Charades'),
          actions: [
            if (_isGameStarted && !_isCountdown)
              IconButton(
                icon: const Icon(Icons.pause),
                onPressed: _pauseGame,
              ),
            IconButton(
              icon: Icon(_isSoundOn ? Icons.volume_up : Icons.volume_off),
              onPressed: () {
                setState(() {
                  _isSoundOn = !_isSoundOn;
                });
              },
            ),
          ],
        ),
        body: SafeArea(
          child: _buildGameContent(),
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_isGameStarted && !_isGameOver) {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Exit Game?'),
          content: const Text('Are you sure you want to exit the game? Your progress will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Exit'),
            ),
          ],
        ),
      );
      return shouldExit ?? false;
    }
    return true;
  }

  Widget _buildGameContent() {
    if (_isCountdown) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Starting in',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(
                scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.elasticOut,
                  ),
                ),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: Container(
              key: ValueKey<int>(_countdownValue),
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF45B7D1).withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF45B7D1),
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  '$_countdownValue',
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF45B7D1),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Get ready to act!',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else if (_isGameOver) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Game Over!',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF45B7D1),
            ),
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF45B7D1)),
            strokeWidth: 2,
          ),
          const SizedBox(height: 24),
          const Text(
            'Calculating results...',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Back to Home',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    } else if (!_isGameStarted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'The word is...',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Text(
                _currentWord,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: _currentWord.length > 12 ? 32 : 48,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                  letterSpacing: 0.5,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
      );
    } else {
      return Column(
        children: [
          // Score and timer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Score: $_score',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Time: $_timeRemaining',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _timeRemaining <= 10 ? Colors.red : null,
                  ),
                ),
              ],
            ),
          ),
          
          // Current word
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  _currentWord,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          
          // Instructions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Tilt device up for correct, down to skip',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          
          // Tilt indicators
          Padding(
            padding: const EdgeInsets.only(bottom: 32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTiltIndicator('↑ Correct', _isTiltedUp),
                const SizedBox(width: 32),
                _buildTiltIndicator('↓ Skip', _isTiltedDown),
              ],
            ),
          ),
        ],
      );
    }
  }
  // Build a tilt indicator widget
  Widget _buildTiltIndicator(String label, bool isActive) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? Colors.blue[100] : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Text(
            label.split(' ')[0],
            style: TextStyle(
              fontSize: 24,
              color: isActive ? Colors.blue[800] : Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.split(' ')[1],
          style: TextStyle(
            color: isActive ? Colors.blue[800] : Colors.grey[600],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  // duplicate _buildGameContent removed
  Future<void> _showExitConfirmation() async {
    if (!_isGameStarted || _isGameOver) {
      Navigator.pop(context);
      return;
    }
    
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Game?'),
        content: const Text('Are you sure you want to exit the current game? Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Exit'),
          ),
        ],
      ),
    ) ?? false;
    
    if (shouldExit && mounted) {
      Navigator.pop(context);
    }
  }
}
