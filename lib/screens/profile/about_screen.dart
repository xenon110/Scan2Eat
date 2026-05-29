import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_theme.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _copyVersion() {
    Clipboard.setData(const ClipboardData(text: 'Scan2Eat v1.0.0'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppTheme.primaryNeon, size: 18),
            SizedBox(width: 10),
            Text('Version copied!', style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: const Color(0xFF161C24),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App Bar ──
            SliverAppBar(
              pinned: true,
              backgroundColor: AppTheme.background,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white70, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text(
                'About',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // ── Hero Logo Section ──
                    _buildHeroSection(),

                    const SizedBox(height: 32),

                    // ── Version Badge ──
                    _buildVersionBadge(),

                    const SizedBox(height: 36),

                    // ── About Card ──
                    _buildAboutCard(),

                    const SizedBox(height: 20),

                    // ── Features ──
                    _buildFeaturesCard(),

                    const SizedBox(height: 20),

                    // ── Developer Card ──
                    _buildDeveloperCard(),

                    const SizedBox(height: 20),

                    // ── Help & Support ──
                    _buildHelpCard(),

                    const SizedBox(height: 20),

                    // ── Legal ──
                    _buildLegalCard(),

                    const SizedBox(height: 32),

                    // ── Footer ──
                    _buildFooter(),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero Section ────────────────────────────────────────────────

  Widget _buildHeroSection() {
    return Center(
      child: SizedBox(
        width: 160,
        height: 160,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer rotating ring
            AnimatedBuilder(
              animation: _rotateController,
              builder: (_, _) => Transform.rotate(
                angle: _rotateController.value * 2 * math.pi,
                child: CustomPaint(
                  size: const Size(160, 160),
                  painter: _ArcPainter(),
                ),
              ),
            ),
            // Pulsing glow
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, child) => Transform.scale(
                scale: _pulseAnim.value,
                child: child,
              ),
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0x3045FFB0),
                      Color(0x1000E5FF),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // App icon
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryNeon, AppTheme.primaryCyan],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryNeon.withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.black,
                size: 44,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Version Badge ────────────────────────────────────────────────

  Widget _buildVersionBadge() {
    return GestureDetector(
      onTap: _copyVersion,
      child: Column(
        children: [
          const Text(
            'Scan2Eat',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primaryNeon.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryNeon,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                const Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: AppTheme.primaryNeon,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 7),
                Icon(Icons.copy_rounded,
                    color: AppTheme.primaryNeon.withValues(alpha: 0.6), size: 12),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap to copy version',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.25), fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ── About Card ──────────────────────────────────────────────────

  Widget _buildAboutCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.info_outline_rounded,
            iconColor: AppTheme.primaryCyan,
            title: 'About the App',
          ),
          const SizedBox(height: 14),
          Text(
            'Scan2Eat is your intelligent nutrition companion — designed to make healthy eating effortless and insightful. Simply scan any food\'s barcode or take a photo, and get instant, detailed nutritional information powered by AI.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 13.5,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Track your daily intake, set personal nutrition goals, monitor hydration, and build healthy habits — all in one beautifully designed app.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 13.5,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  // ── Features Card ────────────────────────────────────────────────

  Widget _buildFeaturesCard() {
    final features = [
      (Icons.qr_code_scanner_rounded, AppTheme.primaryNeon, 'Barcode Scanner',
          'Scan any product barcode for instant nutrition data'),
      (Icons.camera_alt_outlined, AppTheme.primaryCyan, 'AI Food Recognition',
          'Identify food from photos using AI'),
      (Icons.track_changes_rounded, const Color(0xFFC79AFA), 'Goal Tracking',
          'Set and monitor daily calorie & macro targets'),
      (Icons.water_drop_outlined, const Color(0xFF4FC3F7), 'Hydration Monitor',
          'Track your daily water intake'),
      (Icons.bar_chart_rounded, AppTheme.warningOrange, 'Insights & Trends',
          'Visualize your nutrition patterns over time'),
      (Icons.people_outline_rounded, const Color(0xFFFF8A80), 'Community',
          'Connect with others on health journeys'),
    ];

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.star_outline_rounded,
            iconColor: AppTheme.warningOrange,
            title: 'Key Features',
          ),
          const SizedBox(height: 16),
          ...features.map((f) => _buildFeatureRow(f.$1, f.$2, f.$3, f.$4)),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(
      IconData icon, Color color, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11.5)),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded,
              color: color.withValues(alpha: 0.6), size: 16),
        ],
      ),
    );
  }

  // ── URL Launcher Helper ─────────────────────────────────────────

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: AppTheme.dangerRed, size: 18),
                SizedBox(width: 10),
                Text('Could not open link', style: TextStyle(color: Colors.white)),
              ],
            ),
            backgroundColor: const Color(0xFF161C24),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  // ── Help & Support Card ──────────────────────────────────────────

  Widget _buildHelpCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.headset_mic_rounded,
            iconColor: AppTheme.primaryNeon,
            title: 'Help & Support',
          ),
          const SizedBox(height: 16),
          Text(
            'Have a question or need help? We\'re here for you.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _launchUrl(
              'mailto:mayankrajdto@gmail.com?subject=Scan2Eat%20Support&body=Hi%20Mayank%2C%0A%0AI%20need%20help%20with%20Scan2Eat%3A%0A%0A',
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryNeon.withValues(alpha: 0.15),
                    AppTheme.primaryCyan.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNeon.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.email_outlined,
                        color: AppTheme.primaryNeon, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Email Support',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                        const SizedBox(height: 2),
                        Text('mayankrajdto@gmail.com',
                            style: TextStyle(
                                color: AppTheme.primaryNeon.withValues(alpha: 0.8),
                                fontSize: 11.5)),
                      ],
                    ),
                  ),
                  Icon(Icons.open_in_new_rounded,
                      color: AppTheme.primaryNeon.withValues(alpha: 0.6), size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Developer Card ───────────────────────────────────────────────

  Widget _buildDeveloperCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.handshake_outlined,
            iconColor: const Color(0xFFFF8A80),
            title: 'Developer',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryNeon, AppTheme.primaryCyan],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryNeon.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(Icons.person_rounded,
                    color: Colors.black, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mayank Raj',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    const SizedBox(height: 3),
                    Text('Data Scientist & Android Developer',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryNeon.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.primaryNeon.withValues(alpha: 0.25)),
                ),
                child: const Text('v1.0.0',
                    style: TextStyle(
                        color: AppTheme.primaryNeon,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                Icon(Icons.favorite_rounded,
                    color: const Color(0xFFFF8A80).withValues(alpha: 0.8),
                    size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Built with passion to help people lead healthier lives through smarter food choices.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Legal Card ───────────────────────────────────────────────────

  Widget _buildLegalCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.shield_outlined,
            iconColor: Colors.white38,
            title: 'Legal & Privacy',
          ),
          const SizedBox(height: 16),
          _buildLegalRow(
            Icons.privacy_tip_outlined,
            'Privacy Policy',
            'How we handle your data',
            () => _launchUrl('mailto:mayankrajdto@gmail.com?subject=Privacy%20Policy%20-%20Scan2Eat'),
          ),
          const Divider(color: Colors.white12, height: 24),
          _buildLegalRow(
            Icons.description_outlined,
            'Terms of Service',
            'Usage terms and conditions',
            () => _launchUrl('mailto:mayankrajdto@gmail.com?subject=Terms%20of%20Service%20-%20Scan2Eat'),
          ),
          const Divider(color: Colors.white12, height: 24),
          _buildLegalRow(
            Icons.policy_outlined,
            'Open Source Licenses',
            'Third-party libraries & licenses',
            () => _launchUrl('https://pub.dev/'),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '© 2025 Scan2Eat. All rights reserved. Nutritional data provided for informational purposes only. Always consult a healthcare professional for medical advice.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 10.5,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalRow(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(subtitle,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
        ],
      ),
    );
  }

  // ── Footer ───────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == 1 ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == 1
                    ? AppTheme.primaryNeon
                    : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Made with 💚 for your health',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.25),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Scan2Eat • 2025 • v1.0.0',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.15),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // ── Reusable Widgets ─────────────────────────────────────────────

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161C24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }

  Widget _buildCardHeader({
    required IconData icon,
    required Color iconColor,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

// ── Custom Painter for rotating arc ring ─────────────────────────

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final paint1 = Paint()
      ..shader = const SweepGradient(
        colors: [Color(0x0045FFB0), Color(0xFF45FFB0), Color(0x0000E5FF)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi * 1.6,
      false,
      paint1,
    );

    final paint2 = Paint()
      ..color = const Color(0x1545FFB0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, radius - 8, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
