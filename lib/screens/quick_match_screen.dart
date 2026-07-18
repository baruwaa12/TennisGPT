import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/composure_kit.dart';
import '../models/match_performance.dart';
import '../services/match_history_service.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../services/purchase_service.dart';
import '../services/usage_service.dart';
import '../services/celebration_service.dart';
import '../services/streak_service.dart';
import '../utils/match_format_utils.dart';
import '../widgets/shareable_card.dart';
import '../widgets/guided_set_score_editor.dart';
import 'add_match_screen.dart';

class _SetScore {
  int you;
  int opp;
  int? tbYou;
  int? tbOpp;

  _SetScore()
      : you = 0,
        opp = 0;
}

/// Quick Match Log — ComposureDesign1.
///
/// Design Philosophy:
/// - Speed first: Log in under 30 seconds
/// - Minimal inputs: Result + Score only required
/// - Calm tactical canvas: token surfaces, tracked labels, brand CTA
/// - Clear hierarchy: One decision at a time
///
/// Flow:
/// 1. Select match format
/// 2. Select result (Win/Loss)
/// 3. Enter set scores
/// 4. Optional: Opponent name + quick note
/// 5. Save → Success → Optional reflection

class QuickMatchScreen extends StatefulWidget {
  const QuickMatchScreen({super.key});

  @override
  State<QuickMatchScreen> createState() => _QuickMatchScreenState();
}

class _QuickMatchScreenState extends State<QuickMatchScreen>
    with SingleTickerProviderStateMixin {
  final MatchHistoryService _matchHistoryService = MatchHistoryService();
  final TextEditingController _opponentController = TextEditingController();
  final TextEditingController _quickNoteController = TextEditingController();

  String _matchFormat = MatchFormat.fast4;
  String _selectedResult = 'Win';
  final List<_SetScore> _setScores = [
    _SetScore(),
    _SetScore(),
    _SetScore(),
  ];
  bool _isSaving = false;
  bool _showSuccess = false;
  MatchPerformance? _savedMatch;
  String? _draftMatchId;
  DateTime? _draftMatchDate;
  String _guidedScoreLine = '';
  String? _guidedScoreError;
  MatchScoreParseResult? _guidedScoreParsed;

  late AnimationController _successController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _successController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _opponentController.dispose();
    _quickNoteController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _saveMatch() async {
    final scoreError = _guidedScoreError;
    if (scoreError != null) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(scoreError,
              style: AppTheme.bodyMediumThemed(context)
                  .copyWith(color: AppTheme.textPrimaryColor(context))),
          backgroundColor: AppTheme.elevatedBackground(context),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Check usage limits (respects feature flags)
    final purchaseService =
        Provider.of<PurchaseService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final usageService = Provider.of<UsageService>(context, listen: false);
    setState(() => _isSaving = true);
    HapticFeedback.lightImpact();

    try {
      final match = _buildQuickMatch();
      await _matchHistoryService.saveOrUpdateMatch(match);

      // Record usage
      if (!AppConfig.hasPremiumAccess(
        revenueCatPremium: purchaseService.isPremium,
        backendPremium: authService.isPremium,
        email: authService.userEmail,
      )) {
        await usageService.recordMatchLogged();
      }

      setState(() {
        _isSaving = false;
        _showSuccess = true;
        _savedMatch = match;
        _draftMatchId = match.id;
        _draftMatchDate = match.date;
      });

      _successController.forward();
      HapticFeedback.mediumImpact();

      // Handle celebrations
      if (mounted) {
        final streakService =
            Provider.of<StreakService>(context, listen: false);
        final streakMilestone = await streakService.recordActivity();

        if (!mounted) return;
        if (streakMilestone != null && mounted) {
          CelebrationService.showAchievement(
            context,
            type: CelebrationType.milestone,
            title: streakMilestone.title,
            message: streakMilestone.message,
          );
        }

        await CelebrationService.checkFirstMatch(context);
        if (!mounted) return;
        if (match.result == 'Win') {
          await CelebrationService.checkFirstWin(context);
          if (!mounted) return;
        }

        final matchCount = await _matchHistoryService.getTotalMatches();
        if (!mounted) return;
        await CelebrationService.checkTenMatches(context, matchCount);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving match',
                style: AppTheme.bodyMediumThemed(context)
                    .copyWith(color: Colors.white)),
            backgroundColor: AppTheme.loss,
          ),
        );
      }
    }
  }

  MatchPerformance _buildQuickMatch() {
    final parsedScore = _guidedScoreParsed;
    if (parsedScore == null) {
      throw Exception('Score not parsed');
    }

    final matchId =
        _draftMatchId ?? DateTime.now().millisecondsSinceEpoch.toString();
    final matchDate = _draftMatchDate ?? DateTime.now();
    final opponent = _opponentController.text.trim().isNotEmpty
        ? _opponentController.text.trim()
        : 'Opponent';
    final quickNote = _quickNoteController.text.trim();
    final setsWon = parsedScore.setsWon;
    final setsLost = parsedScore.setsLost;
    final result = setsWon > setsLost ? 'Win' : 'Loss';

    return MatchPerformance(
      id: matchId,
      date: matchDate,
      opponent: opponent,
      result: result,
      setsWon: setsWon,
      setsLost: setsLost,
      matchFormat: _matchFormat,
      scoreLine: _guidedScoreLine,
      setScores: parsedScore.setScores,
      opponentLevelSeed: '',
      surface: 'Hard',
      weather: '',
      notes: quickNote,
      matchSummary: '',
      mentalNotes: '',
      tacticalNotes: '',
      strengthNotes: '',
      weaknessNotes: '',
      strengths: {},
      weaknesses: {},
      keyMoments: [],
      tacticalAnalysis: '',
      recommendedDrills: [],
    );
  }

  Future<MatchPerformance?> _saveOrRefreshQuickDraft() async {
    final scoreError = _guidedScoreError;
    if (scoreError != null || _guidedScoreParsed == null) {
      return null;
    }

    final draft = _buildQuickMatch();
    await _matchHistoryService.saveOrUpdateMatch(draft);
    setState(() {
      _draftMatchId = draft.id;
      _draftMatchDate = draft.date;
    });
    return draft;
  }

  bool get _isNormalSets => _matchFormat == MatchFormat.bestOf3;

  void _clearIrrelevantTiebreak(_SetScore score) {
    if (_isNormalSets) {
      if (!_isNormalTiebreakApplicable(score)) {
        score.tbYou = null;
        score.tbOpp = null;
      }
    } else {
      if (!_isFast4TiebreakApplicable(score)) {
        score.tbYou = null;
        score.tbOpp = null;
      }
    }
  }

  bool _isFast4TiebreakApplicable(_SetScore score) {
    return (score.you == 3 && score.opp == 3) ||
        (score.you == 4 && score.opp == 3) ||
        (score.opp == 4 && score.you == 3);
  }

  bool _isNormalTiebreakApplicable(_SetScore score) {
    return (score.you == 7 && score.opp == 6) ||
        (score.opp == 7 && score.you == 6) ||
        (score.you == 6 && score.opp == 6);
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
      child: _showSuccess ? _buildSuccessView() : _buildFormView(),
    );
  }

  Widget _buildFormView() {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground(context),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(AppTheme.spaceLG,
                      AppTheme.spaceSM, AppTheme.spaceLG, AppTheme.spaceXL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Match Format - Primary
                      _buildFormatSection(),

                      const SizedBox(height: AppTheme.spaceLG),

                      // Result
                      _buildResultSection(),

                      const SizedBox(height: AppTheme.spaceLG),

                      // Score - Secondary
                      _buildScoreSection(),

                      const SizedBox(height: AppTheme.spaceLG),

                      // Optional Fields
                      _buildOptionalSection(),

                      const SizedBox(height: AppTheme.spaceXL),
                    ],
                  ),
                ),
              ),

              // Save Button - Fixed at bottom
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spaceSM, AppTheme.spaceSM,
          AppTheme.spaceMD, AppTheme.spaceSM),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            tooltip: 'Close',
            iconSize: 22,
            style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
            color: AppTheme.textSecondaryColor(context),
            icon: const Icon(Icons.close_rounded),
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
          Text('LOG A MATCH',
              style: AppTheme.labelThemed(context).copyWith(
                  fontSize: 16,
                  letterSpacing: 2,
                  color: AppTheme.textPrimaryColor(context))),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text.toUpperCase(),
        style: AppTheme.labelThemed(context)
            .copyWith(letterSpacing: 2, color: AppTheme.textMutedColor(context)));
  }

  Widget _buildFormatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Match format'),
        const SizedBox(height: AppTheme.spaceSM),
        Row(
          children: [
            Expanded(
              child: _buildFormatOption(
                label: MatchFormat.fast4,
                isSelected: _matchFormat == MatchFormat.fast4,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _matchFormat = MatchFormat.fast4;
                    _clearIrrelevantTiebreaksAll();
                  });
                },
              ),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: _buildFormatOption(
                label: 'Normal sets',
                subtitle: 'Best of 3 sets',
                isSelected: _matchFormat == MatchFormat.bestOf3,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _matchFormat = MatchFormat.bestOf3;
                    _clearIrrelevantTiebreaksAll();
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormatOption({
    required String label,
    String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return _selectOption(
      isSelected: isSelected,
      onTap: onTap,
      semanticLabel: 'Match format: $label',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.headingSmallThemed(context).copyWith(
              fontSize: 18,
              color: isSelected
                  ? AppTheme.textPrimaryColor(context)
                  : AppTheme.textSecondaryColor(context),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle.toUpperCase(),
              style: AppTheme.labelThemed(context).copyWith(
                letterSpacing: 1,
                color: isSelected
                    ? AppTheme.primary
                    : AppTheme.textMutedColor(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Shared selection tile: hairline border at rest, brand border +
  /// elevated surface when selected, subtle press feedback.
  Widget _selectOption({
    required bool isSelected,
    required VoidCallback onTap,
    required Widget child,
    String? semanticLabel,
  }) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(
              vertical: AppTheme.spaceMD, horizontal: AppTheme.spaceSM),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.elevatedBackground(context)
                : AppTheme.cardBackground(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primary
                  : AppTheme.borderColor(context),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Result'),
        const SizedBox(height: AppTheme.spaceSM),
        Row(
          children: [
            Expanded(
              child: _buildResultOption(
                label: 'Win',
                isSelected: _selectedResult == 'Win',
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedResult = 'Win');
                },
              ),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: _buildResultOption(
                label: 'Loss',
                isSelected: _selectedResult == 'Loss',
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedResult = 'Loss');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isWin = label == 'Win';
    return _selectOption(
      isSelected: isSelected,
      onTap: onTap,
      semanticLabel: 'Result: $label',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CResultBadge(isWin: isWin),
          const SizedBox(width: AppTheme.spaceSM),
          Text(
            label.toUpperCase(),
            style: AppTheme.headingSmallThemed(context).copyWith(
              fontSize: 17,
              letterSpacing: 1,
              color: isSelected
                  ? AppTheme.textPrimaryColor(context)
                  : AppTheme.textSecondaryColor(context),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreSection() {
    final parsed = _guidedScoreParsed;
    final setsWon = parsed?.setsWon ?? 0;
    final setsLost = parsed?.setsLost ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Score'),
        const SizedBox(height: AppTheme.spaceSM),
        TGCard(
          padding: AppTheme.cardPaddingLarge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sets tally rendered as a scoreboard readout.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _setsTallyColumn('YOU', setsWon),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
                    child: Text('–',
                        style: AppTheme.scorelineThemed(context, size: 34)
                            .copyWith(color: AppTheme.textMutedColor(context))),
                  ),
                  _setsTallyColumn('OPP', setsLost),
                ],
              ),
              const SizedBox(height: AppTheme.spaceMD),
              Divider(color: AppTheme.borderColor(context)),
              const SizedBox(height: AppTheme.spaceMD),
              Text('SET SCORES',
                  style: AppTheme.labelThemed(context).copyWith(
                      letterSpacing: 1.5,
                      color: AppTheme.textMutedColor(context))),
              const SizedBox(height: AppTheme.spaceSM),
              GuidedSetScoreEditor(
                key: ValueKey(_matchFormat),
                matchFormat: _matchFormat,
                initialScoreLine: _guidedScoreLine,
                onChanged: (scoreLine, parsedScore, error) {
                  setState(() {
                    _guidedScoreLine = scoreLine;
                    _guidedScoreParsed = parsedScore;
                    _guidedScoreError = error;
                    if (parsedScore != null &&
                        parsedScore.setsWon != parsedScore.setsLost) {
                      _selectedResult =
                          parsedScore.setsWon > parsedScore.setsLost
                              ? 'Win'
                              : 'Loss';
                    }
                  });
                },
              ),
              if (_guidedScoreError != null) ...[
                const SizedBox(height: AppTheme.spaceXS),
                Text(
                  _guidedScoreError!,
                  style: AppTheme.bodySmallThemed(context)
                      .copyWith(color: AppTheme.loss),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _setsTallyColumn(String label, int value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: AppTheme.labelThemed(context).copyWith(
                letterSpacing: 1.5, color: AppTheme.textMutedColor(context))),
        const SizedBox(height: 4),
        Text('$value',
            style: AppTheme.scorelineThemed(context, size: 40)
                .copyWith(color: AppTheme.textPrimaryColor(context))),
      ],
    );
  }

  Widget _buildOptionalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Optional'),
        const SizedBox(height: AppTheme.spaceSM),
        Container(
          decoration: AppTheme.cardDecorationThemed(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _opponentController,
                style: AppTheme.bodyMediumThemed(context)
                    .copyWith(color: AppTheme.textPrimaryColor(context)),
                decoration: InputDecoration(
                  hintText: 'Opponent name (optional)',
                  hintStyle: AppTheme.bodyMediumThemed(context)
                      .copyWith(color: AppTheme.textMutedColor(context)),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.all(AppTheme.spaceMD),
                ),
                textInputAction: TextInputAction.next,
              ),
              Divider(color: AppTheme.borderColor(context), height: 1),
              const SizedBox(height: AppTheme.spaceSM),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'QUICK REFLECTION (1–2 SENTENCES)',
                  style: AppTheme.labelThemed(context).copyWith(
                      letterSpacing: 1.2,
                      color: AppTheme.textMutedColor(context)),
                ),
              ),
              const SizedBox(height: AppTheme.spaceXS),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 140),
                child: TextField(
                  controller: _quickNoteController,
                  style: AppTheme.bodyMediumThemed(context)
                      .copyWith(color: AppTheme.textPrimaryColor(context)),
                  decoration: InputDecoration(
                    hintText: 'What actually happened out there?',
                    hintStyle: AppTheme.bodyMediumThemed(context)
                        .copyWith(color: AppTheme.textMutedColor(context)),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  textInputAction: TextInputAction.newline,
                  maxLines: 6,
                  minLines: 4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    final parsed = _guidedScoreParsed;
    final isValid = parsed != null &&
        _guidedScoreError == null &&
        parsed.setScores.length >= 2 &&
        parsed.setsWon != parsed.setsLost;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: AppTheme.scaffoldBackground(context),
        border: Border(
          top: BorderSide(color: AppTheme.borderColor(context)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CSecondaryButton(
              label: 'Add detailed match log',
              icon: Icons.tune_rounded,
              onPressed: _isSaving ? null : _openDetailedLog,
            ),
            const SizedBox(height: AppTheme.spaceSM),
            CPrimaryButton(
              label: 'Save match',
              loadingLabel: 'Saving…',
              icon: Icons.check_rounded,
              loading: _isSaving,
              onPressed: isValid && !_isSaving ? _saveMatch : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDetailedLog() async {
    HapticFeedback.lightImpact();
    final draft = await _saveOrRefreshQuickDraft();
    if (draft == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Enter a valid score before opening detailed log.',
            style: AppTheme.bodyMediumThemed(context)
                .copyWith(color: AppTheme.textPrimaryColor(context)),
          ),
          backgroundColor: AppTheme.elevatedBackground(context),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!mounted) return;

    final detailedSaved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddMatchScreen(
          existingMatchId: draft.id,
          existingMatchDate: draft.date,
          initialMatchFormat: _matchFormat,
          initialScoreLine: _guidedScoreLine,
          initialOpponentLevelSeed: '',
          initialOpponentName: _opponentController.text.trim(),
          initialNotes: _quickNoteController.text.trim(),
        ),
      ),
    );

    if (detailedSaved == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  void _clearIrrelevantTiebreaksAll() {
    for (final score in _setScores) {
      _clearIrrelevantTiebreak(score);
    }
  }

  /// Success View — a "FULL TIME" result panel, not a celebration.
  Widget _buildSuccessView() {
    final isWin = _savedMatch?.result == 'Win';
    final scoreDisplay = _savedMatch?.scoreLine ?? '';
    final opponent = _savedMatch?.opponent ?? 'Opponent';

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground(context),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context, true);
                    },
                    tooltip: 'Close',
                    iconSize: 22,
                    style:
                        IconButton.styleFrom(minimumSize: const Size(44, 44)),
                    color: AppTheme.textSecondaryColor(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),

                const Spacer(),

                Semantics(
                  label:
                      'Match saved. ${isWin ? "Win" : "Loss"} $scoreDisplay against $opponent',
                  child: TGCard(
                    padding: AppTheme.cardPaddingLarge,
                    elevated: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('FULL TIME · MATCH SAVED',
                            style: AppTheme.labelThemed(context).copyWith(
                                color: AppTheme.primary, letterSpacing: 2)),
                        const SizedBox(height: AppTheme.spaceMD),
                        Row(
                          children: [
                            CResultBadge(isWin: isWin),
                            const SizedBox(width: AppTheme.spaceSM),
                            Text(
                              isWin ? 'WIN' : 'LOSS',
                              style: AppTheme.labelThemed(context).copyWith(
                                letterSpacing: 2,
                                color: isWin ? AppTheme.win : AppTheme.loss,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spaceSM),
                        _scoreline(scoreDisplay, size: 40),
                        const SizedBox(height: AppTheme.spaceXS),
                        Text('vs $opponent',
                            style: AppTheme.bodyMediumThemed(context).copyWith(
                                color: AppTheme.textSecondaryColor(context))),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                Container(
                  decoration: AppTheme.cardDecorationThemed(context),
                  child: ShareButton(
                    shareText: ShareTextGenerator.matchResult(
                      result: _savedMatch?.result ?? 'Win',
                      opponent: opponent,
                      setsWon: _savedMatch?.setsWon ?? 0,
                      setsLost: _savedMatch?.setsLost ?? 0,
                      scoreLine: _savedMatch?.scoreLine,
                      insight: null,
                    ),
                    subject: 'My tennis match',
                    color: AppTheme.textSecondaryColor(context),
                  ),
                ),

                const SizedBox(height: AppTheme.spaceSM),

                CPrimaryButton(
                  label: 'Done',
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Monospace scoreline with lost sets dimmed so the eye lands on sets won.
  /// Mirrors the `_scoreline` pattern from home_screen.dart.
  Widget _scoreline(String raw, {double size = 17}) {
    final sets = raw.trim().isEmpty
        ? const <String>[]
        : raw.trim().split(RegExp(r'\s+'));
    if (sets.isEmpty) {
      return Text('—', style: AppTheme.scorelineThemed(context, size: size));
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (int i = 0; i < sets.length; i++)
          Padding(
            padding:
                EdgeInsets.only(right: i == sets.length - 1 ? 0 : size * 0.32),
            child: Text(
              sets[i],
              style: AppTheme.scorelineThemed(context, size: size).copyWith(
                color: _wonSet(sets[i])
                    ? AppTheme.textPrimaryColor(context)
                    : AppTheme.textMutedColor(context).withValues(alpha: 0.7),
              ),
            ),
          ),
      ],
    );
  }

  bool _wonSet(String token) {
    final clean = token.replaceAll(RegExp(r'\(.*?\)'), '');
    final parts = clean.split('-');
    if (parts.length < 2) return true;
    final me = int.tryParse(parts[0].trim()) ?? 0;
    final opp = int.tryParse(parts[1].trim()) ?? 0;
    return me >= opp;
  }
}
