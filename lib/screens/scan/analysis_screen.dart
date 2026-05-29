import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/app_theme.dart';
import '../../core/nutrition_log.dart';
import '../../core/ai_service.dart';
import '../journal/alternatives_screen.dart';
import '../journal/nutrition_report_screen.dart';

// ─── Screen ──────────────────────────────────────────────────────────────────

class AnalysisScreen extends StatefulWidget {
  final FoodAnalysisResult result;
  final Uint8List? imageBytes;

  const AnalysisScreen({
    super.key,
    required this.result,
    this.imageBytes,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with TickerProviderStateMixin {
  late AnimationController _scoreController;
  late AnimationController _barController;
  late Animation<double> _scoreAnim;
  late Animation<double> _barAnim;

  Color _getColorForProgress(double p) {
    if (p > 0.8) return AppTheme.dangerRed;
    if (p > 0.5) return const Color(0xFFFF9F43);
    return const Color(0xFF45FFB0);
  }

  IconData _getIconForLevel(String level) {
    if (level.toLowerCase() == 'high') return Icons.warning_amber_rounded;
    if (level.toLowerCase() == 'moderate') return Icons.info_outline;
    return Icons.check_circle_outline;
  }

  @override
  void initState() {
    super.initState();
    _scoreController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _barController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

    _scoreAnim = CurvedAnimation(parent: _scoreController, curve: Curves.easeOut);
    _barAnim = CurvedAnimation(parent: _barController, curve: Curves.easeOutCubic);

    Future.delayed(const Duration(milliseconds: 300), () {
      _scoreController.forward();
      _barController.forward();
    });
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _barController.dispose();
    super.dispose();
  }

  Color get _scoreColor {
    final s = widget.result.healthScore;
    if (s >= 75) return AppTheme.primaryNeon;
    if (s >= 50) return AppTheme.warningOrange;
    return AppTheme.dangerRed;
  }

  String get _scoreLabel {
    final s = widget.result.healthScore;
    if (s >= 75) return 'EXCELLENT';
    if (s >= 50) return 'MODERATE';
    if (s >= 25) return 'POOR';
    return 'AVOID';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            widget.result.name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: AppTheme.primaryNeon,
            labelColor: AppTheme.primaryNeon,
            unselectedLabelColor: Colors.white54,
            indicatorWeight: 3,
            tabs: const [
              Tab(icon: Icon(Icons.bar_chart), text: 'Nutrition'),
              Tab(icon: Icon(Icons.biotech), text: 'Impact'),
              Tab(icon: Icon(Icons.eco), text: 'Alternatives'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildNutritionTab(),
            _buildImpactTab(),
            _buildAlternativesTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            NutritionLog.instance.add(FoodEntry(
              name: widget.result.name,
              imageUrl: 'https://image.pollinations.ai/prompt/${Uri.encodeComponent(widget.result.name + ' food')}?width=400&height=300&nologo=true',
              consumedAt: DateTime.now(),
              healthScore: widget.result.healthScore,
              calories: widget.result.calories,
              protein: widget.result.protein,
              carbs: widget.result.carbs,
              sugar: widget.result.sugar,
              fat: widget.result.fat,
              fiber: widget.result.fiber,
              sodium: widget.result.sodium,
              vitaminD: widget.result.vitaminD,
              iron: widget.result.iron,
              calcium: widget.result.calcium,
            ));

            // Navigate to the journal and clear the scan stack
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const NutritionReportScreen()),
              (route) => route.isFirst,
            );
          },
          backgroundColor: AppTheme.primaryNeon,
          icon: const Icon(Icons.restaurant, color: Colors.black),
          label: const Text(
            'I Ate This',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHealthScoreCard(),
          const SizedBox(height: 24),
          _buildAiSummaryCard(),
          const SizedBox(height: 24),
          _buildSectionTitle('Nutritional Breakdown', Icons.bar_chart_rounded, AppTheme.primaryCyan),
          const SizedBox(height: 16),
          _buildNutrientCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildImpactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Bodily Impact & Risks', Icons.warning_amber_rounded, AppTheme.dangerRed),
          const SizedBox(height: 12),
          Text(
            'Scientific analysis of how these ingredients affect your body.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
          ),
          const SizedBox(height: 16),
          _buildRiskLegend(),
          const SizedBox(height: 16),
          if (widget.result.risks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text('No major risks detected!', style: TextStyle(color: AppTheme.primaryNeon.withValues(alpha: 0.8))),
              ),
            )
          else
            ...widget.result.risks.map((r) => _buildRiskItem(r)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAlternativesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Healthier Alternatives', Icons.eco_outlined, AppTheme.primaryNeon),
          const SizedBox(height: 12),
          if (widget.result.alternatives.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text('No alternatives needed. This is a great choice!', style: TextStyle(color: AppTheme.primaryNeon.withValues(alpha: 0.8))),
              ),
            )
          else
            ...widget.result.alternatives.map((alt) => _buildAlternativeCard(alt)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAlternativeCard(AnalysisAlternative alt) {
    return GestureDetector(
      onTap: () => _showAlternativeDetailBottomSheet(context, alt),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF161C24),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  Image.network(
                    alt.imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryNeon.withValues(alpha: 0.15),
                            AppTheme.primaryCyan.withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.restaurant_menu_rounded, color: AppTheme.primaryNeon.withValues(alpha: 0.5), size: 32),
                            const SizedBox(height: 6),
                            Text(
                              alt.name,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryNeon.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${alt.score} SCORE', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alt.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(alt.subtitle, style: TextStyle(color: AppTheme.primaryNeon.withValues(alpha: 0.8), fontSize: 12)),
                  const SizedBox(height: 12),
                  Text(alt.reason, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAlternativeDetailBottomSheet(BuildContext context, AnalysisAlternative alt) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              color: const Color(0xFF161C24).withValues(alpha: 0.92),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 14,
                bottom: MediaQuery.of(context).padding.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          alt.imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.white.withValues(alpha: 0.05),
                            child: const Icon(Icons.eco_outlined, color: AppTheme.primaryNeon, size: 36),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryNeon.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                '${alt.score} HEALTH SCORE',
                                style: const TextStyle(
                                  color: AppTheme.primaryNeon,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              alt.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              alt.subtitle,
                              style: TextStyle(
                                color: AppTheme.primaryNeon.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 20),
                  const Text(
                    'Why this alternative?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    alt.reason,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (alt.tag.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryCyan.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.primaryCyan.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            alt.tag,
                            style: const TextStyle(
                              color: AppTheme.primaryCyan,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (alt.price.isNotEmpty)
                        Text(
                          'Est. Price: ${alt.price}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryNeon, AppTheme.primaryCyan],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryNeon.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'GREAT, THANKS!',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHealthScoreCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161C24),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _scoreColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: _scoreColor.withValues(alpha: 0.08), blurRadius: 20, spreadRadius: 4),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Animated ring
          AnimatedBuilder(
            animation: _scoreAnim,
            builder: (context, _) {
              return SizedBox(
                width: 85,
                height: 85,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: ArcPainter(
                        progress: _scoreAnim.value * (widget.result.healthScore / 100),
                        color: _scoreColor,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(widget.result.healthScore * _scoreAnim.value).round()}',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _scoreColor, height: 1.1),
                        ),
                        Text('/100', style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.5))),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _scoreColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_scoreLabel, style: TextStyle(color: _scoreColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 10),
                const Text('Health Score', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  widget.result.summary,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 11, height: 1.45),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section Title ────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ─── Nutrient Card ────────────────────────────────────────────────────────

  Widget _buildNutrientCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161C24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Macro pills row
          Row(
            children: [
              _buildMacroPill('PROTEIN', '${widget.result.protein.round()}g', const Color(0xFF45FFB0)),
              const SizedBox(width: 6),
              _buildMacroPill('CARBS', '${widget.result.carbs.round()}g', const Color(0xFF00E5FF)),
              const SizedBox(width: 6),
              _buildMacroPill('FAT', '${widget.result.fat.round()}g', const Color(0xFFC79AFA)),
              const SizedBox(width: 6),
              _buildMacroPill('FIBER', '${widget.result.fiber.round()}g', const Color(0xFFFF9F43)),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 16),
          ...widget.result.nutrients.map((n) => _buildNutrientRow(n)),
        ],
      ),
    );
  }

  Widget _buildMacroPill(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.6),
                fontSize: 8,
                letterSpacing: 0.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientRow(AnalysisNutrient n) {
    final color = _getColorForProgress(n.progress);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                n.name,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                n.dailyValue,
                style: TextStyle(
                  color: n.progress > 0.5 ? color : Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: n.progress > 0.5 ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: _barAnim,
            builder: (context, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: n.progress * _barAnim.value,
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Risk Legend ─────────────────────────────────────────────────────────

  Widget _buildRiskLegend() {
    return Row(
      children: [
        _buildLegendDot('High Risk', AppTheme.dangerRed),
        const SizedBox(width: 16),
        _buildLegendDot('Moderate', AppTheme.warningOrange),
        const SizedBox(width: 16),
        _buildLegendDot('Safe', AppTheme.primaryNeon),
      ],
    );
  }

  Widget _buildLegendDot(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
      ],
    );
  }

  // ─── Risk Item ────────────────────────────────────────────────────────────

  Widget _buildRiskItem(AnalysisRisk risk) {
    Color color;
    Color bgColor;
    final level = risk.level.toLowerCase();
    
    if (level == 'high') {
      color = AppTheme.dangerRed;
      bgColor = const Color(0xFF2A1010);
    } else if (level == 'moderate') {
      color = AppTheme.warningOrange;
      bgColor = const Color(0xFF251A08);
    } else {
      color = AppTheme.primaryNeon;
      bgColor = const Color(0xFF0C2218);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(_getIconForLevel(risk.level), color: color, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(risk.name, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        level == 'high' ? '⚠ HIGH' : level == 'moderate' ? '◆ MOD' : '✓ SAFE',
                        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(risk.reason, style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 12, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── AI Summary ───────────────────────────────────────────────────────────

  Widget _buildAiSummaryCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryCyan.withValues(alpha: 0.12),
            const Color(0xFF161C24),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryCyan.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.psychology, color: AppTheme.primaryCyan, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Scan2Eat Summary', style: TextStyle(color: AppTheme.primaryCyan, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.result.summary,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.result.tags.map((t) => _buildAiTag(t, AppTheme.primaryCyan)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAiTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }

  // ─── CTA Buttons ─────────────────────────────────────────────────────────

  // _buildAlternativesButton removed since alternatives are now their own tab.

  // _onConsumed logic is now in PostScanActionScreen
}

// ─── Custom Ring Painter ──────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bg;

  _RingPainter({required this.progress, required this.color, required this.bg});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 9.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;

    final bgPaint = Paint()
      ..color = bg
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const start = -math.pi / 2;
    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}
