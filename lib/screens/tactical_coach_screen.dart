import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/match_history_service.dart';
import '../services/purchase_service.dart';
import '../services/usage_service.dart';
import '../services/player_profile_service.dart';
import '../models/match_performance.dart';
import '../utils/tennis_validator.dart';
import '../widgets/shareable_card.dart';
import '../services/celebration_service.dart';
import '../services/streak_service.dart';
import '../widgets/voice_input_button.dart';
import '../utils/ai_disclosure_consent.dart';
import '../utils/paywall_navigation.dart';

/// Coach Screen
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
  Map<String, dynamic>? _analysisResult;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _isSaving = false;
  bool _showSavedTab = false;
  List<Map<String, dynamic>> _savedEntries = [];
  int? _expandedCardIndex;

  // Calculated stats
  int _wins = 0;
  int _total = 0;
  String _formTrend = '';
  String _topStrength = '';
  String _needsWork = '';

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
      final matches = await _matchHistoryService.getRecentMatches(35);

      final wins = matches.where((m) => m.result.toLowerCase() == 'win').length;
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

  Future<void> _reviewRecentMatchHistory() async {
    String query =
        'Review my recent logged match history and give a tactical rundown. '
        'Split it into: what keeps showing up, what helps me win, what breaks under pressure, and next match focus.';

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
    final authService = Provider.of<AuthService>(context, listen: false);
    final usageService = Provider.of<UsageService>(context, listen: false);

    final profileService =
        Provider.of<PlayerProfileService>(context, listen: false);
    final playerContext = profileService.getPlayerContext();
    if (playerContext.isNotEmpty) {
      query = '$playerContext\n\n$query';
    }

    final consented = await AiDisclosureConsent.ensureAccepted(context);
    if (!consented) {
      return;
    }
    if (!mounted) return;

    setState(() {
      _isGenerating = true;
      _analysisResult = null;
      _errorMessage = null;
    });

    HapticFeedback.mediumImpact();

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.tacticalAnalysis(
        query,
        _recentMatches,
      );

      setState(() {
        _isGenerating = false;
        _analysisResult = response;
      });

      if (response != null) {
        _scrollToInsight();
      }

      if (response == null && mounted) {
        if (apiService.requiresUpgrade && mounted) {
          await presentPaywall(context, trigger: PaywallTrigger.serverQuota);
          if (!mounted) return;
        }
        final errorMsg = apiService.error ?? 'Unable to generate insight';
        setState(() => _errorMessage = errorMsg);
        return;
      }

      if (!AppConfig.hasPremiumAccess(
        revenueCatPremium: purchaseService.isPremium,
        backendPremium: authService.isPremium,
        email: authService.userEmail,
      )) {
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
            ? Center(
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
                      'Coach',
                      style: AppTheme.headingSmallThemed(context).copyWith(
                        color: AppTheme.textSecondaryColor(context),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() => _showSavedTab = !_showSavedTab);
                          if (_showSavedTab) _loadSavedEntries();
                        },
                        child: Text(
                          _showSavedTab ? 'Coach' : 'Saved',
                          style: AppTheme.labelThemed(context).copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_showSavedTab)
                    SliverPadding(
                      padding: AppTheme.screenPadding,
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildSavedTab(),
                          const SizedBox(height: AppTheme.spaceXXL),
                        ]),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: AppTheme.screenPadding,
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildCurrentFormCard(),
                          const SizedBox(height: AppTheme.spaceLG),
                          _buildOptionalContextInput(),
                          const SizedBox(height: AppTheme.spaceMD),
                          _buildReviewButton(),

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
              Text('Recent Match Trends',
                  style: AppTheme.headingSmallThemed(context)),
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
                          ? AppTheme.win.withValues(alpha: 0.15)
                          : AppTheme.warning.withValues(alpha: 0.15),
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
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
              child: Text(
                'Log matches to see coaching trends',
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
                    style:
                        AppTheme.labelThemed(context).copyWith(fontSize: 11)),
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

  Widget _buildReviewButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review your tennis',
            style: AppTheme.headingMediumThemed(context)),
        const SizedBox(height: AppTheme.spaceXS),
        Text(
          'Insights based on your logged matches',
          style: AppTheme.bodySmallThemed(context),
        ),
        const SizedBox(height: AppTheme.spaceMD),
        GestureDetector(
          onTap: _isGenerating ? null : _reviewRecentMatchHistory,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: Center(
              child: _isGenerating
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: AppTheme.surfaceDark,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spaceSM),
                        Text(
                          'Reviewing history...',
                          style: AppTheme.headingSmallThemed(context)
                              .copyWith(color: AppTheme.surfaceDark),
                        ),
                      ],
                    )
                  : Text(
                      'Review recent match history',
                      style: AppTheme.headingSmallThemed(context)
                          .copyWith(color: AppTheme.surfaceDark),
                    ),
            ),
          ),
        ),
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
                color: AppTheme.textMutedColor(context).withValues(alpha: 0.5)),
            const SizedBox(width: 4),
            Text(
              'Voice enabled',
              style: AppTheme.labelThemed(context).copyWith(
                fontSize: 11,
                color: AppTheme.textMutedColor(context).withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        Text(
          'Optional - type or speak',
          style: AppTheme.labelThemed(context).copyWith(
            fontSize: 11,
            color: AppTheme.textMutedColor(context).withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: AppTheme.spaceSM),
        VoiceTextField(
          controller: _contextController,
          hintText: 'e.g. I get tight serving for sets...',
          maxLines: 2,
          style: AppTheme.bodyMediumThemed(context)
              .copyWith(color: AppTheme.textPrimaryColor(context)),
        ),
      ],
    );
  }

  // ============ Loading State ============

  Widget _buildLoadingState() {
    return TGCard(
      padding: AppTheme.cardPaddingLarge,
      child: Column(
        children: [
          CircularProgressIndicator(color: AppTheme.primary),
          const SizedBox(height: AppTheme.spaceMD),
          Text('Reviewing your recent match history...',
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
        color: AppTheme.loss.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.loss.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.loss, size: 40),
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

  // ============ Structured Coach Output ============

  Widget _buildStructuredAnalysis() {
    final data = _analysisResult!;
    final dataScope = data['dataScope'] as Map<String, dynamic>?;
    final matchesUsed =
        (dataScope?['matchesUsed'] as num?)?.toInt() ?? _recentMatches.length;
    final scopeNote = dataScope?['note'] as String? ?? '';

    final whatKeepsShowingUp =
        data['whatKeepsShowingUp'] as Map<String, dynamic>? ?? {};
    final whatsHelpingYouWin =
        data['whatsHelpingYouWin'] as Map<String, dynamic>? ?? {};
    final whatBreaksUnderPressure =
        data['whatBreaksUnderPressure'] as Map<String, dynamic>? ?? {};
    final nextMatchFocus =
        data['nextMatchFocus'] as Map<String, dynamic>? ?? {};

    final practicePlan = data['optionalPracticePlan'] as Map<String, dynamic>?;
    final hasPracticePlan = practicePlan != null &&
        ((practicePlan['drillName'] as String? ?? '').isNotEmpty ||
            (practicePlan['objective'] as String? ?? '').isNotEmpty);

    final shareText = _buildShareText(
      whatKeepsShowingUp,
      whatsHelpingYouWin,
      whatBreaksUnderPressure,
      nextMatchFocus,
      practicePlan,
      matchesUsed,
      scopeNote,
    );

    return Column(
      key: _insightCardKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Based on your last $matchesUsed logged matches',
          style: AppTheme.labelThemed(context),
        ),
        if (scopeNote.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spaceXS),
          Text(scopeNote, style: AppTheme.bodySmallThemed(context)),
        ],
        const SizedBox(height: AppTheme.spaceMD),
        _buildCoachSectionCard(
          title: 'WHAT KEEPS SHOWING UP',
          text: whatKeepsShowingUp['text'] as String? ?? '',
          evidence: whatKeepsShowingUp['evidence'] as String?,
          confidence: whatKeepsShowingUp['confidence'] as String?,
          trend: whatKeepsShowingUp['trend'] as String?,
          icon: Icons.visibility_outlined,
          highlighted: true,
        ),
        const SizedBox(height: AppTheme.spaceMD),
        _buildCoachSectionCard(
          title: 'WHAT\'S HELPING YOU WIN',
          text: whatsHelpingYouWin['text'] as String? ?? '',
          evidence: whatsHelpingYouWin['evidence'] as String?,
          confidence: whatsHelpingYouWin['confidence'] as String?,
          trend: whatsHelpingYouWin['trend'] as String?,
          icon: Icons.trending_up_rounded,
        ),
        const SizedBox(height: AppTheme.spaceMD),
        _buildCoachSectionCard(
          title: 'WHAT BREAKS UNDER PRESSURE',
          text: whatBreaksUnderPressure['text'] as String? ?? '',
          evidence: whatBreaksUnderPressure['evidence'] as String?,
          confidence: whatBreaksUnderPressure['confidence'] as String?,
          trend: whatBreaksUnderPressure['trend'] as String?,
          icon: Icons.warning_amber_rounded,
        ),
        const SizedBox(height: AppTheme.spaceMD),
        _buildCoachSectionCard(
          title: 'NEXT MATCH FOCUS',
          text: _buildNextMatchFocusText(nextMatchFocus),
          confidence: nextMatchFocus['confidence'] as String?,
          icon: Icons.center_focus_strong_rounded,
        ),
        if (hasPracticePlan) ...[
          const SizedBox(height: AppTheme.spaceMD),
          _buildPracticePlanCard(practicePlan),
        ],
        const SizedBox(height: AppTheme.spaceLG),
        _buildActionsRow(shareText),
      ],
    );
  }

  Widget _buildCoachSectionCard({
    required String title,
    required String text,
    required IconData icon,
    String? evidence,
    String? confidence,
    String? trend,
    bool highlighted = false,
  }) {
    return Container(
      padding: AppTheme.cardPaddingLarge,
      decoration: BoxDecoration(
        color: highlighted
            ? AppTheme.primary.withValues(alpha: 0.05)
            : AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(
          color: highlighted
              ? AppTheme.primary.withValues(alpha: 0.25)
              : AppTheme.borderColor(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 18),
              const SizedBox(width: AppTheme.spaceSM),
              Text(
                title,
                style: AppTheme.labelThemed(context).copyWith(
                  color: AppTheme.textSecondaryColor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            text,
            style: AppTheme.bodyLargeThemed(context).copyWith(height: 1.45),
          ),
          if ((evidence ?? '').isNotEmpty ||
              (confidence ?? '').isNotEmpty ||
              (trend ?? '').isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceSM),
            Text(
              _buildEvidenceMeta(evidence, confidence, trend),
              style: AppTheme.labelThemed(context),
            ),
          ],
        ],
      ),
    );
  }

  String _buildEvidenceMeta(
      String? evidence, String? confidence, String? trend) {
    final parts = <String>[];
    if ((evidence ?? '').isNotEmpty) {
      parts.add(evidence!.trim());
    }
    if ((confidence ?? '').isNotEmpty) {
      parts.add('Confidence: ${confidence!.trim()}');
    }
    if ((trend ?? '').isNotEmpty) {
      parts.add('Trend: ${trend!.trim()}');
    }
    return parts.join(' • ');
  }

  String _buildNextMatchFocusText(Map<String, dynamic> nextMatchFocus) {
    final text = nextMatchFocus['text'] as String? ?? '';
    final triggerRule = nextMatchFocus['triggerRule'] as String? ?? '';
    if (triggerRule.isEmpty) return text;
    return '$text\nTrigger: $triggerRule';
  }

  Widget _buildPracticePlanCard(Map<String, dynamic> practicePlan) {
    final drillName = practicePlan['drillName'] as String? ?? '';
    final objective = practicePlan['objective'] as String? ?? '';

    return Container(
      padding: AppTheme.cardPaddingLarge,
      decoration: BoxDecoration(
        color: AppTheme.elevatedBackground(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center_rounded,
                  color: AppTheme.textSecondaryColor(context), size: 18),
              const SizedBox(width: AppTheme.spaceSM),
              Text(
                'OPTIONAL PRACTICE PLAN',
                style: AppTheme.labelThemed(context).copyWith(
                  color: AppTheme.textSecondaryColor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (drillName.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceSM),
            Text(drillName, style: AppTheme.headingSmallThemed(context)),
          ],
          if (objective.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceXS),
            Text(
              objective,
              style: AppTheme.bodyMediumThemed(context).copyWith(height: 1.45),
            ),
          ],
        ],
      ),
    );
  }

  /// Actions row (share + new focus)
  Widget _buildActionsRow(String shareText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Save button
        TextButton.icon(
          onPressed: _isSaving ? null : () => _saveCurrentAdvice(shareText),
          icon: _isSaving
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.textSecondaryColor(context),
                  ),
                )
              : Icon(Icons.bookmark_outline_rounded,
                  size: 18, color: AppTheme.primary),
          label: Text(
            _isSaving ? 'Saving...' : 'Save',
            style: AppTheme.headingSmallThemed(context).copyWith(
              color: AppTheme.primary,
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spaceSM),
        ShareButton(
          shareText: shareText,
          subject: 'My Tactical Analysis',
          color: AppTheme.primary,
        ),
        const SizedBox(width: AppTheme.spaceSM),
        TextButton.icon(
          onPressed: () {
            HapticFeedback.lightImpact();
            setState(() {
              _analysisResult = null;
              _contextController.clear();
            });
          },
          icon: Icon(Icons.refresh_rounded,
              size: 18, color: AppTheme.textSecondaryColor(context)),
          label: Text(
            'New review',
            style: AppTheme.headingSmallThemed(context).copyWith(
              color: AppTheme.textSecondaryColor(context),
            ),
          ),
        ),
      ],
    );
  }

  // ============ Save + Saved Tab ============

  Future<void> _saveCurrentAdvice(String content) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.lightImpact();

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final success = await apiService.saveTacticalAdvice(content);

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Saved (max 3 stored)' : 'Could not save. Try again.',
              style: AppTheme.bodyMediumThemed(context)
                  .copyWith(color: Colors.white),
            ),
            backgroundColor: success ? AppTheme.win : AppTheme.loss,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _loadSavedEntries() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final entries = await apiService.getSavedTactical();
    if (mounted) {
      setState(() => _savedEntries = entries);
    }
  }

  Widget _buildSavedTab() {
    if (_savedEntries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceXL),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.bookmark_border_rounded,
                  size: 48, color: AppTheme.textMutedColor(context)),
              const SizedBox(height: AppTheme.spaceMD),
              Text('No saved advice yet',
                  style: AppTheme.headingSmallThemed(context)),
              const SizedBox(height: AppTheme.spaceXS),
              Text(
                'Generate tactical advice and tap Save to keep it here.',
                style: AppTheme.bodySmallThemed(context),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Saved Advice', style: AppTheme.headingMediumThemed(context)),
        const SizedBox(height: AppTheme.spaceXS),
        Text(
          'Most recent first (max 3)',
          style: AppTheme.bodySmallThemed(context),
        ),
        const SizedBox(height: AppTheme.spaceMD),
        ...List.generate(_savedEntries.length, (index) {
          final entry = _savedEntries[index];
          final content = entry['content'] as String? ?? '';
          final createdAt = entry['createdAtUtc'] as String? ?? '';
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spaceMD),
            child: _buildExpandableSavedCard(index, content, createdAt),
          );
        }),
      ],
    );
  }

  Widget _buildExpandableSavedCard(
      int index, String content, String createdAt) {
    final isExpanded = _expandedCardIndex == index;

    String dateLabel = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt);
        final diff = DateTime.now().toUtc().difference(dt);
        if (diff.inDays == 0) {
          dateLabel = 'Today';
        } else if (diff.inDays == 1) {
          dateLabel = 'Yesterday';
        } else {
          dateLabel = '${diff.inDays}d ago';
        }
      } catch (_) {}
    }

    // Preview: first ~200 characters or full if short
    final needsExpansion = content.length > 200;
    final previewText =
        needsExpansion ? '${content.substring(0, 200).trimRight()}…' : content;

    return GestureDetector(
      onTap: needsExpansion
          ? () {
              HapticFeedback.selectionClick();
              setState(() {
                _expandedCardIndex = isExpanded ? null : index;
              });
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: AppTheme.cardPaddingLarge,
        decoration: BoxDecoration(
          color: AppTheme.cardBackground(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          border: Border.all(
            color: isExpanded
                ? AppTheme.primary.withValues(alpha: 0.4)
                : AppTheme.borderColor(context),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: date + expand icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (dateLabel.isNotEmpty)
                  Text(
                    dateLabel,
                    style: AppTheme.labelThemed(context).copyWith(
                      color: AppTheme.textMutedColor(context),
                    ),
                  ),
                if (needsExpansion)
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 20,
                      color: AppTheme.textMutedColor(context),
                    ),
                  ),
              ],
            ),
            if (dateLabel.isNotEmpty || needsExpansion)
              const SizedBox(height: AppTheme.spaceSM),

            // Content with animated expand/collapse
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: isExpanded || !needsExpansion
                  ? Text(
                      content,
                      style: AppTheme.bodyMediumThemed(context)
                          .copyWith(height: 1.5),
                    )
                  : Text(
                      previewText,
                      style: AppTheme.bodyMediumThemed(context)
                          .copyWith(height: 1.5),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),

            // Tap hint when collapsed
            if (needsExpansion && !isExpanded) ...[
              const SizedBox(height: AppTheme.spaceXS),
              Text(
                'Tap to read more',
                style: AppTheme.labelThemed(context).copyWith(
                  color: AppTheme.primary.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _buildShareText(
    Map<String, dynamic> whatKeepsShowingUp,
    Map<String, dynamic> whatsHelpingYouWin,
    Map<String, dynamic> whatBreaksUnderPressure,
    Map<String, dynamic> nextMatchFocus,
    Map<String, dynamic>? practicePlan,
    int matchesUsed,
    String scopeNote,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('Tactical Analysis - Composure');
    buffer.writeln();
    buffer.writeln('Based on last $matchesUsed matches');
    if (scopeNote.isNotEmpty) {
      buffer.writeln(scopeNote);
      buffer.writeln();
    }
    buffer
        .writeln('What keeps showing up: ${whatKeepsShowingUp['text'] ?? ''}');
    buffer.writeln();
    buffer.writeln('What helps me win: ${whatsHelpingYouWin['text'] ?? ''}');
    buffer.writeln();
    buffer.writeln(
      'What breaks under pressure: ${whatBreaksUnderPressure['text'] ?? ''}',
    );
    buffer.writeln();
    buffer.writeln('Next match focus: ${nextMatchFocus['text'] ?? ''}');
    final triggerRule = nextMatchFocus['triggerRule'] as String? ?? '';
    if (triggerRule.isNotEmpty) {
      buffer.writeln('Trigger: $triggerRule');
    }

    if (practicePlan != null) {
      final drillName = practicePlan['drillName'] as String? ?? '';
      final objective = practicePlan['objective'] as String? ?? '';
      if (drillName.isNotEmpty || objective.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('Practice: $drillName');
        if (objective.isNotEmpty) buffer.writeln(objective);
      }
    }

    return buffer.toString();
  }
}
