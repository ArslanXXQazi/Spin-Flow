import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'black_text.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style for splash screen
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1F1C2C),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const RandomPickerApp());
}

class RandomPickerApp extends StatelessWidget {
  const RandomPickerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpinFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const SplashScreen(),
    );
  }
}

class RandomPickerScreen extends StatefulWidget {
  const RandomPickerScreen({super.key});

  @override
  State<RandomPickerScreen> createState() => _RandomPickerScreenState();
}

class _RandomPickerScreenState extends State<RandomPickerScreen>
    with TickerProviderStateMixin {
  final List<String> _items = [
    'Arslan',
    'Mudassir',
    'Asif',
    'Mitha',
  ];
  
  final TextEditingController _textController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  bool _isSpinning = false;
  double _currentRotation = 0.0;
  // Arrow animations
  late AnimationController _arrowPulseController;
  late Animation<double> _arrowPulse;
  late AnimationController _arrowTickController;
  late Animation<double> _arrowTick;
  int _lastTickIndex = -1;
  Color _currentArrowColor = const Color(0xFF6C5CE7);
  
  // Wheel colors - same as WheelPainter
  final List<Color> _wheelColors = [
    const Color(0xFFFF6B6B), // Vibrant Red
    const Color(0xFF4ECDC4), // Turquoise
    const Color(0xFFFFE66D), // Yellow
    const Color(0xFF95E1D3), // Mint Green
    const Color(0xFFFF6F91), // Pink
    const Color(0xFF6C5CE7), // Purple
    const Color(0xFFFFA502), // Orange
    const Color(0xFF26DE81), // Green
    const Color(0xFF45AAF2), // Blue
    const Color(0xFFFD79A8), // Rose Pink
  ];
  
  // Audio players
  final AudioPlayer _tickPlayer = AudioPlayer();
  final AudioPlayer _spinPlayer = AudioPlayer();
  final AudioPlayer _winPlayer = AudioPlayer();
  
  // Confetti controller
  late ConfettiController _confettiController;
  
  // Background particles animation
  late AnimationController _particleController;
  
  // Winner history
  final List<String> _winnerHistory = [];
  
  // Wheel glow animation
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  
  // Speed indicator
  double _currentSpeed = 0.0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    // Idle pulsing for the center arrow button
    _arrowPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _arrowPulse = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _arrowPulseController, curve: Curves.easeInOut),
    );
    // Quick tick bounce when passing segments
    _arrowTickController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _arrowTick = CurvedAnimation(
      parent: _arrowTickController,
      curve: Curves.easeOutCubic,
    );
    
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Stop spin sound
        _spinPlayer.stop();
        
        setState(() {
          _isSpinning = false;
          _currentSpeed = 0.0;
          // Keep the final color of the selected segment
          _calculateSelectedItem();
        });
      }
    });
    
    // Update speed indicator during spin
    _animationController.addListener(() {
      if (_isSpinning) {
        setState(() {
          _currentSpeed = (1.0 - _animationController.value) * 100;
        });
      }
    });
    // Tick feedback while spinning: small haptic + arrow bounce per segment
    _animationController.addListener(() {
      if (_items.isEmpty) return;
      final double itemAngle = (2 * 3.14159) / _items.length;
      final double currentAngle = (_rotationAnimation.value) % (2 * 3.14159);
      // Align to the upward selection angle
      final double selectionAngle = 3 * 3.14159 / 2;
      final double adjustedAngle =
          (selectionAngle - currentAngle + 2 * 3.14159) % (2 * 3.14159);
      final int indexAtTop =
          (adjustedAngle / itemAngle).floor() % _items.length;
      
      if (indexAtTop != _lastTickIndex && _isSpinning) {
        // Update arrow color based on current segment
        setState(() {
          _currentArrowColor = _wheelColors[indexAtTop % _wheelColors.length];
        });
        
        // Play tick sound
        _playTickSound();
        
        HapticFeedback.selectionClick();
        if (_arrowTickController.isAnimating) {
          _arrowTickController.stop();
        }
        _arrowTickController.forward(from: 0.0);
        _lastTickIndex = indexAtTop;
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _arrowPulseController.dispose();
    _arrowTickController.dispose();
    _particleController.dispose();
    _glowController.dispose();
    _confettiController.dispose();
    _textController.dispose();
    _tickPlayer.dispose();
    _spinPlayer.dispose();
    _winPlayer.dispose();
    super.dispose();
  }

  // Play sound methods - DISABLED (Enable when sound files are ready)
  Future<void> _playTickSound() async {
    // TODO: Uncomment when tick.mp3 is added to assets/sounds/
    // try {
    //   await _tickPlayer.play(AssetSource('sounds/tick.mp3'));
    //   await _tickPlayer.setVolume(0.3);
    // } catch (e) {
    //   HapticFeedback.lightImpact();
    // }
  }

  Future<void> _playSpinSound() async {
    // TODO: Uncomment when spin.mp3 is added to assets/sounds/
    // try {
    //   await _spinPlayer.play(AssetSource('sounds/spin.mp3'));
    //   await _spinPlayer.setVolume(0.4);
    // } catch (e) {
    //   // Sound file not found
    // }
  }

  Future<void> _playWinSound() async {
    // TODO: Uncomment when win.mp3 is added to assets/sounds/
    // try {
    //   await _winPlayer.play(AssetSource('sounds/win.mp3'));
    //   await _winPlayer.setVolume(0.5);
    // } catch (e) {
    //   // Sound file not found
    // }
  }

  void _calculateSelectedItem() {
    if (_items.isEmpty) return;
    
    final double normalizedRotation = _currentRotation % (2 * 3.14159);
    final double itemAngle = (2 * 3.14159) / _items.length;
    
    // Arrow points upward (top), which is at angle 3π/2 (or -π/2)
    final double selectionAngle = 3 * 3.14159 / 2;
    final double adjustedAngle = (selectionAngle - normalizedRotation + 2 * 3.14159) % (2 * 3.14159);
    final int selectedIndex = (adjustedAngle / itemAngle).floor() % _items.length;
    
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    // Add to winner history
    setState(() {
      _winnerHistory.insert(0, _items[selectedIndex]);
      if (_winnerHistory.length > 10) {
        _winnerHistory.removeLast();
      }
    });
    
    // Play win sound
    _playWinSound();
    
    // Trigger confetti
    _confettiController.play();
    
    // Show dialog with selected item
    Future.delayed(const Duration(milliseconds: 300), () {
      _showSelectedItemDialog(_items[selectedIndex]);
    });
  }

  void _showSelectedItemDialog(String selectedItem) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 600;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2D1B4E).withOpacity(0.95),
                  const Color(0xFF1F1C2C).withOpacity(0.95),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF26DE81).withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF26DE81).withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16.0 : isMediumScreen ? 20.0 : 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated title
                  AnimatedTextKit(
                    animatedTexts: [
                      TypewriterAnimatedText(
                        'Selected Item!',
                        textStyle: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 20 : isMediumScreen ? 22 : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                        speed: const Duration(milliseconds: 100),
                      ),
                    ],
                    totalRepeatCount: 1,
                  ),
                  SizedBox(height: isSmallScreen ? 16 : isMediumScreen ? 20 : 24),
                  // Winner container with shimmer
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : isMediumScreen ? 20 : 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF26DE81),
                          const Color(0xFF20BF6B),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF26DE81).withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Shimmer.fromColors(
                      baseColor: Colors.white,
                      highlightColor: Colors.white70,
                      child: BlackText(
                        text: selectedItem,
                        fontSize: isSmallScreen ? 22 : isMediumScreen ? 25 : 28,
                        fontWeight: FontWeight.bold,
                        textColor: Colors.white,
                        fontFamily: 'a',
                      ),
                    ),
                  )
                      .animate()
                      .scale(delay: 200.ms, duration: 400.ms, curve: Curves.elasticOut)
                      .fadeIn(delay: 200.ms),
                  SizedBox(height: isSmallScreen ? 14 : isMediumScreen ? 17 : 20),
                  // Congratulations text
                  AnimatedTextKit(
                    animatedTexts: [
                      FadeAnimatedText(
                        'Congratulations! 🎉',
                        textStyle: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 14 : isMediumScreen ? 16 : 18,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                        duration: const Duration(milliseconds: 2000),
                      ),
                      FadeAnimatedText(
                        'You Won! 🏆',
                        textStyle: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 14 : isMediumScreen ? 16 : 18,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                        duration: const Duration(milliseconds: 2000),
                      ),
                      FadeAnimatedText(
                        'Amazing! ✨',
                        textStyle: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 14 : isMediumScreen ? 16 : 18,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                        duration: const Duration(milliseconds: 2000),
                      ),
                    ],
                    repeatForever: true,
                  ),
                  const SizedBox(height: 24),
                  // OK Button
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6C5CE7),
                          const Color(0xFF4834DF),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C5CE7).withOpacity(0.5),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 14,
                          ),
                          child: const BlackText(
                            text: 'OK',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            textColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms)
                      .slideY(begin: 0.2, end: 0, delay: 400.ms),
                ],
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 300.ms)
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), curve: Curves.easeOutBack);
      },
    );
  }

  void _spinWheel() {
    if (_items.isEmpty || _isSpinning) return;
    
    setState(() {
      _isSpinning = true;
    });
    
    // Play spin sound
    _playSpinSound();
    
    // Random rotation between 5-10 full rotations plus random angle
    final double randomRotations = 5 + (5 * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000);
    final double randomAngle = (2 * 3.14159 * (DateTime.now().microsecondsSinceEpoch % 1000) / 1000);
    final double totalRotation = (randomRotations * 2 * 3.14159) + randomAngle;
    
    _currentRotation += totalRotation;
    
    _rotationAnimation = Tween<double>(
      begin: _currentRotation - totalRotation,
      end: _currentRotation,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    // Duration proportional to distance, for more realistic deceleration
    final int durationMs = (600 + totalRotation * 90).toInt();
    _animationController.duration = Duration(milliseconds: durationMs);
    // Initialize tick index from start position so first boundary triggers after crossing
    if (_items.isNotEmpty) {
      final double itemAngle = (2 * 3.14159) / _items.length;
      final double startAngle = (_currentRotation - totalRotation) % (2 * 3.14159);
      final double selectionAngle = 3 * 3.14159 / 2;
      final double adjustedAngle =
          (selectionAngle - startAngle + 2 * 3.14159) % (2 * 3.14159);
      _lastTickIndex = (adjustedAngle / itemAngle).floor() % _items.length;
    }
    
    _animationController.reset();
    _animationController.forward();
  }

  void _addItem() {
    if (_textController.text.trim().isNotEmpty) {
      setState(() {
        _items.add(_textController.text.trim());
        _textController.clear();
      });
    }
  }

  void _removeItem(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _items.removeAt(index);
    });
  }
  
  void _showWinnerHistoryDialog() {
    HapticFeedback.lightImpact();
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 600;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: isSmallScreen ? 400 : isMediumScreen ? 450 : 500,
          ),
          padding: EdgeInsets.all(isSmallScreen ? 16 : isMediumScreen ? 20 : 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2D1B4E),
                Color(0xFF1F1C2C),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF26DE81).withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF26DE81).withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF26DE81), Color(0xFF20BF6B)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF26DE81).withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.emoji_events, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Winner History',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${_winnerHistory.length} ${_winnerHistory.length == 1 ? 'spin' : 'spins'} (Latest first)',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Divider
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFF26DE81).withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Winner List
              Flexible(
                child: _winnerHistory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.history,
                              size: 64,
                              color: Colors.white30,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No winners yet!',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _winnerHistory.length,
                        itemBuilder: (context, index) {
                          // Reverse the index to show latest first
                          final reversedIndex = _winnerHistory.length - 1 - index;
                          final displayNumber = index + 1;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _wheelColors[index % _wheelColors.length].withOpacity(0.2),
                                  _wheelColors[index % _wheelColors.length].withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _wheelColors[index % _wheelColors.length].withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Rank badge
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _wheelColors[index % _wheelColors.length],
                                        _wheelColors[index % _wheelColors.length].withOpacity(0.7),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _wheelColors[index % _wheelColors.length].withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$displayNumber',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Winner name
                                Expanded(
                                  child: Row(
                                    children: [
                                      if (index == 0)
                                        const Icon(Icons.star, color: Colors.amber, size: 20),
                                      if (index == 0) const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          _winnerHistory[reversedIndex],
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: index == 0 ? FontWeight.bold : FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Medal for top 3
                                if (index < 3)
                                  Text(
                                    ['🥇', '🥈', '🥉'][index],
                                    style: const TextStyle(fontSize: 24),
                                  ),
                              ],
                            ),
                          )
                              .animate(key: ValueKey('history_$reversedIndex'))
                              .fadeIn(duration: 300.ms, delay: Duration(milliseconds: index * 50))
                              .slideX(begin: -0.2, end: 0, duration: 400.ms, delay: Duration(milliseconds: index * 50));
                        },
                      ),
              ),
            ],
          ),
        )
            .animate()
            .scale(duration: 300.ms, curve: Curves.easeOutBack)
            .fadeIn(duration: 200.ms),
      ),
    );
  }
  
  void _clearAllItems() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2D1B4E).withOpacity(0.95),
                const Color(0xFF1F1C2C).withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFF6B6B).withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF6B6B), size: 48),
              const SizedBox(height: 16),
              const BlackText(
                text: 'Clear All Items?',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                textColor: Colors.white,
              ),
              const SizedBox(height: 8),
              const BlackText(
                text: 'This will remove all items from the list.',
                fontSize: 14,
                textColor: Colors.white60,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C5CE7), Color(0xFF4834DF)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            child: const BlackText(
                              text: 'Cancel',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              textColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFFF4757)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _items.clear();
                            });
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            child: const BlackText(
                              text: 'Clear All',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              textColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
            .animate()
            .scale(duration: 300.ms, curve: Curves.easeOutBack),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    
    // Responsive breakpoints
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 600;
    final isTablet = screenWidth >= 600;
    
    // Responsive sizes
    final wheelSize = isSmallScreen 
        ? screenWidth * 0.75 
        : isMediumScreen 
            ? screenWidth * 0.8 
            : screenWidth * 0.55;
    
    final headerFontSize = isSmallScreen ? 24.0 : isMediumScreen ? 28.0 : 36.0;
    final subtitleFontSize = isSmallScreen ? 12.0 : isMediumScreen ? 14.0 : 18.0;
    final padding = isTablet ? 32.0 : isMediumScreen ? 16.0 : 12.0;
    final spacing = isTablet ? 30.0 : isMediumScreen ? 20.0 : 15.0;
    
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background with particles
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1F1C2C),
                  const Color(0xFF2D1B4E),
                  const Color(0xFF1F1C2C),
                ],
              ),
            ),
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlePainter(_particleController.value),
                );
              },
            ),
          ),
          // Main Content
          SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                children: [
              // Header with animation
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8.0 : 0),
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFF4ECDC4),
                      Color(0xFF26DE81),
                      Color(0xFF6C5CE7),
                    ],
                  ).createShader(bounds),
                  child: AnimatedTextKit(
                    animatedTexts: [
                      FadeAnimatedText(
                        'SpinFlow',
                        textAlign: TextAlign.center,
                        textStyle: GoogleFonts.poppins(
                          fontSize: headerFontSize,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                        duration: const Duration(milliseconds: 2000),
                      ),
                    ],
                    totalRepeatCount: 1,
                    onFinished: () {},
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(begin: const Offset(0.9, 0.9), duration: 600.ms, curve: Curves.easeOut),
              ),
              SizedBox(height: spacing * 0.5),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12.0 : 0),
                child: Shimmer.fromColors(
                  baseColor: Colors.white60,
                  highlightColor: Colors.white,
                  period: const Duration(milliseconds: 2000),
                  child: Text(
                    'Spin the wheel and get your choice! 🎯',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: subtitleFontSize,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 600.ms)
                    .slideY(begin: -0.2, end: 0, delay: 500.ms),
              ),
              SizedBox(height: spacing),
              
              // Wheel Container
              Container(
                height: wheelSize,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return Container(
                        width: wheelSize,
                        height: wheelSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                            if (_isSpinning)
                              BoxShadow(
                                color: _currentArrowColor.withOpacity(_glowAnimation.value * 0.6),
                                blurRadius: 40 * _glowAnimation.value,
                                spreadRadius: 10 * _glowAnimation.value,
                              ),
                          ],
                        ),
                        child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Wheel - Different painter for empty state
                              _items.isEmpty
                                  ? AnimatedBuilder(
                                      animation: _particleController,
                                      builder: (context, child) {
                                        return CustomPaint(
                                          size: Size(wheelSize, wheelSize),
                                          painter: EmptyWheelPainter(_particleController.value),
                                        );
                                      },
                                    )
                                  : AnimatedBuilder(
                                      animation: _rotationAnimation,
                                      builder: (context, child) {
                                        return Transform.rotate(
                                          angle: _rotationAnimation.value,
                                          child: CustomPaint(
                                            size: Size(wheelSize, wheelSize),
                                            painter: WheelPainter(_items),
                                          ),
                                        );
                                      },
                                    ),
                          
                          // Center Circle with Arrow Button
                          GestureDetector(
                            onTap: _items.isNotEmpty && !_isSpinning ? _spinWheel : null,
                            child: AnimatedBuilder(
                              animation: Listenable.merge([
                                _arrowPulseController,
                                _arrowTickController,
                              ]),
                              builder: (context, child) {
                                // Only animate if items exist
                                final double scale = _items.isNotEmpty 
                                    ? _arrowPulse.value * (1.0 + 0.18 * _arrowTick.value)
                                    : 1.0;
                                return Transform.scale(
                                  scale: scale,
                                  child: child,
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                                width: wheelSize * 0.15,
                                height: wheelSize * 0.15,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: _items.isEmpty
                                        ? [
                                            Colors.grey.withOpacity(0.3),
                                            Colors.grey.withOpacity(0.2),
                                          ]
                                        : [
                                            _currentArrowColor,
                                            _currentArrowColor.withOpacity(0.7),
                                          ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                    color: _items.isEmpty 
                                        ? Colors.white.withOpacity(0.3) 
                                        : Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _items.isEmpty
                                          ? Colors.black.withOpacity(0.2)
                                          : _isSpinning 
                                              ? _currentArrowColor.withOpacity(0.6)
                                              : Colors.black.withOpacity(0.3),
                                      blurRadius: _isSpinning ? 18 : 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Center(
                                    child: _items.isEmpty
                                        ? Icon(
                                            Icons.lock_outline,
                                            color: Colors.white.withOpacity(0.4),
                                            size: wheelSize * 0.08,
                                          )
                                        : Image.asset(
                                            'assets/arrowUp.png',
                                            width: wheelSize * 0.08,
                                            height: wheelSize * 0.08,
                                            color: Colors.white,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) {
                                              // Fallback to icon if image not found
                                              return Icon(
                                                Icons.arrow_upward,
                                                color: Colors.white,
                                                size: wheelSize * 0.08,
                                              );
                                            },
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Speed Indicator
              if (_isSpinning)
                Container(
                  margin: EdgeInsets.only(top: spacing * 0.5),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 20,
                    vertical: isSmallScreen ? 8 : 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _currentArrowColor.withOpacity(0.8),
                        _currentArrowColor.withOpacity(0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _currentArrowColor.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.speed, color: Colors.white, size: isSmallScreen ? 18 : 20),
                      SizedBox(width: isSmallScreen ? 6 : 8),
                      BlackText(
                        text: '${_currentSpeed.toStringAsFixed(0)}%',
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        textColor: Colors.white,
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 200.ms)
                    .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOut),
              
              SizedBox(height: spacing),
              
              // Tap to spin instruction with glassmorphism - Hide when spinning
              if (!_isSpinning)
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 10 : isMediumScreen ? 12 : 16),
                  margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : isMediumScreen ? 20 : 40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF2D1B4E).withOpacity(0.7),
                        const Color(0xFF1F1C2C).withOpacity(0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFF4ECDC4).withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4ECDC4).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: BlackText(
                    text: _items.isEmpty 
                        ? 'Add items to start spinning!'
                        : 'Tap arrow button to spin! 🎯',
                    fontSize: isSmallScreen ? 12 : isMediumScreen ? 14 : 16,
                    textColor: Colors.white70,
                    textAlign: TextAlign.center,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms)
                    .shimmer(delay: 1000.ms, duration: 2000.ms, color: const Color(0xFF4ECDC4).withOpacity(0.3)),
              
              SizedBox(height: spacing),
              
              // Add Item Section
              Container(
                constraints: BoxConstraints(
                  minHeight: isSmallScreen ? 180 : 200,
                  maxHeight: isSmallScreen ? 250 : 300,
                ),
                child: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : isMediumScreen ? 16 : 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF2D1B4E).withOpacity(0.8),
                        const Color(0xFF1F1C2C).withOpacity(0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF6C5CE7).withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C5CE7).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
        child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          BlackText(
                            text: 'Add New Item:',
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            textColor: Colors.white,
                          ),
                          const Spacer(),
                          if (_items.isNotEmpty)
                            GestureDetector(
                              onTap: _clearAllItems,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 8 : 12,
                                  vertical: isSmallScreen ? 4 : 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF6B6B), Color(0xFFFF4757)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF6B6B).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.delete_sweep, color: Colors.white, size: isSmallScreen ? 14 : 16),
                                    SizedBox(width: isSmallScreen ? 3 : 4),
                                    BlackText(
                                      text: 'Clear All',
                                      fontSize: isSmallScreen ? 10 : 12,
                                      fontWeight: FontWeight.bold,
                                      textColor: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            )
                                .animate()
                                .fadeIn(duration: 300.ms)
                                .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOut),
                        ],
                      ),
                      SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Enter item name...',
                                hintStyle: TextStyle(color: Colors.white60),
                                filled: true,
                                fillColor: const Color(0xFF1F1C2C).withOpacity(0.6),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: const Color(0xFF4ECDC4).withOpacity(0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: const Color(0xFF4ECDC4).withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF4ECDC4), width: 2),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 12 : 15,
                                  vertical: isSmallScreen ? 10 : isMediumScreen ? 12 : 15,
                                ),
                              ),
                              onSubmitted: (_) => _addItem(),
                            )
                                .animate()
                                .fadeIn(delay: 200.ms)
                                .shimmer(delay: 1500.ms, duration: 2000.ms, color: const Color(0xFF4ECDC4).withOpacity(0.2)),
                          ),
                          SizedBox(width: isSmallScreen ? 8 : 10),
                          Container(
                            height: isSmallScreen ? 42 : isMediumScreen ? 45 : 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF26DE81),
                                  const Color(0xFF20BF6B),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF26DE81).withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _addItem,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
                                  alignment: Alignment.center,
                                  child: Icon(Icons.add, color: Colors.white, size: isSmallScreen ? 20 : 24),
                                ),
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 300.ms)
                              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), delay: 300.ms, curve: Curves.elasticOut),
                        ],
                      ),
                      SizedBox(height: 15),
                      Expanded(
                        child: _items.isEmpty
                            ? Center(
                                child: Shimmer.fromColors(
                                  baseColor: Colors.white60,
                                  highlightColor: Colors.white,
                                  child: BlackText(
                                    text: 'No items added yet!\nAdd some items to start spinning.',
                                    fontSize: isSmallScreen ? 12 : isMediumScreen ? 14 : 16,
                                    textColor: Colors.white60,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: _items.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    margin: EdgeInsets.only(bottom: isSmallScreen ? 6 : 8),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 12 : 15,
                                      vertical: isSmallScreen ? 8 : isMediumScreen ? 10 : 12,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          _wheelColors[index % _wheelColors.length].withOpacity(0.2),
                                          _wheelColors[index % _wheelColors.length].withOpacity(0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _wheelColors[index % _wheelColors.length].withOpacity(0.6),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _wheelColors[index % _wheelColors.length].withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        // Item number badge
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: _wheelColors[index % _wheelColors.length],
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: _wheelColors[index % _wheelColors.length].withOpacity(0.5),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: BlackText(
                                              text: '${index + 1}',
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              textColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: BlackText(
                                            text: _items[index],
                                            fontSize: isTablet ? 16 : 14,
                                            textColor: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => _removeItem(index),
                                          child: Container(
                                            padding: EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.2),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.close,
                                              color: Colors.red.shade300,
                                              size: isSmallScreen ? 14 : isMediumScreen ? 16 : 18,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                      .animate(key: ValueKey(_items[index]))
                                      .fadeIn(duration: 300.ms)
                                      .slideX(begin: -0.2, end: 0, duration: 300.ms, curve: Curves.easeOut)
                                      .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), duration: 300.ms);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
                ],
              ),
            ),
          ),
          ),
          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14 / 2, // Down
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                Color(0xFFFF6B6B),
                Color(0xFF4ECDC4),
                Color(0xFFFFE66D),
                Color(0xFF26DE81),
                Color(0xFF6C5CE7),
                Color(0xFFFFA502),
                Color(0xFF45AAF2),
                Color(0xFFFD79A8),
              ],
            ),
          ),
          // Floating Action Button for Winner History
          if (_winnerHistory.isNotEmpty)
            Positioned(
              bottom: isSmallScreen ? 16 : 20,
              right: isSmallScreen ? 16 : 20,
              child: GestureDetector(
                onTap: _showWinnerHistoryDialog,
                child: Container(
                  width: isSmallScreen ? 50 : isMediumScreen ? 56 : 60,
                  height: isSmallScreen ? 50 : isMediumScreen ? 56 : 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF26DE81),
                        Color(0xFF20BF6B),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF26DE81).withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: Colors.white,
                        size: isSmallScreen ? 24 : 28,
                      ),
                      Positioned(
                        top: isSmallScreen ? 6 : 8,
                        right: isSmallScreen ? 6 : 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Center(
                            child: Text(
                              '${_winnerHistory.length}',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scale(
                      duration: 1500.ms,
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.1, 1.1),
                      curve: Curves.easeInOut,
                    )
                    .then()
                    .scale(
                      duration: 1500.ms,
                      begin: const Offset(1.1, 1.1),
                      end: const Offset(1.0, 1.0),
                      curve: Curves.easeInOut,
                    ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: 0.5, end: 0, duration: 400.ms, curve: Curves.easeOutBack),
            ),
        ],
      ),
    );
  }
}

// Particle Painter for animated background
class ParticlePainter extends CustomPainter {
  final double animationValue;
  
  ParticlePainter(this.animationValue);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    final random = math.Random(42);
    final particleCount = 30;
    
    for (int i = 0; i < particleCount; i++) {
      final seed = random.nextDouble();
      final x = (size.width * seed) % size.width;
      final y = (size.height * seed * 2 + animationValue * size.height * 2) % (size.height * 2);
      
      final opacity = (0.1 + (seed * 0.2)).clamp(0.0, 1.0);
      final radius = 2 + (seed * 3);
      
      final colorIndex = (i % 10);
      final colors = [
        const Color(0xFFFF6B6B),
        const Color(0xFF4ECDC4),
        const Color(0xFFFFE66D),
        const Color(0xFF95E1D3),
        const Color(0xFFFF6F91),
        const Color(0xFF6C5CE7),
        const Color(0xFFFFA502),
        const Color(0xFF26DE81),
        const Color(0xFF45AAF2),
        const Color(0xFFFD79A8),
      ];
      
      paint.color = colors[colorIndex].withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Empty Wheel Painter with animation
class EmptyWheelPainter extends CustomPainter {
  final double animationValue;
  
  EmptyWheelPainter(this.animationValue);
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw gradient background circle
    final gradientPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF6C5CE7).withOpacity(0.3),
          const Color(0xFF4ECDC4).withOpacity(0.2),
          const Color(0xFF26DE81).withOpacity(0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, gradientPaint);
    
    // Draw animated pulsing rings
    for (int i = 0; i < 3; i++) {
      final animOffset = (animationValue + i * 0.33) % 1.0;
      final ringOpacity = (1.0 - animOffset) * 0.5;
      
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 - (animOffset * 2)
        ..color = [
          const Color(0xFF6C5CE7),
          const Color(0xFF4ECDC4),
          const Color(0xFF26DE81),
        ][i].withOpacity(ringOpacity);
      
      canvas.drawCircle(
        center,
        radius * (0.3 + animOffset * 0.6),
        ringPaint,
      );
    }

    
    // Draw rotating dashed outer circle
    final dashedPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFF4ECDC4).withOpacity(0.5);
    
    const dashCount = 30;
    const dashAngle = (2 * 3.14159) / dashCount;
    final rotationOffset = animationValue * 2 * 3.14159;
    
    for (int i = 0; i < dashCount; i++) {
      if (i % 2 == 0) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius - 5),
          i * dashAngle + rotationOffset,
          dashAngle * 0.6,
          false,
          dashedPaint,
        );
      }
    }

    
    // Draw center icon with pulsing animation
    final pulseScale = 1.0 + (math.sin(animationValue * 2 * 3.14159) * 0.1);
    final iconPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF6C5CE7),
          const Color(0xFF4ECDC4),
          const Color(0xFF26DE81),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.15));
    
    // Draw plus icon in center with pulse
    final iconSize = radius * 0.15 * pulseScale;
    // Vertical line
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: iconSize * 0.3,
          height: iconSize * 2,
        ),
        const Radius.circular(10),
      ),
      iconPaint,
    );
    // Horizontal line
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: iconSize * 2,
          height: iconSize * 0.3,
        ),
        const Radius.circular(10),
      ),
      iconPaint,
    );

    
    // Draw "Add Items" text with fade animation
    final textOpacity = 0.5 + (math.sin(animationValue * 2 * 3.14159) * 0.2);
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Add Items to Spin',
        style: TextStyle(
          color: Colors.white.withOpacity(textOpacity),
          fontSize: size.width * 0.045,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy + radius * 0.35,
      ),
    );
    
    // Draw emoji/decoration
    final emojiPainter = TextPainter(
      text: const TextSpan(
        text: '🎯',
        style: TextStyle(fontSize: 40),
      ),
      textDirection: TextDirection.ltr,
    );
    emojiPainter.layout();
    emojiPainter.paint(
      canvas,
      Offset(
        center.dx - emojiPainter.width / 2,
        center.dy - radius * 0.45,
      ),
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class WheelPainter extends CustomPainter {
  final List<String> items;
  
  WheelPainter(this.items);
  
  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final anglePerItem = (2 * 3.14159) / items.length;
    
    final List<Color> colors = [
      const Color(0xFFFF6B6B), // Vibrant Red
      const Color(0xFF4ECDC4), // Turquoise
      const Color(0xFFFFE66D), // Yellow
      const Color(0xFF95E1D3), // Mint Green
      const Color(0xFFFF6F91), // Pink
      const Color(0xFF6C5CE7), // Purple
      const Color(0xFFFFA502), // Orange
      const Color(0xFF26DE81), // Green
      const Color(0xFF45AAF2), // Blue
      const Color(0xFFFD79A8), // Rose Pink
    ];
    
    // Draw beautiful background glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF6C5CE7).withOpacity(0.15),
          const Color(0xFF4ECDC4).withOpacity(0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius * 0.98, glowPaint);
    
    // Draw segments with beautiful gradients
    for (int i = 0; i < items.length; i++) {
      final startAngle = i * anglePerItem;
      final endAngle = (i + 1) * anglePerItem;
      
      // Base color
      final baseColor = colors[i % colors.length];
      
      // Draw segment with radial gradient
      final paint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.0, -0.4),
          radius: 1.2,
          colors: [
            Color.lerp(baseColor, Colors.white, 0.3)!,
            baseColor,
            Color.lerp(baseColor, Colors.black, 0.2)!,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        endAngle - startAngle,
        true,
        paint,
      );
      
      // Add subtle shine effect
      final shinePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.25),
            Colors.transparent,
            Colors.black.withOpacity(0.1),
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        endAngle - startAngle,
        true,
        shinePaint,
      );
      
      // Draw clean white border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        endAngle - startAngle,
        true,
        borderPaint,
      );
      
      // Draw text - Original style
      final textAngle = startAngle + (anglePerItem / 2);
      final textRadius = radius * 0.7;
      final textX = center.dx + textRadius * cos(textAngle);
      final textY = center.dy + textRadius * sin(textAngle);
      
      canvas.save();
      canvas.translate(textX, textY);
      canvas.rotate(textAngle + (3.14159 / 2));
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: items[i],
          style: TextStyle(
            color: Colors.white,
            fontSize: size.width * 0.05,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      
      canvas.restore();
    }
    
    // Multiple rim layers for premium 3D look
    // Outer dark rim
    final Paint outerRimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..shader = LinearGradient(
        colors: [
          Colors.black.withOpacity(0.4),
          Colors.black.withOpacity(0.2),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius + 2, outerRimPaint);
    
    // Main gradient rim
    final Paint rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..shader = SweepGradient(
        colors: [
          const Color(0xFF6C5CE7),
          const Color(0xFF4ECDC4),
          const Color(0xFF26DE81),
          const Color(0xFFFFA502),
          const Color(0xFFFF6B6B),
          const Color(0xFF6C5CE7),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius - 1, rimPaint);
    
    // Inner white highlight rim
    final Paint innerRimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withOpacity(0.5);
    canvas.drawCircle(center, radius - 4, innerRimPaint);
    
    // Center hub with gradient
    final Paint hubPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF2D1B4E).withOpacity(0.8),
          const Color(0xFF1F1C2C).withOpacity(0.9),
          Colors.black.withOpacity(0.6),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.15));
    canvas.drawCircle(center, radius * 0.15, hubPaint);
    
    // Hub border
    final Paint hubBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF6C5CE7).withOpacity(0.8),
          const Color(0xFF4ECDC4).withOpacity(0.8),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.15));
    canvas.drawCircle(center, radius * 0.15, hubBorderPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Helper functions for trigonometry
double cos(double angle) {
  return math.cos(angle);
}

double sin(double angle) {
  return math.sin(angle);
}


