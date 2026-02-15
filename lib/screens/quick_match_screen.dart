import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/match_performance.dart';
import '../services/match_history_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/purchase_service.dart';
import '../services/usage_service.dart';
import '../services/celebration_service.dart';
import '../services/streak_service.dart';
import '../services/pattern_service.dart';
import '../utils/match_format_utils.dart';
import '../widgets/shareable_card.dart';
import '../config/app_config.dart';
import 'paywall_screen.dart';
import 'match_reflection_screen.dart';
import 'add_match_screen.dart';

class _SetScore {
  int you;
  int opp;
  int? tbYou;
  int? tbOpp;

  _SetScore({
    this.you = 0,
    this.opp = 0,
    this.tbYou,
    this.tbOpp,
  });
}

class _SetResultSummary {
  final int setsWon;
  final int setsLost;
  final int completedSets;

  const _SetResultSummary({
    required this.setsWon,
    required this.setsLost,
    required this.completedSets,
  });
}

/// Quick Match Log - Stage 1
/// 
/// Design Philosophy:
/// - Speed first: Log in under 30 seconds
/// - Minimal inputs: Result + Score only required
/// - Calm aesthetic: No emojis, no loud colors
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
  String? _aiInsight;
  MatchPerformance? _savedMatch;
  
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
    final scoreError = _validateAllScores();
    if (scoreError != null) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(scoreError, style: AppTheme.bodyMediumThemed(context)),
          backgroundColor: AppTheme.elevatedBackground(context),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Check usage limits (respects feature flags)
    final purchaseService = Provider.of<PurchaseService>(context, listen: false);
    final usageService = Provider.of<UsageService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Skip paywall if: payments disabled, user is comped, or user is premium
    final shouldShowPaywall = AppConfig.shouldShowPaywall(email: authService.userEmail);

    if (shouldShowPaywall && !purchaseService.isPremium && !usageService.canLogMatch) {
      HapticFeedback.mediumImpact();
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const PaywallScreen(trigger: PaywallTrigger.matchLimit),
        ),
      );
      if (result != true) return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.lightImpact();

    try {
      final matchId = DateTime.now().millisecondsSinceEpoch.toString();
      final opponent = _opponentController.text.trim().isNotEmpty
          ? _opponentController.text.trim()
          : 'Opponent';
      final quickNote = _quickNoteController.text.trim();

      final setResults = _calculateSetResults();
      final setsWon = setResults.setsWon;
      final setsLost = setResults.setsLost;
      final result = setsWon > setsLost ? 'Win' : 'Loss';
      final scoreLine = _buildScoreLine();
      final setScores = _buildSetScoresList();

      // Create match description for AI
      final matchDescription = '''
Match Format: ${_formatLabel()}
Score: $scoreLine
Result: $result
Opponent: $opponent
${quickNote.isNotEmpty ? 'Quick note: $quickNote' : ''}
      '''.trim();

      // Get AI analysis (background, non-blocking feel)
      final apiService = Provider.of<ApiService>(context, listen: false);
      final recentMatches = await _matchHistoryService.getRecentMatches(3);
      final analysis = await apiService.tacticalAnalysisSummary(matchDescription, recentMatches);

      // Create match
      final match = MatchPerformance(
        id: matchId,
        date: DateTime.now(),
        opponent: opponent,
        result: result,
        setsWon: setsWon,
        setsLost: setsLost,
        matchFormat: _matchFormat,
        scoreLine: scoreLine,
        setScores: setScores,
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
        tacticalAnalysis: analysis ?? '',
        recommendedDrills: [],
      );

      await _matchHistoryService.saveMatch(match);

      // Record usage
      if (!purchaseService.isPremium) {
        await usageService.recordMatchLogged();
      }

      setState(() {
        _isSaving = false;
        _showSuccess = true;
        _aiInsight = analysis;
        _savedMatch = match;
      });

      _successController.forward();
      HapticFeedback.mediumImpact();

      // Handle celebrations
      if (mounted) {
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

        await CelebrationService.checkFirstMatch(context);
        if (result == 'Win') {
          await CelebrationService.checkFirstWin(context);
        }

        final matchCount = await _matchHistoryService.getTotalMatches();
        await CelebrationService.checkTenMatches(context, matchCount);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving match', style: AppTheme.bodyMediumThemed(context).copyWith(color: Colors.white)),
            backgroundColor: AppTheme.loss,
          ),
        );
      }
    }
  }

  bool get _isNormalSets => _matchFormat == MatchFormat.bestOf3;

  int get _visibleSetCount => _isNormalSets ? 3 : 2;

  String _formatLabel() {
    return _isNormalSets ? 'Normal sets (Best of 3 sets)' : MatchFormat.fast4;
  }

  bool _isSetUnused(_SetScore score) {
    return score.you == 0 && score.opp == 0 && score.tbYou == null && score.tbOpp == null;
  }

  bool _isPotentialFast4Score(int you, int opp) {
    if (you < 0 || opp < 0) return false;
    if (you > 4 || opp > 4) return false;
    if (you == 4 && opp == 4) return false;
    if (you == 4 && opp > 3) return false;
    if (opp == 4 && you > 3) return false;
    return true;
  }

  bool _isPotentialNormalScore(int you, int opp) {
    if (you < 0 || opp < 0) return false;
    if (you > 7 || opp > 7) return false;
    if (you == 7 && opp == 7) return false;
    final max = you > opp ? you : opp;
    final min = you > opp ? opp : you;
    if (max == 7 && min <= 4) {
      return false; // 7-0 to 7-4 are not valid final outcomes
    }
    return true;
  }

  void _updateGameScore(int setIndex, bool isYou, int delta) {
    final score = _setScores[setIndex];
    final current = isYou ? score.you : score.opp;
    final other = isYou ? score.opp : score.you;
    final next = current + delta;

    if (delta < 0 && next < 0) return;

    if (_isNormalSets) {
      if (other >= 7 && delta > 0) return;
      if (next > 7) return;
      if (!_isPotentialNormalScore(isYou ? next : other, isYou ? other : next)) return;
    } else {
      if (other >= 4 && delta > 0) return;
      if (next > 4) return;
      if (!_isPotentialFast4Score(isYou ? next : other, isYou ? other : next)) return;
    }

    setState(() {
      if (isYou) {
        score.you = next;
      } else {
        score.opp = next;
      }
      _clearIrrelevantTiebreak(score);
      _syncResultFromScores();
    });
  }

  void _updateTiebreakScore(int setIndex, bool isYou, int delta) {
    final score = _setScores[setIndex];
    final current = isYou ? (score.tbYou ?? 0) : (score.tbOpp ?? 0);
    final next = current + delta;
    if (next < 0 || next > 20) return;

    setState(() {
      if (isYou) {
        score.tbYou = next;
      } else {
        score.tbOpp = next;
      }
    });
  }

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

  bool _isFast4TiebreakVisible(_SetScore score) {
    return score.you == 3 && score.opp == 3;
  }

  bool _isFast4TiebreakApplicable(_SetScore score) {
    return (score.you == 3 && score.opp == 3) ||
        (score.you == 4 && score.opp == 3) ||
        (score.opp == 4 && score.you == 3);
  }

  bool _isNormalTiebreakVisible(_SetScore score) {
    return (score.you == 6 && score.opp == 6) ||
        (score.you == 7 && score.opp == 6) ||
        (score.opp == 7 && score.you == 6);
  }

  bool _isNormalTiebreakApplicable(_SetScore score) {
    return (score.you == 7 && score.opp == 6) ||
        (score.opp == 7 && score.you == 6) ||
        (score.you == 6 && score.opp == 6);
  }

  bool _isFast4Final(_SetScore score) {
    return (score.you == 4 && score.opp <= 3) ||
        (score.opp == 4 && score.you <= 3);
  }

  bool _isNormalFinal(_SetScore score) {
    final you = score.you;
    final opp = score.opp;
    if ((you == 6 && opp <= 4) || (opp == 6 && you <= 4)) {
      return true;
    }
    if ((you == 7 && opp == 5) || (opp == 7 && you == 5)) {
      return true;
    }
    if ((you == 7 && opp == 6) || (opp == 7 && you == 6)) {
      return true;
    }
    return false;
  }

  String? _validateSetScore(int index, _SetScore score, {required bool requiredSet}) {
    if (_isSetUnused(score)) {
      return requiredSet ? 'Enter a set score' : null;
    }

    if (_isNormalSets) {
      if (!_isNormalFinal(score)) {
        return 'Use 6-0 to 6-4, 7-5, or 7-6';
      }
      if ((score.you == 7 && score.opp == 6) || (score.opp == 7 && score.you == 6)) {
        if (score.tbYou == null || score.tbOpp == null) {
          return 'Enter tiebreak score for 7-6 set';
        }
        if (score.tbYou == score.tbOpp) {
          return 'Tiebreak score must have a winner';
        }
        final winnerIsYou = score.you > score.opp;
        final tbWinnerIsYou = (score.tbYou ?? 0) > (score.tbOpp ?? 0);
        if (winnerIsYou != tbWinnerIsYou) {
          return 'Tiebreak winner must match set winner';
        }
      }
    } else {
      if (!_isFast4Final(score)) {
        return 'Fast4 sets must be 4-0 to 4-3';
      }
      if ((score.you == 4 && score.opp == 3) || (score.opp == 4 && score.you == 3)) {
        if (score.tbYou != null && score.tbOpp != null) {
          if (score.tbYou == score.tbOpp) {
            return 'Tiebreak score must have a winner';
          }
          final winnerIsYou = score.you > score.opp;
          final tbWinnerIsYou = (score.tbYou ?? 0) > (score.tbOpp ?? 0);
          if (winnerIsYou != tbWinnerIsYou) {
            return 'Tiebreak winner must match set winner';
          }
        }
      }
    }

    return null;
  }

  String? _validateAllScores() {
    for (var i = 0; i < _visibleSetCount; i++) {
      final requiredSet = i < 2;
      final error = _validateSetScore(i, _setScores[i], requiredSet: requiredSet);
      if (error != null) {
        return 'Set ${i + 1}: $error';
      }
    }

    final results = _calculateSetResults();
    if (results.completedSets < 2) {
      return 'Enter at least two set scores';
    }
    if (results.setsWon == results.setsLost) {
      return 'Score must have a winner';
    }
    if (results.setsWon > 2 || results.setsLost > 2) {
      return 'Best of 3 requires first to 2 sets';
    }

    return null;
  }

  _SetResultSummary _calculateSetResults() {
    int setsWon = 0;
    int setsLost = 0;
    int completedSets = 0;

    for (var i = 0; i < _visibleSetCount; i++) {
      final score = _setScores[i];
      if (_isSetUnused(score)) {
        continue;
      }
      final isFinal = _isNormalSets ? _isNormalFinal(score) : _isFast4Final(score);
      if (!isFinal) {
        continue;
      }
      completedSets += 1;
      if (score.you > score.opp) {
        setsWon += 1;
      } else if (score.opp > score.you) {
        setsLost += 1;
      }
    }

    return _SetResultSummary(
      setsWon: setsWon,
      setsLost: setsLost,
      completedSets: completedSets,
    );
  }

  void _syncResultFromScores() {
    final results = _calculateSetResults();
    if (results.setsWon == results.setsLost) return;
    setState(() {
      _selectedResult = results.setsWon > results.setsLost ? 'Win' : 'Loss';
    });
  }

  String _buildScoreLine() {
    final scores = _buildSetScoresList();
    return scores.join(' ');
  }

  List<String> _buildSetScoresList() {
    final List<String> scores = [];
    for (var i = 0; i < _visibleSetCount; i++) {
      final score = _setScores[i];
      if (_isSetUnused(score)) {
        continue;
      }
      scores.add(_formatSetScore(score));
    }
    return scores;
  }

  String _formatSetScore(_SetScore score) {
    final base = '${score.you}-${score.opp}';
    if (_isNormalSets) {
      final isTbSet = (score.you == 7 && score.opp == 6) || (score.opp == 7 && score.you == 6);
      if (isTbSet && score.tbYou != null && score.tbOpp != null) {
        final loserPoints = score.you > score.opp ? score.tbOpp! : score.tbYou!;
        return '$base($loserPoints)';
      }
    } else {
      final isTbSet = (score.you == 4 && score.opp == 3) || (score.opp == 4 && score.you == 3);
      if (isTbSet && score.tbYou != null && score.tbOpp != null) {
        final loserPoints = score.you > score.opp ? score.tbOpp! : score.tbYou!;
        return '$base($loserPoints)';
      }
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    if (_showSuccess) {
      return _buildSuccessView();
    }
    
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
                  padding: const EdgeInsets.all(AppTheme.spaceMD),
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
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spaceSM),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: Icon(
                Icons.close,
                color: AppTheme.textSecondaryColor(context),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Text('Quick Match Log', style: AppTheme.headingMediumThemed(context)),
        ],
      ),
    );
  }

  Widget _buildFormatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Match format', style: AppTheme.headingSmallThemed(context)),
        const SizedBox(height: AppTheme.spaceMD),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.15) : AppTheme.cardBackground(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.borderColor(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTheme.headingMediumThemed(context).copyWith(
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondaryColor(context),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTheme.labelThemed(context).copyWith(
                    color: isSelected ? AppTheme.primary : AppTheme.textMutedColor(context),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Result', style: AppTheme.headingSmallThemed(context)),
        const SizedBox(height: AppTheme.spaceMD),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.15) : AppTheme.cardBackground(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.borderColor(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTheme.headingMediumThemed(context).copyWith(
              color: isSelected ? AppTheme.primary : AppTheme.textSecondaryColor(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreSection() {
    final setResults = _calculateSetResults();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Score', style: AppTheme.headingSmallThemed(context)),
        const SizedBox(height: AppTheme.spaceMD),
        Container(
          padding: AppTheme.cardPaddingLarge,
          decoration: AppTheme.cardDecorationThemed(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMainScoreHeaderRow(),
              const SizedBox(height: AppTheme.spaceSM),
              _buildMainScoreRow(
                youValue: setResults.setsWon,
                oppValue: setResults.setsLost,
              ),
              const SizedBox(height: AppTheme.spaceMD),
              Divider(color: AppTheme.borderColor(context)),
              const SizedBox(height: AppTheme.spaceMD),
              Text('Set scores', style: AppTheme.labelThemed(context)),
              const SizedBox(height: AppTheme.spaceSM),
              _buildSetScoreHeaderRow(),
              const SizedBox(height: AppTheme.spaceSM),
              ...List.generate(_visibleSetCount, (index) {
                final score = _setScores[index];
                final showFast4Tb = !_isNormalSets && _isFast4TiebreakVisible(score);
                final showNormalTb = _isNormalSets && _isNormalTiebreakVisible(score);
                return Padding(
                  padding: EdgeInsets.only(bottom: index == _visibleSetCount - 1 ? 0 : AppTheme.spaceSM),
                  child: Column(
                    children: [
                      _buildSetScoreRow(
                        label: 'Set ${index + 1}',
                        youValue: score.you,
                        oppValue: score.opp,
                        onYouMinus: () => _updateGameScore(index, true, -1),
                        onYouPlus: () => _updateGameScore(index, true, 1),
                        onOppMinus: () => _updateGameScore(index, false, -1),
                        onOppPlus: () => _updateGameScore(index, false, 1),
                        compact: true,
                      ),
                      if (showFast4Tb || showNormalTb) ...[
                        const SizedBox(height: AppTheme.spaceXS),
                        _buildSetScoreRow(
                          label: 'TB',
                          youValue: score.tbYou ?? 0,
                          oppValue: score.tbOpp ?? 0,
                          onYouMinus: () => _updateTiebreakScore(index, true, -1),
                          onYouPlus: () => _updateTiebreakScore(index, true, 1),
                          onOppMinus: () => _updateTiebreakScore(index, false, -1),
                          onOppPlus: () => _updateTiebreakScore(index, false, 1),
                          compact: true,
                          isTiebreak: true,
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Optional', style: AppTheme.labelThemed(context)),
        const SizedBox(height: AppTheme.spaceMD),
        Container(
          decoration: AppTheme.cardDecorationThemed(context),
          child: Column(
            children: [
              TextField(
                controller: _opponentController,
                style: AppTheme.bodyMediumThemed(context).copyWith(color: AppTheme.textPrimaryColor(context)),
                decoration: InputDecoration(
                  hintText: 'Opponent name (optional)',
                  hintStyle: AppTheme.bodyMediumThemed(context).copyWith(color: AppTheme.textMutedColor(context)),
                  border: InputBorder.none,
                  contentPadding: AppTheme.cardPadding,
                ),
                textInputAction: TextInputAction.next,
              ),
              Divider(color: AppTheme.borderColor(context), height: 1),
              const SizedBox(height: AppTheme.spaceSM),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Quick Reflection (1–2 sentences)',
                  style: AppTheme.labelThemed(context),
                ),
              ),
              const SizedBox(height: AppTheme.spaceXS),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 140),
                child: TextField(
                  controller: _quickNoteController,
                  style: AppTheme.bodyMediumThemed(context).copyWith(
                    color: AppTheme.textPrimaryColor(context),
                  ),
                  decoration: InputDecoration(
                    hintText: 'What actually happened out there?',
                    hintStyle: AppTheme.bodyMediumThemed(context).copyWith(
                      color: AppTheme.textMutedColor(context),
                    ),
                    border: InputBorder.none,
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
    final isValid = _validateAllScores() == null;
    
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
            GestureDetector(
              onTap: _isSaving ? null : () async {
                HapticFeedback.lightImpact();
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddMatchScreen(
                      initialMatchFormat: _matchFormat,
                      initialScoreLine: _buildScoreLine(),
                      initialOpponentLevelSeed: '',
                      initialOpponentName: _opponentController.text.trim(),
                      initialNotes: _quickNoteController.text.trim(),
                    ),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  border: Border.all(color: AppTheme.borderColor(context)),
                ),
                child: Center(
                  child: Text(
                    'Add Detailed Match Log',
                    style: AppTheme.headingSmallThemed(context).copyWith(
                      color: AppTheme.textSecondaryColor(context),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceSM),
            GestureDetector(
              onTap: _isSaving ? null : _saveMatch,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
                decoration: BoxDecoration(
                  color: isValid ? AppTheme.primary : AppTheme.cardBackground(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: Center(
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Save Match',
                          style: AppTheme.headingSmallThemed(context).copyWith(
                            color: isValid ? Colors.white : AppTheme.textMutedColor(context),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainScoreHeaderRow() {
    return Row(
      children: [
        Expanded(
          child: Center(
            child: Text('You', style: AppTheme.labelThemed(context)),
          ),
        ),
        const SizedBox(width: 28),
        Expanded(
          child: Center(
            child: Text('Opp', style: AppTheme.labelThemed(context)),
          ),
        ),
      ],
    );
  }

  Widget _buildSetScoreHeaderRow() {
    return Row(
      children: [
        SizedBox(width: 64, child: Text('', style: AppTheme.labelThemed(context))),
        Expanded(
          child: Center(
            child: Text('You', style: AppTheme.labelThemed(context)),
          ),
        ),
        const SizedBox(width: 28),
        Expanded(
          child: Center(
            child: Text('Opp', style: AppTheme.labelThemed(context)),
          ),
        ),
      ],
    );
  }

  Widget _buildMainScoreRow({
    required int youValue,
    required int oppValue,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildStepper(
            value: youValue,
            onMinus: null,
            onPlus: null,
            compact: false,
          ),
        ),
        const SizedBox(width: 28, child: Center(child: Text('–'))),
        Expanded(
          child: _buildStepper(
            value: oppValue,
            onMinus: null,
            onPlus: null,
            compact: false,
          ),
        ),
      ],
    );
  }

  Widget _buildSetScoreRow({
    required String label,
    required int youValue,
    required int oppValue,
    required VoidCallback? onYouMinus,
    required VoidCallback? onYouPlus,
    required VoidCallback? onOppMinus,
    required VoidCallback? onOppPlus,
    required bool compact,
    bool isTiebreak = false,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: isTiebreak ? AppTheme.labelThemed(context) : AppTheme.bodySmallThemed(context),
          ),
        ),
        Expanded(
          child: _buildStepper(
            value: youValue,
            onMinus: onYouMinus,
            onPlus: onYouPlus,
            compact: compact,
          ),
        ),
        const SizedBox(width: 28, child: Center(child: Text('–'))),
        Expanded(
          child: _buildStepper(
            value: oppValue,
            onMinus: onOppMinus,
            onPlus: onOppPlus,
            compact: compact,
          ),
        ),
      ],
    );
  }

  Widget _buildStepper({
    required int value,
    required VoidCallback? onMinus,
    required VoidCallback? onPlus,
    required bool compact,
  }) {
    final buttonSize = compact ? 28.0 : 36.0;
    final valueStyle = compact
        ? AppTheme.bodyMediumThemed(context)
        : AppTheme.headingMediumThemed(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepperButton(
          icon: Icons.remove,
          size: buttonSize,
          onTap: onMinus,
        ),
        SizedBox(
          width: compact ? 28 : 36,
          child: Center(
            child: Text('$value', style: valueStyle),
          ),
        ),
        _buildStepperButton(
          icon: Icons.add,
          size: buttonSize,
          onTap: onPlus,
        ),
      ],
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required double size,
    required VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isEnabled ? AppTheme.cardBackground(context) : AppTheme.cardBackground(context).withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Icon(
          icon,
          size: size * 0.6,
          color: isEnabled ? AppTheme.textSecondaryColor(context) : AppTheme.textMutedColor(context),
        ),
      ),
    );
  }

  void _clearIrrelevantTiebreaksAll() {
    for (final score in _setScores) {
      _clearIrrelevantTiebreak(score);
    }
  }

  /// Success View - Calm confirmation, not celebration
  Widget _buildSuccessView() {
    final isWin = _savedMatch?.result == 'Win';
    final scoreDisplay = _savedMatch?.scoreLine ?? '';
    
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground(context),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMD),
            child: Column(
              children: [
                // Close button
                Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context, true);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spaceSM),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground(context),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      ),
                      child: Icon(
                        Icons.close,
                        color: AppTheme.textSecondaryColor(context),
                        size: 20,
                      ),
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Confirmation
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: (isWin ? AppTheme.win : AppTheme.primary).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 32,
                    color: isWin ? AppTheme.win : AppTheme.primary,
                  ),
                ),
                
                const SizedBox(height: AppTheme.spaceLG),
                
                Text(
                  'Match Saved',
                  style: AppTheme.headingLargeThemed(context),
                ),
                
                const SizedBox(height: AppTheme.spaceSM),
                
                Text(
                  '${isWin == true ? "Win" : "Loss"} · $scoreDisplay',
                  style: AppTheme.bodyLargeThemed(context),
                ),
                
                const SizedBox(height: AppTheme.spaceXL),
                
                // AI Insight card (if available)
                if (_aiInsight != null && _aiInsight!.isNotEmpty)
                  Expanded(
                    child: TGCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 18,
                                color: AppTheme.warning,
                              ),
                              const SizedBox(width: AppTheme.spaceSM),
                              Text('Quick Insight', style: AppTheme.headingSmallThemed(context)),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spaceMD),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Text(
                                _aiInsight!,
                                style: AppTheme.bodyMediumThemed(context).copyWith(
                                  color: AppTheme.textPrimaryColor(context),
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: AppTheme.spaceMD),
                
                // Actions
                Row(
                  children: [
                    // Share
                    Expanded(
                      child: Container(
                        decoration: AppTheme.cardDecorationThemed(context),
                        child: ShareButton(
                          shareText: ShareTextGenerator.matchResult(
                            result: _savedMatch?.result ?? 'Win',
                            opponent: _savedMatch?.opponent ?? 'Opponent',
                            setsWon: _savedMatch?.setsWon ?? 0,
                            setsLost: _savedMatch?.setsLost ?? 0,
                            scoreLine: _savedMatch?.scoreLine,
                            insight: null,
                          ),
                          subject: 'My tennis match',
                          color: AppTheme.textSecondaryColor(context),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppTheme.spaceSM),
                
                // Reflect option (Stage 2 entry)
                if (_savedMatch != null)
                  GestureDetector(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MatchReflectionScreen(match: _savedMatch!),
                        ),
                      );
                      if (result != null && result is Map) {
                        final patternService = PatternService();
                        await patternService.saveReflection(
                          matchId: _savedMatch!.id,
                          strengths: List<String>.from(result['strengths'] ?? []),
                          weaknesses: List<String>.from(result['weaknesses'] ?? []),
                          result: _savedMatch!.result,
                          date: _savedMatch!.date,
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground(context),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        border: Border.all(color: AppTheme.borderColor(context)),
                      ),
                      child: Center(
                        child: Text(
                          'Add Reflection',
                          style: AppTheme.headingSmallThemed(context).copyWith(
                            color: AppTheme.textSecondaryColor(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(height: AppTheme.spaceSM),
                
                // Done - Primary
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context, true);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                    child: Center(
                      child: Text(
                        'Done',
                        style: AppTheme.headingSmallThemed(context).copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
