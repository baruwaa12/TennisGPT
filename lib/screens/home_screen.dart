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

/// Home Screen - Performance Dashboard
/// 
/// Design Philosophy:
/// - Strava structure: Clear dashboard, performance-first
/// - Whoop tone: Calm, confident, coach-like
/// - Premium feel: Restraint over noise
/// 
/// Hierarchy:
/// 1. Performance stats (visual anchor)
/// 2. Primary action (Quick Match Log)
/// 3. Recent activity (context)
/// 4. Quick tools (secondary)

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

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final streakService = Provider.of<StreakService>(context);
    final firstName = authService.userDisplayName?.split(' ').first ?? 'Player';

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground(context),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStats,
          color: AppTheme.primary,
          backgroundColor: AppTheme.cardBackground(context),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Minimal header
              SliverToBoxAdapter(
                child: _buildHeader(context, authService, firstName),
              ),
              
              // Content
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMD),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    
                    // Performance Card - Visual Anchor
                    _buildPerformanceCard(streakService),
                    
                    const SizedBox(height: AppTheme.spaceLG),
                    
                    // Primary Action
                    _buildPrimaryAction(),
                    
                    const SizedBox(height: AppTheme.spaceXL),
                    
                    // Recent Activity
                    if (_recentMatches.isNotEmpty) ...[
                      _buildRecentActivity(),
                      const SizedBox(height: AppTheme.spaceXL),
                    ],
                    
                    // Tools (minimal)
                    _buildToolsSection(),
                    
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

  /// Get time-based greeting
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  /// Header with timed greeting
  Widget _buildHeader(BuildContext context, AuthService authService, String firstName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMD, 
        AppTheme.spaceMD, 
        AppTheme.spaceMD, 
        AppTheme.spaceSM,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Timed greeting with name
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: AppTheme.bodySmallThemed(context).copyWith(
                  color: AppTheme.textMutedColor(context),
                ),
              ),
              Text(
                firstName,
                style: AppTheme.headingMediumThemed(context),
              ),
            ],
          ),
          
          // Settings icon
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.cardBackground(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.borderColor(context)),
              ),
              child: Icon(
                Icons.settings_outlined,
                color: AppTheme.textMutedColor(context),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Performance Card - The visual anchor
  /// Hierarchy: Primary stat → Secondary stats → Tertiary indicators
  Widget _buildPerformanceCard(StreakService streakService) {
    final winPercentage = (_winRate * 100).toStringAsFixed(0);
    
    return Container(
      padding: AppTheme.cardPaddingLarge,
      decoration: AppTheme.cardDecorationThemed(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primary Stat: Win Rate (large, prominent)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$winPercentage%',
                style: AppTheme.statLargeThemed(context).copyWith(
                  fontSize: 48,
                ),
              ),
              const SizedBox(width: AppTheme.spaceSM),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'win rate',
                  style: AppTheme.labelThemed(context),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spaceLG),
          
          // Divider
          Container(height: 1, color: AppTheme.borderColor(context)),
          
          const SizedBox(height: AppTheme.spaceMD),
          
          // Secondary Stats Row
          Row(
            children: [
              // Matches played
              Expanded(
                child: _buildSecondaryStatItem(
                  value: '$_totalMatches',
                  label: 'matches',
                ),
              ),
              
              // Streak (integrated, not separate)
              if (_currentStreak != 0)
                Expanded(
                  child: _buildSecondaryStatItem(
                    value: '${_currentStreak.abs()}',
                    label: _currentStreak > 0 ? 'win streak' : 'to bounce back',
                    valueColor: _currentStreak > 0 ? AppTheme.win : null,
                  ),
                ),
              
              // App streak (subtle)
              if (streakService.currentStreak > 0)
                Expanded(
                  child: _buildSecondaryStatItem(
                    value: '${streakService.currentStreak}',
                    label: 'day streak',
                  ),
                ),
            ],
          ),
          
          // Tertiary: Recent form (subtle visual)
          if (_recentMatches.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceMD),
            Container(height: 1, color: AppTheme.borderColor(context)),
            const SizedBox(height: AppTheme.spaceMD),
            
            Row(
              children: [
                Text('Recent', style: AppTheme.labelThemed(context)),
                const SizedBox(width: AppTheme.spaceMD),
                ...List.generate(
                  _recentMatches.take(5).length,
                  (index) {
                    final isWin = _recentMatches[index].result.toLowerCase() == 'win';
                    return Container(
                      margin: const EdgeInsets.only(right: 6),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isWin ? AppTheme.win : AppTheme.loss.withOpacity(0.6),
                        shape: BoxShape.circle,
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

  Widget _buildSecondaryStatItem({
    required String value,
    required String label,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTheme.statMediumThemed(context).copyWith(
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTheme.labelThemed(context)),
      ],
    );
  }

  /// Primary Action - Clear but not overpowering
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
          vertical: AppTheme.spaceMD,
        ),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: AppTheme.spaceSM),
            Text(
              'Quick Match Log',
              style: AppTheme.headingSmall.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  /// Recent Activity - Context with subtle insights
  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent', style: AppTheme.headingSmallThemed(context)),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MatchHistoryScreen()),
                );
              },
              child: Text(
                'View all',
                style: AppTheme.bodySmallThemed(context).copyWith(color: AppTheme.primary),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppTheme.spaceMD),
        
        // Match list
        ...List.generate(
          _recentMatches.take(3).length,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spaceSM),
            child: _buildMatchItem(_recentMatches[index]),
          ),
        ),
      ],
    );
  }

  /// Match item - Clean with optional insight
  Widget _buildMatchItem(MatchPerformance match) {
    final isWin = match.result.toLowerCase() == 'win';
    
    // Extract a brief insight if available
    String? insight;
    if (match.notes.isNotEmpty) {
      // Take first sentence or first 60 chars
      final firstSentence = match.notes.split('.').first;
      insight = firstSentence.length > 60 
          ? '${firstSentence.substring(0, 57)}...' 
          : firstSentence;
    }
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MatchHistoryScreen()),
        );
      },
      child: Container(
        padding: AppTheme.cardPadding,
        decoration: AppTheme.cardDecorationThemed(context),
        child: Row(
          children: [
            // Result indicator - subtle
            Container(
              width: 4,
              height: insight != null ? 48 : 36,
              decoration: BoxDecoration(
                color: isWin ? AppTheme.win : AppTheme.loss.withOpacity(0.7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(width: AppTheme.spaceMD),
            
            // Match info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        match.opponent,
                        style: AppTheme.bodyMediumThemed(context).copyWith(
                          color: AppTheme.textPrimaryColor(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceSM),
                      Text(
                        match.scoreLine.isNotEmpty
                            ? match.scoreLine
                            : '${match.setsWon}-${match.setsLost}',
                        style: AppTheme.bodySmallThemed(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(match.date),
                    style: AppTheme.labelThemed(context),
                  ),
                  // Subtle insight line
                  if (insight != null) ...[
                    const SizedBox(height: AppTheme.spaceSM),
                    Text(
                      insight,
                      style: AppTheme.bodySmallThemed(context).copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppTheme.textMutedColor(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            
            Icon(
              Icons.chevron_right,
              color: AppTheme.textMutedColor(context),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  /// Tools Section - Minimal, secondary
  Widget _buildToolsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tools', style: AppTheme.headingSmallThemed(context)),
        
        const SizedBox(height: AppTheme.spaceMD),
        
        Row(
          children: [
            Expanded(child: _buildToolItem(
              icon: Icons.psychology_outlined,
              label: 'Tactical',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TacticalCoachScreen()),
              ),
            )),
            const SizedBox(width: AppTheme.spaceSM),
            Expanded(child: _buildToolItem(
              icon: Icons.flag_outlined,
              label: 'Pre-Match',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MentalCheckInScreen()),
              ),
            )),
            const SizedBox(width: AppTheme.spaceSM),
            Expanded(child: _buildToolItem(
              icon: Icons.edit_note_outlined,
              label: 'Debrief',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EmotionalResetScreen()),
              ),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildToolItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceSM,
          vertical: AppTheme.spaceMD,
        ),
        decoration: AppTheme.cardDecorationThemed(context),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AppTheme.textSecondaryColor(context)),
            const SizedBox(height: AppTheme.spaceSM),
            Text(
              label,
              style: AppTheme.labelThemed(context).copyWith(color: AppTheme.textSecondaryColor(context)),
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
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}
