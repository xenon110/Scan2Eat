import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/app_theme.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _ringController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _taglineFade;
  late Animation<Offset> _taglineSlide;

  @override
  void initState() {
    super.initState();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _logoFade = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.elasticOut),
    );
    _taglineFade = CurvedAnimation(
      parent: _slideController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _slideController.forward();
      });
    });

    // Navigate after 3.5 seconds
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, _, _) => const OnboardingScreen(),
            transitionDuration: const Duration(milliseconds: 700),
            transitionsBuilder: (_, anim, _, child) => FadeTransition(
              opacity: anim,
              child: child,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _ringController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Animated radial rings
          Center(
            child: AnimatedBuilder(
              animation: _ringController,
              builder: (_, _) => CustomPaint(
                size: const Size(400, 400),
                painter: _RingsPainter(_ringController.value),
              ),
            ),
          ),

          // Radial gradient glow at center
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryNeon.withValues(alpha: 0.18),
                    AppTheme.primaryCyan.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Column(
                      children: [
                        // Icon mark
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryNeon.withValues(alpha: 0.08),
                            border: Border.all(
                              color: AppTheme.primaryNeon.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryNeon.withValues(alpha: 0.35),
                                blurRadius: 40,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            color: AppTheme.primaryNeon,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // App name — NEON style
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [AppTheme.primaryNeon, AppTheme.primaryCyan],
                          ).createShader(bounds),
                          child: const Text(
                            'SCAN2EAT',
                            style: TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                        ),
                        const Text(
                          'AI',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 14,
                            color: AppTheme.primaryCyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Tagline
                SlideTransition(
                  position: _taglineSlide,
                  child: FadeTransition(
                    opacity: _taglineFade,
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 1,
                          color: AppTheme.primaryNeon.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your AI-Powered Health Intelligence',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 13,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom loading bar
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _taglineFade,
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _ringController,
                    builder: (_, _) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 80),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_ringController.value * 1.5).clamp(0, 1),
                          minHeight: 2,
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryNeon,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Initializing AI Engine...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.25),
                      fontSize: 11,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  final double t;
  _RingsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const neon = AppTheme.primaryNeon;
    const cyan = AppTheme.primaryCyan;

    for (var i = 0; i < 4; i++) {
      final phase = (t + i * 0.25) % 1.0;
      final radius = 60.0 + phase * 160.0;
      final opacity = (1.0 - phase) * 0.25;
      final color = i.isEven ? neon : cyan;

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Floating particles
    final rand = math.Random(42);
    for (var i = 0; i < 18; i++) {
      final angle = (rand.nextDouble() * 2 * math.pi) + t * math.pi * 2 * (rand.nextBool() ? 0.1 : -0.05);
      final r = 80.0 + rand.nextDouble() * 130.0;
      final px = center.dx + r * math.cos(angle);
      final py = center.dy + r * math.sin(angle);
      canvas.drawCircle(
        Offset(px, py),
        1.2,
        Paint()..color = AppTheme.primaryNeon.withValues(alpha: 0.4),
      );
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.t != t;
}
