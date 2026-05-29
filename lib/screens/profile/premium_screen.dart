import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _isYearlySelected = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFD700).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        ),
                      ),
                      const Expanded(child: SizedBox()),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 16),
                            SizedBox(width: 4),
                            Text('PRO', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [const Color(0xFFFFD700).withValues(alpha: 0.2), const Color(0xFFFFAA00).withValues(alpha: 0.05)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4)),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.2), blurRadius: 30),
                            ],
                          ),
                          child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 64),
                        ),
                        const SizedBox(height: 24),
                        
                        // Title
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFAA00)],
                          ).createShader(b),
                          child: const Text(
                            'Scan2Eat Premium',
                            style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Unlock your full health potential with advanced AI tools and unlimited tracking.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 15, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Features
                        _buildFeatureRow(Icons.camera_alt_rounded, 'Precision AI Food Recognition', 'Instantly identify meals and estimate calories using advanced computer vision.'),
                        const SizedBox(height: 20),
                        _buildFeatureRow(Icons.psychology_rounded, 'Personalized AI Coaching', 'Receive dynamic, AI-generated metabolic insights based on your daily eating habits.'),
                        const SizedBox(height: 20),
                        _buildFeatureRow(Icons.auto_graph_rounded, 'Detailed Micro-nutrients', 'Go beyond calories—track essential metrics like Sodium, Fiber, and Sugar.'),
                        const SizedBox(height: 20),
                        _buildFeatureRow(Icons.emoji_events_rounded, 'Gamified Health Tracking', 'Build healthy habits with daily streaks and compete on the community leaderboard.'),
                        
                        const SizedBox(height: 50),
                        
                        // Pricing Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildPricingCard(
                                'Monthly', '₹299', '/mo', 
                                !_isYearlySelected,
                                () => setState(() => _isYearlySelected = false),
                                false,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildPricingCard(
                                'Yearly', '₹2999', '/yr', 
                                _isYearlySelected,
                                () => setState(() => _isYearlySelected = true),
                                true,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Subscribe Button
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Premium payment gateway integration coming soon!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                backgroundColor: Color(0xFFFFD700),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFAA00)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'Start 7-Day Free Trial',
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Cancel anytime. Auto-renews after trial.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                        ),
                      ],
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

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: const Color(0xFFFFD700), size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPricingCard(String title, String price, String interval, bool isSelected, VoidCallback onTap, bool isBestValue) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFD700).withValues(alpha: 0.1) : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFFFFD700).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            if (isBestValue)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFD700) : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('BEST VALUE', style: TextStyle(color: isSelected ? Colors.black : Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
              )
            else
              const SizedBox(height: 31), // Spacer to align cards
            Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                Text(interval, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
