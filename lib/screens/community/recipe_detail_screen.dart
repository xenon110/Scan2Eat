import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_theme.dart';
import '../../core/recipe_service.dart';
import '../../core/nutrition_log.dart';

class RecipeDetailScreen extends StatefulWidget {
  final MealRecipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _showIngredients = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context, recipe),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildInfoChips(recipe),
                      const SizedBox(height: 24),
                      _buildToggleTabs(),
                      const SizedBox(height: 16),
                      if (_showIngredients)
                        _buildIngredientsList(recipe)
                      else
                        _buildInstructionsCard(recipe),
                      const SizedBox(height: 24),
                      if (recipe.youtubeUrl != null &&
                          recipe.youtubeUrl!.isNotEmpty)
                        _buildYoutubeCard(recipe),
                      const SizedBox(height: 16),
                      _buildLogButton(context, recipe),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sliver App Bar ──────────────────────────────────────────────────────

  Widget _buildSliverAppBar(BuildContext context, MealRecipe recipe) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: AppTheme.background,
      leading: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.white, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Recipe saved!'),
                  backgroundColor: const Color(0xFF161C24),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Hero image
            Hero(
              tag: 'recipe_${recipe.id}',
              child: Image.network(
                recipe.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: const Color(0xFF161C24),
                  child: const Icon(Icons.restaurant, color: Colors.white24, size: 80),
                ),
              ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    AppTheme.background.withValues(alpha: 0.6),
                    AppTheme.background,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
            // Title at bottom
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Area badges
                  Row(
                    children: [
                      if (recipe.category.isNotEmpty)
                        _buildBadge(recipe.category, AppTheme.primaryNeon),
                      if (recipe.area.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _buildBadge(recipe.area, AppTheme.primaryCyan),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    recipe.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.15,
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

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ── Info Chips ──────────────────────────────────────────────────────────

  Widget _buildInfoChips(MealRecipe recipe) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161C24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
            Icons.restaurant_menu,
            '${recipe.ingredients.length}',
            'Ingredients',
            const Color(0xFFFF9F43),
          ),
          Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.08)),
          _buildInfoItem(
            Icons.category_outlined,
            recipe.category,
            'Category',
            AppTheme.primaryNeon,
          ),
          Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.08)),
          _buildInfoItem(
            Icons.public,
            recipe.area,
            'Cuisine',
            AppTheme.primaryCyan,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // ── Toggle Tabs (Ingredients / Instructions) ────────────────────────────

  Widget _buildToggleTabs() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161C24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showIngredients = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _showIngredients ? AppTheme.primaryNeon : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.list_alt,
                      size: 16,
                      color: _showIngredients ? Colors.black : Colors.white54,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ingredients',
                      style: TextStyle(
                        color: _showIngredients ? Colors.black : Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showIngredients = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_showIngredients ? AppTheme.primaryNeon : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.menu_book,
                      size: 16,
                      color: !_showIngredients ? Colors.black : Colors.white54,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Instructions',
                      style: TextStyle(
                        color: !_showIngredients ? Colors.black : Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Ingredients List ────────────────────────────────────────────────────

  Widget _buildIngredientsList(MealRecipe recipe) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161C24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: recipe.ingredients.asMap().entries.map((entry) {
          final i = entry.key;
          final ing = entry.value;
          final isLast = i == recipe.ingredients.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Ingredient thumbnail
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        ing.thumbUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.egg_alt,
                          color: Colors.white.withValues(alpha: 0.3),
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Ingredient name
                    Expanded(
                      child: Text(
                        ing.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Measure
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryNeon.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        ing.measure.isNotEmpty ? ing.measure : '—',
                        style: const TextStyle(
                          color: AppTheme.primaryNeon,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.04),
                  indent: 74,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Instructions Card ───────────────────────────────────────────────────

  Widget _buildInstructionsCard(MealRecipe recipe) {
    // Split instructions into steps
    final rawSteps = recipe.instructions
        .split(RegExp(r'\r?\n'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161C24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rawSteps.asMap().entries.map((entry) {
          final i = entry.key;
          final step = entry.value.trim();
          // Remove leading step numbers like "1." or "STEP 1:"
          final cleanStep = step.replaceFirst(RegExp(r'^(STEP\s*)?\d+[\.\)\:]?\s*', caseSensitive: false), '');
          if (cleanStep.isEmpty) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step number badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryNeon.withValues(alpha: 0.3),
                        AppTheme.primaryCyan.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: AppTheme.primaryNeon,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    cleanStep,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── YouTube Card ────────────────────────────────────────────────────────

  Widget _buildYoutubeCard(MealRecipe recipe) {
    return GestureDetector(
      onTap: () async {
        final url = recipe.youtubeUrl;
        if (url != null && url.isNotEmpty) {
          try {
            final uri = Uri.parse(url);
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Could not open video'),
                  backgroundColor: const Color(0xFF161C24),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFF0000).withValues(alpha: 0.12),
              const Color(0xFF161C24),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF0000).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF0000).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.play_circle_fill, color: Color(0xFFFF4444), size: 28),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Watch Video Tutorial',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Step-by-step cooking guide on YouTube',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, color: Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }

  // ── Log Button ──────────────────────────────────────────────────────────

  Widget _buildLogButton(BuildContext context, MealRecipe recipe) {
    return GestureDetector(
      onTap: () {
        NutritionLog.instance.add(FoodEntry(
          name: recipe.name,
          imageUrl: recipe.imageUrl,
          consumedAt: DateTime.now(),
          healthScore: 85,
          calories: 0,
          protein: 0,
          carbs: 0,
          sugar: 0,
          fat: 0,
          fiber: 0,
          sodium: 0,
        ));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF161C24),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryNeon.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: AppTheme.primaryNeon, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Added ${recipe.name} to your journal!',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryNeon, AppTheme.primaryCyan],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryNeon.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: Colors.black, size: 20),
            SizedBox(width: 10),
            Text(
              'I Ate This',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
