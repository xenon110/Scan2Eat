import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/nutrition_log.dart';
import '../../core/ai_service.dart';
import '../../core/notification_service.dart';
import '../journal/nutrition_report_screen.dart';
import 'analysis_screen.dart';

class PostScanActionScreen extends StatelessWidget {
  final FoodAnalysisResult result;
  final Uint8List imageBytes;

  const PostScanActionScreen({
    super.key,
    required this.result,
    required this.imageBytes,
  });

  void _onConsumed(BuildContext context) {
    NutritionLog.instance.add(FoodEntry(
      name: result.name,
      imageUrl: 'https://image.pollinations.ai/prompt/${Uri.encodeComponent('${result.name} food')}?width=400&height=300&nologo=true',
      consumedAt: DateTime.now(),
      healthScore: result.healthScore,
      calories: result.calories,
      protein: result.protein,
      carbs: result.carbs,
      sugar: result.sugar,
      fat: result.fat,
      fiber: result.fiber,
      sodium: result.sodium,
      vitaminD: result.vitaminD,
      iron: result.iron,
      calcium: result.calcium,
    ));

    // Navigate straight to the user's journal and clear the scan stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const NutritionReportScreen()),
      (route) => route.isFirst,
    );
    
    NotificationService.instance.createNotification(
      'Meal Logged 🥗', 
      'Logged ${result.name} (${result.calories.round()} kcal).',
      type: 'food',
    );
  }

  void _viewReport(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, _) => FadeTransition(
          opacity: animation,
          child: AnalysisScreen(
            result: result,
            imageBytes: imageBytes,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background blurred image
          Image.memory(
            imageBytes,
            fit: BoxFit.cover,
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(
              color: AppTheme.background.withValues(alpha: 0.7),
            ),
          ),
          
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  
                  // Circular image preview
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.5), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryNeon.withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                      image: DecorationImage(
                        image: MemoryImage(imageBytes),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Identified text
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, color: AppTheme.primaryCyan, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'AI IDENTIFIED',
                          style: TextStyle(
                            color: AppTheme.primaryCyan,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    result.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  Text(
                    'Health Score: \${result.healthScore}/100',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Action Buttons
                  _buildActionButton(
                    context,
                    title: 'View Scientific Report',
                    subtitle: 'Detailed nutrition, bodily impact & alternatives',
                    icon: Icons.science_outlined,
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryNeon, AppTheme.primaryCyan],
                    ),
                    textColor: Colors.black,
                    onTap: () => _viewReport(context),
                  ),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    context,
                    title: 'I Ate This',
                    subtitle: 'Log \${result.calories.round()} kcal to daily journal',
                    icon: Icons.restaurant,
                    gradient: LinearGradient(
                      colors: [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.05)],
                    ),
                    textColor: Colors.white,
                    borderColor: Colors.white.withValues(alpha: 0.15),
                    onTap: () => _onConsumed(context),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel & Scan Again',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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

  Widget _buildActionButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required Color textColor,
    required VoidCallback onTap,
    Color? borderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          border: borderColor != null ? Border.all(color: borderColor) : null,
          boxShadow: borderColor == null
              ? [
                  BoxShadow(
                    color: AppTheme.primaryNeon.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: textColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: textColor.withValues(alpha: 0.5), size: 16),
          ],
        ),
      ),
    );
  }
}
