import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/match_history_service.dart';
import '../services/streak_service.dart';
import '../models/match_performance.dart';
import 'tactical_coach_screen.dart';
import 'match_history_screen.dart';
import 'quick_match_screen.dart';
import 'mental_check_in_screen.dart';
import 'emotional_reset_screen.dart';
import 'settings_screen.dart';

/// Home Screen - Dashboard Hub
/// 
/// Design: Strava-inspired feed with Whoop-style insights
/// Structure:
/// 1. Header (greeting + profile)
/// 2. Stats overview card
/// 3. Primary action (Log Match)
/// 4. Recent activity feed
/// 5. Quick access tools

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MatchHistoryService _matchHistoryService = MatchHistoryService();
  
  List<MatchPerformance> _recentMatches = [];
  double _winRate = 0.0;
  int _currentStreak = 0;
  int _totalMatches = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    
    try {
      final matches = await _matchHistoryService.getRecentMatches(10);
      final winRate = await _matchHistoryService.getWinRate();
      final total = await _matchHistoryService.getTotalMatches();
      final streak = _calculateStreak(matches);
      
      setState(() {
        _recentMatches = matches;
        _winRate = winRate;
        _totalMatches = total;
        _currentStreak = streak;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  int _calculateStreak(List<MatchPerformance> matches) {
    if (matches.isEmpty) return 0;
    
    int streak = 0;
    final bool isWinStreak = matches.first.result.toLowerCase() == 'win';
    
    for (final match in matches) {
      if ((match.result.toLowerCase() == 'win') == isWinStreak) {
        streak++;
      } else {
        break;
      }
    }
    
    return isWinStreak ? streak : -streak;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final streakService = Provider.of<StreakService>(context);
    final firstName = authService.userDisplayName?.split(' ').first ?? 'Player';

    return Scaffold(
      backgroundColor: AppTheme.surfaceDark,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStats,
          color: AppTheme.primary,
          backgroundColor: AppTheme.surfaceCard,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: _buildHeader(context, authService, firstName),
              ),
              
              // Content
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMD),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: AppTheme.spaceMD),
                    
                    // Stats Overview Card
                    _buildStatsCard(),
                    
                    const SizedBox(height: AppTheme.spaceMD),
                    
                    // Primary Action - Log Match
                    _buildPrimaryAction(),
                    
                    const SizedBox(height: AppTheme.spaceLG),
                    
                    // Streak indicator (if active)
                    if (streakService.currentStreak > 0) ...[
                      _buildStreakBanner(streakService),
                      const SizedBox(height: AppTheme.spaceLG),
                    ],
                    
                    // Recent Activity
                    _buildRecentActivity(),
                    
                    const SizedBox(height: AppTheme.spaceLG),
                    
                    // Quick Tools
                    _buildQuickTools(),
                    
                    const SizedBox(height: AppTheme.spaceXXL),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthService authService, String firstName) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Greeting
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: AppTheme.bodySmall,
              ),
              const SizedBox(height: AppTheme.spaceXS),
              Text(
                firstName,
                style: AppTheme.headingLarge,
              ),
            ],
          ),
          
          // Profile avatar
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.surfaceBorder, width: 2),
              ),
              child: authService.userPhotoURL != null
                  ? ClipOval(
                      child: Image.network(
                        authService.userPhotoURL!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildAvatarFallback(firstName),
                      ),
                    )
                  : _buildAvatarFallback(firstName),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    return Center(
      child: Text(
        name.substring(0, 1).toUpperCase(),
        style: AppTheme.headingMedium.copyWith(color: AppTheme.primary),
      ),
    );
  }

  Widget _buildStatsCard() {
    final winPercentage = (_winRate * 100).toStringAsFixed(0);
    
    return TGCard(
      padding: AppTheme.cardPaddingLarge,
      child: Column(
        children: [
          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  value: '$winPercentage%',
                  label: 'Win Rate',
                  valueColor: double.parse(winPercentage) >= 50 
                      ? AppTheme.win 
                      : AppTheme.loss,
                ),
              ),
              Container(
                width: 1,
                height: 48,
                color: AppTheme.surfaceBorder,
              ),
              Expanded(
                child: _buildStatItem(
                  value: '$_totalMatches',
                  label: 'Matches',
                ),
              ),
              Container(
                width: 1,
                height: 48,
                color: AppTheme.surfaceBorder,
              ),
              Expanded(
                child: _buildStatItem(
                  value: '${_currentStreak.abs()}',
                  label: _currentStreak >= 0 ? 'Win Streak' : 'Loss Streak',
                  valueColor: _currentStreak >= 0 ? AppTheme.win : AppTheme.loss,
                ),
              ),
            ],
          ),
          
          // Last 5 matches visual
          if (_recentMatches.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceMD),
            Container(
              height: 1,
              color: AppTheme.surfaceBorder,
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Row(
              children: [
                Text(
                  'Last ${_recentMatches.take(5).length}',
                  style: AppTheme.label,
                ),
                const SizedBox(width: AppTheme.spaceMD),
                ...List.generate(
                  _recentMatches.take(5).length,
                  (index) {
                    final match = _recentMatches[index];
                    final isWin = match.result.toLowerCase() == 'win';
                    return Container(
                      margin: const EdgeInsets.only(right: AppTheme.spaceSM),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isWin 
                            ? AppTheme.win.withOpacity(0.15)
                            : AppTheme.loss.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                        border: Border.all(
                          color: isWin ? AppTheme.win : AppTheme.loss,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          isWin ? 'W' : 'L',
                          style: AppTheme.bodySmall.copyWith(
                            color: isWin ? AppTheme.win : AppTheme.loss,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.statLarge.copyWith(
            color: valueColor ?? AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spaceXS),
        Text(label, style: AppTheme.label),
      ],
    );
  }

  Widget _buildPrimaryAction() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const QuickMatchScreen()),
        ).then((_) => _loadStats());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceLG,
          vertical: AppTheme.spaceMD + 4,
        ),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_circle_outline,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: AppTheme.spaceSM),
            Text(
              'Log Match',
              style: AppTheme.headingSmall.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakBanner(StreakService streakService) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.warning.withOpacity(0.2),
            AppTheme.warning.withOpacity(0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceSM),
            decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: const Text('🔥', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${streakService.currentStreak} Day Streak',
                  style: AppTheme.headingSmall.copyWith(color: AppTheme.warning),
                ),
                Text(
                  streakService.hasActivityToday 
                      ? "You're on fire!" 
                      : "Log a match to keep it going",
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Activity', style: AppTheme.headingMedium),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MatchHistoryScreen()),
                );
              },
              child: Text(
                'See All',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.primary),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppTheme.spaceMD),
        
        // Activity feed
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spaceLG),
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          )
        else if (_recentMatches.isEmpty)
          _buildEmptyState()
        else
          ...List.generate(
            _recentMatches.take(3).length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spaceMD),
              child: _buildMatchCard(_recentMatches[index]),
            ),
          ),
      ],
    );
  }

  Widget _buildMatchCard(MatchPerformance match) {
    final isWin = match.result.toLowerCase() == 'win';
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MatchHistoryScreen()),
        );
      },
      child: TGCard(
        child: Row(
          children: [
            // Result indicator
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isWin 
                    ? AppTheme.win.withOpacity(0.15)
                    : AppTheme.loss.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: Center(
                child: Text(
                  isWin ? 'W' : 'L',
                  style: AppTheme.headingMedium.copyWith(
                    color: isWin ? AppTheme.win : AppTheme.loss,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: AppTheme.spaceMD),
            
            // Match details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'vs ${match.opponent}',
                    style: AppTheme.headingSmall,
                  ),
                  const SizedBox(height: AppTheme.spaceXS),
                  Text(
                    '${_formatDate(match.date)} • ${match.setsWon}-${match.setsLost}',
                    style: AppTheme.bodySmall,
                  ),
                ],
              ),
            ),
            
            // Arrow
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return TGCard(
      padding: AppTheme.cardPaddingLarge,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMD),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sports_tennis,
              size: 32,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Text(
            'No matches yet',
            style: AppTheme.headingSmall,
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            'Log your first match to start tracking your progress',
            textAlign: TextAlign.center,
            style: AppTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTools() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Tools', style: AppTheme.headingMedium),
        
        const SizedBox(height: AppTheme.spaceMD),
        
        Row(
          children: [
            Expanded(
              child: _buildToolCard(
                icon: Icons.psychology_outlined,
                label: 'Tactical Coach',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TacticalCoachScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: _buildToolCard(
                icon: Icons.flag_outlined,
                label: 'Pre-Match',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MentalCheckInScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: _buildToolCard(
                icon: Icons.rate_review_outlined,
                label: 'Debrief',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EmotionalResetScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: TGCard(
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: AppTheme.primary,
            ),
            const SizedBox(height: AppTheme.spaceSM),
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}
