import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/match_history_service.dart';
import '../services/purchase_service.dart';
import '../services/usage_service.dart';
import '../services/player_profile_service.dart';
import '../services/auth_service.dart';
import '../models/match_performance.dart';
import '../utils/tennis_validator.dart';
import '../widgets/shareable_card.dart';
import '../services/celebration_service.dart';
import '../services/streak_service.dart';
import '../widgets/voice_input_button.dart';
import '../config/app_config.dart';
import 'paywall_screen.dart';

/// Tactical Coach Screen
///
/// Redesigned to display structured analytical output:
/// - Summary Card
/// - 3 Recommendation Cards (Title / Why / How)
/// - Pattern Detected Highlight Card
/// - Next Match Focus Banner
///
/// Clean, structured, analytical. No hype visuals.
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
  Map<String, dynamic>? _analysisResult;
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
      'prompt':
          'Analyze my recent opponents and identify tactical patterns I can exploit in future matches',
    },
    {
      'id': 'patterns',
      'title': 'Fix recurring mistakes',
      'subtitle': 'Address weak patterns',
      'icon': Icons.repeat_rounded,
      'prompt':
          'Identify recurring patterns in my losses and provide actionable fixes',
    },
    {
      'id': 'upcoming',
      'title': 'Prepare for next match',
      'subtitle': 'Tactical game plan',
      'icon': Icons.calendar_today_rounded,
      'prompt':
          'Help me prepare a tactical game plan for my next match based on my recent form',
    },
    {
      'id': 'drills',
      'title': 'Practice with purpose',
      'subtitle': 'Targeted drill plan',
      'icon': Icons.fitness_center_rounded,
      'prompt':
          'Create a focused practice drill plan targeting my specific weaknesses',
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_insightCardKey.currentContext != null) {
          Scrollable.ensureVisible(
            _insightCardKey.currentContext!,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            alignment: 0.1,
          );
        } else if (_scrollController.hasClients) {
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

      final wins =
          matches.where((m) => m.result.toLowerCase() == 'win').length;
      final total = matches.length;

      String trend = '';
      if (matches.length >= 3) {
        final last3 = matches.take(3).toList();
        final recentWins =
            last3.where((m) => m.result.toLowerCase() == 'win').length;
        if (recentWins >= 2) {
          trend = 'Trending up';
        } else if (recentWins <= 1) {
          trend = 'Room to improve';
        }
      }

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
            style: AppTheme.bodyMediumThemed(context)
                .copyWith(color: Colors.white),
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

    final focusArea =
        _focusAreas.firstWhere((f) => f['id'] == _selectedFocus);
    String query = focusArea['prompt'];

    final additionalContext = _contextController.text.trim();
    if (additionalContext.isNotEmpty) {
      final validationError = TennisValidator.validate(additionalContext);
      if (validationError != null) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validationError,
                style: AppTheme.bodyMediumThemed(context)
                    .copyWith(color: Colors.white)),
            backgroundColor: AppTheme.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      query = '$query\n\nAdditional context from player: $additionalContext';
    }

    final purchaseService =
        Provider.of<PurchaseService>(context, listen: false);
    final usageService = Provider.of<UsageService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    final shouldShowPaywall =
        AppConfig.shouldShowPaywall(email: authService.userEmail);

    if (shouldShowPaywall &&
        !purchaseService.isPremium &&
        !usageService.canUseTacticalAnalysis) {
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

    final profileService =
        Provider.of<PlayerProfileService>(context, listen: false);
    final playerContext = profileService.getPlayerContext();
    if (playerContext.isNotEmpty) {
      query = '$playerContext\n\n$query';
    }

    setState(() {
      _isGenerating = true;
      _analysisResult = null;
      _errorMessage = null;
    });

    HapticFeedback.mediumImpact();

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response =
          await apiService.tacticalAnalysis(query, _recentMatches);

      setState(() {
        _isGenerating = false;
        _analysisResult = response;
      });

      if (response != null) {
        _scrollToInsight();
      }

      if (response == null && mounted) {
        final errorMsg = apiService.error ?? 'Unable to generate insight';
        setState(() => _errorMessage = errorMsg);
        return;
      }

      if (!purchaseService.isPremium) {
        await usageService.recordTacticalAnalysis();
      }

      HapticFeedback.lightImpact();

      if (response != null && mounted) {
        CelebrationService.checkFirstAnalysis(context);

        final streakService =
            Provider.of<StreakService>(context, listen: false);
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
      backgroundColor: AppTheme.scaffoldBackground(context),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              )
            : CustomScrollView(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverAppBar(
                    backgroundColor: AppTheme.scaffoldBackground(context),
                    elevation: 0,
                    pinned: true,
                    centerTitle: true,
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back,
                          color: AppTheme.textSecondaryColor(context)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    title: Text(
                      'Tactical Coach',
                      style: AppTheme.headingSmallThemed(context).copyWith(
                        color: AppTheme.textSecondaryColor(context),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: AppTheme.screenPadding,
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildCurrentFormCard(),
                        const SizedBox(height: AppTheme.spaceLG),
                        _buildFocusAreasSection(),
                        const SizedBox(height: AppTheme.spaceLG),
                        _buildOptionalContextInput(),
                        const SizedBox(height: AppTheme.spaceLG),
                        _buildPrimaryCTA(),

                        if (_isGenerating) ...[
                          const SizedBox(height: AppTheme.spaceLG),
                          _buildLoadingState(),
                        ],

                        if (_errorMessage != null && !_isGenerating) ...[
                          const SizedBox(height: AppTheme.spaceLG),
                          _buildErrorState(),
                        ],

                        // Structured analysis output
                        if (_analysisResult != null && !_isGenerating) ...[
                          const SizedBox(height: AppTheme.spaceLG),
                          _buildStructuredAnalysis(),
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

  // ============ Current Form Card ============

  Widget _buildCurrentFormCard() {
    final winPercentage = _total > 0 ? ((_wins / _total) * 100).round() : 0;
    final hasMatches = _recentMatches.isNotEmpty;

    return Container(
      padding: AppTheme.cardPaddingLarge,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.borderColor(context), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart_rounded, color: AppTheme.primary, size: 20),
              const SizedBox(width: AppTheme.spaceSM),
              Text('Current Form', style: AppTheme.headingSmallThemed(context)),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMD),
          if (hasMatches) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$winPercentage%',
                  style: AppTheme.statLargeThemed(context).copyWith(
                    color: winPercentage >= 50
                        ? AppTheme.win
                        : AppTheme.textPrimaryColor(context),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSM),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('win rate',
                      style: AppTheme.bodySmallThemed(context)),
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
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSM),
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
                          style: AppTheme.labelThemed(context).copyWith(
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
            Row(
              children: [
                Text('Last ${_recentMatches.take(5).length}',
                    style: AppTheme.labelThemed(context)),
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
              padding:
                  const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
              child: Text(
                'Log matches to see your form analysis',
                style: AppTheme.bodyMediumThemed(context),
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
        color: AppTheme.elevatedBackground(context),
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
                Text(label,
                    style: AppTheme.labelThemed(context)
                        .copyWith(fontSize: 11)),
                Text(
                  value,
                  style: AppTheme.headingSmallThemed(context)
                      .copyWith(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ Focus Areas Section ============

  Widget _buildFocusAreasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose a focus', style: AppTheme.headingMediumThemed(context)),
        const SizedBox(height: AppTheme.spaceXS),
        Text('What would you like to work on?',
            style: AppTheme.bodySmallThemed(context)),
        const SizedBox(height: AppTheme.spaceMD),
        ...List.generate(_focusAreas.length, (index) {
          final focus = _focusAreas[index];
          final isSelected = _selectedFocus == focus['id'];

          return Padding(
            padding: EdgeInsets.only(
              bottom:
                  index < _focusAreas.length - 1 ? AppTheme.spaceSM : 0,
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
                      : AppTheme.cardBackground(context),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusMD),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.borderColor(context),
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
                            : AppTheme.elevatedBackground(context),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSM),
                      ),
                      child: Icon(
                        focus['icon'] as IconData,
                        size: 20,
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.textSecondaryColor(context),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            focus['title'] as String,
                            style: AppTheme.headingSmallThemed(context)
                                .copyWith(
                              color: isSelected
                                  ? AppTheme.textPrimaryColor(context)
                                  : AppTheme.textSecondaryColor(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            focus['subtitle'] as String,
                            style: AppTheme.bodySmallThemed(context),
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

  // ============ Optional Context Input ============

  Widget _buildOptionalContextInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Add context',
              style: AppTheme.labelThemed(context)
                  .copyWith(color: AppTheme.textMutedColor(context)),
            ),
            const Spacer(),
            Icon(Icons.mic,
                size: 14,
                color: AppTheme.textMutedColor(context).withOpacity(0.5)),
            const SizedBox(width: 4),
            Text(
              'Voice enabled',
              style: AppTheme.labelThemed(context).copyWith(
                fontSize: 11,
                color: AppTheme.textMutedColor(context).withOpacity(0.5),
              ),
            ),
          ],
        ),
        Text(
          'Optional - type or speak',
          style: AppTheme.labelThemed(context).copyWith(
            fontSize: 11,
            color: AppTheme.textMutedColor(context).withOpacity(0.6),
          ),
        ),
        const SizedBox(height: AppTheme.spaceSM),
        VoiceTextField(
          controller: _contextController,
          hintText: 'e.g., Facing a left-handed opponent...',
          maxLines: 2,
          style: AppTheme.bodyMediumThemed(context)
              .copyWith(color: AppTheme.textPrimaryColor(context)),
        ),
      ],
    );
  }

  // ============ Primary CTA ============

  Widget _buildPrimaryCTA() {
    final hasSelection = _selectedFocus != null;

    return GestureDetector(
      onTap: _isGenerating || !hasSelection ? null : _getInsight,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: hasSelection
              ? AppTheme.primary
              : AppTheme.elevatedBackground(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: hasSelection
              ? null
              : Border.all(color: AppTheme.borderColor(context)),
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
                        color: hasSelection
                            ? Colors.white
                            : AppTheme.textMutedColor(context),
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceSM),
                    Text(
                      'Preparing insight...',
                      style: AppTheme.headingSmallThemed(context).copyWith(
                        color: hasSelection
                            ? Colors.white
                            : AppTheme.textMutedColor(context),
                      ),
                    ),
                  ],
                )
              : Text(
                  'View tactical insight',
                  style: AppTheme.headingSmallThemed(context).copyWith(
                    color: hasSelection
                        ? Colors.white
                        : AppTheme.textMutedColor(context),
                  ),
                ),
        ),
      ),
    );
  }

  // ============ Loading State ============

  Widget _buildLoadingState() {
    return TGCard(
      padding: AppTheme.cardPaddingLarge,
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppTheme.primary),
          const SizedBox(height: AppTheme.spaceMD),
          Text('Analyzing your recent form...',
              style: AppTheme.bodyMediumThemed(context)),
        ],
      ),
    );
  }

  // ============ Error State ============

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
            style: AppTheme.headingSmallThemed(context)
                .copyWith(color: AppTheme.loss),
          ),
          const SizedBox(height: AppTheme.spaceXS),
          Text(
            _errorMessage ?? 'Please try again',
            textAlign: TextAlign.center,
            style: AppTheme.bodySmallThemed(context),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          TextButton(
            onPressed: () {
              setState(() => _errorMessage = null);
            },
            child: Text(
              'Dismiss',
              style: AppTheme.headingSmallThemed(context)
                  .copyWith(color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  // ============ Structured Analysis Output ============

  Widget _buildStructuredAnalysis() {
    final data = _analysisResult!;
    final summary = data['summary'] as String? ?? '';
    final recommendations =
        (data['recommendations'] as List<dynamic>?) ?? [];
    final patternDetected = data['patternDetected'] as String? ?? '';
    final nextMatchFocus = data['nextMatchFocus'] as String? ?? '';

    // Build share text from structured data
    final shareText = _buildShareText(
        summary, recommendations, patternDetected, nextMatchFocus);

    return Column(
      key: _insightCardKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1) Summary Card
        _buildSummaryCard(summary),

        const SizedBox(height: AppTheme.spaceMD),

        // 2) Recommendation Cards
        if (recommendations.isNotEmpty) ...[
          Text('Recommendations',
              style: AppTheme.headingMediumThemed(context)),
          const SizedBox(height: AppTheme.spaceSM),
          ...recommendations.asMap().entries.map((entry) {
            final rec = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spaceSM),
              child: _buildRecommendationCard(
                index: entry.key + 1,
                title: rec['title'] as String? ?? '',
                why: rec['why'] as String? ?? '',
                how: rec['how'] as String? ?? '',
              ),
            );
          }),
          const SizedBox(height: AppTheme.spaceSM),
        ],

        // 3) Pattern Detected Highlight Card
        if (patternDetected.isNotEmpty)
          _buildPatternDetectedCard(patternDetected),

        if (patternDetected.isNotEmpty)
          const SizedBox(height: AppTheme.spaceMD),

        // 4) Next Match Focus Banner
        if (nextMatchFocus.isNotEmpty)
          _buildNextMatchFocusBanner(nextMatchFocus),

        const SizedBox(height: AppTheme.spaceLG),

        // Actions row
        _buildActionsRow(shareText),
      ],
    );
  }

  /// Summary Card — analytical overview
  Widget _buildSummaryCard(String summary) {
    return Container(
      padding: AppTheme.cardPaddingLarge,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceSM),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spaceSM),
              Text('Summary',
                  style: AppTheme.headingMediumThemed(context)),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Divider(color: AppTheme.borderColor(context), height: 1),
          const SizedBox(height: AppTheme.spaceMD),
          Text(
            summary,
            style: AppTheme.bodyLargeThemed(context).copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }

  /// Recommendation Card — title, why, how
  Widget _buildRecommendationCard({
    required int index,
    required String title,
    required String why,
    required String how,
  }) {
    return Container(
      padding: AppTheme.cardPaddingLarge,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with index badge
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: AppTheme.labelThemed(context).copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spaceSM),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.headingSmallThemed(context),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spaceMD),

          // Why section
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceSM),
            decoration: BoxDecoration(
              color: AppTheme.elevatedBackground(context),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded,
                    size: 16,
                    color: AppTheme.textMutedColor(context)),
                const SizedBox(width: AppTheme.spaceSM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Why it matters',
                          style: AppTheme.labelThemed(context).copyWith(
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(why,
                          style: AppTheme.bodySmallThemed(context)
                              .copyWith(height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spaceSM),

          // How section
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceSM),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              border:
                  Border.all(color: AppTheme.primary.withOpacity(0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.play_circle_outline_rounded,
                    size: 16, color: AppTheme.primary),
                const SizedBox(width: AppTheme.spaceSM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('How to apply',
                          style: AppTheme.labelThemed(context).copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary)),
                      const SizedBox(height: 2),
                      Text(how,
                          style: AppTheme.bodySmallThemed(context)
                              .copyWith(height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Pattern Detected Highlight Card
  Widget _buildPatternDetectedCard(String pattern) {
    return Container(
      padding: AppTheme.cardPaddingLarge,
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.warning.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceSM),
            decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: Icon(Icons.pattern_rounded,
                color: AppTheme.warning, size: 20),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pattern Detected',
                    style: AppTheme.headingSmallThemed(context)
                        .copyWith(color: AppTheme.warning)),
                const SizedBox(height: AppTheme.spaceXS),
                Text(
                  pattern,
                  style: AppTheme.bodyMediumThemed(context)
                      .copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Next Match Focus Banner
  Widget _buildNextMatchFocusBanner(String focus) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLG,
        vertical: AppTheme.spaceMD,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.flag_rounded, color: AppTheme.primary, size: 20),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Next Match Focus',
                    style: AppTheme.labelThemed(context).copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  focus,
                  style: AppTheme.bodyMediumThemed(context).copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Actions row (share + new focus)
  Widget _buildActionsRow(String shareText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ShareButton(
          shareText: shareText,
          subject: 'My Tactical Analysis',
          color: AppTheme.primary,
        ),
        const SizedBox(width: AppTheme.spaceMD),
        TextButton.icon(
          onPressed: () {
            HapticFeedback.lightImpact();
            setState(() {
              _analysisResult = null;
              _selectedFocus = null;
              _contextController.clear();
            });
          },
          icon: Icon(Icons.refresh_rounded,
              size: 18, color: AppTheme.textSecondaryColor(context)),
          label: Text(
            'New focus',
            style: AppTheme.headingSmallThemed(context).copyWith(
              color: AppTheme.textSecondaryColor(context),
            ),
          ),
        ),
      ],
    );
  }

  String _buildShareText(String summary, List<dynamic> recommendations,
      String patternDetected, String nextMatchFocus) {
    final buffer = StringBuffer();
    buffer.writeln('Tactical Analysis — Composure');
    buffer.writeln();
    buffer.writeln('Summary: $summary');
    buffer.writeln();
    for (var i = 0; i < recommendations.length; i++) {
      final rec = recommendations[i];
      buffer.writeln(
          '${i + 1}. ${rec['title'] ?? ''}: ${rec['how'] ?? ''}');
    }
    if (patternDetected.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Pattern: $patternDetected');
    }
    if (nextMatchFocus.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Next Focus: $nextMatchFocus');
    }
    return buffer.toString();
  }
}
