import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'home/home_screen.dart';
import 'scan/scan_screen.dart';
import 'journal/nutrition_report_screen.dart';
import 'community/community_screen.dart';
import 'profile/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fabPulse;

  final List<Widget> _screens = [
    const HomeScreen(),
    const NutritionReportScreen(),
    const ScanScreen(),
    const CommunityScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fabPulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _fabPulse.dispose();
    super.dispose();
  }

  static const _navItems = [
    _NavItem(Icons.grid_view_rounded, Icons.grid_view_rounded, 'Home'),
    _NavItem(Icons.bar_chart_rounded, Icons.bar_chart_rounded, 'Journal'),
    _NavItem(Icons.abc, Icons.abc, ''),          // Scan placeholder
    _NavItem(Icons.people_rounded, Icons.people_outline_rounded, 'Community'),
    _NavItem(Icons.settings_rounded, Icons.settings_outlined, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      // ── Floating Scan Button ──
      floatingActionButton: AnimatedBuilder(
        animation: _fabPulse,
        builder: (_, child) {
          final glow = 0.3 + _fabPulse.value * 0.25;
          return Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppTheme.primaryNeon, AppTheme.primaryCyan],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryNeon.withValues(alpha: glow),
                  blurRadius: 20 + _fabPulse.value * 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(32),
                onTap: () => setState(() => _currentIndex = 2),
                child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.black, size: 30),
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ── Premium Frosted Glass Bottom Nav ──
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF0A1020).withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
            ),
          ),
          child: Row(
            children: [
              _navTile(0),
              _navTile(1),
              // Centre gap for FAB
              const Expanded(child: SizedBox()),
              _navTile(3),
              _navTile(4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navTile(int index) {
    final isActive = _currentIndex == index;
    final item = _navItems[index];

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primaryNeon.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isActive ? AppTheme.neonGlow(intensity: 0.2, blur: 12) : null,
              ),
              child: Icon(
                isActive ? item.activeIcon : item.icon,
                color: isActive ? AppTheme.primaryNeon : AppTheme.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isActive ? AppTheme.primaryNeon : AppTheme.textSecondary,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData activeIcon;
  final IconData icon;
  final String label;
  const _NavItem(this.activeIcon, this.icon, this.label);
}
