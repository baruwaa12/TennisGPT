import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';
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

/// Coach Screen — modern, scannable, colour-coded analytical output.
/// Each insight section gets a distinct tonal accent so the wall of text
/// becomes glanceable without feeling loud.
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
  int _activeTab = 0; // 0 = Coach, 1 = Saved
  List<Map<String, dynamic>> _savedEntries = [];
  int? _expandedCardIndex;

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

      String topStrength = '';
      String needsWork = '';

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

      if (!mounted) return;
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
      if (!mounted) return;
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
    if (!consented) return;
    if (!mounted) return;

    setState(() {
      _isGenerating = true;
      _analysisResult = null;
      _errorMessage = null;
    });

    HapticFeedback.mediumImpact();

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.tacticalAnalysis(query, _recentMatches);

      if (!mounted) return;
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
      if (!mounted) return;
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
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.translucent,
              child: Column(
                children: [
                  _buildTopBar(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spaceMD,
                      0,
                      AppTheme.spaceMD,
                      AppTheme.spaceMD,
                    ),
                    child: SegmentedTabs(
                      labels: const ['Coach', 'Saved'],
                      selectedIndex: _activeTab,
                      onChanged: (i) {
                        setState(() => _activeTab = i);
                        if (i == 1) _loadSavedEntries();
                      },
                    ),
                  ),
                  Expanded(
                    child: _activeTab == 1 ? _buildSavedView() : _buildCoachView(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceSM,
        AppTheme.spaceSM,
        AppTheme.spaceMD,
        AppTheme.spaceSM,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back',
            iconSize: 22,
            style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
            color: AppTheme.textSecondaryColor(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: AppTheme.spaceXS),
          Text('Coach', style: AppTheme.headingMediumThemed(context)),
        ],
      ),
    );
  }

  // ============ Coach view ============

  Widget _buildCoachView() {
    return SingleChildScrollView(
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMD,
        0,
        AppTheme.spaceMD,
        AppTheme.spaceXXL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoading)
            const SkeletonBox(height: 150, radius: AppTheme.radiusXL)
          else
            _buildCurrentFormCard(),
          const SizedBox(height: AppTheme.spaceLG),
          _buildContextInput(),
          const SizedBox(height: AppTheme.spaceMD),
          PrimaryActionButton(
            label: 'Review my matches',
            icon: Icons.auto_awesome_rounded,
            loading: _isGenerating,
            loadingLabel: 'Reviewing…',
            onPressed: _isLoading ? null : _reviewRecentMatchHistory,
          ),
          if (_isGenerating) ...[
            const SizedBox(height: AppTheme.spaceLG),
            _buildAnalysisSkeleton(),
          ],
          if (_errorMessage != null && !_isGenerating) ...[
            const SizedBox(height: AppTheme.spaceLG),
            _buildErrorState(),
          ],
          if (_analysisResult != null && !_isGenerating) ...[
            const SizedBox(height: AppTheme.spaceLG),
            _buildStructuredAnalysis(),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentFormCard() {
    final winPercentage = _total > 0 ? ((_wins / _total) * 100).round() : 0;
    final hasMatches = _recentMatches.isNotEmpty;
    final trendingUp = _formTrend.toLowerCase().contains('up');

    if (!hasMatches) {
      return Container(
        padding: AppTheme.cardPaddingLarge,
        decoration: BoxDecoration(
          color: AppTheme.cardBackground(context).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Row(
          children: [
            const TonalIconBadge(
              icon: Icons.query_stats_rounded,
              color: AppAccents.blue,
              size: 48,
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: Text(
                'Log a few matches and your coach will spot the patterns.',
                style: AppTheme.bodyMediumThemed(context),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: AppTheme.cardPaddingLarge,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Recent trends',
                  style: AppTheme.labelThemed(context)),
              const Spacer(),
              if (_formTrend.isNotEmpty)
                TonalChip(
                  label: _formTrend,
                  color: trendingUp ? AppAccents.green : AppAccents.amber,
                  icon: trendingUp
                      ? Icons.trending_up_rounded
                      : Icons.trending_flat_rounded,
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$winPercentage%',
                style: AppTheme.statLargeThemed(context).copyWith(
                  color: winPercentage >= 50
                      ? AppAccents.green
                      : AppTheme.textPrimaryColor(context),
                ),
              ),
              const SizedBox(width: AppTheme.spaceSM),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child:
                    Text('win rate', style: AppTheme.bodySmallThemed(context)),
              ),
              const Spacer(),
              ..._recentMatches.take(5).map((match) {
                final isWin = match.result.toLowerCase() == 'win';
                return Container(
                  margin: const EdgeInsets.only(left: 4),
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: isWin ? AppAccents.green : AppAccents.coral,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ],
          ),
          if (_topStrength.isNotEmpty || _needsWork.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceMD),
            Row(
              children: [
                if (_topStrength.isNotEmpty)
                  Expanded(
                    child: _buildFormStat(
                      label: 'Strength',
                      value: _topStrength,
                      color: AppAccents.green,
                    ),
                  ),
                if (_topStrength.isNotEmpty && _needsWork.isNotEmpty)
                  const SizedBox(width: AppTheme.spaceMD),
                if (_needsWork.isNotEmpty)
                  Expanded(
                    child: _buildFormStat(
                      label: 'Needs work',
                      value: _needsWork,
                      color: AppAccents.amber,
                    ),
                  ),
              ],
            ),
          ],
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
        color: AppAccents.tint(color, alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 26,
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
                      .copyWith(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Add context',
                style: AppTheme.headingSmallThemed(context)),
            const SizedBox(width: AppTheme.spaceSM),
            const TonalChip(
              label: 'Optional',
              color: AppAccents.blue,
            ),
            const Spacer(),
            Icon(Icons.mic_none_rounded,
                size: 16, color: AppTheme.textMutedColor(context)),
            const SizedBox(width: 4),
            Text('Type or speak',
                style: AppTheme.bodySmallThemed(context)),
          ],
        ),
        const SizedBox(height: AppTheme.spaceSM),
        VoiceTextField(
          controller: _contextController,
          hintText: 'e.g. I get tight serving for the set…',
          maxLines: 2,
          style: AppTheme.bodyMediumThemed(context)
              .copyWith(color: AppTheme.textPrimaryColor(context)),
        ),
      ],
    );
  }

  Widget _buildAnalysisSkeleton() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(height: 14, width: 180, radius: AppTheme.radiusSM),
        SizedBox(height: AppTheme.spaceMD),
        SkeletonBox(height: 96, radius: AppTheme.radiusLG),
        SizedBox(height: AppTheme.spaceMD),
        SkeletonBox(height: 96, radius: AppTheme.radiusLG),
        SizedBox(height: AppTheme.spaceMD),
        SkeletonBox(height: 96, radius: AppTheme.radiusLG),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: AppTheme.cardPaddingLarge,
      decoration: BoxDecoration(
        color: AppAccents.tint(AppAccents.coral, alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppAccents.coral.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const TonalIconBadge(
            icon: Icons.error_outline_rounded,
            color: AppAccents.coral,
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            'Couldn\'t generate insight',
            style: AppTheme.headingSmallThemed(context),
          ),
          const SizedBox(height: AppTheme.spaceXS),
          Text(
            _errorMessage ?? 'Please try again',
            textAlign: TextAlign.center,
            style: AppTheme.bodySmallThemed(context),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          TextButton(
            onPressed: () => setState(() => _errorMessage = null),
            style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
            child: Text('Dismiss',
                style: AppTheme.label.copyWith(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  // ============ Structured analysis ============

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
        Row(
          children: [
            const Icon(Icons.auto_awesome_rounded,
                size: 15, color: AppAccents.violet),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Based on your last $matchesUsed matches',
                style: AppTheme.labelThemed(context),
              ),
            ),
          ],
        ),
        if (scopeNote.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spaceXS),
          Text(scopeNote, style: AppTheme.bodySmallThemed(context)),
        ],
        const SizedBox(height: AppTheme.spaceMD),
        _buildCoachSection(
          title: 'What keeps showing up',
          text: whatKeepsShowingUp['text'] as String? ?? '',
          evidence: whatKeepsShowingUp['evidence'] as String?,
          confidence: whatKeepsShowingUp['confidence'] as String?,
          trend: whatKeepsShowingUp['trend'] as String?,
          icon: Icons.radar_rounded,
          color: AppAccents.blue,
          highlighted: true,
        ),
        const SizedBox(height: AppTheme.spaceMD),
        _buildCoachSection(
          title: 'What\'s helping you win',
          text: whatsHelpingYouWin['text'] as String? ?? '',
          evidence: whatsHelpingYouWin['evidence'] as String?,
          confidence: whatsHelpingYouWin['confidence'] as String?,
          trend: whatsHelpingYouWin['trend'] as String?,
          icon: Icons.trending_up_rounded,
          color: AppAccents.green,
        ),
        const SizedBox(height: AppTheme.spaceMD),
        _buildCoachSection(
          title: 'What breaks under pressure',
          text: whatBreaksUnderPressure['text'] as String? ?? '',
          evidence: whatBreaksUnderPressure['evidence'] as String?,
          confidence: whatBreaksUnderPressure['confidence'] as String?,
          trend: whatBreaksUnderPressure['trend'] as String?,
          icon: Icons.warning_amber_rounded,
          color: AppAccents.coral,
        ),
        const SizedBox(height: AppTheme.spaceMD),
        _buildCoachSection(
          title: 'Next match focus',
          text: _buildNextMatchFocusText(nextMatchFocus),
          confidence: nextMatchFocus['confidence'] as String?,
          icon: Icons.center_focus_strong_rounded,
          color: AppAccents.violet,
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

  Widget _buildCoachSection({
    required String title,
    required String text,
    required IconData icon,
    required Color color,
    String? evidence,
    String? confidence,
    String? trend,
    bool highlighted = false,
  }) {
    return Container(
      padding: AppTheme.cardPaddingLarge,
      decoration: BoxDecoration(
        color: highlighted
            ? AppAccents.tint(color, alpha: 0.07)
            : AppTheme.cardBackground(context).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(
          color: highlighted
              ? color.withValues(alpha: 0.35)
              : AppTheme.borderColor(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TonalIconBadge(icon: icon, color: color, size: 36),
              const SizedBox(width: AppTheme.spaceSM),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.headingSmallThemed(context)
                      .copyWith(fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            text,
            style: AppTheme.bodyLargeThemed(context)
                .copyWith(height: 1.5, fontSize: 16),
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
    if ((evidence ?? '').isNotEmpty) parts.add(evidence!.trim());
    if ((confidence ?? '').isNotEmpty) {
      parts.add('Confidence: ${confidence!.trim()}');
    }
    if ((trend ?? '').isNotEmpty) parts.add('Trend: ${trend!.trim()}');
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
        color: AppAccents.tint(AppAccents.amber, alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppAccents.amber.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const TonalIconBadge(
                icon: Icons.fitness_center_rounded,
                color: AppAccents.amber,
                size: 36,
              ),
              const SizedBox(width: AppTheme.spaceSM),
              Text(
                'Practice plan',
                style:
                    AppTheme.headingSmallThemed(context).copyWith(fontSize: 16),
              ),
            ],
          ),
          if (drillName.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceSM),
            Text(drillName,
                style: AppTheme.headingSmallThemed(context)
                    .copyWith(fontSize: 15)),
          ],
          if (objective.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceXS),
            Text(objective,
                style: AppTheme.bodyMediumThemed(context).copyWith(height: 1.5)),
          ],
        ],
      ),
    );
  }

  Widget _buildActionsRow(String shareText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton.icon(
          onPressed: _isSaving ? null : () => _saveCurrentAdvice(shareText),
          style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
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
            _isSaving ? 'Saving…' : 'Save',
            style: AppTheme.label.copyWith(color: AppTheme.primary),
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
          style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
          icon: Icon(Icons.refresh_rounded,
              size: 18, color: AppTheme.textSecondaryColor(context)),
          label: Text(
            'New review',
            style:
                AppTheme.label.copyWith(color: AppTheme.textSecondaryColor(context)),
          ),
        ),
      ],
    );
  }

  // ============ Save + Saved view ============

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
              success ? 'Saved — keeps your latest 3' : 'Could not save. Try again.',
              style: AppTheme.bodyMediumThemed(context)
                  .copyWith(color: Colors.white),
            ),
            backgroundColor: success ? AppAccents.green : AppAccents.coral,
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
    if (mounted) setState(() => _savedEntries = entries);
  }

  Widget _buildSavedView() {
    if (_savedEntries.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceXXL),
          child: Center(
            child: Column(
              children: [
                const TonalIconBadge(
                  icon: Icons.bookmark_border_rounded,
                  color: AppAccents.violet,
                  size: 60,
                ),
                const SizedBox(height: AppTheme.spaceMD),
                Text('No saved advice yet',
                    style: AppTheme.headingSmallThemed(context)),
                const SizedBox(height: AppTheme.spaceXS),
                Text(
                  'Generate a review and tap Save to keep it here\n(your latest 3 are kept).',
                  style: AppTheme.bodySmallThemed(context),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMD,
        0,
        AppTheme.spaceMD,
        AppTheme.spaceXXL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Saved advice', style: AppTheme.headingMediumThemed(context)),
          const SizedBox(height: AppTheme.spaceXS),
          Text('Most recent first · keeps your latest 3',
              style: AppTheme.bodySmallThemed(context)),
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
      ),
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

    final needsExpansion = content.length > 200;
    final previewText =
        needsExpansion ? '${content.substring(0, 200).trimRight()}…' : content;

    return PressableCard(
      padding: AppTheme.cardPaddingLarge,
      accent: isExpanded ? AppAccents.violet : null,
      onTap: needsExpansion
          ? () {
              HapticFeedback.selectionClick();
              setState(() => _expandedCardIndex = isExpanded ? null : index);
            }
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (dateLabel.isNotEmpty)
                TonalChip(label: dateLabel, color: AppAccents.violet)
              else
                const SizedBox.shrink(),
              if (needsExpansion)
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(Icons.expand_more_rounded,
                      size: 20, color: AppTheme.textMutedColor(context)),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSM),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Text(
              isExpanded || !needsExpansion ? content : previewText,
              style: AppTheme.bodyMediumThemed(context).copyWith(height: 1.5),
              maxLines: isExpanded || !needsExpansion ? null : 4,
              overflow: isExpanded || !needsExpansion
                  ? TextOverflow.clip
                  : TextOverflow.ellipsis,
            ),
          ),
          if (needsExpansion && !isExpanded) ...[
            const SizedBox(height: AppTheme.spaceXS),
            Text('Tap to read more',
                style: AppTheme.label
                    .copyWith(color: AppTheme.primary.withValues(alpha: 0.8))),
          ],
        ],
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
