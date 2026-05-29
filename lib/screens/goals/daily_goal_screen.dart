import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/app_theme.dart';
import '../../core/user_goals.dart';

class DailyGoalScreen extends StatefulWidget {
  const DailyGoalScreen({super.key});

  @override
  State<DailyGoalScreen> createState() => _DailyGoalScreenState();
}

class _DailyGoalScreenState extends State<DailyGoalScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  // 0=period select, 1=morning, 2=afternoon, 3=evening, 4=summary
  int _step = 0;
  int _periodIndex = -1; // which period the user tapped

  // Local copies so user can cancel
  late MealPeriodGoal _morning;
  late MealPeriodGoal _afternoon;
  late MealPeriodGoal _evening;

  final _periods = ['Morning', 'Afternoon', 'Evening'];
  final _periodIcons = [Icons.wb_sunny_outlined, Icons.wb_cloudy_outlined, Icons.nights_stay_outlined];
  final _periodColors = [const Color(0xFFFFD700), const Color(0xFF00E5FF), const Color(0xFFC79AFA)];
  final _periodTimes = ['6 AM – 12 PM', '12 PM – 6 PM', '6 PM – 11 PM'];

  @override
  void initState() {
    super.initState();
    final d = UserGoals.instance.daily;
    _morning = MealPeriodGoal(
      water: d.morning.water, protein: d.morning.protein, carbs: d.morning.carbs,
      fat: d.morning.fat, fiber: d.morning.fiber, calories: d.morning.calories,
    );
    _afternoon = MealPeriodGoal(
      water: d.afternoon.water, protein: d.afternoon.protein, carbs: d.afternoon.carbs,
      fat: d.afternoon.fat, fiber: d.afternoon.fiber, calories: d.afternoon.calories,
    );
    _evening = MealPeriodGoal(
      water: d.evening.water, protein: d.evening.protein, carbs: d.evening.carbs,
      fat: d.evening.fat, fiber: d.evening.fiber, calories: d.evening.calories,
    );

    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  MealPeriodGoal get _currentGoal {
    if (_periodIndex == 0) return _morning;
    if (_periodIndex == 1) return _afternoon;
    return _evening;
  }

  void _setCurrentGoal(MealPeriodGoal g) {
    setState(() {
      if (_periodIndex == 0) {
        _morning = g;
      } else if (_periodIndex == 1) {
        _afternoon = g;
      } else {
        _evening = g;
      }
    });
  }

  void _animateTo(int step) {
    _fadeCtrl.reverse().then((_) {
      setState(() => _step = step);
      _fadeCtrl.forward();
    });
  }

  Future<void> _save() async {
    final d = UserGoals.instance.daily;
    d.morning = _morning;
    d.afternoon = _afternoon;
    d.evening = _evening;

    final total = d.total;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'calorieGoal': total.calories,
        'proteinGoal': total.protein,
        'carbGoal': total.carbs,
        'fatGoal': total.fat,
      }, SetOptions(merge: true));
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF161C24),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.primaryNeon, size: 18),
            SizedBox(width: 10),
            Text('Daily goals saved!', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
          onPressed: () {
            if (_step == 0) {
              Navigator.of(context).pop();
            } else {
              _animateTo(0);
            }
          },
        ),
        title: Text(
          _step == 0 ? 'Daily Goal' : _step == 4 ? 'Summary' : '${_periods[_periodIndex]} Goal',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (_step == 4)
            TextButton(
              onPressed: _save,
              child: const Text('Save', style: TextStyle(color: AppTheme.primaryNeon, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fade,
        child: _step == 0
            ? _buildPeriodSelect()
            : _step == 4
                ? _buildSummary()
                : _buildPeriodEditor(),
      ),
    );
  }

  // ── Step 0: Choose period ─────────────────────────────────────────────────

  Widget _buildPeriodSelect() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Which part of the day do you want to set goals for?',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),

          ...List.generate(3, (i) {
            final goal = [_morning, _afternoon, _evening][i];
            final color = _periodColors[i];
            return GestureDetector(
              onTap: () {
                _periodIndex = i;
                _animateTo(1);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF161C24),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                      child: Icon(_periodIcons[i], color: color, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_periods[i], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 3),
                          Text(_periodTimes[i], style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            children: [
                              _miniChip('${goal.calories.round()} kcal', const Color(0xFFFF9F43)),
                              _miniChip('${goal.water.round()} 💧', Colors.blue),
                              _miniChip('${goal.protein.round()}g protein', const Color(0xFF45FFB0)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: color, size: 14),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 10),
          // View summary button
          GestureDetector(
            onTap: () => _animateTo(4),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primaryNeon, AppTheme.primaryCyan]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppTheme.primaryNeon.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart_rounded, color: Colors.black, size: 18),
                  SizedBox(width: 8),
                  Text('View Total Summary', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
  );

  // ── Step 1/2/3: Period editor ──────────────────────────────────────────────

  Widget _buildPeriodEditor() {
    final color = _periodColors[_periodIndex];
    final goal = _currentGoal;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.3))),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_periodIcons[_periodIndex], color: color, size: 16),
                const SizedBox(width: 6),
                Text('${_periods[_periodIndex]} · ${_periodTimes[_periodIndex]}',
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Water ───────────────────────────────────────────
          _buildSectionCard(
            icon: Icons.water_drop_rounded,
            color: Colors.blue,
            title: 'Water Goal',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${goal.water.round()} glasses', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${(goal.water * 250).round()} ml', style: TextStyle(color: Colors.blue.shade300, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(8, (i) => Expanded(
                    child: GestureDetector(
                      onTap: () => _setCurrentGoal(goal.copyWith(water: (i + 1).toDouble())),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 36,
                        decoration: BoxDecoration(
                          color: i < goal.water ? Colors.blue.shade400 : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: i < goal.water ? Colors.blue.shade300 : Colors.transparent),
                        ),
                        child: Icon(Icons.water_drop, color: i < goal.water ? Colors.white : Colors.white12, size: 15),
                      ),
                    ),
                  )),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Nutrients ────────────────────────────────────────
          _buildSectionCard(
            icon: Icons.bar_chart_rounded,
            color: AppTheme.primaryNeon,
            title: 'Nutrient Goals',
            child: Column(
              children: [
                _buildSlider('Calories', goal.calories, 0, 1200, 'kcal', const Color(0xFFFF9F43),
                    (v) => _setCurrentGoal(goal.copyWith(calories: v))),
                _buildSlider('Protein', goal.protein, 0, 80, 'g', const Color(0xFF45FFB0),
                    (v) => _setCurrentGoal(goal.copyWith(protein: v))),
                _buildSlider('Carbs', goal.carbs, 0, 200, 'g', const Color(0xFF00E5FF),
                    (v) => _setCurrentGoal(goal.copyWith(carbs: v))),
                _buildSlider('Fat', goal.fat, 0, 60, 'g', const Color(0xFFC79AFA),
                    (v) => _setCurrentGoal(goal.copyWith(fat: v))),
                _buildSlider('Fiber', goal.fiber, 0, 30, 'g', const Color(0xFFFFD700),
                    (v) => _setCurrentGoal(goal.copyWith(fiber: v))),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Next / Done button
          GestureDetector(
            onTap: () {
              if (_periodIndex < 2) {
                _periodIndex++;
                _animateTo(1);
              } else {
                _animateTo(4);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.6)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _periodIndex < 2 ? 'Next: ${_periods[_periodIndex + 1]}' : 'View Summary',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, color: Colors.black, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required IconData icon, required Color color, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF161C24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSlider(String name, double value, double min, double max, String unit, Color color, ValueChanged<double> onChange) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.12),
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.15),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(value: value.clamp(min, max), min: min, max: max, divisions: ((max - min) / 5).round(), onChanged: onChange),
          ),
        ],
      ),
    );
  }

  // ── Step 4: Summary ───────────────────────────────────────────────────────

  Widget _buildSummary() {
    final total = MealPeriodGoal.combine([_morning, _afternoon, _evening]);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Here\'s your full daily goal breakdown across all three periods.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13, height: 1.5)),
          const SizedBox(height: 20),

          // Period cards
          ...[
            (_morning, 'Morning', _periodIcons[0], _periodColors[0], _periodTimes[0]),
            (_afternoon, 'Afternoon', _periodIcons[1], _periodColors[1], _periodTimes[1]),
            (_evening, 'Evening', _periodIcons[2], _periodColors[2], _periodTimes[2]),
          ].map((p) => _buildSummaryPeriodCard(p.$1, p.$2, p.$3, p.$4, p.$5)),

          // Total
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryNeon.withValues(alpha: 0.15), const Color(0xFF161C24)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.summarize_outlined, color: AppTheme.primaryNeon, size: 18),
                  SizedBox(width: 8),
                  Text('Daily Total', style: TextStyle(color: AppTheme.primaryNeon, fontWeight: FontWeight.bold, fontSize: 16)),
                ]),
                const SizedBox(height: 16),
                _summaryRow('Calories', '${total.calories.round()} kcal', const Color(0xFFFF9F43)),
                _summaryRow('Water', '${total.water.round()} glasses (${(total.water * 250).round()} ml)', Colors.blue),
                _summaryRow('Protein', '${total.protein.round()} g', const Color(0xFF45FFB0)),
                _summaryRow('Carbs', '${total.carbs.round()} g', const Color(0xFF00E5FF)),
                _summaryRow('Fat', '${total.fat.round()} g', const Color(0xFFC79AFA)),
                _summaryRow('Fiber', '${total.fiber.round()} g', const Color(0xFFFFD700)),
              ],
            ),
          ),

          const SizedBox(height: 20),
          GestureDetector(
            onTap: _save,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primaryNeon, AppTheme.primaryCyan]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppTheme.primaryNeon.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.black, size: 20),
                  SizedBox(width: 10),
                  Text('Save Goals', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPeriodCard(MealPeriodGoal g, String name, IconData icon, Color color, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161C24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 8),
            Text('$name · $time', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 6,
            children: [
              _miniSummaryChip('${g.calories.round()} kcal', const Color(0xFFFF9F43)),
              _miniSummaryChip('${g.water.round()} 💧 water', Colors.blue),
              _miniSummaryChip('${g.protein.round()}g protein', const Color(0xFF45FFB0)),
              _miniSummaryChip('${g.carbs.round()}g carbs', const Color(0xFF00E5FF)),
              _miniSummaryChip('${g.fat.round()}g fat', const Color(0xFFC79AFA)),
              _miniSummaryChip('${g.fiber.round()}g fiber', const Color(0xFFFFD700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniSummaryChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.2))),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
  );

  Widget _summaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
