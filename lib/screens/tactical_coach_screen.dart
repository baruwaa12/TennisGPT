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

/// Coach Screen — Broadcast.
/// Scoreboard chrome, uppercase tabs and a bold review CTA, fronting an
/// AI tactical breakdown of the player's recent matches.
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
    return Scaffold(
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
                child:
                    _activeTab == 1 ? _buildSavedView() : _buildCoachView(),
              ),
            ],
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
          Container(width: 4, height: 24, color: AppTheme.primary),
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
          border: Border(
            bottom: BorderSide(color: AppTheme.borderColor(context)),
          ),
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
            const SkeletonBox(height: 130, radius: AppTheme.radiusSM)
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
      return Container(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Text(
          'Log a few matches and your coach will spot the patterns.',
          style: AppTheme.bodyMediumThemed(context),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        border: Border(
          left: BorderSide(color: AppTheme.primary, width: 3),
          top: BorderSide(color: AppTheme.borderColor(context)),
          right: BorderSide(color: AppTheme.borderColor(context)),
          bottom: BorderSide(color: AppTheme.borderColor(context)),
        ),
      ),
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('FORM',
                  style: AppTheme.labelThemed(context)
                      .copyWith(color: AppTheme.primary, letterSpacing: 2)),
              const SizedBox(height: 2),
              Text('$winPct%',
                  style: AppTheme.scorelineThemed(context, size: 46)),
            ],
          ),
          const SizedBox(width: AppTheme.spaceLG),
          Container(width: 1, height: 76, color: AppTheme.borderColor(context)),
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
    );
  }

  Widget _coachFormLine(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(label,
              style: AppTheme.labelThemed(context).copyWith(letterSpacing: 1)),
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
    final disabled = _isLoading;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: GestureDetector(
        onTap: disabled
            ? null
            : () {
                HapticFeedback.mediumImpact();
                _reviewRecentMatchHistory();
              },
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isGenerating) ...[
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                ),
                const SizedBox(width: AppTheme.spaceSM),
              ] else ...[
                const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 19),
                const SizedBox(width: AppTheme.spaceSM),
              ],
              Text(
                _isGenerating ? 'REVIEWING…' : 'REVIEW MY MATCHES',
                style: AppTheme.headingSmall.copyWith(
                    color: Colors.white, fontSize: 15, letterSpacing: 1.2),
              ),
            ],
          ),
        ),
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
    const errorColor = AppAccents.negative;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: errorColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const TonalIconBadge(
              icon: Icons.error_outline_rounded, color: errorColor),
          const SizedBox(height: AppTheme.spaceSM),
          Text('Couldn\'t generate insight',
              style: AppTheme.headingSmallThemed(context)),
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
        Text(
          'BASED ON YOUR LAST $matchesUsed MATCHES',
          style: AppTheme.labelThemed(context).copyWith(letterSpacing: 1.2),
        ),
        if (scopeNote.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spaceXS),
          Text(scopeNote, style: AppTheme.bodySmallThemed(context)),
        ],
        const SizedBox(height: AppTheme.spaceMD),
        _buildCoachSection(
          step: '01',
          title: 'What keeps showing up',
          text: whatKeepsShowingUp['text'] as String? ?? '',
          evidence: whatKeepsShowingUp['evidence'] as String?,
          confidence: whatKeepsShowingUp['confidence'] as String?,
          trend: whatKeepsShowingUp['trend'] as String?,
          icon: Icons.radar_rounded,
          accentColor: AppAccents.blue,
        ),
        const SizedBox(height: AppTheme.spaceLG),
        _buildCoachSection(
          step: '02',
          title: 'What\'s helping you win',
          text: whatsHelpingYouWin['text'] as String? ?? '',
          evidence: whatsHelpingYouWin['evidence'] as String?,
          confidence: whatsHelpingYouWin['confidence'] as String?,
          trend: whatsHelpingYouWin['trend'] as String?,
          icon: Icons.trending_up_rounded,
          accentColor: AppAccents.green,
        ),
        const SizedBox(height: AppTheme.spaceLG),
        _buildCoachSection(
          step: '03',
          title: 'What breaks under pressure',
          text: whatBreaksUnderPressure['text'] as String? ?? '',
          evidence: whatBreaksUnderPressure['evidence'] as String?,
          confidence: whatBreaksUnderPressure['confidence'] as String?,
          trend: whatBreaksUnderPressure['trend'] as String?,
          icon: Icons.warning_amber_rounded,
          accentColor: AppAccents.coral,
        ),
        const SizedBox(height: AppTheme.spaceLG),
        // The single accent moment — the one thing to act on next.
        _buildCoachSection(
          step: '04',
          title: 'Next match focus',
          text: _buildNextMatchFocusText(nextMatchFocus),
          confidence: nextMatchFocus['confidence'] as String?,
          icon: Icons.center_focus_strong_rounded,
          accentColor: AppAccents.violet,
          highlighted: true,
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
    String? step,
    Color? accentColor,
    String? evidence,
    String? confidence,
    String? trend,
    bool highlighted = false,
  }) {
    // Editorial: a numbered block with no card chrome; the highlighted focus
    // gets a thin accent rule on the left.
    final hasMeta = (evidence ?? '').isNotEmpty ||
        (confidence ?? '').isNotEmpty ||
        (trend ?? '').isNotEmpty;
    final block = Column(
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
                  color: highlighted
                      ? AppTheme.primary
                      : AppTheme.textMutedColor(context),
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
                  color: highlighted ? AppTheme.primary : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceSM),
        Text(
          text,
          style: AppTheme.bodyLargeThemed(context)
              .copyWith(height: 1.6, fontSize: 16),
        ),
        if (hasMeta) ...[
          const SizedBox(height: AppTheme.spaceSM),
          Text(_buildEvidenceMeta(evidence, confidence, trend),
              style: AppTheme.labelThemed(context)),
        ],
      ],
    );

    if (highlighted) {
      return Container(
        padding: const EdgeInsets.only(left: AppTheme.spaceMD),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: AppTheme.primary, width: 2.5),
          ),
        ),
        child: block,
      );
    }
    return block;
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
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        color: AppTheme.elevatedBackground(context).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
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
                style:
                    AppTheme.bodyMediumThemed(context).copyWith(height: 1.55)),
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
            style: AppTheme.label
                .copyWith(color: AppTheme.textSecondaryColor(context)),
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
      padding: const EdgeInsets.all(AppTheme.spaceLG),
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
            child: Text(
              isExpanded || !needsExpansion ? content : previewText,
              style: AppTheme.bodyMediumThemed(context).copyWith(height: 1.55),
              maxLines: isExpanded || !needsExpansion ? null : 4,
              overflow: isExpanded || !needsExpansion
                  ? TextOverflow.clip
                  : TextOverflow.ellipsis,
            ),
          ),
          if (needsExpansion && !isExpanded) ...[
            const SizedBox(height: AppTheme.spaceXS),
            Text('Tap to read more',
                style: AppTheme.label.copyWith(color: AppTheme.primary)),
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
