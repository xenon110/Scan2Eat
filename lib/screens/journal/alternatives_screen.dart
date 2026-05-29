import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/ai_service.dart';
import 'dart:math' as math;

class AlternativesScreen extends StatelessWidget {
  final FoodAnalysisResult scannedResult;
  final List<AnalysisAlternative> alternatives;

  const AlternativesScreen({
    super.key,
    required this.scannedResult,
    required this.alternatives,
  });

  @override
  Widget build(BuildContext context) {
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
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'), // Generic avatar
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Better Alternatives Found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              'We\'ve analyzed your recent scan. Swapping these items could improve your metabolic score by 14% this week.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            
            // The VS Section
            _buildVsSection(),
            
            const SizedBox(height: 32),
            const SizedBox(height: 32),
            if (alternatives.length > 1) ...[
              const Text('Other Healthy Alternatives', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
              const SizedBox(height: 16),
              ...alternatives.skip(1).map((alt) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildAlternativeCard(
                  title: alt.name,
                  subtitle: alt.subtitle,
                  price: alt.price,
                  tag: alt.tag,
                  imageUrl: alt.imageUrl,
                ),
              )),
            ],
            
            const SizedBox(height: 24),
            _buildPredictedResponseCard(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildVsSection() {
    return Column(
      children: [
        // Top Bad Product
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF161C24),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.dangerRed.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history, color: AppTheme.dangerRed, size: 12),
                    SizedBox(width: 4),
                    Text('Recently Scanned', style: TextStyle(color: AppTheme.dangerRed, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Simulated image of cereal box
              Container(
                height: 100,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.breakfast_dining, color: Colors.blueAccent, size: 40),
              ),
              const SizedBox(height: 16),
              Text(scannedResult.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text('\${scannedResult.calories.round()} kcal | \${scannedResult.sugar}g Sugar', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTrait('Glycemic Load', 'High (72)', AppTheme.dangerRed),
                  _buildTrait('Inflammatory', 'Moderate', const Color(0xFFFF9F43)), // Orange
                ],
              ),
            ],
          ),
        ),
        
        // VS Badge & Savings
        if (alternatives.isNotEmpty) ...[
          Transform.translate(
            offset: const Offset(0, -20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryNeon,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppTheme.primaryNeon.withValues(alpha: 0.4), blurRadius: 15, spreadRadius: 2),
                    ],
                  ),
                  child: const Text('VS', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                const SizedBox(height: 12),
                _buildSavingsPill('Better', 'CHOICE', AppTheme.primaryNeon),
                const SizedBox(height: 8),
                _buildSavingsPill('Healthier', 'METABOLISM', AppTheme.primaryCyan),
              ],
            ),
          ),
          
          // Bottom Good Product
          Transform.translate(
            offset: const Offset(0, -20),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF161C24),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(color: AppTheme.primaryNeon.withValues(alpha: 0.05), blurRadius: 20, spreadRadius: 5),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNeon.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, color: AppTheme.primaryNeon, size: 12),
                        SizedBox(width: 4),
                        Text('Scan2Eat Choice', style: TextStyle(color: AppTheme.primaryNeon, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      alternatives.first.imageUrl,
                      height: 100,
                      width: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.fastfood, size: 60, color: Colors.white24),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(alternatives.first.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryNeon), textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text(alternatives.first.subtitle, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTrait('Metabolic Impact', 'Optimal', AppTheme.primaryNeon),
                      _buildTrait('Safety Score', '\${alternatives.first.score} / 100', Colors.white),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNeon,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('Add to Smart Cart', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildTrait(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5))),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }

  Widget _buildSavingsPill(String amount, String label, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(amount, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 8, letterSpacing: 1, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAlternativeCard({required String title, required String subtitle, required String price, required String tag, required String imageUrl}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161C24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  imageUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.5)),
                  ),
                  child: Text(tag, style: const TextStyle(color: AppTheme.primaryNeon, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
                      const SizedBox(height: 8),
                      Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Buy Now', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictedResponseCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF161C24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            width: 120,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: ArcPainter(progress: 0.84, color: AppTheme.primaryNeon, backgroundColor: Colors.white.withValues(alpha: 0.1)),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('84', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('SCORE', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.6), letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Your Predicted Response', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, height: 1.5),
                children: [
                  const TextSpan(text: 'By switching to '),
                  TextSpan(text: alternatives.isNotEmpty ? alternatives.first.name : 'a healthier alternative', style: const TextStyle(color: AppTheme.primaryNeon, fontWeight: FontWeight.bold)),
                  const TextSpan(text: ', your blood glucose response is predicted to stay in the "Green Zone" (70-110 mg/dL) for 4 hours longer compared to the scanned item.'),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTag('Stable Insulin'),
              const SizedBox(width: 8),
              _buildTag('Fat Burn Mode'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTag('Anti-Inflammatory'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11)),
    );
  }
}

// Reusing ArcPainter from home_screen
class ArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  ArcPainter({required this.progress, required this.color, required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 10.0;
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

    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, bgPaint);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
