import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/app_theme.dart';
import '../../core/nutrition_log.dart';
import '../../core/user_goals.dart';

class NutritionReportScreen extends StatefulWidget {
  const NutritionReportScreen({super.key});

  @override
  State<NutritionReportScreen> createState() => _NutritionReportScreenState();
}

class _NutritionReportScreenState extends State<NutritionReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _now = DateTime.now();

  // Goals come from UserGoals singleton
  MealPeriodGoal get _goal {
    switch (_tab.index) {
      case 0:  return UserGoals.instance.daily.total;
      case 1:  return UserGoals.instance.weekly;
      default: return UserGoals.instance.monthly;
    }
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {}));
    NutritionLog.instance.addListener(_onLogUpdated);
  }

  void _onLogUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    NutritionLog.instance.removeListener(_onLogUpdated);
    _tab.dispose();
    super.dispose();
  }

  List<FoodEntry> get _entries {
    switch (_tab.index) {
      case 0: return NutritionLog.instance.forDay(_now);
      case 1: return NutritionLog.instance.forWeek(_now);
      default: return NutritionLog.instance.forMonth(_now);
    }
  }

  String get _periodLabel => ['Today', 'This Week', 'This Month'][_tab.index];
  // int get _periodDays => [1, 7, 30][_tab.index];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NutritionLog.instance,
      builder: (context, _) {
        final entries = _entries;
        final totals = NutritionLog.instance.totalsFor(entries);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('My Nutrition Journal',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF161C24),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: TabBar(
              controller: _tab,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
              labelColor: Colors.black,
              unselectedLabelColor: AppTheme.textSecondary,
              indicator: BoxDecoration(
                color: AppTheme.primaryNeon,
                borderRadius: BorderRadius.circular(24),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Day'),
                Tab(text: 'Week'),
                Tab(text: 'Month'),
              ],
            ),
          ),
        ),
      ),
      body: entries.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryHeader(entries, totals),
                  const SizedBox(height: 20),
                  _buildCalorieRing(totals),
                  const SizedBox(height: 20),
                  _buildSectionLabel('Macronutrients', AppTheme.primaryNeon),
                  const SizedBox(height: 12),
                  _buildNutrientBar('Protein', totals.protein, _goal.protein, 'g', const Color(0xFF45FFB0)),
                  _buildNutrientBar('Carbs', totals.carbs, _goal.carbs, 'g', const Color(0xFF00E5FF)),
                  _buildNutrientBar('Sugar', totals.sugar, 50.0 * (_tab.index == 0 ? 1 : _tab.index == 1 ? 7 : 30), 'g', const Color(0xFFFF4D4D)),
                  _buildNutrientBar('Fat', totals.fat, _goal.fat, 'g', const Color(0xFFC79AFA)),
                  _buildNutrientBar('Fiber', totals.fiber, _goal.fiber, 'g', const Color(0xFFFF9F43)),
                  const SizedBox(height: 20),
                  _buildSectionLabel('Minerals & Sodium', AppTheme.primaryCyan),
                  const SizedBox(height: 12),
                  _buildNutrientBar('Sodium', totals.sodium, 2300.0 * (_tab.index == 0 ? 1 : _tab.index == 1 ? 7 : 30), 'mg', const Color(0xFFFFAA00)),
                  const SizedBox(height: 20),
                  _buildSectionLabel(
                    'Food Log ($_periodLabel)', 
                    Colors.white,
                    action: GestureDetector(
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppTheme.cardBackground,
                            title: const Text('Clear All Logs?', style: TextStyle(color: Colors.white)),
                            content: const Text('This will permanently delete all your food logs from the backend. This cannot be undone.', style: TextStyle(color: Colors.white70)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.white))),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await NutritionLog.instance.clearAllLogs();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.warningOrange.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check_circle_outline_rounded, color: AppTheme.warningOrange, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'All logs cleared permanently.',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF1C2534),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(color: AppTheme.warningOrange, width: 1),
                                ),
                                margin: const EdgeInsets.all(16),
                                elevation: 0,
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.dangerRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.dangerRed.withValues(alpha: 0.3)),
                        ),
                        child: const Text('Clear Logs', style: TextStyle(color: AppTheme.dangerRed, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...entries.reversed.map((e) => _buildLogItem(e)),
                ],
              ),
            ),
        );
      },
    );
  }

  // ── Summary header ─────────────────────────────────────────────────────────

  Widget _buildSummaryHeader(List<FoodEntry> entries, NutrientTotals t) {
    final avgScore = entries.isEmpty
        ? 0
        : (entries.map((e) => e.healthScore).reduce((a, b) => a + b) / entries.length).round();

    return Row(
      children: [
        Expanded(child: _buildStatCard('${t.calories.round()}', 'kcal $_periodLabel', AppTheme.primaryNeon)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard('${entries.length}', 'Foods Logged', AppTheme.primaryCyan)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard('$avgScore', 'Avg Score', avgScore >= 70 ? AppTheme.primaryNeon : AppTheme.dangerRed)),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.14), AppTheme.cardBackground],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 16)],
      ),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (b) => LinearGradient(colors: [color, color.withValues(alpha: 0.7)]).createShader(b),
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10.5), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ── Calorie ring ───────────────────────────────────────────────────────────

  Widget _buildCalorieRing(NutrientTotals t) {
    final goal = _goal.calories;
    final progress = (t.calories / goal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2639), AppTheme.cardBackground],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.2)),
        boxShadow: AppTheme.neonGlow(intensity: 0.08, blur: 24),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: _RingPainter(progress: progress, color: AppTheme.primaryNeon, bg: Colors.white.withValues(alpha: 0.06))),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShaderMask(
                      shaderCallback: (b) => AppTheme.neonGradient.createShader(b),
                      child: Text('${t.calories.round()}',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, height: 1)),
                    ),
                    Text('kcal', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${(progress * 100).round()}% of goal',
                    style: const TextStyle(color: AppTheme.primaryNeon, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 5),
                Text('Goal: ${goal.round()} kcal',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                const SizedBox(height: 16),
                _miniPill('${t.protein.round()}g Protein', const Color(0xFF45FFB0)),
                const SizedBox(height: 7),
                _miniPill('${t.carbs.round()}g Carbs', const Color(0xFF00E5FF)),
                const SizedBox(height: 7),
                _miniPill('${t.fat.round()}g Fat', const Color(0xFFC79AFA)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  // ── Nutrient bar ──────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label, Color color, {Widget? action}) {
    return Row(
      children: [
        Container(width: 3, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        if (action != null) ...[
          const Spacer(),
          action,
        ]
      ],
    );
  }

  Widget _buildNutrientBar(String name, double amount, double goal, String unit, Color color) {
    final progress = (amount / goal).clamp(0.0, 1.0);
    final isOver = amount > goal;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
              Row(
                children: [
                  Text('${amount % 1 == 0 ? amount.round() : amount.toStringAsFixed(1)}$unit',
                      style: TextStyle(color: isOver ? AppTheme.dangerRed : color, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(' / ${goal.round()}$unit', style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11)),
                  if (isOver) const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.arrow_upward, color: AppTheme.dangerRed, size: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.07),
              valueColor: AlwaysStoppedAnimation<Color>(isOver ? AppTheme.dangerRed : color),
            ),
          ),
        ],
      ),
    );
  }

  // ── Food log item ─────────────────────────────────────────────────────────

  Widget _buildLogItem(FoodEntry e) {
    final Color scoreColor = e.healthScore >= 75
        ? AppTheme.primaryNeon
        : e.healthScore >= 50
            ? AppTheme.warningOrange
            : AppTheme.dangerRed;

    final time = '${e.consumedAt.hour.toString().padLeft(2, '0')}:${e.consumedAt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: AppTheme.cardShadow(),
      ),
      child: Row(
        children: [
          // Health-score left accent bar
          Container(
            width: 4,
            height: 72,
            margin: const EdgeInsets.only(left: 0),
            decoration: BoxDecoration(
              color: scoreColor,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
              boxShadow: [BoxShadow(color: scoreColor.withValues(alpha: 0.5), blurRadius: 8)],
            ),
          ),
          // Thumbnail
          Padding(
            padding: const EdgeInsets.all(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                e.imageUrl,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.fastfood_rounded, color: scoreColor.withValues(alpha: 0.6), size: 24),
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)),
                const SizedBox(height: 4),
                Text(
                  '${e.calories.round()} kcal  ·  ${e.protein.toStringAsFixed(1)}g protein  ·  $time',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11.5),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: scoreColor.withValues(alpha: 0.4)),
                boxShadow: [BoxShadow(color: scoreColor.withValues(alpha: 0.2), blurRadius: 8)],
              ),
              child: Text('${e.healthScore}', style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    IconData icon;
    if (_tab.index == 0) {
      icon = Icons.calendar_today_rounded;
    } else if (_tab.index == 1) {
      icon = Icons.calendar_view_week_rounded;
    } else {
      icon = Icons.calendar_month_rounded;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryNeon.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.1)),
              ),
              child: Icon(icon, color: AppTheme.primaryNeon.withValues(alpha: 0.6), size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'Fresh Start $_periodLabel!',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'You have not consumed anything ${_periodLabel.toLowerCase()} yet.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161C24),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppTheme.primaryCyan, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your daily logs automatically pipeline into your weekly and monthly reports. Scan a food to get started!',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ring Painter ──────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bg;
  _RingPainter({required this.progress, required this.color, required this.bg});

  @override
  void paint(Canvas canvas, Size size) {
    const sw = 10.0;
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - sw / 2;
    canvas.drawCircle(c, r, Paint()..color = bg..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.round);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}
