import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/match_performance.dart';
import '../services/match_history_service.dart';
import '../services/api_service.dart';
import '../services/purchase_service.dart';
import '../services/usage_service.dart';
import '../services/celebration_service.dart';
import '../services/streak_service.dart';
import '../services/pattern_service.dart';
import '../utils/match_format_utils.dart';
import '../widgets/shareable_card.dart';
import 'paywall_screen.dart';
import 'match_reflection_screen.dart';
import 'add_match_screen.dart';

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
/// 2. Enter score
/// 3. Optional: Opponent level / seed
/// 4. Save → Success → Optional reflection

class QuickMatchScreen extends StatefulWidget {
  const QuickMatchScreen({super.key});

  @override
  State<QuickMatchScreen> createState() => _QuickMatchScreenState();
}

class _QuickMatchScreenState extends State<QuickMatchScreen>
    with SingleTickerProviderStateMixin {
  final MatchHistoryService _matchHistoryService = MatchHistoryService();
  final TextEditingController _scoreController = TextEditingController();
  final TextEditingController _opponentLevelSeedController = TextEditingController();
  final FocusNode _scoreFocus = FocusNode();
  final FocusNode _opponentLevelSeedFocus = FocusNode();
  
  String _matchFormat = MatchFormat.fast4;
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
    _scoreController.dispose();
    _opponentLevelSeedController.dispose();
    _scoreFocus.dispose();
    _opponentLevelSeedFocus.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _saveMatch() async {
    final scoreError = MatchScoreValidator.validate(_matchFormat, _scoreController.text);
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

    // Check usage limits
    final purchaseService = Provider.of<PurchaseService>(context, listen: false);
    final usageService = Provider.of<UsageService>(context, listen: false);
    
    if (!purchaseService.isPremium && !usageService.canLogMatch) {
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
      final opponent = 'Opponent';
      final parsedScore = MatchScoreValidator.parse(_matchFormat, _scoreController.text);
      final result = parsedScore.setsWon > parsedScore.setsLost ? 'Win' : 'Loss';
      if (parsedScore.setsWon == parsedScore.setsLost) {
        throw Exception('Score must have a winner');
      }
      
      // Create match description for AI
      final matchDescription = '''
Match Format: $_matchFormat
Score: ${parsedScore.displayScore}
Result: $result
Opponent: $opponent
${_opponentLevelSeedController.text.isNotEmpty ? 'Opponent level/seed: ${_opponentLevelSeedController.text}' : ''}
      '''.trim();

      // Get AI analysis (background, non-blocking feel)
      final apiService = Provider.of<ApiService>(context, listen: false);
      final recentMatches = await _matchHistoryService.getRecentMatches(3);
      final analysis = await apiService.tacticalAnalysis(matchDescription, recentMatches);

      // Create match
      final match = MatchPerformance(
        id: matchId,
        date: DateTime.now(),
        opponent: opponent,
        result: result,
        setsWon: parsedScore.setsWon,
        setsLost: parsedScore.setsLost,
        matchFormat: _matchFormat,
        scoreLine: parsedScore.displayScore,
        setScores: parsedScore.setScores,
        opponentLevelSeed: _opponentLevelSeedController.text.trim(),
        surface: 'Hard',
        weather: '',
        notes: '',
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
                color: AppTheme.primary,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _matchFormat = MatchFormat.fast4;
                  });
                },
              ),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: _buildFormatOption(
                label: MatchFormat.bestOf3,
                isSelected: _matchFormat == MatchFormat.bestOf3,
                color: AppTheme.primary,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _matchFormat = MatchFormat.bestOf3;
                  });
                },
              ),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: _buildFormatOption(
                label: MatchFormat.shortSets,
                isSelected: _matchFormat == MatchFormat.shortSets,
                color: AppTheme.primary,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _matchFormat = MatchFormat.shortSets;
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
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceLG),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppTheme.cardBackground(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(
            color: isSelected ? color : AppTheme.borderColor(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTheme.headingMediumThemed(context).copyWith(
              color: isSelected ? color : AppTheme.textSecondaryColor(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Score', style: AppTheme.headingSmallThemed(context)),
        const SizedBox(height: AppTheme.spaceMD),
        Container(
          padding: AppTheme.cardPadding,
          decoration: AppTheme.cardDecorationThemed(context),
          child: TextField(
            controller: _scoreController,
            focusNode: _scoreFocus,
            style: AppTheme.bodyMediumThemed(context).copyWith(color: AppTheme.textPrimaryColor(context)),
            decoration: InputDecoration(
              hintText: _scoreHintForFormat(),
              hintStyle: AppTheme.bodyMediumThemed(context).copyWith(color: AppTheme.textMutedColor(context)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _opponentLevelSeedFocus.requestFocus(),
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
          child: TextField(
            controller: _opponentLevelSeedController,
            focusNode: _opponentLevelSeedFocus,
            style: AppTheme.bodyMediumThemed(context).copyWith(color: AppTheme.textPrimaryColor(context)),
            decoration: InputDecoration(
              hintText: 'Opponent level / seed (optional)',
              hintStyle: AppTheme.bodyMediumThemed(context).copyWith(color: AppTheme.textMutedColor(context)),
              border: InputBorder.none,
              contentPadding: AppTheme.cardPadding,
            ),
            textInputAction: TextInputAction.done,
          ),
        ),
      ],
    );
  }

  String _scoreHintForFormat() {
    switch (_matchFormat) {
      case MatchFormat.fast4:
        return 'e.g. 4-1 4-3 or 4-3(5)';
      case MatchFormat.shortSets:
        return 'e.g. 4-2 4-1 or 6-4 7-6(5)';
      case MatchFormat.bestOf3:
      default:
        return 'e.g. 6-4 7-6(5)';
    }
  }

  Widget _buildSaveButton() {
    final isValid = _scoreController.text.trim().isNotEmpty;
    
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
                      initialScoreLine: _scoreController.text.trim(),
                      initialOpponentLevelSeed: _opponentLevelSeedController.text.trim(),
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
