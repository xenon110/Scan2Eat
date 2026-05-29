import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/app_theme.dart';
import '../auth/auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _floatController;
  late AnimationController _scanController;

  static const _pages = [
    _PageData(
      icon: Icons.qr_code_scanner_rounded,
      accent: AppTheme.primaryNeon,
      title: 'Scan Any Food',
      subtitle: 'Point your camera at any food label, barcode, or even a '
          'restaurant menu. Our AI reads every ingredient in under 2 seconds.',
      badgeLabel: '2s Analysis',
      badgeIcon: Icons.flash_on,
    ),
    _PageData(
      icon: Icons.insights_rounded,
      accent: AppTheme.primaryCyan,
      title: 'Know Every Nutrient',
      subtitle: 'Get a full breakdown of calories, protein, sugar, dangerous '
          'additives, and AI-suggested healthy alternatives — all in one tap.',
      badgeLabel: 'AI Powered',
      badgeIcon: Icons.auto_awesome,
    ),
    _PageData(
      icon: Icons.emoji_events_rounded,
      accent: Color(0xFFC79AFA),
      title: 'Achieve Your Goals',
      subtitle: 'Set daily, weekly and monthly nutrition targets. Track your '
          'progress in real time and compete with friends on the leaderboard.',
      badgeLabel: 'Goal Tracking',
      badgeIcon: Icons.track_changes_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _goToAuth();
    }
  }

  void _goToAuth() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const AuthScreen(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, anim, _, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final accent = page.accent;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -80,
            left: -60,
            child: AnimatedBuilder(
              animation: _floatController,
              builder: (_, _) => Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accent.withValues(alpha: 0.08 + _floatController.value * 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          Column(
            children: [
              // Skip button
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20, top: 12),
                    child: TextButton(
                      onPressed: _goToAuth,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Pages
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _pages.length,
                  itemBuilder: (_, i) => _buildPage(_pages[i]),
                ),
              ),

              // Bottom controls
              _buildBottomControls(accent),
              const SizedBox(height: 40),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPage(_PageData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Illustration area
          Expanded(
            flex: 5,
            child: _buildIllustration(data),
          ),

          const SizedBox(height: 32),

          // Title
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [data.accent, Colors.white],
            ).createShader(bounds),
            child: Text(
              data.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.1,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 15,
              height: 1.65,
            ),
          ),

          const SizedBox(height: 24),

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: data.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: data.accent.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(data.badgeIcon, color: data.accent, size: 15),
                const SizedBox(width: 6),
                Text(
                  data.badgeLabel,
                  style: TextStyle(
                    color: data.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildIllustration(_PageData data) {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _scanController]),
      builder: (_, _) {
        final float = math.sin(_floatController.value * math.pi) * 10;
        return Transform.translate(
          offset: Offset(0, float),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: data.accent.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
              ),
              // Inner glow ring
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: data.accent.withValues(alpha: 0.06),
                  border: Border.all(
                    color: data.accent.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: data.accent.withValues(alpha: 0.25),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),

              // Scan beam (only for page 0)
              if (_currentPage == 0)
                Positioned(
                  top: 55 + _scanController.value * 110,
                  child: Container(
                    width: 150,
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        data.accent.withValues(alpha: 0.8),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),

              // Main icon
              Icon(
                data.icon,
                size: 88,
                color: data.accent,
              ),

              // Orbiting dots
              ..._buildOrbitDots(data.accent),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildOrbitDots(Color accent) {
    return List.generate(6, (i) {
      return AnimatedBuilder(
        animation: _scanController,
        builder: (_, _) {
          final angle = (i / 6) * 2 * math.pi + _scanController.value * 2 * math.pi;
          const radius = 115.0;
          return Transform.translate(
            offset: Offset(math.cos(angle) * radius, math.sin(angle) * radius),
            child: Container(
              width: i.isEven ? 6 : 4,
              height: i.isEven ? 6 : 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: i.isEven ? 0.8 : 0.4),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildBottomControls(Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          // Dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (i) {
              final active = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? accent : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 28),

          // Next / Get Started button
          GestureDetector(
            onTap: _nextPage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent, AppTheme.primaryCyan],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentPage == _pages.length - 1
                        ? 'Get Started'
                        : 'Continue',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded,
                      color: Colors.black, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageData {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final String badgeLabel;
  final IconData badgeIcon;

  const _PageData({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.badgeIcon,
  });
}
