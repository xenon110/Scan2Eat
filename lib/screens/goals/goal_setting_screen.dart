import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/user_goals.dart';
import 'daily_goal_screen.dart';

class GoalSettingScreen extends StatelessWidget {
  const GoalSettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final goals = UserGoals.instance;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Set Your Goals', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Define your nutrition targets for each period. Your dashboard will track progress against these goals automatically.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),

            // ── Daily Goal ───────────────────────────────────────
            _GoalCard(
              icon: Icons.wb_sunny_rounded,
              color: AppTheme.primaryNeon,
              title: 'Daily Goal',
              subtitle: 'Set morning, afternoon & evening targets',
              summary: _buildSummary(goals.daily.total),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DailyGoalScreen()),
                );
              },
            ),

            const SizedBox(height: 14),

            // ── Weekly Goal (derived) ────────────────────────────
            _GoalCard(
              icon: Icons.calendar_view_week_rounded,
              color: AppTheme.primaryCyan,
              title: 'Weekly Goal',
              subtitle: 'Automatically calculated from your daily goal × 7',
              summary: _buildSummary(goals.weekly),
              onTap: null, // read-only, derived
              locked: true,
            ),

            const SizedBox(height: 14),

            // ── Monthly Goal (derived) ───────────────────────────
            _GoalCard(
              icon: Icons.calendar_month_rounded,
              color: const Color(0xFFC79AFA),
              title: 'Monthly Goal',
              subtitle: 'Automatically calculated from your daily goal × 30',
              summary: _buildSummary(goals.monthly),
              onTap: null,
              locked: true,
            ),

            const SizedBox(height: 28),

            // ── Info card ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryNeon.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.primaryNeon, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Weekly & Monthly goals auto-update whenever you change your Daily goal. Tap "Daily Goal" to edit your targets.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, height: 1.5),
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

  List<_NutrientChip> _buildSummary(MealPeriodGoal g) => [
    _NutrientChip('${g.calories.round()} kcal', const Color(0xFFFF9F43)),
    _NutrientChip('${g.protein.round()}g protein', const Color(0xFF45FFB0)),
    _NutrientChip('${g.water.round()} glasses', Colors.blue),
  ];
}

// ── Goal Card ─────────────────────────────────────────────────────────────────

class _NutrientChip {
  final String label;
  final Color color;
  const _NutrientChip(this.label, this.color);
}

class _GoalCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final List<_NutrientChip> summary;
  final VoidCallback? onTap;
  final bool locked;

  const _GoalCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.summary,
    required this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF161C24),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: locked ? Colors.white.withValues(alpha: 0.05) : color.withValues(alpha: 0.3)),
          boxShadow: locked ? [] : [BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 12)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 3),
                      Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
                    ],
                  ),
                ),
                Icon(
                  locked ? Icons.lock_outline : Icons.arrow_forward_ios,
                  color: locked ? Colors.white24 : color,
                  size: locked ? 16 : 14,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: summary.map((c) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: c.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.color.withValues(alpha: 0.25)),
                ),
                child: Text(c.label, style: TextStyle(color: c.color, fontSize: 11, fontWeight: FontWeight.w600)),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
