import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import 'dart:math' as math;
import '../../core/nutrition_log.dart';

class MetabolicScreen extends StatelessWidget {
  const MetabolicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NutritionLog.instance,
      builder: (context, _) {
        final todayEntries = NutritionLog.instance.forDay(DateTime.now());
        final totals = NutritionLog.instance.totalsFor(todayEntries);

        return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        toolbarHeight: 60,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryNeon, width: 2),
              ),
              child: const CircleAvatar(
                radius: 14,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Scan2Eat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryNeon)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.primaryNeon), 
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No new notifications.', style: TextStyle(color: Colors.black)), backgroundColor: AppTheme.primaryNeon)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('MORNING, DR. CHEN', style: TextStyle(color: AppTheme.primaryNeon, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Text('You\'re on a ', style: TextStyle(fontSize: 14, color: Colors.white)),
                Text('12-Day Streak', style: TextStyle(fontSize: 14, color: AppTheme.primaryCyan, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            
            // Metabolic Peak Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF161C24),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNeon.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.show_chart, color: AppTheme.primaryNeon, size: 14),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Metabolic Peak', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                      Text('+4.2% from yesterday', style: TextStyle(fontSize: 11, color: AppTheme.primaryNeon)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            _buildCaloriesCard(context, totals),
            const SizedBox(height: 16),
            _buildHydrationCard(context),
            const SizedBox(height: 16),
            _buildGlucoseCard(context, totals),
            const SizedBox(height: 16),
            _buildWeeklyChartCard(context),
            const SizedBox(height: 24),
            const Text('AI Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            _buildAiInsightCard(),
            const SizedBox(height: 100), // FAB padding
          ],
        ),
      ),
    );
  }
);
  }

  Widget _buildCaloriesCard(BuildContext context, NutrientTotals totals) {
    final progress = (totals.calories / 2200).clamp(0.0, 1.0);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161C24),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Text('Calories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            width: 180,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: CircleProgressPainter(
                    progress: progress,
                    color: AppTheme.primaryCyan,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${totals.calories.round()}', style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1)),
                    Text('of 2,200 kcal', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroItem('PROTEIN', '${totals.protein.round()}g', AppTheme.primaryNeon),
              _buildMacroItem('CARBS', '${totals.carbs.round()}g', Colors.white),
              _buildMacroItem('FAT', '${totals.fat.round()}g', const Color(0xFFC79AFA)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, letterSpacing: 1.2, color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildHydrationCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161C24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Hydration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              Icon(Icons.water_drop_outlined, color: AppTheme.primaryCyan, size: 22),
            ],
          ),
          const SizedBox(height: 4),
          Text('Goal: 3.5L', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('2.4L Reached', style: TextStyle(fontSize: 13, color: Colors.white)),
              Text('68%', style: TextStyle(color: AppTheme.primaryCyan, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.68,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryCyan),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: Colors.white70, size: 16),
                SizedBox(width: 8),
                Text('Add 250ml', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlucoseCard(BuildContext context, NutrientTotals totals) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161C24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sugar (Glucose Proxy)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFF6B6B))),
                child: const Icon(Icons.priority_high, color: Color(0xFFFF6B6B), size: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Daily Limit: 50g', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
          const SizedBox(height: 24),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('${totals.sugar.round()}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('g', style: TextStyle(fontSize: 20, color: Colors.white.withValues(alpha: 0.6))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Glucose bar chart proxy based on historical sugar today
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (index) {
              Color color = index < 5 ? AppTheme.primaryNeon : const Color(0xFF8B5A5A); // Green to brownish red
              return Container(
                width: 14,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
              );
            }),
          ),
          const SizedBox(height: 16),
          Center(child: Text('Sugar consumption tracked throughout the day.', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildWeeklyChartCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161C24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Metabolic\nWeekly Chart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryNeon.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.3)),
                ),
                child: const Text('ACTIVE AI\nSCANNING', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.primaryNeon, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final day = DateTime.now().subtract(Duration(days: 6 - index));
              final entries = NutritionLog.instance.forDay(day);
              final totals = NutritionLog.instance.totalsFor(entries);
              final height = (totals.calories / 3000 * 100).clamp(10.0, 100.0);
              
              return Container(
                width: 24,
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryNeon.withValues(alpha: 0.8), AppTheme.primaryNeon.withValues(alpha: 0.1)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAiInsightCard() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF161C24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppTheme.primaryCyan.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.psychology, color: AppTheme.primaryCyan, size: 16),
              ),
              const SizedBox(width: 8),
              Text('COGNITIVE PEAK', style: TextStyle(color: AppTheme.primaryCyan, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Your glucose levels suggest high focus potential for the next 90 minutes. Schedule deep work now.', style: TextStyle(color: Colors.white, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}

class CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  CircleProgressPainter({required this.progress, required this.color, required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 14.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2) - (strokeWidth / 2);

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
