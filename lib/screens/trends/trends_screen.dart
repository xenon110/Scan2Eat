import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class TrendsScreen extends StatelessWidget {
  const TrendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        toolbarHeight: 60,
        title: const Text('Scan2Eat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryNeon)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.primaryNeon), 
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No new notifications.', style: TextStyle(color: Colors.black)), backgroundColor: AppTheme.primaryNeon)),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 14,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Community Pulse', style: TextStyle(color: AppTheme.primaryNeon, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Text(
              'Connect with 12,402 health enthusiasts optimizing their vitality through AI-driven insights.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            
            // Horizontal Cards
            SizedBox(
              height: 160,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildMilestoneCard(),
                  const SizedBox(width: 12),
                  _buildTopRankCard(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Social Rank Circular Card
            _buildSocialRankCard(),
            const SizedBox(height: 32),
            
            // Trending Scans Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Trending\nScans', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1)),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF161C24),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryNeon.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.5)),
                        ),
                        child: const Text('Most\nRecent', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.primaryNeon, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: const Text('Most\nSaved', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 10)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Feed Post 1
            _buildFeedPost(
              name: 'Julian Rivers',
              time: '2 hours ago • Clean Protein Bar',
              avatarUrl: 'https://i.pravatar.cc/150?img=33',
              imageUrl: 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?q=80&w=600',
              text: '"Found this at the local co-op. AI Scan shows 24g protein with zero artificial sweeteners. The macro-ratio is nearly perfect for post-workout."',
              stats: [
                _buildMacroStat('Protein', '24g', AppTheme.primaryNeon),
                _buildMacroStat('Net Carbs', '4.2g', Colors.white),
                _buildMacroStat('Vitality Score', '92/100', AppTheme.primaryCyan),
              ],
            ),
            const SizedBox(height: 24),
            
            // Feed Post 2 (Text only)
            _buildTextPost(
              name: 'Elena Chen',
              time: '6 hours ago • Meal Achievement',
              avatarUrl: 'https://i.pravatar.cc/150?img=44',
              title: 'Hit my Micronutrient Goal! 🥦',
              text: 'Finally balanced my Zinc and Magnesium levels using the AI\'s dinner suggestions. Feeling remarkably more focused today.',
            ),
            
            const SizedBox(height: 32),
            const Text('Community Channels', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            
            _buildChannelCard(Icons.fitness_center, 'Clean Protein Bars', '2.4k active members'),
            const SizedBox(height: 12),
            _buildChannelCard(Icons.eco, 'Vegan Optimization', '1.8k active members'),
            const SizedBox(height: 12),
            _buildChannelCard(Icons.nights_stay, 'Sleep & Biohacking', '3.1k active members'),
            
            const SizedBox(height: 24),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: const Text('Explore All Channels', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
            
            const SizedBox(height: 32),
            _buildLeaderboard(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneCard() {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161C24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.emoji_events, color: AppTheme.primaryNeon, size: 20),
              Text('MILESTONE', style: TextStyle(color: AppTheme.primaryNeon, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          const Text('12-Day Streak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          const SizedBox(height: 4),
          Text('Consistent morning vitals scan', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: AppTheme.primaryNeon, borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('Share Achievement', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12))),
          ),
        ],
      ),
    );
  }

  Widget _buildTopRankCard() {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161C24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.bolt, color: Colors.white, size: 20),
              Text('TOP 5%', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Vitality Rank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          const SizedBox(height: 4),
          Text('You\'re outperforming 95% of users', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('View Leaderboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialRankCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161C24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 100,
            width: 100,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 0.75,
                  strokeWidth: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryNeon),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('75%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Social Rank', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.6))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('You\'re more active than usual!', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Keep upvoting scans to increase your AI knowledge score.', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildFeedPost({required String name, required String time, required String avatarUrl, required String imageUrl, required String text, required List<Widget> stats}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161C24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(imageUrl, height: 220, width: double.infinity, fit: BoxFit.cover),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: AppTheme.primaryNeon, size: 12),
                      SizedBox(width: 4),
                      Text('AI Verified', style: TextStyle(color: AppTheme.primaryNeon, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(radius: 18, backgroundImage: NetworkImage(avatarUrl)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(time, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, height: 1.5)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: stats,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.thumb_up_outlined, color: Colors.white.withValues(alpha: 0.6), size: 16),
                    const SizedBox(width: 6),
                    Text('482', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                    const SizedBox(width: 20),
                    Icon(Icons.chat_bubble_outline, color: Colors.white.withValues(alpha: 0.6), size: 16),
                    const SizedBox(width: 6),
                    Text('59', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                    const Spacer(),
                    Icon(Icons.bookmark_border, color: Colors.white.withValues(alpha: 0.6), size: 16),
                    const SizedBox(width: 6),
                    Text('Save Scan', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroStat(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildTextPost({required String name, required String time, required String avatarUrl, required String title, required String text}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161C24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 18, backgroundImage: NetworkImage(avatarUrl)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(time, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, height: 1.5)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 24,
                    child: Stack(
                      children: [
                        const Positioned(left: 0, child: CircleAvatar(radius: 12, backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=1'))),
                        const Positioned(left: 16, child: CircleAvatar(radius: 12, backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=2'))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('and 34 others\ncelebrated this', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryNeon.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.celebration, color: AppTheme.primaryNeon, size: 14),
                    SizedBox(width: 6),
                    Text('Celebrate', style: TextStyle(color: AppTheme.primaryNeon, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChannelCard(IconData icon, String name, String members) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161C24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.white70, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(members, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.3)),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161C24),
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: AppTheme.primaryNeon, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('WEEKLY LEADERBOARD', style: TextStyle(color: AppTheme.primaryNeon, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
          const SizedBox(height: 20),
          _buildLeaderboardRow('1', 'https://i.pravatar.cc/100?img=11', 'Marcus Thorne', '982 pts'),
          const SizedBox(height: 16),
          _buildLeaderboardRow('2', 'https://i.pravatar.cc/100?img=5', 'Sarah Jenkins', '945 pts'),
          const SizedBox(height: 16),
          _buildLeaderboardRow('3', 'https://i.pravatar.cc/100?img=33', 'Alex Rivera', '890 pts'),
        ],
      ),
    );
  }

  Widget _buildLeaderboardRow(String rank, String avatar, String name, String points) {
    return Row(
      children: [
        SizedBox(width: 24, child: Text(rank, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12))),
        CircleAvatar(radius: 12, backgroundImage: NetworkImage(avatar)),
        const SizedBox(width: 12),
        Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 13))),
        Text(points, style: const TextStyle(color: AppTheme.primaryNeon, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}
