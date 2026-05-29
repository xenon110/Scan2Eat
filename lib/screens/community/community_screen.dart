import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/multiplayer_service.dart';
import '../../core/recipe_service.dart';
import 'recipe_detail_screen.dart';
import '../profile/settings_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoadingRecipes = true;
  List<MealRecipe> _mealRecipes = [];
  String? _recipesError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _fetchMealRecipes();
  }



  Future<void> _fetchMealRecipes() async {
    setState(() {
      _isLoadingRecipes = true;
      _recipesError = null;
    });
    try {
      final recipes = await RecipeService.instance.fetchRandomRecipes(count: 8);
      if (mounted) {
        setState(() {
          _mealRecipes = recipes;
        });
      }
    } catch (e) {
      debugPrint('Error fetching meal recipes: $e');
      if (mounted) {
        setState(() => _recipesError = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingRecipes = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: const Text('Community', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF161C24),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.primaryNeon,
                borderRadius: BorderRadius.circular(25),
              ),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Challenges'),
                Tab(text: 'Recipes'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChallengesTab(),
          _buildRecipesTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? null // Hide FAB on challenges tab
          : FloatingActionButton.extended(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Upload Recipe flow...')));
              },
              backgroundColor: AppTheme.primaryNeon,
              icon: const Icon(Icons.add_photo_alternate, color: Colors.black),
              label: const Text('Recipe', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
    );
  }

  void _createRoom() async {
    final name = await _askForName();
    if (name != null && name.isNotEmpty) {
      final code = await MultiplayerService.instance.createRoom(name);
      if (code != null) setState(() {});
    }
  }

  void _joinRoom() async {
    final code = await _askForCode();
    if (code != null && code.isNotEmpty) {
      final name = await _askForName();
      if (name != null && name.isNotEmpty) {
        final success = await MultiplayerService.instance.joinRoom(code, name);
        if (success) {
          setState(() {});
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room not found!')));
        }
      }
    }
  }

  void _leaveRoom() async {
    await MultiplayerService.instance.leaveRoom();
    setState(() {});
  }

  Future<String?> _askForName() {
    String name = '';
    return showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF161C24),
        title: const Text('Your Name', style: TextStyle(color: Colors.white)),
        content: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          onChanged: (v) => name = v,
          decoration: const InputDecoration(hintText: 'Enter your display name', hintStyle: TextStyle(color: Colors.white54)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(c, name), child: const Text('OK', style: TextStyle(color: AppTheme.primaryNeon))),
        ],
      ),
    );
  }

  Future<String?> _askForCode() {
    String code = '';
    return showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF161C24),
        title: const Text('Room Code', style: TextStyle(color: Colors.white)),
        content: TextField(
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(color: Colors.white),
          onChanged: (v) => code = v,
          decoration: const InputDecoration(hintText: 'Enter 6-digit code', hintStyle: TextStyle(color: Colors.white54)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(c, code), child: const Text('Join', style: TextStyle(color: AppTheme.primaryNeon))),
        ],
      ),
    );
  }



  // ── 2. Challenges Tab ────────────────────────────────────────────────────

  Widget _buildChallengesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildWeeklyChallengeCard(),
        const SizedBox(height: 24),
        const Text('Leaderboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        _buildLeaderboard(),
      ],
    );
  }

  Widget _buildWeeklyChallengeCard() {
    final code = MultiplayerService.instance.currentRoomCode;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1040), Color(0xFF0D1520)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accentPurple.withValues(alpha: 0.45)),
        boxShadow: AppTheme.purpleGlow(intensity: 0.2, blur: 24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.accentPurple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.accentPurple.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: AppTheme.accentPurple, size: 14),
                    const SizedBox(width: 5),
                    const Text('Multiplayer Challenge', style: TextStyle(color: Color(0xFFB57BFF), fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (code == null) ...[
            const Text('Multiplayer Showdown', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
            const SizedBox(height: 8),
            Text('Create a room or join a friend to compete in real-time!',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13, height: 1.5)),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _createRoom,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: AppTheme.purpleGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppTheme.purpleGlow(intensity: 0.4, blur: 14),
                      ),
                      child: const Center(
                        child: Text('Create Room', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _joinRoom,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.accentPurple.withValues(alpha: 0.5)),
                      ),
                      child: const Center(
                        child: Text('Join Room', style: TextStyle(color: Color(0xFFB57BFF), fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            ShaderMask(
              shaderCallback: (b) => AppTheme.purpleGradient.createShader(b),
              child: Text('Room: $code',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 26, letterSpacing: 3)),
            ),
            const SizedBox(height: 8),
            Text('Share this code with your friend so they can join your leaderboard!',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13, height: 1.5)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _leaveRoom,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.warningOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.warningOrange.withValues(alpha: 0.5)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.exit_to_app_rounded, color: AppTheme.warningOrange, size: 18),
                    SizedBox(width: 8),
                    Text('Leave Challenge', style: TextStyle(color: AppTheme.warningOrange, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    final code = MultiplayerService.instance.currentRoomCode;
    if (code == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: const Text('Join a challenge to see the live leaderboard!', style: TextStyle(color: Colors.white54)),
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: MultiplayerService.instance.getLeaderboardStream(code),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon));
        final users = snapshot.data!;
        
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            boxShadow: AppTheme.cardShadow(),
          ),
          child: Column(
            children: users.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final u = entry.value;
              final medalColor = index == 1
                  ? const Color(0xFFFFD700)
                  : index == 2
                      ? const Color(0xFFC0C0C0)
                      : index == 3
                          ? const Color(0xFFCD7F32)
                          : Colors.white24;
              final isTop3 = index <= 3;
              final isMe = u['uid'] == MultiplayerService.instance.currentUserId;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isMe
                      ? AppTheme.primaryNeon.withValues(alpha: 0.07)
                      : isTop3
                          ? medalColor.withValues(alpha: 0.06)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: isMe
                      ? Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.25))
                      : isTop3
                          ? Border.all(color: medalColor.withValues(alpha: 0.2))
                          : null,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: isTop3 ? medalColor.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                          border: Border.all(color: isTop3 ? medalColor.withValues(alpha: 0.5) : Colors.white12),
                          boxShadow: isTop3 ? [BoxShadow(color: medalColor.withValues(alpha: 0.3), blurRadius: 8)] : null,
                        ),
                        child: Center(
                          child: Text('#$index',
                              style: TextStyle(color: isTop3 ? medalColor : Colors.white54,
                                  fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: isTop3 ? medalColor.withValues(alpha: 0.2) : Colors.grey[800],
                        child: Text(u['displayName'].toString()[0].toUpperCase(),
                            style: TextStyle(fontSize: 13, color: isTop3 ? medalColor : Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  title: Text(
                    u['displayName'] + (isMe ? ' (You)' : ''),
                    style: TextStyle(
                      color: isMe ? AppTheme.primaryNeon : Colors.white,
                      fontWeight: isMe || isTop3 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: isTop3 ? medalColor.withValues(alpha: 0.15) : Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                      border: isTop3 ? Border.all(color: medalColor.withValues(alpha: 0.3)) : null,
                    ),
                    child: Text('${u['score']} pts',
                        style: TextStyle(color: isTop3 ? medalColor : Colors.white70,
                            fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ── 3. Recipes Tab ───────────────────────────────────────────────────────

  Widget _buildRecipesTab() {
    if (_isLoadingRecipes) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryNeon.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.3)),
              ),
              child: const CircularProgressIndicator(color: AppTheme.primaryNeon, strokeWidth: 2.5),
            ),
            const SizedBox(height: 20),
            Text(
              'Discovering recipes...',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_mealRecipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, color: Colors.white.withValues(alpha: 0.2), size: 56),
            const SizedBox(height: 16),
            Text(
              _recipesError != null ? 'Could not load recipes.' : 'No recipes found.',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _fetchMealRecipes,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryNeon,
                side: const BorderSide(color: AppTheme.primaryNeon),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryNeon,
      backgroundColor: const Color(0xFF161C24),
      onRefresh: _fetchMealRecipes,
      child: GridView.builder(
        itemCount: _mealRecipes.length,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.72,
        ),
        itemBuilder: (context, index) {
          final r = _mealRecipes[index];
          return _buildMealRecipeCard(r);
        },
      ),
    );
  }

  Widget _buildMealRecipeCard(MealRecipe recipe) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RecipeDetailScreen(recipe: recipe),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161C24),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with hero animation
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'recipe_${recipe.id}',
                    child: Image.network(
                      recipe.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: const Color(0xFF1A2332),
                          child: const Center(
                            child: SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryNeon,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, _, _) => Container(
                        color: const Color(0xFF1A2332),
                        child: Icon(Icons.restaurant, color: Colors.white.withValues(alpha: 0.2), size: 36),
                      ),
                    ),
                  ),
                  // Category badge
                  if (recipe.category.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.6), width: 1),
                        ),
                        child: Text(
                          recipe.category,
                          style: const TextStyle(color: AppTheme.primaryNeon, fontWeight: FontWeight.bold, fontSize: 9),
                        ),
                      ),
                    ),
                  // Cuisine flag at bottom-left
                  if (recipe.area.isNotEmpty)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.public, color: AppTheme.primaryCyan, size: 10),
                            const SizedBox(width: 4),
                            Text(
                              recipe.area,
                              style: const TextStyle(color: AppTheme.primaryCyan, fontWeight: FontWeight.w600, fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.restaurant_menu, color: Colors.white.withValues(alpha: 0.4), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.ingredients.length} ingredients',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNeon.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_forward_rounded, color: AppTheme.primaryNeon, size: 14),
                        SizedBox(width: 4),
                        Text('View Recipe', style: TextStyle(color: AppTheme.primaryNeon, fontWeight: FontWeight.bold, fontSize: 11)),
                      ],
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
