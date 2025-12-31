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
import '../widgets/shareable_card.dart';
import 'paywall_screen.dart';
import 'match_reflection_screen.dart';

/// Quick Match Log - Stage 1
/// 
/// Design Philosophy:
/// - Speed first: Log in under 30 seconds
/// - Minimal inputs: Result + Score only required
/// - Calm aesthetic: No emojis, no loud colors
/// - Clear hierarchy: One decision at a time
/// 
/// Flow:
/// 1. Select result (Win/Loss)
/// 2. Enter score
/// 3. Optional: Opponent name, quick note
/// 4. Save → Success → Optional reflection

class QuickMatchScreen extends StatefulWidget {
  const QuickMatchScreen({super.key});

  @override
  State<QuickMatchScreen> createState() => _QuickMatchScreenState();
}

class _QuickMatchScreenState extends State<QuickMatchScreen>
    with SingleTickerProviderStateMixin {
  final MatchHistoryService _matchHistoryService = MatchHistoryService();
  final TextEditingController _opponentController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _opponentFocus = FocusNode();
  final FocusNode _noteFocus = FocusNode();
  
  String? _result;
  int _setsWon = 2;
  int _setsLost = 0;
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
    _noteController.dispose();
    _opponentFocus.dispose();
    _noteFocus.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _saveMatch() async {
    if (_result == null) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Select Win or Loss', style: AppTheme.bodyMedium),
          backgroundColor: AppTheme.surfaceElevated,
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
      final opponent = _opponentController.text.trim().isEmpty 
          ? 'Opponent' 
          : _opponentController.text.trim();
      
      // Create match description for AI
      final matchDescription = '''
Match Result: $_result ($_setsWon-$_setsLost)
Opponent: $opponent
${_noteController.text.isNotEmpty ? 'Notes: ${_noteController.text}' : ''}
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
        result: _result!,
        setsWon: _setsWon,
        setsLost: _setsLost,
        surface: 'Hard',
        weather: '',
        notes: _noteController.text,
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
        if (_result == 'Win') {
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
            content: Text('Error saving match', style: AppTheme.bodyMedium),
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
      backgroundColor: AppTheme.surfaceDark,
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
                      // Result Selection - Primary
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
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: const Icon(
                Icons.close,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Text('Log Match', style: AppTheme.headingMedium),
        ],
      ),
    );
  }

  Widget _buildResultSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Result', style: AppTheme.headingSmall),
        const SizedBox(height: AppTheme.spaceMD),
        Row(
          children: [
            Expanded(
              child: _buildResultOption(
                label: 'Win',
                isSelected: _result == 'Win',
                color: AppTheme.win,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _result = 'Win';
                    if (_setsWon <= _setsLost) {
                      _setsWon = 2;
                      _setsLost = 0;
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: _buildResultOption(
                label: 'Loss',
                isSelected: _result == 'Loss',
                color: AppTheme.loss,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _result = 'Loss';
                    if (_setsLost <= _setsWon) {
                      _setsWon = 0;
                      _setsLost = 2;
                    }
                  });
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
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceLG),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(
            color: isSelected ? color : AppTheme.surfaceBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTheme.headingMedium.copyWith(
              color: isSelected ? color : AppTheme.textSecondary,
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
        Text('Score', style: AppTheme.headingSmall),
        const SizedBox(height: AppTheme.spaceMD),
        Container(
          padding: AppTheme.cardPadding,
          decoration: AppTheme.cardDecoration,
          child: Row(
            children: [
              Expanded(
                child: _buildScoreInput(
                  value: _setsWon,
                  label: 'You',
                  isHighlighted: _result == 'Win',
                  onChanged: (val) => setState(() => _setsWon = val),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMD),
                child: Text(
                  '–',
                  style: AppTheme.statMedium.copyWith(color: AppTheme.textMuted),
                ),
              ),
              Expanded(
                child: _buildScoreInput(
                  value: _setsLost,
                  label: 'Opp',
                  isHighlighted: _result == 'Loss',
                  onChanged: (val) => setState(() => _setsLost = val),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScoreInput({
    required int value,
    required String label,
    required bool isHighlighted,
    required Function(int) onChanged,
  }) {
    return Column(
      children: [
        Text(label, style: AppTheme.label),
        const SizedBox(height: AppTheme.spaceSM),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildScoreButton(
              icon: Icons.remove,
              enabled: value > 0,
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(value - 1);
              },
            ),
            Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSM),
              decoration: BoxDecoration(
                color: isHighlighted 
                    ? AppTheme.primary.withOpacity(0.15) 
                    : AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                border: Border.all(
                  color: isHighlighted ? AppTheme.primary : AppTheme.surfaceBorder,
                ),
              ),
              child: Center(
                child: Text(
                  '$value',
                  style: AppTheme.statMedium.copyWith(
                    color: isHighlighted ? AppTheme.primary : AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
            _buildScoreButton(
              icon: Icons.add,
              enabled: value < 3,
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(value + 1);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppTheme.textSecondary : AppTheme.textMuted,
        ),
      ),
    );
  }

  Widget _buildOptionalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Optional', style: AppTheme.label),
        const SizedBox(height: AppTheme.spaceMD),
        
        // Opponent name
        Container(
          decoration: AppTheme.cardDecoration,
          child: TextField(
            controller: _opponentController,
            focusNode: _opponentFocus,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Opponent name',
              hintStyle: AppTheme.bodyMedium,
              border: InputBorder.none,
              contentPadding: AppTheme.cardPadding,
            ),
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _noteFocus.requestFocus(),
          ),
        ),
        
        const SizedBox(height: AppTheme.spaceSM),
        
        // Quick note
        Container(
          decoration: AppTheme.cardDecoration,
          child: TextField(
            controller: _noteController,
            focusNode: _noteFocus,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Quick note (e.g., "serve was off today")',
              hintStyle: AppTheme.bodyMedium,
              border: InputBorder.none,
              contentPadding: AppTheme.cardPadding,
            ),
            textInputAction: TextInputAction.done,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    final isValid = _result != null;
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          top: BorderSide(color: AppTheme.surfaceBorder),
        ),
      ),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: _isSaving ? null : _saveMatch,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
            decoration: BoxDecoration(
              color: isValid ? AppTheme.primary : AppTheme.surfaceCard,
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
                      style: AppTheme.headingSmall.copyWith(
                        color: isValid ? Colors.white : AppTheme.textMuted,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  /// Success View - Calm confirmation, not celebration
  Widget _buildSuccessView() {
    final isWin = _result == 'Win';
    
    return Scaffold(
      backgroundColor: AppTheme.surfaceDark,
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
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: AppTheme.textSecondary,
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
                  style: AppTheme.headingLarge,
                ),
                
                const SizedBox(height: AppTheme.spaceSM),
                
                Text(
                  '${isWin ? "Win" : "Loss"} · $_setsWon-$_setsLost vs ${_opponentController.text.isEmpty ? "Opponent" : _opponentController.text}',
                  style: AppTheme.bodyLarge,
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
                              Text('Quick Insight', style: AppTheme.headingSmall),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spaceMD),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Text(
                                _aiInsight!,
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.textPrimary,
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
                        decoration: AppTheme.cardDecoration,
                        child: ShareButton(
                          shareText: ShareTextGenerator.matchResult(
                            result: _result!,
                            opponent: _opponentController.text.isEmpty 
                                ? 'Opponent' 
                                : _opponentController.text,
                            setsWon: _setsWon,
                            setsLost: _setsLost,
                            insight: null,
                          ),
                          subject: 'My tennis match',
                          color: AppTheme.textSecondary,
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
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        border: Border.all(color: AppTheme.surfaceBorder),
                      ),
                      child: Center(
                        child: Text(
                          'Add Reflection',
                          style: AppTheme.headingSmall.copyWith(
                            color: AppTheme.textSecondary,
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
                        style: AppTheme.headingSmall.copyWith(color: Colors.white),
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
