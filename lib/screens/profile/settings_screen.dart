import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_theme.dart';
import '../../core/nutrition_log.dart';
import '../../core/user_stats.dart';
import '../../services/auth_service.dart';
import '../auth/auth_screen.dart';
import '../goals/goal_setting_screen.dart';
import 'about_screen.dart';
import 'premium_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _mealReminders = false;
  bool _isDeleting = false;
  bool _isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _mealReminders = prefs.getBool('meal_reminders') ?? false;
      });
    }
  }

  User? get _user => FirebaseAuth.instance.currentUser;

  // ── Actions ─────────────────────────────────────────────────────

  void _showEditNameSheet() {
    final controller = TextEditingController(text: _user?.displayName ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF161C24),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Edit Display Name',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Your name',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    prefixIcon: Icon(Icons.person_outline, color: Colors.white.withValues(alpha: 0.35), size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  final name = controller.text.trim();
                  if (name.isEmpty) return;
                  Navigator.of(ctx).pop();
                  try {
                    await AuthService.updateDisplayName(name);
                    if (mounted) {
                      setState(() {});
                      _showSnackbar('Name updated!', AppTheme.primaryNeon);
                    }
                  } catch (e) {
                    if (mounted) _showSnackbar('Failed to update name', AppTheme.dangerRed);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryNeon, AppTheme.primaryCyan],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToGoals() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GoalSettingScreen()),
    );
  }

  Future<void> _clearTodayLog() async {
    final confirmed = await _showConfirmDialog(
      title: 'Clear Today\'s Log',
      message: 'This will delete all food entries logged today. This cannot be undone.',
      confirmText: 'Clear All',
      isDanger: true,
    );
    if (confirmed != true) return;
    try {
      await NutritionLog.instance.clearTodayLogs();
      if (mounted) _showSnackbar('Today\'s log cleared!', AppTheme.primaryNeon);
    } catch (e) {
      if (mounted) _showSnackbar('Failed to clear log', AppTheme.dangerRed);
    }
  }

  Future<void> _resetWater() async {
    final confirmed = await _showConfirmDialog(
      title: 'Reset Water Intake',
      message: 'This will reset today\'s water intake back to 0.',
      confirmText: 'Reset',
      isDanger: false,
    );
    if (confirmed != true) return;
    try {
      await UserStats.instance.setWater(0);
      if (mounted) _showSnackbar('Water intake reset!', AppTheme.primaryNeon);
    } catch (e) {
      if (mounted) _showSnackbar('Failed to reset water', AppTheme.dangerRed);
    }
  }

  Future<void> _toggleMealReminders(bool value) async {
    setState(() => _mealReminders = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('meal_reminders', value);
    if (mounted) {
      _showSnackbar(
        value ? 'Meal reminders enabled' : 'Meal reminders disabled',
        AppTheme.primaryNeon,
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await _showConfirmDialog(
      title: 'Logout',
      message: 'Are you sure you want to sign out?',
      confirmText: 'Logout',
      isDanger: true,
    );
    if (confirmed != true) return;

    // Show loading overlay
    setState(() => _isDeleting = true);
    try {
      await AuthService.signOut();
    } catch (_) {
      // Force sign out even if network fails
    }
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const AuthScreen(canPop: false),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, anim, _, child) => FadeTransition(
            opacity: anim,
            child: child,
          ),
        ),
        (route) => false,
      );
    }
  }


  Future<void> _deleteAccount() async {
    // First confirmation
    final first = await _showConfirmDialog(
      title: 'Delete Account',
      message: 'This will permanently delete your account and all your data. This action CANNOT be undone.',
      confirmText: 'I Understand, Continue',
      isDanger: true,
    );
    if (first != true) return;

    // Second confirmation
    final second = await _showConfirmDialog(
      title: 'Are you absolutely sure?',
      message: 'All your food logs, goals, stats, and account data will be permanently deleted.',
      confirmText: 'Delete Everything',
      isDanger: true,
    );
    if (second != true) return;

    setState(() { _isDeleting = true; _isDeletingAccount = true; });
    try {
      await AuthService.deleteAccount();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, _, _) => const AuthScreen(canPop: false),
            transitionDuration: const Duration(milliseconds: 500),
            transitionsBuilder: (_, anim, _, child) => FadeTransition(
              opacity: anim,
              child: child,
            ),
          ),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        _showSnackbar(
          e.code == 'requires-recent-login'
              ? 'Please re-login and try again for security.'
              : 'Failed to delete account.',
          AppTheme.dangerRed,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        _showSnackbar('Failed to delete account.', AppTheme.dangerRed);
      }
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────

  void _showSnackbar(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == AppTheme.dangerRed ? Icons.error_outline : Icons.check_circle_outline,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: const Color(0xFF161C24),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required bool isDanger,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF161C24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (isDanger ? AppTheme.dangerRed : AppTheme.primaryNeon).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDanger ? Icons.warning_amber_rounded : Icons.info_outline,
                  color: isDanger ? AppTheme.dangerRed : AppTheme.primaryNeon,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        alignment: Alignment.center,
                        child: const Text('Cancel', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isDanger ? AppTheme.dangerRed : AppTheme.primaryNeon,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          confirmText,
                          style: TextStyle(
                            color: isDanger ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final displayName = user?.displayName ?? 'User';
    final email = user?.email ?? '';
    final initials = displayName.isNotEmpty
        ? displayName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _isDeleting
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.dangerRed),
                  const SizedBox(height: 20),
                  Text(
                    _isDeletingAccount ? 'Deleting account...' : 'Signing out...',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── App Bar ──
                SliverAppBar(
                  pinned: true,
                  backgroundColor: AppTheme.background,
                  title: const Text(
                    'Settings',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // ── Profile Header ──
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryNeon.withValues(alpha: 0.1),
                                AppTheme.primaryCyan.withValues(alpha: 0.05),
                                AppTheme.cardBackground,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.2)),
                            boxShadow: AppTheme.neonGlow(intensity: 0.07, blur: 24),
                          ),
                          child: Row(
                            children: [
                              // Avatar with neon ring
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.neonGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: AppTheme.neonGlow(intensity: 0.4, blur: 16),
                                ),
                                child: Container(
                                  width: 66, height: 66,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.cardBackground,
                                    shape: BoxShape.circle,
                                  ),
                                  child: ClipOval(
                                    child: user?.photoURL != null
                                        ? Image.network(
                                            user!.photoURL!,
                                            width: 66, height: 66,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) => Center(
                                              child: Text(initials,
                                                  style: const TextStyle(color: AppTheme.primaryNeon, fontWeight: FontWeight.bold, fontSize: 22)),
                                            ),
                                          )
                                        : Center(
                                            child: Text(initials,
                                                style: const TextStyle(color: AppTheme.primaryNeon, fontWeight: FontWeight.bold, fontSize: 22)),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      email,
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryNeon.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.3)),
                                      ),
                                      child: const Text('Active Member',
                                          style: TextStyle(color: AppTheme.primaryNeon, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: _showEditNameSheet,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryNeon.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.25)),
                                  ),
                                  child: const Icon(Icons.edit_rounded, color: AppTheme.primaryNeon, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Premium Banner ──
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PremiumScreen())),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFAA00)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.workspace_premium_rounded, color: Colors.black, size: 24),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Upgrade to Premium', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                                      SizedBox(height: 2),
                                      Text('Unlock unlimited scans & AI coaching', style: TextStyle(color: Colors.black87, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: Colors.black54),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── ACCOUNT Section ──
                        _buildSectionHeader('ACCOUNT'),
                        _buildTile(
                          icon: Icons.track_changes_rounded,
                          iconColor: AppTheme.primaryNeon,
                          title: 'Nutrition Goals',
                          subtitle: 'Set daily calorie & macro targets',
                          onTap: _navigateToGoals,
                          trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
                        ),

                        const SizedBox(height: 24),

                        // ── DATA Section ──
                        _buildSectionHeader('DATA'),
                        _buildTile(
                          icon: Icons.delete_sweep_outlined,
                          iconColor: AppTheme.warningOrange,
                          title: 'Clear Today\'s Log',
                          subtitle: '${NutritionLog.instance.todayEntries.length} entries logged today',
                          onTap: _clearTodayLog,
                          trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
                        ),
                        const SizedBox(height: 8),
                        _buildTile(
                          icon: Icons.water_drop_outlined,
                          iconColor: const Color(0xFF4FC3F7),
                          title: 'Reset Water Intake',
                          subtitle: '${UserStats.instance.waterLitres.toStringAsFixed(1)}L tracked today',
                          onTap: _resetWater,
                          trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
                        ),

                        const SizedBox(height: 24),

                        // ── NOTIFICATIONS Section ──
                        _buildSectionHeader('NOTIFICATIONS'),
                        _buildTile(
                          icon: Icons.notifications_active_outlined,
                          iconColor: const Color(0xFFC79AFA),
                          title: 'Meal Reminders',
                          subtitle: 'Get reminded to log your meals',
                          onTap: null,
                          trailing: Switch(
                            value: _mealReminders,
                            activeThumbColor: AppTheme.primaryNeon,
                            onChanged: _toggleMealReminders,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── ABOUT Section ──
                        _buildSectionHeader('ABOUT'),
                        _buildTile(
                          icon: Icons.info_outline_rounded,
                          iconColor: AppTheme.primaryCyan,
                          title: 'About Scan2Eat',
                          subtitle: 'Version 1.0.0 • Tap to learn more',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AboutScreen()),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
                        ),

                        const SizedBox(height: 32),

                        // ── Logout ──
                        GestureDetector(
                          onTap: _logout,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 17),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.dangerRed.withValues(alpha: 0.18), AppTheme.dangerRed.withValues(alpha: 0.08)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.dangerRed.withValues(alpha: 0.4)),
                              boxShadow: [BoxShadow(color: AppTheme.dangerRed.withValues(alpha: 0.12), blurRadius: 16)],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.logout_rounded, color: AppTheme.dangerRed, size: 20),
                                SizedBox(width: 10),
                                Text(
                                  'Sign Out',
                                  style: TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ── Delete Account ──
                        GestureDetector(
                          onTap: _deleteAccount,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_remove_outlined, color: Colors.white.withValues(alpha: 0.35), size: 18),
                                const SizedBox(width: 10),
                                Text(
                                  'Delete Account',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Footer ──
                        Center(
                          child: Text(
                            'Made with 💚 for your health',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 11),
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ── Reusable Widgets ────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 2),
      child: Row(
        children: [
          Container(
            width: 3, height: 14,
            decoration: BoxDecoration(
              gradient: AppTheme.neonGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.primaryNeon,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String? subtitle,
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          boxShadow: AppTheme.cardShadow(),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [iconColor.withValues(alpha: 0.2), iconColor.withValues(alpha: 0.08)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: iconColor.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, color: iconColor, size: 19),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11.5)),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
