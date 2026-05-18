import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/match_performance.dart';
import '../services/match_history_service.dart';
import '../services/api_service.dart';
import '../utils/match_format_utils.dart';
import '../widgets/voice_input_button.dart';
import '../widgets/guided_set_score_editor.dart';
import '../utils/paywall_navigation.dart';

/// Add Match Screen (Detailed)
/// 
/// UX Philosophy: Fast, frictionless post-match logging
/// 
/// Key refinements:
/// - Performance ratings collapsed by default (optional)
/// - Single key moment input (not a list builder)
/// - Notes de-emphasized as optional
/// - Clear CTA prominence
/// 
/// Goal: Complete in under 60 seconds
class AddMatchScreen extends StatefulWidget {
  final String? initialMatchFormat;
  final String? initialScoreLine;
  final String? initialOpponentLevelSeed;
  final String? initialOpponentName;
  final String? initialNotes;

  const AddMatchScreen({
    super.key,
    this.initialMatchFormat,
    this.initialScoreLine,
    this.initialOpponentLevelSeed,
    this.initialOpponentName,
    this.initialNotes,
  });

  @override
  State<AddMatchScreen> createState() => _AddMatchScreenState();
}

class _AddMatchScreenState extends State<AddMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final MatchHistoryService _matchHistoryService = MatchHistoryService();
  
  final TextEditingController _opponentController = TextEditingController();
  final TextEditingController _opponentLevelSeedController = TextEditingController();
  final TextEditingController _scoreController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _keyMomentController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _mentalNotesController = TextEditingController();
  final TextEditingController _tacticalNotesController = TextEditingController();
  
  String _matchFormat = MatchFormat.bestOf3;
  String _surface = 'Hard';
  String _weather = 'Sunny';
  
  bool _showRatings = false;
  bool _showMentalNotes = false;
  bool _showTacticalNotes = false;
  
  final Map<String, int> _ratings = {
    'Serve': 7,
    'Forehand': 7,
    'Backhand': 7,
    'Volley': 7,
    'Footwork': 7,
  };
  
  bool _isSaving = false;
  String? _errorMessage;

  final List<String> _surfaces = ['Hard', 'Clay', 'Grass', 'Carpet', 'Indoor'];
  final List<String> _weatherConditions = ['Sunny', 'Cloudy', 'Rainy', 'Windy', 'Hot', 'Cold'];

  @override
  void initState() {
    super.initState();
    _matchFormat = widget.initialMatchFormat ?? MatchFormat.bestOf3;
    if (widget.initialOpponentName != null && widget.initialOpponentName!.isNotEmpty) {
      _opponentController.text = widget.initialOpponentName!;
    }
    if (widget.initialScoreLine != null && widget.initialScoreLine!.isNotEmpty) {
      _scoreController.text = widget.initialScoreLine!;
    }
    if (widget.initialOpponentLevelSeed != null && widget.initialOpponentLevelSeed!.isNotEmpty) {
      _opponentLevelSeedController.text = widget.initialOpponentLevelSeed!;
    }
    if (widget.initialNotes != null && widget.initialNotes!.isNotEmpty) {
      _notesController.text = widget.initialNotes!;
    }
  }

  @override
  void dispose() {
    _opponentController.dispose();
    _opponentLevelSeedController.dispose();
    _scoreController.dispose();
    _notesController.dispose();
    _keyMomentController.dispose();
    _summaryController.dispose();
    _mentalNotesController.dispose();
    _tacticalNotesController.dispose();
    super.dispose();
  }

  Future<void> _saveMatch() async {
    if (!_formKey.currentState!.validate()) return;
    final scoreError = MatchScoreValidator.validate(_matchFormat, _scoreController.text);
    if (scoreError != null) {
      setState(() {
        _errorMessage = scoreError;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    
    HapticFeedback.mediumImpact();

    try {
      final String matchId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Collect key moment if provided
      final keyMoments = _keyMomentController.text.trim().isNotEmpty 
          ? [_keyMomentController.text.trim()] 
          : <String>[];
      
      final parsedScore = MatchScoreValidator.parse(_matchFormat, _scoreController.text);
      final result = parsedScore.setsWon > parsedScore.setsLost ? 'Win' : 'Loss';

      // Build match description for analysis
      final String matchDescription = '''
Opponent: ${_opponentController.text}
Match Format: $_matchFormat
Score: ${parsedScore.displayScore}
Result: $result
${_opponentLevelSeedController.text.isNotEmpty ? 'Opponent level/seed: ${_opponentLevelSeedController.text}' : ''}
Surface: $_surface
Weather: $_weather
${_showRatings ? 'Ratings: ${_ratings.entries.map((e) => '${e.key}(${e.value}/10)').join(', ')}' : ''}
${keyMoments.isNotEmpty ? 'Key moment: ${keyMoments.first}' : ''}
${_notesController.text.isNotEmpty ? 'Notes: ${_notesController.text}' : ''}
${_summaryController.text.isNotEmpty ? 'Match summary: ${_summaryController.text}' : ''}
${_mentalNotesController.text.isNotEmpty ? 'Mental notes: ${_mentalNotesController.text}' : ''}
${_tacticalNotesController.text.isNotEmpty ? 'Tactical notes: ${_tacticalNotesController.text}' : ''}
      '''.trim();

      // Get AI analysis
      final apiService = Provider.of<ApiService>(context, listen: false);
      final recentMatches = await _matchHistoryService.getRecentMatches(3);
      final analysis = await apiService.tacticalAnalysisSummary(matchDescription, recentMatches);

      if (analysis == null && apiService.requiresUpgrade) {
        if (context.mounted) {
          await presentPaywall(context, trigger: PaywallTrigger.serverQuota);
        }
      }
      
      // Generate drill recommendations
      final allMatches = await _matchHistoryService.getAllMatches();
      allMatches.add(MatchPerformance(
        id: matchId,
        date: DateTime.now(),
        opponent: _opponentController.text,
        result: result,
        setsWon: parsedScore.setsWon,
        setsLost: parsedScore.setsLost,
        matchFormat: _matchFormat,
        scoreLine: parsedScore.displayScore,
        setScores: parsedScore.setScores,
        opponentLevelSeed: _opponentLevelSeedController.text.trim(),
        surface: _surface,
        weather: _weather,
        notes: _notesController.text,
        matchSummary: _summaryController.text,
        mentalNotes: _mentalNotesController.text,
        tacticalNotes: _tacticalNotesController.text,
        strengthNotes: '',
        weaknessNotes: '',
        strengths: _showRatings ? Map.from(_ratings) : {},
        weaknesses: {},
        keyMoments: keyMoments,
        tacticalAnalysis: analysis ?? '',
        recommendedDrills: [],
      ));
      
      final drills = await apiService.generateDrillsFromHistory(allMatches);

      if (drills == null && apiService.requiresUpgrade) {
        if (context.mounted) {
          await presentPaywall(context, trigger: PaywallTrigger.serverQuota);
        }
      }
      
      // Create final match
      final match = MatchPerformance(
        id: matchId,
        date: DateTime.now(),
        opponent: _opponentController.text,
        result: result,
        setsWon: parsedScore.setsWon,
        setsLost: parsedScore.setsLost,
        matchFormat: _matchFormat,
        scoreLine: parsedScore.displayScore,
        setScores: parsedScore.setScores,
        opponentLevelSeed: _opponentLevelSeedController.text.trim(),
        surface: _surface,
        weather: _weather,
        notes: _notesController.text,
        matchSummary: _summaryController.text,
        mentalNotes: _mentalNotesController.text,
        tacticalNotes: _tacticalNotesController.text,
        strengthNotes: '',
        weaknessNotes: '',
        strengths: _showRatings ? Map.from(_ratings) : {},
        weaknesses: {},
        keyMoments: keyMoments,
        tacticalAnalysis: analysis ?? '',
        recommendedDrills: drills?.split('\n').where((line) => line.trim().isNotEmpty).toList() ?? [],
      );

      await _matchHistoryService.saveMatch(match);

      setState(() => _isSaving = false);
      
      HapticFeedback.lightImpact();

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Couldn\'t save match. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground(context),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              backgroundColor: AppTheme.scaffoldBackground(context),
              elevation: 0,
              pinned: true,
              centerTitle: true,
              leading: IconButton(
                icon: Icon(Icons.close_rounded, color: AppTheme.textSecondaryColor(context)),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Detailed Match Log',
                style: AppTheme.headingSmallThemed(context).copyWith(color: AppTheme.textSecondaryColor(context)),
              ),
            ),
            
            SliverPadding(
              padding: AppTheme.screenPadding,
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Error message
                  if (_errorMessage != null) ...[
                    _buildErrorCard(),
                    const SizedBox(height: AppTheme.spaceMD),
                  ],
                  
                  // Match Details (required)
                  _buildMatchDetailsSection(),
                  
                  const SizedBox(height: AppTheme.spaceLG),
                  
                  // Performance Ratings (collapsible, optional)
                  _buildRatingsSection(),
                  
                  const SizedBox(height: AppTheme.spaceLG),
                  
                  // Match Summary (required, always visible)
                  _buildMatchSummarySection(),
                  
                  const SizedBox(height: AppTheme.spaceLG),
                  
                  // Mental Notes (collapsible, closed by default)
                  _buildCollapsibleMentalNotes(),
                  
                  const SizedBox(height: AppTheme.spaceLG),
                  
                  // Tactical Notes (collapsible, closed by default)
                  _buildCollapsibleTacticalNotes(),
                  
                  const SizedBox(height: AppTheme.spaceLG),
                  
                  // Key Moment (optional, single input)
                  _buildKeyMomentSection(),
                  
                  const SizedBox(height: AppTheme.spaceXL),
                  
                  // Save Button (prominent)
                  _buildSaveButton(),
                  
                  const SizedBox(height: AppTheme.spaceXXL),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: AppTheme.loss.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.loss.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppTheme.loss, size: 20),
          const SizedBox(width: AppTheme.spaceSM),
          Expanded(
            child: Text(_errorMessage!, style: AppTheme.bodySmallThemed(context)),
          ),
          TextButton(
            onPressed: () => setState(() => _errorMessage = null),
            child: Text('Dismiss', style: AppTheme.labelThemed(context).copyWith(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchDetailsSection() {
    return Container(
      padding: AppTheme.cardPaddingLarge,
      decoration: AppTheme.cardDecorationThemed(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Match details', style: AppTheme.headingMediumThemed(context)),
          const SizedBox(height: AppTheme.spaceLG),
          
          // Opponent
          TextFormField(
            controller: _opponentController,
            style: AppTheme.bodyMediumThemed(context).copyWith(color: AppTheme.textPrimaryColor(context)),
            decoration: AppTheme.inputDecorationThemed(
              context,
              label: 'Opponent',
              hint: 'Who did you play?',
            ),
            validator: (value) {
              if (value?.trim().isEmpty ?? true) {
                return 'Enter opponent name';
              }
              return null;
            },
          ),
          
          const SizedBox(height: AppTheme.spaceMD),
          
          // Match format
          _buildDropdown(
            label: 'Match format',
            value: _matchFormat,
            items: MatchFormat.values,
            onChanged: (value) => setState(() => _matchFormat = value!),
          ),
          
          const SizedBox(height: AppTheme.spaceMD),
          
          GuidedSetScoreEditor(
            matchFormat: _matchFormat,
            initialScoreLine: _scoreController.text,
            onChanged: (scoreLine, _, __) {
              _scoreController.text = scoreLine;
            },
          ),
          
          const SizedBox(height: AppTheme.spaceMD),
          
          // Opponent level/seed (optional)
          TextFormField(
            controller: _opponentLevelSeedController,
            style: AppTheme.bodyMediumThemed(context).copyWith(color: AppTheme.textPrimaryColor(context)),
            decoration: AppTheme.inputDecorationThemed(
              context,
              label: 'Opponent level / seed',
              hint: 'Optional',
            ),
          ),
          
          const SizedBox(height: AppTheme.spaceMD),
          
          // Surface + Weather
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Surface',
                  value: _surface,
                  items: _surfaces,
                  onChanged: (value) => setState(() => _surface = value!),
                ),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: _buildDropdown(
                  label: 'Weather',
                  value: _weather,
                  items: _weatherConditions,
                  onChanged: (value) => setState(() => _weather = value!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      dropdownColor: AppTheme.elevatedBackground(context),
      style: AppTheme.bodyMediumThemed(context).copyWith(color: AppTheme.textPrimaryColor(context)),
      decoration: AppTheme.inputDecorationThemed(context, label: label),
      items: items.map((item) => DropdownMenuItem<T>(
        value: item,
        child: Text(item.toString()),
      )).toList(),
      onChanged: onChanged,
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

  Widget _buildKeyMomentSection() {
    return Container(
      padding: AppTheme.cardPadding,
      decoration: AppTheme.cardDecorationThemed(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Key moment', style: AppTheme.headingSmallThemed(context)),
              const SizedBox(width: AppTheme.spaceSM),
              Text('optional', style: AppTheme.labelThemed(context)),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            'One thing that stood out from this match',
            style: AppTheme.bodySmallThemed(context),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          TextField(
            controller: _keyMomentController,
            style: AppTheme.bodyMediumThemed(context).copyWith(color: AppTheme.textPrimaryColor(context)),
            decoration: AppTheme.inputDecorationThemed(
              context,
              hint: 'e.g., Stayed calm in the tiebreak',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingsSection() {
    return Container(
      decoration: AppTheme.cardDecorationThemed(context),
      child: Column(
        children: [
          // Toggle header
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _showRatings = !_showRatings);
            },
            child: Container(
              padding: AppTheme.cardPadding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text('Rate performance', style: AppTheme.headingSmallThemed(context)),
                      const SizedBox(width: AppTheme.spaceSM),
                      Text('optional', style: AppTheme.labelThemed(context)),
                    ],
                  ),
                  AnimatedRotation(
                    turns: _showRatings ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.textMutedColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Collapsed content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceMD,
                0,
                AppTheme.spaceMD,
                AppTheme.spaceMD,
              ),
              child: Column(
                children: _ratings.keys.map((skill) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spaceSM),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(skill, style: AppTheme.bodyMediumThemed(context)),
                      ),
                      Expanded(
                        flex: 3,
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                            activeTrackColor: AppTheme.primary,
                            inactiveTrackColor: AppTheme.borderColor(context),
                            thumbColor: AppTheme.primary,
                            overlayColor: AppTheme.primary.withValues(alpha: 0.2),
                          ),
                          child: Slider(
                            value: _ratings[skill]!.toDouble(),
                            min: 1,
                            max: 10,
                            divisions: 9,
                            onChanged: (value) {
                              HapticFeedback.selectionClick();
                              setState(() => _ratings[skill] = value.round());
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${_ratings[skill]}',
                          style: AppTheme.labelThemed(context).copyWith(color: AppTheme.textSecondaryColor(context)),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
            crossFadeState: _showRatings 
                ? CrossFadeState.showSecond 
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchSummarySection() {
    return Container(
      padding: AppTheme.cardPaddingLarge,
      decoration: AppTheme.cardDecorationThemed(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Match Summary', style: AppTheme.headingMediumThemed(context)),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            'Required — what actually happened in this match?',
            style: AppTheme.bodySmallThemed(context),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          VoiceTextField(
            controller: _summaryController,
            hintText: 'What actually happened in this match?',
            maxLines: 6,
            style: AppTheme.bodyMediumThemed(context).copyWith(
              color: AppTheme.textPrimaryColor(context),
            ),
          ),
          // General notes field (compact)
          if (_notesController.text.isNotEmpty || true) ...[
            const SizedBox(height: AppTheme.spaceMD),
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: AppTheme.bodyMediumThemed(context).copyWith(
                color: AppTheme.textPrimaryColor(context),
              ),
              decoration: AppTheme.inputDecorationThemed(
                context,
                label: 'Quick notes',
                hint: 'Anything else to remember...',
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildCollapsibleMentalNotes() {
    return Container(
      decoration: AppTheme.cardDecorationThemed(context),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _showMentalNotes = !_showMentalNotes);
            },
            child: Container(
              padding: AppTheme.cardPadding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text('Mental Notes', style: AppTheme.headingSmallThemed(context)),
                      const SizedBox(width: AppTheme.spaceSM),
                      Text('optional', style: AppTheme.labelThemed(context)),
                    ],
                  ),
                  AnimatedRotation(
                    turns: _showMentalNotes ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.textMutedColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextField(
                controller: _mentalNotesController,
                maxLines: 4,
                minLines: 2,
                style: AppTheme.bodyMediumThemed(context).copyWith(
                  color: AppTheme.textPrimaryColor(context),
                ),
                decoration: AppTheme.inputDecorationThemed(
                  context,
                  hint: 'Mindset, focus, nerves, confidence...',
                ),
              ),
            ),
            crossFadeState: _showMentalNotes 
                ? CrossFadeState.showSecond 
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCollapsibleTacticalNotes() {
    return Container(
      decoration: AppTheme.cardDecorationThemed(context),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _showTacticalNotes = !_showTacticalNotes);
            },
            child: Container(
              padding: AppTheme.cardPadding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text('Tactical Notes', style: AppTheme.headingSmallThemed(context)),
                      const SizedBox(width: AppTheme.spaceSM),
                      Text('optional', style: AppTheme.labelThemed(context)),
                    ],
                  ),
                  AnimatedRotation(
                    turns: _showTacticalNotes ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.textMutedColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextField(
                controller: _tacticalNotesController,
                maxLines: 4,
                minLines: 2,
                style: AppTheme.bodyMediumThemed(context).copyWith(
                  color: AppTheme.textPrimaryColor(context),
                ),
                decoration: AppTheme.inputDecorationThemed(
                  context,
                  hint: 'Patterns, tactics, adjustments...',
                ),
              ),
            ),
            crossFadeState: _showTacticalNotes 
                ? CrossFadeState.showSecond 
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _saveMatch,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
        child: Center(
          child: _isSaving
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceSM),
                    Text(
                      'Saving...',
                      style: AppTheme.headingSmall.copyWith(color: Colors.white),
                    ),
                  ],
                )
              : Text(
                  'Save match',
                  style: AppTheme.headingSmall.copyWith(color: Colors.white),
                ),
        ),
      ),
    );
  }
}
