import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/composure_kit.dart';
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

/// Coach Screen — ComposureDesign1.
/// A calm intelligence surface: uppercase tabs, a form card, and a brand
/// review CTA, fronting an AI tactical breakdown of the player's recent
/// matches, styled with the ComposureDesign1 token system.
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

  void _onTabChanged(int i) {
    setState(() => _activeTab = i);
    if (i == 1) _loadSavedEntries();
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackground(context),
        body: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.translucent,
            child: Column(
              children: [
                _coachTopBar(),
                _coachTabs(),
                Expanded(
                  child: _activeTab == 1
                      ? _buildSavedView()
                      : _buildCoachView(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _coachTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spaceSM, AppTheme.spaceSM,
          AppTheme.spaceMD, AppTheme.spaceSM),
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
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
          ),
          const SizedBox(width: 10),
          Text('TACTICAL COACH',
              style: AppTheme.labelThemed(context).copyWith(
                  fontSize: 16,
                  letterSpacing: 2,
                  color: AppTheme.textPrimaryColor(context))),
        ],
      ),
    );
  }

  Widget _coachTabs() {
    Widget tab(String label, int index) {
      final selected = _activeTab == index;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            _onTabChanged(index);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceSM),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? AppTheme.primary : Colors.transparent,
                  width: 2.5,
                ),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTheme.labelThemed(context).copyWith(
                letterSpacing: 1.5,
                color: selected
                    ? AppTheme.textPrimaryColor(context)
                    : AppTheme.textMutedColor(context),
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceLG, 0, AppTheme.spaceLG, AppTheme.spaceSM),
      child: Container(
        decoration: BoxDecoration(
          border:
              Border(bottom: BorderSide(color: AppTheme.borderColor(context))),
        ),
        child: Row(children: [tab('COACH', 0), tab('SAVED', 1)]),
      ),
    );
  }

  Widget _buildCoachView() {
    final winPct = _total > 0 ? ((_wins / _total) * 100).round() : 0;
    return SingleChildScrollView(
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(AppTheme.spaceLG, AppTheme.spaceSM,
          AppTheme.spaceLG, AppTheme.spaceXXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoading)
            const SkeletonBox(height: 130, radius: AppTheme.radiusLG)
          else
            _coachForm(winPct),
          const SizedBox(height: AppTheme.spaceLG),
          _buildContextInput(),
          const SizedBox(height: AppTheme.spaceMD),
          _reviewCta(),
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

  Widget _coachForm(int winPct) {
    if (_recentMatches.isEmpty) {
      return TGCard(
        child: Text(
          'Log a few matches and your coach will spot the patterns.',
          style: AppTheme.bodyMediumThemed(context),
        ),
      );
    }

    return Semantics(
      label: 'Current form: $winPct percent win rate',
      child: TGCard(
        elevated: true,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const CEyebrow('Form'),
                const SizedBox(height: 2),
                Text('$winPct%',
                    style: AppTheme.scorelineThemed(context, size: 46)),
              ],
            ),
            const SizedBox(width: AppTheme.spaceLG),
            Container(
                width: 1, height: 76, color: AppTheme.borderColor(context)),
            const SizedBox(width: AppTheme.spaceLG),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_formTrend.isNotEmpty) ...[
                    Text(_formTrend.toUpperCase(),
                        style: AppTheme.labelThemed(context)
                            .copyWith(color: AppTheme.win, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                  ],
                  if (_topStrength.isNotEmpty)
                    _coachFormLine('STRENGTH', _topStrength),
                  if (_needsWork.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _coachFormLine('NEEDS WORK', _needsWork),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coachFormLine(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(label,
              style: AppTheme.labelThemed(context).copyWith(
                  letterSpacing: 1, color: AppTheme.textMutedColor(context))),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.headingSmallThemed(context).copyWith(fontSize: 15),
          ),
        ),
      ],
    );
  }

  Widget _reviewCta() {
    return CPrimaryButton(
      label: 'Review my matches',
      loadingLabel: 'Reviewing…',
      icon: Icons.auto_awesome_rounded,
      loading: _isGenerating,
      onPressed: _isLoading ? null : _reviewRecentMatchHistory,
    );
  }

  Widget _buildContextInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Add context',
                style: AppTheme.headingSmallThemed(context)
                    .copyWith(letterSpacing: -0.2)),
            const SizedBox(width: AppTheme.spaceSM),
            const TonalChip(label: 'Optional'),
            const Spacer(),
            Icon(Icons.mic_none_rounded,
                size: 16, color: AppTheme.textMutedColor(context)),
            const SizedBox(width: 4),
            Text('Type or speak', style: AppTheme.bodySmallThemed(context)),
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
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.loss.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const TonalIconBadge(
              icon: Icons.error_outline_rounded, color: AppTheme.loss),
          const SizedBox(height: AppTheme.spaceSM),
          Text('Couldn\'t generate insight',
              style: AppTheme.headingSmallThemed(context)),
          const SizedBox(height: AppTheme.spaceXS),
          Text(
            _errorMessage ?? 'Please try again',
            textAlign: TextAlign.center,
            style: AppTheme.bodySmallThemed(context)
                .copyWith(color: AppTheme.textSecondaryColor(context)),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          TextButton(
            onPressed: () => setState(() => _errorMessage = null),
            style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
            child: Text('Dismiss',
                style: AppTheme.labelThemed(context)
                    .copyWith(color: AppTheme.primary)),
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

    final headerLabel = matchesUsed > 0
        ? 'BASED ON YOUR LAST $matchesUsed ${matchesUsed == 1 ? 'MATCH' : 'MATCHES'}'
        : 'YOUR COACH REVIEW';

    // Keyed per result so the staggered reveal replays for each new review.
    return KeyedSubtree(
      key: ValueKey(identityHashCode(data)),
      child: Column(
        key: _insightCardKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RevealIn(
            delayMs: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headerLabel,
                  style: AppTheme.labelThemed(context).copyWith(
                      letterSpacing: 1.2,
                      color: AppTheme.textMutedColor(context)),
                ),
                if (scopeNote.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spaceXS),
                  Text(scopeNote,
                      style: AppTheme.bodySmallThemed(context).copyWith(
                          color: AppTheme.textSecondaryColor(context))),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          _RevealIn(
            delayMs: 80,
            child: _buildCoachSection(
              step: '01',
              title: 'What keeps showing up',
              text: whatKeepsShowingUp['text'] as String? ?? '',
              evidence: whatKeepsShowingUp['evidence'] as String?,
              confidence: whatKeepsShowingUp['confidence'] as String?,
              trend: whatKeepsShowingUp['trend'] as String?,
            ),
          ),
          const SizedBox(height: AppTheme.spaceLG),
          _RevealIn(
            delayMs: 180,
            child: _buildCoachSection(
              step: '02',
              title: 'What\'s helping you win',
              text: whatsHelpingYouWin['text'] as String? ?? '',
              evidence: whatsHelpingYouWin['evidence'] as String?,
              confidence: whatsHelpingYouWin['confidence'] as String?,
              trend: whatsHelpingYouWin['trend'] as String?,
            ),
          ),
          const SizedBox(height: AppTheme.spaceLG),
          _RevealIn(
            delayMs: 280,
            child: _buildCoachSection(
              step: '03',
              title: 'What breaks under pressure',
              text: whatBreaksUnderPressure['text'] as String? ?? '',
              evidence: whatBreaksUnderPressure['evidence'] as String?,
              confidence: whatBreaksUnderPressure['confidence'] as String?,
              trend: whatBreaksUnderPressure['trend'] as String?,
            ),
          ),
          const SizedBox(height: AppTheme.spaceLG),
          // The single accent moment — the one thing to act on next.
          _RevealIn(
            delayMs: 400,
            child: _buildNextFocusCard(nextMatchFocus),
          ),
          if (hasPracticePlan) ...[
            const SizedBox(height: AppTheme.spaceMD),
            _RevealIn(
              delayMs: 500,
              child: _buildPracticePlanCard(practicePlan),
            ),
          ],
          const SizedBox(height: AppTheme.spaceLG),
          _RevealIn(
            delayMs: 560,
            child: _buildActionsRow(shareText),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachSection({
    required String title,
    required String text,
    String? step,
    String? evidence,
    String? confidence,
    String? trend,
  }) {
    // Editorial: a numbered block with no card chrome. The advice text is the
    // hero of the block, so it renders in the primary text color.
    final evidenceText = (evidence ?? '').trim();
    final trendBadge = _trendBadge(trend);
    final confidenceLabel = _confidenceLabel(confidence);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (step != null) ...[
              Text(
                step,
                style: AppTheme.labelThemed(context).copyWith(
                  letterSpacing: 1,
                  color: AppTheme.textMutedColor(context),
                ),
              ),
              const SizedBox(width: AppTheme.spaceSM),
            ],
            Expanded(
              child: Text(
                title,
                style: AppTheme.headingSmallThemed(context).copyWith(
                  fontSize: 18,
                  letterSpacing: -0.3,
                  color: AppTheme.textPrimaryColor(context),
                ),
              ),
            ),
            if (trendBadge != null) ...[
              const SizedBox(width: AppTheme.spaceSM),
              trendBadge,
            ],
          ],
        ),
        const SizedBox(height: AppTheme.spaceSM),
        Text(
          text,
          style: AppTheme.bodyLargeThemed(context).copyWith(
              height: 1.6,
              fontSize: 16,
              color: AppTheme.textPrimaryColor(context)),
        ),
        if (evidenceText.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spaceSM),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 2,
                height: 32,
                margin: const EdgeInsets.only(top: 2),
                color: AppTheme.borderColor(context),
              ),
              const SizedBox(width: AppTheme.spaceSM),
              Expanded(
                child: Text(
                  evidenceText,
                  style: AppTheme.bodySmallThemed(context).copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textSecondaryColor(context),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (confidenceLabel != null) ...[
          const SizedBox(height: AppTheme.spaceSM),
          CBadge(label: confidenceLabel),
        ],
      ],
    );
  }

  /// Translates the model's confidence value into player-friendly wording.
  String? _confidenceLabel(String? confidence) {
    switch (confidence?.toLowerCase().trim()) {
      case 'high':
        return 'Clear pattern';
      case 'medium':
        return 'Solid read';
      case 'low':
        return 'Early signs — log more matches';
      default:
        return null;
    }
  }

  /// Trend rendered as a colored badge with a direction icon.
  /// "unclear" is intentionally hidden — it adds noise, not signal.
  Widget? _trendBadge(String? trend) {
    switch (trend?.toLowerCase().trim()) {
      case 'improving':
        return const CBadge(
          label: 'Improving',
          variant: CBadgeVariant.success,
          icon: Icons.trending_up_rounded,
        );
      case 'slipping':
        return const CBadge(
          label: 'Slipping',
          variant: CBadgeVariant.danger,
          icon: Icons.trending_down_rounded,
        );
      case 'stable':
        return const CBadge(
          label: 'Steady',
          variant: CBadgeVariant.neutral,
          icon: Icons.trending_flat_rounded,
        );
      default:
        return null;
    }
  }

  /// The one thing to act on next — a proper card, not just an accent rule.
  Widget _buildNextFocusCard(Map<String, dynamic> nextMatchFocus) {
    final text = (nextMatchFocus['text'] as String? ?? '').trim();
    final triggerRule = (nextMatchFocus['triggerRule'] as String? ?? '').trim();
    final confidenceLabel =
        _confidenceLabel(nextMatchFocus['confidence'] as String?);

    return Container(
      padding: AppTheme.cardPaddingLarge,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.35)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '04',
                style: AppTheme.labelThemed(context)
                    .copyWith(letterSpacing: 1, color: AppTheme.primary),
              ),
              const SizedBox(width: AppTheme.spaceSM),
              const Expanded(child: CEyebrow('Next match focus')),
              if (confidenceLabel != null)
                CBadge(label: confidenceLabel, variant: CBadgeVariant.brand),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            text,
            style: AppTheme.headingSmallThemed(context).copyWith(
              fontSize: 17,
              height: 1.45,
              letterSpacing: -0.2,
              color: AppTheme.textPrimaryColor(context),
            ),
          ),
          if (triggerRule.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceMD),
            Divider(color: AppTheme.borderColor(context), height: 1),
            const SizedBox(height: AppTheme.spaceMD),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.bolt_rounded,
                    size: 18, color: AppTheme.primary),
                const SizedBox(width: AppTheme.spaceSM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'IN-MATCH TRIGGER',
                        style: AppTheme.labelThemed(context).copyWith(
                          letterSpacing: 1.2,
                          color: AppTheme.textMutedColor(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        triggerRule,
                        style: AppTheme.bodyMediumThemed(context).copyWith(
                          height: 1.5,
                          color: AppTheme.textPrimaryColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPracticePlanCard(Map<String, dynamic> practicePlan) {
    final drillName = practicePlan['drillName'] as String? ?? '';
    final objective = practicePlan['objective'] as String? ?? '';

    return TGCard(
      elevated: true,
      padding: AppTheme.cardPaddingLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const TonalIconBadge(
                  icon: Icons.fitness_center_rounded, size: 36),
              const SizedBox(width: AppTheme.spaceSM),
              Text('Practice plan',
                  style: AppTheme.headingSmallThemed(context)
                      .copyWith(fontSize: 16)),
            ],
          ),
          if (drillName.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceMD),
            Text(drillName,
                style: AppTheme.headingSmallThemed(context)
                    .copyWith(fontSize: 15)),
          ],
          if (objective.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceXS),
            Text(objective,
                style: AppTheme.bodyMediumThemed(context).copyWith(height: 1.55)),
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
          onPressed: _isSaving ? null : _saveCurrentAdvice,
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
              : const Icon(Icons.bookmark_outline_rounded,
                  size: 18, color: AppTheme.primary),
          label: Text(
            _isSaving ? 'Saving…' : 'Save',
            style: AppTheme.labelThemed(context).copyWith(color: AppTheme.primary),
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
            style: AppTheme.labelThemed(context)
                .copyWith(color: AppTheme.textSecondaryColor(context)),
          ),
        ),
      ],
    );
  }

  // ============ Save + Saved view ============

  Future<void> _saveCurrentAdvice() async {
    if (_isSaving || _analysisResult == null) return;
    setState(() => _isSaving = true);
    HapticFeedback.lightImpact();

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      // Save the structured JSON so the Saved tab can re-render full sections.
      final success =
          await apiService.saveTacticalAdvice(jsonEncode(_analysisResult));

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Saved — keeps your latest 3'
                  : 'Could not save. Try again.',
              style: AppTheme.bodyMediumThemed(context)
                  .copyWith(color: Colors.white),
            ),
            backgroundColor:
                success ? AppAccents.positive : AppAccents.negative,
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
                    icon: Icons.bookmark_border_rounded, size: 60),
                const SizedBox(height: AppTheme.spaceMD),
                Text('No saved advice yet',
                    style: AppTheme.headingSmallThemed(context)),
                const SizedBox(height: AppTheme.spaceXS),
                Text(
                  'Generate a review and tap Save to keep it here\n(your latest 3 are kept).',
                  style: AppTheme.bodySmallThemed(context)
                      .copyWith(color: AppTheme.textSecondaryColor(context)),
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
        AppTheme.spaceLG,
        0,
        AppTheme.spaceLG,
        AppTheme.spaceXXL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Saved advice',
              style: AppTheme.headingMediumThemed(context)
                  .copyWith(letterSpacing: -0.4)),
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

  /// Decodes a saved entry back into the structured coach format, or null
  /// for legacy plain-text entries.
  Map<String, dynamic>? _tryDecodeStructured(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic> &&
          decoded.containsKey('whatKeepsShowingUp') &&
          decoded.containsKey('nextMatchFocus')) {
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  String _savedSectionText(Map<String, dynamic> data, String key) {
    final section = data[key];
    if (section is Map<String, dynamic>) {
      return (section['text'] as String? ?? '').trim();
    }
    return '';
  }

  Widget _buildSavedSection(String title, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: AppTheme.labelThemed(context).copyWith(
              letterSpacing: 1.2, color: AppTheme.textMutedColor(context)),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: AppTheme.bodyMediumThemed(context).copyWith(
              height: 1.5, color: AppTheme.textPrimaryColor(context)),
        ),
      ],
    );
  }

  Widget _buildSavedStructuredPreview(Map<String, dynamic> data) {
    final focusText = _savedSectionText(data, 'nextMatchFocus');
    final fallback = _savedSectionText(data, 'whatKeepsShowingUp');
    return _buildSavedSection(
      focusText.isNotEmpty ? 'Next match focus' : 'What keeps showing up',
      focusText.isNotEmpty ? focusText : fallback,
    );
  }

  Widget _buildSavedStructuredFull(Map<String, dynamic> data) {
    final sections = <(String, String)>[
      ('What keeps showing up', _savedSectionText(data, 'whatKeepsShowingUp')),
      ('What\'s helping you win', _savedSectionText(data, 'whatsHelpingYouWin')),
      (
        'What breaks under pressure',
        _savedSectionText(data, 'whatBreaksUnderPressure')
      ),
      ('Next match focus', _savedSectionText(data, 'nextMatchFocus')),
    ].where((s) => s.$2.isNotEmpty).toList();

    final nextFocus = data['nextMatchFocus'];
    final triggerRule = nextFocus is Map<String, dynamic>
        ? (nextFocus['triggerRule'] as String? ?? '').trim()
        : '';

    final practicePlan = data['optionalPracticePlan'];
    final drillName = practicePlan is Map<String, dynamic>
        ? (practicePlan['drillName'] as String? ?? '').trim()
        : '';
    final objective = practicePlan is Map<String, dynamic>
        ? (practicePlan['objective'] as String? ?? '').trim()
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: AppTheme.spaceMD),
          _buildSavedSection(sections[i].$1, sections[i].$2),
        ],
        if (triggerRule.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spaceSM),
          _buildSavedSection('In-match trigger', triggerRule),
        ],
        if (drillName.isNotEmpty || objective.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spaceMD),
          _buildSavedSection(
              'Practice plan',
              [drillName, objective]
                  .where((s) => s.isNotEmpty)
                  .join(' — ')),
        ],
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

    final structured = _tryDecodeStructured(content);
    final needsExpansion = structured != null || content.length > 200;
    final previewText = structured == null && needsExpansion
        ? '${content.substring(0, 200).trimRight()}…'
        : content;

    final Widget body;
    if (structured != null) {
      body = isExpanded
          ? _buildSavedStructuredFull(structured)
          : _buildSavedStructuredPreview(structured);
    } else {
      body = Text(
        isExpanded || !needsExpansion ? content : previewText,
        style: AppTheme.bodyMediumThemed(context).copyWith(height: 1.55),
        maxLines: isExpanded || !needsExpansion ? null : 4,
        overflow: isExpanded || !needsExpansion
            ? TextOverflow.clip
            : TextOverflow.ellipsis,
      );
    }

    final card = TGCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (dateLabel.isNotEmpty)
                TonalChip(label: dateLabel)
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
            child: SizedBox(width: double.infinity, child: body),
          ),
          if (needsExpansion && !isExpanded) ...[
            const SizedBox(height: AppTheme.spaceXS),
            Text(
                structured != null ? 'Tap for full review' : 'Tap to read more',
                style: AppTheme.labelThemed(context)
                    .copyWith(color: AppTheme.primary)),
          ],
        ],
      ),
    );

    if (!needsExpansion) {
      return Semantics(label: 'Saved advice from $dateLabel', child: card);
    }

    return Semantics(
      button: true,
      label: 'Saved advice from $dateLabel',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _expandedCardIndex = isExpanded ? null : index);
        },
        child: card,
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

/// Fades and slides its child in after [delayMs], so result sections land
/// one after another instead of appearing as a single wall of text.
class _RevealIn extends StatefulWidget {
  const _RevealIn({required this.delayMs, required this.child});

  final int delayMs;
  final Widget child;

  @override
  State<_RevealIn> createState() => _RevealInState();
}

class _RevealInState extends State<_RevealIn> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.05),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
