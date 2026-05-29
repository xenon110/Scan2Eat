import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/app_theme.dart';
import '../../core/nutrition_log.dart';
import '../scan/scan_screen.dart';
import '../goals/goal_setting_screen.dart';
import '../../core/user_goals.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/user_stats.dart';
import '../insights/metabolic_screen.dart';
import '../../core/ai_service.dart';
import '../../core/notification_service.dart';
import 'notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  // Goals come from UserGoals singleton (set by user)
  MealPeriodGoal get _goals => UserGoals.instance.daily.total;
  double get _calGoal  => _goals.calories;
  double get _proGoal  => _goals.protein;
  double get _carbGoal => _goals.carbs;
  double get _fatGoal  => _goals.fat;
  int    get _waterGoal => _goals.water.round();

  double get _waterGoalLitres => _waterGoal * 0.25;
  bool _showAllMacros = false;

  List<Map<String, dynamic>> _insightsList = [];
  bool _isLoadingInsights = false;
  int _lastEntriesCountForInsights = -1;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);

    NutritionLog.instance.addListener(_onDataChanged);
    UserGoals.instance.addListener(_onDataChanged);
    UserStats.instance.addListener(_onDataChanged);
    NotificationService.instance.addListener(_onDataChanged);

    // Start listening if not already
    NutritionLog.instance.startListening();
    UserGoals.instance.startListening();
    UserStats.instance.startListening();
    NotificationService.instance.startListening();
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {});
      _checkAndFetchInsights();
    }
  }

  void _checkAndFetchInsights() async {
    final entries = NutritionLog.instance.todayEntries;
    if (entries.length != _lastEntriesCountForInsights && entries.isNotEmpty) {
      _lastEntriesCountForInsights = entries.length;
      setState(() => _isLoadingInsights = true);
      
      try {
        final newInsights = await AiService.instance.generateDailyInsights(
          NutritionLog.instance.todayTotals, 
          entries, 
          UserStats.instance.waterLitres,
        ).timeout(const Duration(seconds: 10));
        
        if (mounted) {
          setState(() {
            _insightsList = newInsights;
            _isLoadingInsights = false;
          });
        }
      } catch (e) {
        debugPrint('Failed to load insights: $e');
        if (mounted) {
          setState(() {
            _isLoadingInsights = false;
          });
        }
      }
    } else if (entries.isEmpty && _insightsList.isNotEmpty) {
      setState(() {
        _insightsList = [];
        _lastEntriesCountForInsights = 0;
      });
    }
  }

  @override
  void dispose() {
    NutritionLog.instance.removeListener(_onDataChanged);
    UserGoals.instance.removeListener(_onDataChanged);
    UserStats.instance.removeListener(_onDataChanged);
    NotificationService.instance.removeListener(_onDataChanged);
    _pulse.dispose();
    super.dispose();
  }

  List<FoodEntry> get _todayEntries => NutritionLog.instance.forDay(DateTime.now());
  NutrientTotals get _todayTotals => NutritionLog.instance.totalsFor(_todayEntries);

  int get _healthScore {
    if (_todayEntries.isEmpty) return 0;
    return (_todayEntries.map((e) => e.healthScore).reduce((a, b) => a + b) / _todayEntries.length).round();
  }

  @override
  Widget build(BuildContext context) {
    final totals = _todayTotals;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => setState(() {}),
          color: AppTheme.primaryNeon,
          backgroundColor: AppTheme.cardBackground,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────
                _buildHeader(),
                const SizedBox(height: 20),

                // ── Quick Actions ────────────────────────────────
                _buildQuickActions(context),
                const SizedBox(height: 20),

                // ── Today's Goal Card ───────────────────────────
                _buildTodayGoalCard(totals),
                const SizedBox(height: 14),

                // ── Water Tracker ────────────────────────────────
                _buildWaterTracker(),
                const SizedBox(height: 14),

                // ── Log Manually ─────────────────────────────────
                _buildLogManuallyButton(context),
                const SizedBox(height: 24),

                // ── AI Insights ──────────────────────────────────
                _buildSectionHeader('✨ AI Insights', '', null),
                const SizedBox(height: 12),
                _buildInsights(totals),

                // ── Streak card ──────────────────────────────────
                const SizedBox(height: 14),
                _buildStreakCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';
    final user = FirebaseAuth.instance.currentUser;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$greeting,', style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13)),
            Text('${user?.displayName?.split(' ').first ?? 'User'} 👋', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
          ],
        ),
        Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NotificationScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNeon.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.notifications_none_rounded, color: AppTheme.primaryNeon, size: 20),
                  ),
                ),
                if (NotificationService.instance.unreadCount > 0)
                  Positioned(
                    top: -2, right: -2,
                    child: FadeTransition(
                      opacity: Tween<double>(begin: 0.4, end: 1.0).animate(_pulse),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AppTheme.dangerRed, shape: BoxShape.circle),
                        child: Text(
                          NotificationService.instance.unreadCount.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ── Quick Actions ─────────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _actionChip(Icons.qr_code_scanner_rounded, 'Scan Food', AppTheme.primaryNeon, true, () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScanScreen()));
          }),
          const SizedBox(width: 10),
          _actionChip(Icons.track_changes_rounded, 'Set Goals', AppTheme.primaryCyan, false, () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GoalSettingScreen()));
          }),
          const SizedBox(width: 10),
          _actionChip(Icons.water_drop_rounded, 'Log Water', const Color(0xFF4FC3F7), false, () {
            final current = UserStats.instance.waterLitres;
            if (current < 4) {
              UserStats.instance.setWater(current + 0.25);
              if (current + 0.25 >= _waterGoalLitres && current < _waterGoalLitres) {
                 NotificationService.instance.createNotification('Hydration Goal Reached! 💧', 'You hit your daily water goal. Stay hydrated!', type: 'water');
              } else if (current + 0.25 <= 4) {
                 NotificationService.instance.createNotification('Water Logged 💧', 'You drank 250ml of water. Great job!', type: 'water');
              }
            }
          }),
          const SizedBox(width: 10),
          _actionChip(Icons.psychology_rounded, 'Ask AI', AppTheme.accentPurple, false, () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MetabolicScreen()));
          }),
        ],
      ),
    );
  }

  Widget _actionChip(IconData icon, String label, Color color, bool isPrimary, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? LinearGradient(colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.08)])
              : null,
          color: isPrimary ? null : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: isPrimary ? 0.5 : 0.2)),
          boxShadow: isPrimary ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 14)] : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12.5)),
          ],
        ),
      ),
    );
  }

  // ── Today's Overview Card ─────────────────────────────────────────────────

  Widget _buildTodayOverview(NutrientTotals t) {
    final score = _healthScore;
    final calProgress = (t.calories / _calGoal).clamp(0.0, 1.0);
    final scoreColor = score >= 75 ? AppTheme.primaryNeon : score >= 50 ? AppTheme.warningOrange : score > 0 ? AppTheme.dangerRed : Colors.white24;
    final scoreLabel = score >= 75 ? 'EXCELLENT' : score >= 50 ? 'MODERATE' : score > 0 ? 'POOR' : 'NO DATA';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF161C24), scoreColor.withValues(alpha: 0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scoreColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          // Score ring
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _RingPainter(
                    progress: score / 100.0,
                    color: scoreColor,
                    bg: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$score', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: scoreColor, height: 1)),
                    Text(scoreLabel, style: TextStyle(fontSize: 7, color: scoreColor.withValues(alpha: 0.8), letterSpacing: 1, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Today\'s Health Score', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${t.calories.round()} kcal', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('/ ${_calGoal.round()}', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: calProgress,
                    minHeight: 7,
                    backgroundColor: Colors.white.withValues(alpha: 0.07),
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _smallBadge('${_todayEntries.length} foods', Icons.fastfood_outlined, Colors.white54),
                    const SizedBox(width: 8),
                    _smallBadge('${(UserStats.instance.waterLitres / 0.25).round()}/$_waterGoal water', Icons.water_drop_outlined, Colors.blue),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallBadge(String label, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 11)),
      ],
    );
  }

  // ── Today's Goal Card ─────────────────────────────────────────────────────

  Widget _buildTodayGoalCard(NutrientTotals t) {
    final g = UserGoals.instance.daily.total;
    final allItems = [
      ('Calories', t.calories,              g.calories, 'kcal', const Color(0xFFFF9F43)),
      ('Protein',  t.protein,               g.protein,  'g',    const Color(0xFF45FFB0)),
      ('Carbs',    t.carbs,                 g.carbs,    'g',    const Color(0xFF00E5FF)),
      ('Fat',      t.fat,                   g.fat,      'g',    const Color(0xFFC79AFA)),
    ];
    // Only include nutrients where the goal is greater than 0
    final items = allItems.where((i) => i.$3 > 0).toList();
    final completedCount = items.where((i) => i.$2 >= i.$3).length;
    final allDone = completedCount == items.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: allDone
          ? AppTheme.glowCard(color: AppTheme.primaryNeon)
          : AppTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: (allDone ? AppTheme.primaryNeon : AppTheme.primaryCyan).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(allDone ? Icons.emoji_events_rounded : Icons.track_changes_rounded,
                      color: allDone ? AppTheme.primaryNeon : AppTheme.primaryCyan, size: 18),
                ),
                const SizedBox(width: 10),
                const Text("Today's Goals", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: allDone ? AppTheme.primaryNeon.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: allDone ? AppTheme.primaryNeon.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08)),
                ),
                child: Text('$completedCount/${items.length} done',
                    style: TextStyle(color: allDone ? AppTheme.primaryNeon : Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...items.map((item) {
            final progress = (item.$2 / item.$3).clamp(0.0, 1.0);
            final done = item.$2 >= item.$3;
            final color = item.$5;
            return Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: done ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                      border: Border.all(color: done ? color : Colors.white12),
                      boxShadow: done ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8)] : null,
                    ),
                    child: Icon(done ? Icons.check_rounded : Icons.remove, color: done ? color : Colors.white24, size: 13),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(width: 58, child: Text(item.$1, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12.5))),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress, minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                        valueColor: AlwaysStoppedAnimation<Color>(done ? color : color.withValues(alpha: 0.65)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${item.$2.round()}/${item.$3.round()}${item.$4}',
                      style: TextStyle(color: done ? color : Colors.white38, fontSize: 10.5, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Macro Bars ────────────────────────────────────────────────────────────

  Widget _buildMacroBars(NutrientTotals t) {
    final g = UserGoals.instance.daily.total;
    // All nutrients — auto-populated from every scanned & consumed food
    final allRows = [
      ('Calories', t.calories, _calGoal,  'kcal', const Color(0xFFFF9F43)),
      ('Protein',  t.protein,  _proGoal,  'g',    const Color(0xFF45FFB0)),
      ('Carbs',    t.carbs,    _carbGoal, 'g',    const Color(0xFF00E5FF)),
      ('Fat',      t.fat,      _fatGoal,  'g',    const Color(0xFFC79AFA)),
      ('Sugar',    t.sugar,    g.sugar,   'g',    const Color(0xFFFF4D4D)),
      ('Fiber',    t.fiber,    g.fiber,   'g',    const Color(0xFFFFD700)),
      ('Sodium',   t.sodium,   g.sodium,  'mg',   const Color(0xFFFFAA00)),
    ];

    // Default: show 4, expand to all on "See More"
    final visible = _showAllMacros ? allRows : allRows.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF161C24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Today\'s Nutrients', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              GestureDetector(
                onTap: () => setState(() => _showAllMacros = !_showAllMacros),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryNeon.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _showAllMacros ? 'See Less' : 'See More',
                        style: const TextStyle(color: AppTheme.primaryNeon, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        _showAllMacros ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: AppTheme.primaryNeon, size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...visible.map((r) => _macroRow(r.$1, r.$2, r.$3, r.$4, r.$5)),
          if (!_showAllMacros)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+ ${allRows.length - 4} more nutrients tracked',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _macroRow(String name, double val, double goal, String unit, Color color) {
    final p = (val / goal).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 52, child: Text(name, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: p,
                minHeight: 7,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: Text(
              '${val % 1 == 0 ? val.round() : val.toStringAsFixed(1)}/${ goal.round()}$unit',
              textAlign: TextAlign.right,
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ── Water Tracker (Litres) ─────────────────────────────────────

  Widget _buildWaterTracker() {
    final waterLitres = UserStats.instance.waterLitres;
    final progress = (waterLitres / _waterGoalLitres).clamp(0.0, 1.0);
    final done = waterLitres >= _waterGoalLitres;
    // Steps of 0.25L up to 4L
    final steps = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0, 3.5, 4.0];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: done
          ? AppTheme.glowCard(color: const Color(0xFF4FC3F7))
          : BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF4FC3F7).withValues(alpha: 0.2)),
              boxShadow: AppTheme.cardShadow(),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(Icons.water_drop, color: done ? Colors.blue : Colors.blue.shade300, size: 18),
                const SizedBox(width: 8),
                Text('Water Intake', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ]),
              Text(
                '${waterLitres.toStringAsFixed(2)} / ${_waterGoalLitres.toStringAsFixed(1)} L',
                style: TextStyle(color: done ? Colors.blue.shade300 : Colors.blue.shade300, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.blue.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(done ? Colors.blue : Colors.blue.shade400),
            ),
          ),
          const SizedBox(height: 14),
          // +/- controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Subtract button
              GestureDetector(
                onTap: () {
                  if (waterLitres > 0) UserStats.instance.setWater(double.parse((waterLitres - 0.25).clamp(0, 4).toStringAsFixed(2)));
                },
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.remove, color: Colors.blue, size: 18),
                ),
              ),
              const SizedBox(width: 16),
              // Amount display
              Column(
                children: [
                  Text(
                    '${waterLitres.toStringAsFixed(2)} L',
                    style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold,
                      color: done ? Colors.blue : Colors.white,
                    ),
                  ),
                  Text('of ${_waterGoalLitres.toStringAsFixed(1)} L goal',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                ],
              ),
              const SizedBox(width: 16),
              // Add button
              GestureDetector(
                onTap: () {
                  if (waterLitres < 4) {
                    final newVal = double.parse((waterLitres + 0.25).clamp(0, 4).toStringAsFixed(2));
                    UserStats.instance.setWater(newVal);
                    if (newVal >= _waterGoalLitres && waterLitres < _waterGoalLitres) {
                       NotificationService.instance.createNotification('Hydration Goal Reached! 💧', 'You hit your daily water goal. Stay hydrated!', type: 'water');
                    } else if (newVal <= 4) {
                       NotificationService.instance.createNotification('Water Logged 💧', 'You drank 250ml of water. Great job!', type: 'water');
                    }
                  }
                },
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.add, color: Colors.blue, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Quick-add pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: steps.map((s) {
                final active = waterLitres == s;
                return GestureDetector(
                  onTap: () => UserStats.instance.setWater(s),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: active ? Colors.blue.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: active ? Colors.blue : Colors.white12),
                    ),
                    child: Text('${s}L', style: TextStyle(color: active ? Colors.blue : Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            done ? '✓ Daily water goal reached! Great job!' : '${(_waterGoalLitres - waterLitres).toStringAsFixed(2)} L more to reach your goal',
            style: TextStyle(color: done ? AppTheme.primaryNeon : Colors.white.withValues(alpha: 0.4), fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ── Log Manually button + bottom sheet ─────────────────────────────

  Widget _buildLogManuallyButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showManualLogSheet(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryNeon.withValues(alpha: 0.12), AppTheme.primaryCyan.withValues(alpha: 0.06)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.4)),
          boxShadow: AppTheme.neonGlow(intensity: 0.1, blur: 12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_rounded, color: AppTheme.primaryNeon, size: 20),
            SizedBox(width: 10),
            Text('Log Food Manually', style: TextStyle(color: AppTheme.primaryNeon, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _showManualLogSheet(BuildContext context) {
    double calories = 0, protein = 0, carbs = 0, fat = 0, fiber = 0, sugar = 0, sodium = 0;
    String mealName = 'Manual Entry';
    File? selectedImage;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 16, top: 20, left: 20, right: 20),
          decoration: const BoxDecoration(
            color: Color(0xFF131A22),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                const Text('Log Manually', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                Text('Enter what you consumed and it will be added to today\'s report.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12)),
                const SizedBox(height: 20),

                // Image Picker
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                      if (picked != null) {
                        setSheet(() => selectedImage = File(picked.path));
                      }
                    },
                    child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.3)),
                        image: selectedImage != null ? DecorationImage(image: FileImage(selectedImage!), fit: BoxFit.cover) : null,
                      ),
                      child: selectedImage == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, color: AppTheme.primaryNeon, size: 28),
                                SizedBox(height: 8),
                                Text('Add Photo', style: TextStyle(color: AppTheme.primaryNeon, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Meal name
                _sheetTextField('Meal / Food Name', (v) => mealName = v.isEmpty ? 'Manual Entry' : v),
                const SizedBox(height: 16),

                // Nutrient sliders
                _sheetSlider(ctx, setSheet, 'Calories', calories, 0, 2000, 'kcal', const Color(0xFFFF9F43), (v) { calories = v; }),
                _sheetSlider(ctx, setSheet, 'Protein',  protein,  0, 150,  'g',    const Color(0xFF45FFB0), (v) { protein = v;  }),
                _sheetSlider(ctx, setSheet, 'Carbs',    carbs,    0, 400,  'g',    const Color(0xFF00E5FF), (v) { carbs = v;    }),
                _sheetSlider(ctx, setSheet, 'Fat',      fat,      0, 100,  'g',    const Color(0xFFC79AFA), (v) { fat = v;      }),
                _sheetSlider(ctx, setSheet, 'Sugar',    sugar,    0, 150,  'g',    const Color(0xFFFF4D4D), (v) { sugar = v;    }),
                _sheetSlider(ctx, setSheet, 'Fiber',    fiber,    0, 60,   'g',    const Color(0xFFFFD700), (v) { fiber = v;    }),
                _sheetSlider(ctx, setSheet, 'Sodium',   sodium,   0, 4000, 'mg',   const Color(0xFFFFAA00), (v) { sodium = v;   }),

                const SizedBox(height: 20),
                // Add to report button
                GestureDetector(
                  onTap: isUploading ? null : () async {
                    setSheet(() => isUploading = true);
                    
                    String imageUrl = '';
                    if (selectedImage != null) {
                      try {
                        final ref = FirebaseStorage.instance.ref().child('food_images').child('${DateTime.now().millisecondsSinceEpoch}.jpg');
                        await ref.putFile(selectedImage!);
                        imageUrl = await ref.getDownloadURL();
                      } catch (e) {
                        debugPrint('Upload failed: $e');
                      }
                    }

                    int newScore = 100;
                    if (sugar > 15) newScore -= 15;
                    if (sodium > 800) newScore -= 15;
                    if (calories > 800) newScore -= 10;
                    if (protein > 15) newScore += 10;
                    if (calories == 0 && protein == 0) newScore = 0;
                    newScore = newScore.clamp(0, 100);

                    NutritionLog.instance.add(FoodEntry(
                      name: mealName,
                      imageUrl: imageUrl,
                      consumedAt: DateTime.now(),
                      healthScore: newScore,
                      calories: calories, protein: protein, carbs: carbs,
                      sugar: sugar, fat: fat, fiber: fiber, sodium: sodium,
                    ));
                    
                    if (ctx.mounted) {
                      Navigator.of(ctx).pop();
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        backgroundColor: const Color(0xFF161C24),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        margin: const EdgeInsets.all(16),
                        content: Row(children: [
                          const Icon(Icons.check_circle, color: AppTheme.primaryNeon, size: 18),
                          const SizedBox(width: 10),
                          Text('"$mealName" added to today\'s report!', style: const TextStyle(color: Colors.white)),
                        ]),
                      ));
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.primaryNeon, AppTheme.primaryCyan]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: AppTheme.primaryNeon.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6))],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_chart, color: Colors.black, size: 20),
                        SizedBox(width: 10),
                        Text('Add to Report', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetTextField(String hint, ValueChanged<String> onChange) {
    return TextField(
      onChanged: onChange,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _sheetSlider(BuildContext ctx, StateSetter setSheet, String name, double value, double min, double max, String unit, Color color, ValueChanged<double> onChange) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Text('${value.round()} $unit', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(ctx).copyWith(
              activeTrackColor: color, inactiveTrackColor: color.withValues(alpha: 0.12),
              thumbColor: color, overlayColor: color.withValues(alpha: 0.15),
              trackHeight: 5, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: value.clamp(min, max), min: min, max: max,
              divisions: ((max - min) / (max > 500 ? 50 : 5)).round(),
              onChanged: (v) => setSheet(() => onChange(v)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Header ────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, String action, VoidCallback? onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        if (action.isNotEmpty)
          GestureDetector(
            onTap: onTap,
            child: Text(action, style: const TextStyle(color: AppTheme.primaryNeon, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  // ── Food Log Row ──────────────────────────────────────────────────────────

  Widget _buildFoodLogRow() {
    final entries = _todayEntries.reversed.take(4).toList();
    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final e = entries[i];
          final c = e.healthScore >= 75 ? AppTheme.primaryNeon : e.healthScore >= 50 ? AppTheme.warningOrange : AppTheme.dangerRed;
          return Container(
            width: 130,
            decoration: BoxDecoration(
              color: const Color(0xFF161C24),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(e.imageUrl, fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(color: Colors.white10, child: const Icon(Icons.fastfood, color: Colors.white24))),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
                              begin: Alignment.topCenter, end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${e.calories.round()} kcal', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10)),
                          Text('${e.healthScore}', style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── AI Insights ───────────────────────────────────────────────────────────

  Widget _buildInsights(NutrientTotals t) {
    if (_isLoadingInsights) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryNeon),
        ),
      );
    }

    final insights = List<Map<String, dynamic>>.from(_insightsList);

    if (insights.isEmpty) {
      insights.add({'icon': Icons.check_circle_outline, 'color': AppTheme.primaryNeon,
        'title': 'On Track!', 'body': 'Your nutrition looks balanced today. Keep maintaining these healthy habits!'});
    }

    return Column(
      children: insights.take(3).map((ins) {
        final color = ins['color'] as Color;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.1), AppTheme.cardBackground],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 16)],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Coloured left accent
              Container(
                width: 3,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(ins['icon'] as IconData, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ins['title'] as String,
                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13.5)),
                    const SizedBox(height: 5),
                    Text(ins['body'] as String,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12.5, height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Streak Card ───────────────────────────────────────────────────────────

  Widget _buildStreakCard() {
    final streak = UserStats.instance.streak;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2A1A), Color(0xFF0F1E2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.25)),
        boxShadow: AppTheme.neonGlow(intensity: 0.12, blur: 20),
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryNeon.withValues(alpha: 0.2), AppTheme.primaryCyan.withValues(alpha: 0.1)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.3)),
            ),
            child: const Center(child: Text('🔥', style: TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (b) => AppTheme.neonGradient.createShader(b),
                  child: Text('$streak-Day Streak! 🏆',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(height: 5),
                Text('Keep scanning & logging to maintain your streak!',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, height: 1.4)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryNeon.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.3)),
            ),
            child: Text('$streak', style: const TextStyle(color: AppTheme.primaryNeon, fontWeight: FontWeight.bold, fontSize: 20)),
          ),
        ],
      ),
    );
  }
}

// ── Ring Painter ──────────────────────────────────────────────────────────────

class ArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  ArcPainter({required this.progress, required this.color, required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    const sw = 14.0;
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width / 2, size.height / 2) - sw / 2;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), math.pi * 0.75, math.pi * 1.5, false,
        Paint()..color = backgroundColor..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.round);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), math.pi * 0.75, math.pi * 1.5 * progress, false,
        Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bg;
  _RingPainter({required this.progress, required this.color, required this.bg});

  @override
  void paint(Canvas canvas, Size size) {
    const sw = 9.0;
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - sw / 2;
    canvas.drawCircle(c, r, Paint()..color = bg..style = PaintingStyle.stroke..strokeWidth = sw);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, 2 * math.pi * progress, false,
        Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}
