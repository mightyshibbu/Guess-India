import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:party_charades/models/deck.dart';
import 'package:party_charades/screens/results_screen.dart';

class GameScreen extends StatefulWidget {
  static const routeName = '/game';
  
  const GameScreen({super.key});

  @override
  _GameScreenState createState() => _GameScreenState();
}

enum TiltState { idle, up, down }

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  String _gameMode = 'single'; // 'single' or 'team'
  // Dedicated player for last_seconds sound
  final AudioPlayer _lastSecondsPlayer = AudioPlayer();
  bool _isLastSecondsPlaying = false;
  DateTime _lastTiltTime = DateTime.fromMillisecondsSinceEpoch(0);
  // --- Hysteresis thresholds (angles in g, assuming -10 to 10 is -90° to 90°) ---
  // These are now computed using _tiltSensitivity for easier tuning
  double get _tiltThreshold {
    const double minThreshold = 1.0; // most sensitive
    const double maxThreshold = 8.0; // least sensitive
    return maxThreshold - ((_tiltSensitivity - 1) / 9) * (maxThreshold - minThreshold);
  }

  double get CORRECT_ENGAGE => -_tiltThreshold;
  double get CORRECT_DISENGAGE => -(_tiltThreshold - 2.0); // Require much closer to neutral before re-engage (tighter hysteresis)

  double get SKIP_ENGAGE => _tiltThreshold;
  double get SKIP_DISENGAGE => _tiltThreshold - 2.0; // Require back to near-neutral before re-engage

  // Hysteresis engagement flags
  bool _isCorrectEngaged = false;
  bool _isSkipEngaged = false;
  TiltState _tiltState = TiltState.idle;
  // Sensitivity for tilt detection (default, can be customized)
  double _tiltSensitivity = 9.8; // Default for 90° tilt, can be customized
  // For color flash effect
  Color? _flashColor;
  Timer? _flashTimer;
  // Guard for late init
  bool _gameInitialized = false;
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

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  
  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSoundOn = true;
  
  // Results
  final Map<String, bool> _wordResults = {}; // word -> isCorrect
  // Prevent repeated scoring for the same word
  bool _hasScoredThisWord = false;

  // Team number for multiplayer mode
  int _teamNumber = 1;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // _initializeGame(); // Removed from here, will be called in didChangeDependencies
  }
  
  @override
  void dispose() {
    _gameTimer.cancel();
    _countdownTimer.cancel();
    _accelerometerSubscription?.cancel();
    _audioPlayer.dispose();
    _lastSecondsPlayer.dispose();
    WidgetsBinding.instance.removeObserver(this);
    // Restore orientation to system default
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _flashTimer?.cancel();
    super.dispose();
  }
  
  void _initializeGame() {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _deck = args['deck'] as Deck;
    _duration = args['duration'] as int;
    _teamNumber = args['teamNumber'] ?? 1;
    _gameMode = args['gameMode'] ?? 'single';
    _timeRemaining = _duration;
    _words.addAll(_deck.words);
    _remainingWords.addAll(_deck.words);
    _startCountdown();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Lock orientation to landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Load sensitivity from SharedPreferences
    _loadSensitivity();
    // Only initialize game once
    if (!_gameInitialized) {
      _initializeGame();
      _gameInitialized = true;
    }
  }

  Future<void> _loadSensitivity() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tiltSensitivity = prefs.getDouble('tilt_sensitivity') ?? 9.8;
    });
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
      _isLastSecondsPlaying = false;
      _lastSecondsPlayer.stop();
    });

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
        // Play last_seconds.mp3 when time is 10 or less and not already playing
        if (_timeRemaining <= 10 && _timeRemaining > 0 && !_isLastSecondsPlaying) {
          _isLastSecondsPlaying = true;
          try {
            await _lastSecondsPlayer.setReleaseMode(ReleaseMode.loop);
            await _lastSecondsPlayer.play(AssetSource('sounds/last_seconds.mp3'));
          } catch (e) {
  
          }
        } else if ((_timeRemaining > 10 || _timeRemaining == 0) && _isLastSecondsPlaying) {
          // Stop if time is above 10 or timer ended
          _isLastSecondsPlaying = false;
          await _lastSecondsPlayer.stop();
        }
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
    if (!_isGameStarted || _isCountdown || _isGameOver) return;

    final double z = event.z;
    final now = DateTime.now();

    // --- Correct (tilt up) logic ---
    if (!_isCorrectEngaged && z < CORRECT_ENGAGE && !_hasScoredThisWord) {
      // Engage correct only if not already engaged, not already scored for this word, and after cooldown
      if (now.difference(_lastTiltTime).inMilliseconds >= 1000) {
        debugPrint('[CORRECT] z before: ' + z.toStringAsFixed(2));
        setState(() {
          _tiltState = TiltState.up;
          _isTiltedUp = true;
          _isTiltedDown = false;
          _isCorrectEngaged = true;
          _hasScoredThisWord = true;
        });
        _onCorrect();
        debugPrint('[CORRECT] z after: ' + z.toStringAsFixed(2));
        _lastTiltTime = now;
        _flashBackground(Colors.greenAccent);
        Vibration.hasVibrator().then((hasVibrator) {
          if (hasVibrator ?? false) {
            Vibration.vibrate(duration: 100);
          }
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _isTiltedUp = false;
            });
          }
        });
      }
    } else if (_isCorrectEngaged && z > CORRECT_DISENGAGE) {
      // Disengage correct (require back to near-neutral)
      setState(() {
        _isCorrectEngaged = false;
        if (!_isSkipEngaged) {
          _tiltState = TiltState.idle;
          _isTiltedUp = false;
          _isTiltedDown = false;
        }
      });
    }

    // --- Skip (tilt down) logic ---
    if (!_isSkipEngaged && z > SKIP_ENGAGE) {
      // Engage skip only if not already engaged and after cooldown
      if (now.difference(_lastTiltTime).inMilliseconds >= 1000) {
        debugPrint('[SKIP] z before: ' + z.toStringAsFixed(2));
        setState(() {
          _tiltState = TiltState.down;
          _isTiltedDown = true;
          _isTiltedUp = false;
          _isSkipEngaged = true;
        });
        _onSkip();
        debugPrint('[SKIP] z after: ' + z.toStringAsFixed(2));
        _lastTiltTime = now;
        _flashBackground(Colors.orangeAccent);
        Vibration.hasVibrator().then((hasVibrator) {
          if (hasVibrator ?? false) {
            Vibration.vibrate(duration: 100);
          }
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _isTiltedDown = false;
            });
          }
        });
      }
    } else if (_isSkipEngaged && z < SKIP_DISENGAGE) {
      // Disengage skip (require back to near-neutral)
      setState(() {
        _isSkipEngaged = false;
        if (!_isCorrectEngaged) {
          _tiltState = TiltState.idle;
          _isTiltedUp = false;
          _isTiltedDown = false;
        }
      });
    }
  }


  void _flashBackground(Color color) {
    setState(() {
      _flashColor = color;
    });
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _flashColor = null;
        });
      }
    });
  }

  Future<void> _playSound(String sound) async {
    if (!_isSoundOn) return;
    
    try {
      await _audioPlayer.play(AssetSource('sounds/$sound.mp3'));
    } catch (e) {
  
    }
  }

  void _onCorrect() {
    _playSound('correct');
    debugPrint('[WORD MARKED] CORRECT: $_currentWord');
    setState(() {
      _score += 10;
      _correctCount++;
      _wordResults[_currentWord] = true;
    });
    _nextWord();
  }

  void _onSkip() {
    _playSound('skip');
    debugPrint('[WORD MARKED] SKIP: $_currentWord');
    setState(() {
      _skippedCount++;
    });
    _nextWord();
  }

  void _nextWord() {
    if (_remainingWords.isNotEmpty) {
      _currentWord = _remainingWords.removeLast();
      _wordResults[_currentWord] = false;
      _hasScoredThisWord = false; // Reset for new word
    } else {
      _endGame();
    }
  }

  void _endGame() {
    _gameTimer.cancel();
    _lastSecondsPlayer.stop();
    _isLastSecondsPlaying = false;
    setState(() {
      _isGameOver = true;
      _isGameStarted = false;
    });
    
    // Navigate to results screen after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      Navigator.pushReplacementNamed(
        context,
        ResultsScreen.routeName,
        arguments: {
          'score': _score,
          'correctCount': _correctCount,
          'skippedCount': _skippedCount,
          'wordResults': _wordResults,
          'deck': _deck,
          'teamNumber': _teamNumber,
          'gameMode': _gameMode,
          if (args != null && args['team1Score'] != null) 'team1Score': args['team1Score'],
          if (args != null && args['team1WordResults'] != null) 'team1WordResults': args['team1WordResults'],
          'duration': _duration,
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isPortrait = screenSize.height > screenSize.width;
    
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _flashColor ?? Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_gameMode == 'team')
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Text(
                  _teamNumber == 1 ? 'Team A' : 'Team B',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey<int>(_countdownValue),
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFF45B7D1).withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF45B7D1),
                    width: 4,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$_countdownValue',
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF45B7D1),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (_isGameOver) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Time's Up!",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFC107),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC107)),
              strokeWidth: 3,
            ),
            const SizedBox(height: 32),
            const Text(
              'Calculating results...',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else if (_isGameStarted) {
      // Gameplay UI: Only timer, score, and word
      return Stack(
        children: [
          // Timer at top left
          Positioned(
            top: 32,
            left: 32,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                '$_timeRemaining',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF45B7D1),
                ),
              ),
            ),
          ),
          // Score at top right
          Positioned(
            top: 32,
            right: 32,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFFFC107), size: 28),
                  const SizedBox(width: 8),
                  Text(
                    '$_score',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFC107),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Word in center
          Center(
            child: Container(
              width: 430,
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Text(
                _currentWord,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: _currentWord.length > 12 ? 38 : 56,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                  letterSpacing: 1.2,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
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
