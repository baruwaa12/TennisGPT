import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/match_history_service.dart';
import '../services/purchase_service.dart';
import '../services/usage_service.dart';
import '../services/player_profile_service.dart';
import '../models/match_performance.dart';
import '../utils/tennis_validator.dart';
import '../widgets/shareable_card.dart';
import '../services/celebration_service.dart';
import '../services/streak_service.dart';
import 'paywall_screen.dart';

/// Tactical Coach Screen
/// 
/// UX Philosophy: Coach-first, not AI-first
/// The screen should feel like a trusted tennis coach reviewing form,
/// not a chatbot waiting for questions.
/// 
/// Key UX Shifts:
/// - Insights are PRESENTED, not requested
/// - Focus areas are the PRIMARY interaction
/// - Free-text input is OPTIONAL and de-emphasized
/// - CTAs frame as "reviewing prepared insights"
class TacticalCoachScreen extends StatefulWidget {
  const TacticalCoachScreen({super.key});

  @override
  State<TacticalCoachScreen> createState() => _TacticalCoachScreenState();
}

class _TacticalCoachScreenState extends State<TacticalCoachScreen> {
  final TextEditingController _contextController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MatchHistoryService _matchHistoryService = MatchHistoryService();
  final GlobalKey _insightCardKey = GlobalKey();
  
  List<MatchPerformance> _recentMatches = [];
  String? _selectedFocus;
  String? _insightResponse;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isGenerating = false;
  
  // Calculated stats
  int _wins = 0;
  int _total = 0;
  String _formTrend = '';
  String _topStrength = '';
  String _needsWork = '';

  /// Focus areas - framed as coach lenses, not AI tools
  final List<Map<String, dynamic>> _focusAreas = [
    {
      'id': 'opponent',
      'title': 'Break down your opponent',
      'subtitle': 'Patterns to exploit',
      'icon': Icons.person_search_rounded,
      'prompt': 'Analyze my recent opponents and identify tactical patterns I can exploit in future matches',
    },
    {
      'id': 'patterns',
      'title': 'Fix recurring mistakes',
      'subtitle': 'Address weak patterns',
      'icon': Icons.repeat_rounded,
      'prompt': 'Identify recurring patterns in my losses and provide actionable fixes',
    },
    {
      'id': 'upcoming',
      'title': 'Prepare for next match',
      'subtitle': 'Tactical game plan',
      'icon': Icons.calendar_today_rounded,
      'prompt': 'Help me prepare a tactical game plan for my next match based on my recent form',
    },
    {
      'id': 'drills',
      'title': 'Practice with purpose',
      'subtitle': 'Targeted drill plan',
      'icon': Icons.fitness_center_rounded,
      'prompt': 'Create a focused practice drill plan targeting my specific weaknesses',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _contextController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToInsight() {
    // Use post-frame callback to ensure widget is built first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Additional delay for iOS rendering
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_insightCardKey.currentContext != null) {
          Scrollable.ensureVisible(
            _insightCardKey.currentContext!,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            alignment: 0.1, // Show slightly below top
          );
        } else if (_scrollController.hasClients) {
          // Fallback: scroll to bottom
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final matches = await _matchHistoryService.getRecentMatches(10);
      
      // Calculate stats
      final wins = matches.where((m) => m.result.toLowerCase() == 'win').length;
      final total = matches.length;
      
      // Determine form trend
      String trend = '';
      if (matches.length >= 3) {
        final last3 = matches.take(3).toList();
        final recentWins = last3.where((m) => m.result.toLowerCase() == 'win').length;
        if (recentWins >= 2) {
          trend = 'Trending up';
        } else if (recentWins <= 1) {
          trend = 'Room to improve';
        }
      }
      
      // Calculate top strength and weakness
      String topStrength = 'Serve';
      String needsWork = 'Consistency';
      
      if (matches.isNotEmpty) {
        final strengthTotals = <String, int>{};
        final weaknessTotals = <String, int>{};
        
        for (final match in matches) {
          match.strengths.forEach((key, value) {
            strengthTotals[key] = (strengthTotals[key] ?? 0) + value;
          });
          match.weaknesses.forEach((key, value) {
            weaknessTotals[key] = (weaknessTotals[key] ?? 0) + value;
          });
        }
        
        if (strengthTotals.isNotEmpty) {
          topStrength = strengthTotals.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
        }
        if (weaknessTotals.isNotEmpty) {
          needsWork = weaknessTotals.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
        }
      }
      
      setState(() {
        _recentMatches = matches;
        _wins = wins;
        _total = total;
        _formTrend = trend;
        _topStrength = topStrength;
        _needsWork = needsWork;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getInsight() async {
    if (_selectedFocus == null) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Select a focus area to continue',
            style: AppTheme.bodyMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          ),
        ),
      );
      return;
    }

    // Get the focus area's base prompt
    final focusArea = _focusAreas.firstWhere((f) => f['id'] == _selectedFocus);
    String query = focusArea['prompt'];
    
    // Add optional context if provided
    final additionalContext = _contextController.text.trim();
    if (additionalContext.isNotEmpty) {
      // Validate tennis-related content
      final validationError = TennisValidator.validate(additionalContext);
      if (validationError != null) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validationError, style: AppTheme.bodyMedium.copyWith(color: Colors.white)),
            backgroundColor: AppTheme.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      query = '$query\n\nAdditional context from player: $additionalContext';
    }

    // Check usage limits
    final purchaseService = Provider.of<PurchaseService>(context, listen: false);
    final usageService = Provider.of<UsageService>(context, listen: false);
    
    if (!purchaseService.isPremium && !usageService.canUseTacticalAnalysis) {
      HapticFeedback.mediumImpact();
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const PaywallScreen(
            trigger: PaywallTrigger.tacticalAnalysisLimit,
          ),
        ),
      );
      if (result != true) return;
    }

    // Add player profile context
    final profileService = Provider.of<PlayerProfileService>(context, listen: false);
    final playerContext = profileService.getPlayerContext();
    if (playerContext.isNotEmpty) {
      query = '$playerContext\n\n$query';
    }

    setState(() {
      _isGenerating = true;
      _insightResponse = null;
      _errorMessage = null;
    });
    
    HapticFeedback.mediumImpact();

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.tacticalAnalysis(query, _recentMatches);
      
      setState(() {
        _isGenerating = false;
        _insightResponse = response;
      });
      
      if (response != null) {
        _scrollToInsight();
      }
      
      if (response == null && mounted) {
        final errorMsg = apiService.error ?? 'Unable to generate insight';
        setState(() => _errorMessage = errorMsg);
        return;
      }
      
      // Record usage for free users
      if (!purchaseService.isPremium) {
        await usageService.recordTacticalAnalysis();
      }
      
      HapticFeedback.lightImpact();
      
      // Celebrations and streaks
      if (response != null && mounted) {
        CelebrationService.checkFirstAnalysis(context);
        
        final streakService = Provider.of<StreakService>(context, listen: false);
        final streakMilestone = await streakService.recordActivity();
        
        if (streakMilestone != null && mounted) {
          CelebrationService.showAchievement(
            context,
            type: CelebrationType.milestone,
            title: streakMilestone.title,
            message: streakMilestone.message,
          );
        }
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceDark,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : CustomScrollView(
              controller: _scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                // Subtle header
                SliverAppBar(
                  backgroundColor: AppTheme.surfaceDark,
                  elevation: 0,
                  pinned: true,
                  centerTitle: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    'Tactical Coach',
                    style: AppTheme.headingSmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                
                SliverPadding(
                  padding: AppTheme.screenPadding,
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Current Form Card (Primary visual anchor)
                      _buildCurrentFormCard(),
                      
                      const SizedBox(height: AppTheme.spaceLG),
                      
                      // Focus Areas (Primary interaction)
                      _buildFocusAreasSection(),
                      
                      const SizedBox(height: AppTheme.spaceLG),
                      
                      // Optional Context Input (De-emphasized)
                      _buildOptionalContextInput(),
                      
                      const SizedBox(height: AppTheme.spaceLG),
                      
                      // Primary CTA
                      _buildPrimaryCTA(),
                      
                      // Loading state
                      if (_isGenerating) ...[
                        const SizedBox(height: AppTheme.spaceLG),
                        _buildLoadingState(),
                      ],
                      
                      // Error state
                      if (_errorMessage != null && !_isGenerating) ...[
                        const SizedBox(height: AppTheme.spaceLG),
                        _buildErrorState(),
                      ],
                      
                      // Insight Response
                      if (_insightResponse != null && !_isGenerating) ...[
                        const SizedBox(height: AppTheme.spaceLG),
                        _buildInsightCard(),
                      ],
                      
                      const SizedBox(height: AppTheme.spaceXXL),
                    ]),
                  ),
                ),
              ],
            ),
      ),
    );
  }

  /// Current Form Card
  /// Primary visual anchor - shows form at a glance
  /// Hierarchy: Form % + trend → Last 5 → Strength/Needs work
  Widget _buildCurrentFormCard() {
    final winPercentage = _total > 0 ? ((_wins / _total) * 100).round() : 0;
    final hasMatches = _recentMatches.isNotEmpty;
    
    return Container(
      padding: AppTheme.cardPaddingLarge,
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.surfaceBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.show_chart_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spaceSM),
              Text(
                'Current Form',
                style: AppTheme.headingSmall,
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spaceMD),
          
          if (hasMatches) ...[
            // Primary: Win rate + trend
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$winPercentage%',
                  style: AppTheme.statLarge.copyWith(
                    color: winPercentage >= 50 ? AppTheme.win : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSM),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'win rate',
                    style: AppTheme.bodySmall,
                  ),
                ),
                if (_formTrend.isNotEmpty) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceSM,
                      vertical: AppTheme.spaceXS,
                    ),
                    decoration: BoxDecoration(
                      color: _formTrend.contains('up') 
                          ? AppTheme.win.withOpacity(0.15)
                          : AppTheme.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _formTrend.contains('up') 
                              ? Icons.trending_up_rounded
                              : Icons.trending_flat_rounded,
                          size: 14,
                          color: _formTrend.contains('up') 
                              ? AppTheme.win
                              : AppTheme.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formTrend,
                          style: AppTheme.label.copyWith(
                            color: _formTrend.contains('up') 
                                ? AppTheme.win
                                : AppTheme.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: AppTheme.spaceMD),
            
            // Secondary: Last 5 match indicators
            Row(
              children: [
                Text(
                  'Last ${_recentMatches.take(5).length}',
                  style: AppTheme.label,
                ),
                const SizedBox(width: AppTheme.spaceSM),
                ..._recentMatches.take(5).map((match) {
                  final isWin = match.result.toLowerCase() == 'win';
                  return Container(
                    margin: const EdgeInsets.only(right: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isWin ? AppTheme.win : AppTheme.loss,
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ],
            ),
            
            const SizedBox(height: AppTheme.spaceMD),
            
            // Tertiary: Strength / Needs work
            Row(
              children: [
                Expanded(
                  child: _buildFormStat(
                    label: 'Strength',
                    value: _topStrength,
                    color: AppTheme.win,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMD),
                Expanded(
                  child: _buildFormStat(
                    label: 'Needs work',
                    value: _needsWork,
                    color: AppTheme.warning,
                  ),
                ),
              ],
            ),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
              child: Text(
                'Log matches to see your form analysis',
                style: AppTheme.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormStat({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceSM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppTheme.spaceSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.label.copyWith(fontSize: 11),
                ),
                Text(
                  value,
                  style: AppTheme.headingSmall.copyWith(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Focus Areas Section
  /// PRIMARY interaction - coach lenses, not AI tools
  Widget _buildFocusAreasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose a focus',
          style: AppTheme.headingMedium,
        ),
        const SizedBox(height: AppTheme.spaceXS),
        Text(
          'What would you like to work on?',
          style: AppTheme.bodySmall,
        ),
        const SizedBox(height: AppTheme.spaceMD),
        
        ...List.generate(_focusAreas.length, (index) {
          final focus = _focusAreas[index];
          final isSelected = _selectedFocus == focus['id'];
          
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < _focusAreas.length - 1 ? AppTheme.spaceSM : 0,
            ),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedFocus = isSelected ? null : focus['id'];
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(AppTheme.spaceMD),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppTheme.primary.withOpacity(0.1)
                      : AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  border: Border.all(
                    color: isSelected 
                        ? AppTheme.primary
                        : AppTheme.surfaceBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spaceSM),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppTheme.primary.withOpacity(0.2)
                            : AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      ),
                      child: Icon(
                        focus['icon'] as IconData,
                        size: 20,
                        color: isSelected 
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            focus['title'] as String,
                            style: AppTheme.headingSmall.copyWith(
                              color: isSelected 
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            focus['subtitle'] as String,
                            style: AppTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Optional Context Input
  /// De-emphasized, positioned AFTER focus areas
  Widget _buildOptionalContextInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add context',
          style: AppTheme.label.copyWith(color: AppTheme.textMuted),
        ),
        Text(
          'Optional',
          style: AppTheme.label.copyWith(
            fontSize: 11,
            color: AppTheme.textMuted.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: AppTheme.spaceSM),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(color: AppTheme.surfaceBorder),
          ),
          child: TextField(
            controller: _contextController,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'e.g., Facing a left-handed opponent...',
              hintStyle: AppTheme.bodySmall.copyWith(
                color: AppTheme.textMuted.withOpacity(0.5),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(AppTheme.spaceMD),
            ),
          ),
        ),
      ],
    );
  }

  /// Primary CTA
  /// Framed as reviewing something prepared, not asking
  Widget _buildPrimaryCTA() {
    final hasSelection = _selectedFocus != null;
    
    return GestureDetector(
      onTap: _isGenerating || !hasSelection ? null : _getInsight,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: hasSelection ? AppTheme.primary : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: hasSelection 
              ? null 
              : Border.all(color: AppTheme.surfaceBorder),
        ),
        child: Center(
          child: _isGenerating
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: hasSelection ? Colors.white : AppTheme.textMuted,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceSM),
                    Text(
                      'Preparing insight...',
                      style: AppTheme.headingSmall.copyWith(
                        color: hasSelection ? Colors.white : AppTheme.textMuted,
                      ),
                    ),
                  ],
                )
              : Text(
                  'View tactical insight',
                  style: AppTheme.headingSmall.copyWith(
                    color: hasSelection ? Colors.white : AppTheme.textMuted,
                  ),
                ),
        ),
      ),
    );
  }

  /// Loading State
  Widget _buildLoadingState() {
    return TGCard(
      padding: AppTheme.cardPaddingLarge,
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppTheme.primary),
          const SizedBox(height: AppTheme.spaceMD),
          Text(
            'Analyzing your recent form...',
            style: AppTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  /// Error State
  Widget _buildErrorState() {
    return Container(
      padding: AppTheme.cardPaddingLarge,
      decoration: BoxDecoration(
        color: AppTheme.loss.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.loss.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: AppTheme.loss, size: 40),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            'Unable to generate insight',
            style: AppTheme.headingSmall.copyWith(color: AppTheme.loss),
          ),
          const SizedBox(height: AppTheme.spaceXS),
          Text(
            _errorMessage ?? 'Please try again',
            textAlign: TextAlign.center,
            style: AppTheme.bodySmall,
          ),
          const SizedBox(height: AppTheme.spaceMD),
          TextButton(
            onPressed: () {
              setState(() => _errorMessage = null);
            },
            child: Text(
              'Dismiss',
              style: AppTheme.headingSmall.copyWith(color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  /// Insight Card
  /// Presented as prepared coaching insight
  Widget _buildInsightCard() {
    return Container(
      key: _insightCardKey,
      padding: AppTheme.cardPaddingLarge,
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceSM),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spaceSM),
              Text(
                'Tactical Insight',
                style: AppTheme.headingMedium,
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spaceMD),
          
          Divider(color: AppTheme.surfaceBorder, height: 1),
          
          const SizedBox(height: AppTheme.spaceMD),
          
          // Insight content
          Text(
            _insightResponse!,
            style: AppTheme.bodyLarge.copyWith(
              height: 1.7,
              color: AppTheme.textSecondary,
            ),
          ),
          
          const SizedBox(height: AppTheme.spaceLG),
          
          Divider(color: AppTheme.surfaceBorder, height: 1),
          
          const SizedBox(height: AppTheme.spaceMD),
          
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShareButton(
                shareText: ShareTextGenerator.tacticalAnalysis(_insightResponse!),
                subject: 'My Tactical Insight',
                color: AppTheme.primary,
              ),
              const SizedBox(width: AppTheme.spaceMD),
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _insightResponse = null;
                    _selectedFocus = null;
                    _contextController.clear();
                  });
                },
                icon: Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: AppTheme.textSecondary,
                ),
                label: Text(
                  'New focus',
                  style: AppTheme.headingSmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
