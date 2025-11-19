import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import 'main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _wheelController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    
    // Wheel rotation animation
    _wheelController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Particle animation
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

   // Navigate after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const RandomPickerScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _wheelController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 600;
    
    // Responsive wheel size
    final wheelSize = isSmallScreen 
        ? screenWidth * 0.45 
        : isMediumScreen 
            ? screenWidth * 0.5 
            : screenWidth * 0.35;
    
    // Responsive font sizes
    final titleFontSize = isSmallScreen ? 28.0 : isMediumScreen ? 32.0 : 38.0;
    final spacing = screenHeight * 0.05;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1F1C2C),
              Color(0xFF2D1B4E),
              Color(0xFF1F1C2C),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background particles
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: SplashParticlePainter(_particleController.value),
                );
              },
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated spinning wheel icon
                  AnimatedBuilder(
                    animation: _wheelController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _wheelController.value * 2 * math.pi,
                        child: Container(
                          width: wheelSize,
                          height: wheelSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF6C5CE7),
                                Color(0xFF4ECDC4),
                                Color(0xFF26DE81),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4ECDC4).withOpacity(0.5),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: CustomPaint(
                            painter: MiniWheelPainter(),
                          ),
                        ),
                      );
                    },
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut),

                  SizedBox(height: spacing),

                  // App title with gradient
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFF4ECDC4),
                          Color(0xFF26DE81),
                          Color(0xFF6C5CE7),
                        ],
                      ).createShader(bounds),
                      child: Text(
                        'SpinFlow',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 600.ms)
                      .slideY(begin: 0.3, end: 0, delay: 300.ms, duration: 600.ms),
                ],
              ),
            ),

            // Floating particles effect
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _particleController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: FloatingParticlesPainter(_particleController.value),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Mini wheel painter for splash
class MiniWheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const segments = 8;
    final anglePerSegment = (2 * math.pi) / segments;

    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFFFFE66D),
      const Color(0xFF95E1D3),
      const Color(0xFFFF6F91),
      const Color(0xFF6C5CE7),
      const Color(0xFFFFA502),
      const Color(0xFF26DE81),
    ];

    for (int i = 0; i < segments; i++) {
      final startAngle = i * anglePerSegment;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.8),
        startAngle,
        anglePerSegment,
        true,
        paint,
      );

      // White border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.8),
        startAngle,
        anglePerSegment,
        true,
        borderPaint,
      );
    }

    // Center circle
    final centerPaint = Paint()
      ..color = const Color(0xFF1F1C2C)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.25, centerPaint);

    // Center border
    final centerBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius * 0.25, centerBorderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Background particle painter
class SplashParticlePainter extends CustomPainter {
  final double animationValue;

  SplashParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final random = math.Random(42);
    const particleCount = 50;

    for (int i = 0; i < particleCount; i++) {
      final seed = random.nextDouble();
      final x = size.width * seed;
      final y = (size.height * seed * 2 + animationValue * size.height) %
          size.height;

      final opacity = (0.1 + (seed * 0.3)).clamp(0.0, 1.0);
      final radius = 1 + (seed * 2);

      final colors = [
        const Color(0xFF6C5CE7),
        const Color(0xFF4ECDC4),
        const Color(0xFF26DE81),
        const Color(0xFFFFA502),
      ];

      paint.color = colors[i % colors.length].withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Floating particles painter
class FloatingParticlesPainter extends CustomPainter {
  final double animationValue;

  FloatingParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final random = math.Random(123);
    const particleCount = 20;

    for (int i = 0; i < particleCount; i++) {
      final seed = random.nextDouble();
      final baseX = size.width * seed;
      final baseY = size.height * seed;

      // Floating motion
      final x = baseX + math.sin(animationValue * 2 * math.pi + i) * 20;
      final y = baseY + math.cos(animationValue * 2 * math.pi + i) * 20;

      final opacity = (0.15 + math.sin(animationValue * 2 * math.pi + seed) * 0.15)
          .clamp(0.0, 1.0);
      final radius = 3 + (seed * 4);

      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

