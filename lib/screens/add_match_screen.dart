import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/match_performance.dart';
import '../services/match_history_service.dart';
import '../services/api_service.dart';

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
  const AddMatchScreen({super.key});

  @override
  State<AddMatchScreen> createState() => _AddMatchScreenState();
}

class _AddMatchScreenState extends State<AddMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final MatchHistoryService _matchHistoryService = MatchHistoryService();
  
  final TextEditingController _opponentController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _keyMomentController = TextEditingController();
  
  String _result = 'Win';
  int _setsWon = 2;
  int _setsLost = 0;
  String _surface = 'Hard';
  String _weather = 'Sunny';
  
  bool _showRatings = false;
  
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
  void dispose() {
    _opponentController.dispose();
    _notesController.dispose();
    _keyMomentController.dispose();
    super.dispose();
  }

  Future<void> _saveMatch() async {
    if (!_formKey.currentState!.validate()) return;

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
      
      // Build match description for analysis
      final String matchDescription = '''
Opponent: ${_opponentController.text}
Result: $_result (${_setsWon}-${_setsLost})
Surface: $_surface
Weather: $_weather
${_showRatings ? 'Ratings: ${_ratings.entries.map((e) => '${e.key}(${e.value}/10)').join(', ')}' : ''}
${keyMoments.isNotEmpty ? 'Key moment: ${keyMoments.first}' : ''}
${_notesController.text.isNotEmpty ? 'Notes: ${_notesController.text}' : ''}
      '''.trim();

      // Get AI analysis
      final apiService = Provider.of<ApiService>(context, listen: false);
      final recentMatches = await _matchHistoryService.getRecentMatches(3);
      final analysis = await apiService.tacticalAnalysis(matchDescription, recentMatches);
      
      // Generate drill recommendations
      final allMatches = await _matchHistoryService.getAllMatches();
      allMatches.add(MatchPerformance(
        id: matchId,
        date: DateTime.now(),
        opponent: _opponentController.text,
        result: _result,
        setsWon: _setsWon,
        setsLost: _setsLost,
        surface: _surface,
        weather: _weather,
        notes: _notesController.text,
        strengths: _showRatings ? Map.from(_ratings) : {},
        weaknesses: {},
        keyMoments: keyMoments,
        tacticalAnalysis: analysis ?? '',
        recommendedDrills: [],
      ));
      
      final drills = await apiService.generateDrillsFromHistory(allMatches);
      
      // Create final match
      final match = MatchPerformance(
        id: matchId,
        date: DateTime.now(),
        opponent: _opponentController.text,
        result: _result,
        setsWon: _setsWon,
        setsLost: _setsLost,
        surface: _surface,
        weather: _weather,
        notes: _notesController.text,
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
      backgroundColor: AppTheme.surfaceDark,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              backgroundColor: AppTheme.surfaceDark,
              elevation: 0,
              pinned: true,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Log Match',
                style: AppTheme.headingSmall.copyWith(color: AppTheme.textSecondary),
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
                  
                  // Key Moment (optional, single input)
                  _buildKeyMomentSection(),
                  
                  const SizedBox(height: AppTheme.spaceLG),
                  
                  // Performance Ratings (collapsible, optional)
                  _buildRatingsSection(),
                  
                  const SizedBox(height: AppTheme.spaceLG),
                  
                  // Notes (optional, de-emphasized)
                  _buildNotesSection(),
                  
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
        color: AppTheme.loss.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.loss.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppTheme.loss, size: 20),
          const SizedBox(width: AppTheme.spaceSM),
          Expanded(
            child: Text(_errorMessage!, style: AppTheme.bodySmall),
          ),
          TextButton(
            onPressed: () => setState(() => _errorMessage = null),
            child: Text('Dismiss', style: AppTheme.label.copyWith(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchDetailsSection() {
    return Container(
      padding: AppTheme.cardPaddingLarge,
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Match details', style: AppTheme.headingMedium),
          const SizedBox(height: AppTheme.spaceLG),
          
          // Opponent
          TextFormField(
            controller: _opponentController,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
            decoration: AppTheme.inputDecoration(
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
          
          // Result + Score
          Row(
            children: [
              // Result
              Expanded(
                child: _buildDropdown(
                  label: 'Result',
                  value: _result,
                  items: ['Win', 'Loss'],
                  onChanged: (value) => setState(() => _result = value!),
                ),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              
              // Score
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: 'Sets won',
                        value: _setsWon,
                        items: [0, 1, 2, 3],
                        onChanged: (value) => setState(() => _setsWon = value!),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('–', style: AppTheme.headingMedium),
                    ),
                    Expanded(
                      child: _buildDropdown(
                        label: 'Sets lost',
                        value: _setsLost,
                        items: [0, 1, 2, 3],
                        onChanged: (value) => setState(() => _setsLost = value!),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
      dropdownColor: AppTheme.surfaceElevated,
      style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
      decoration: AppTheme.inputDecoration(label: label),
      items: items.map((item) => DropdownMenuItem<T>(
        value: item,
        child: Text(item.toString()),
      )).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildKeyMomentSection() {
    return Container(
      padding: AppTheme.cardPadding,
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Key moment', style: AppTheme.headingSmall),
              const SizedBox(width: AppTheme.spaceSM),
              Text('optional', style: AppTheme.label),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            'One thing that stood out from this match',
            style: AppTheme.bodySmall,
          ),
          const SizedBox(height: AppTheme.spaceMD),
          TextField(
            controller: _keyMomentController,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
            decoration: AppTheme.inputDecoration(
              hint: 'e.g., Stayed calm in the tiebreak',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingsSection() {
    return Container(
      decoration: AppTheme.cardDecoration,
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
                      Text('Rate performance', style: AppTheme.headingSmall),
                      const SizedBox(width: AppTheme.spaceSM),
                      Text('optional', style: AppTheme.label),
                    ],
                  ),
                  AnimatedRotation(
                    turns: _showRatings ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.textMuted,
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
                        child: Text(skill, style: AppTheme.bodyMedium),
                      ),
                      Expanded(
                        flex: 3,
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                            activeTrackColor: AppTheme.primary,
                            inactiveTrackColor: AppTheme.surfaceBorder,
                            thumbColor: AppTheme.primary,
                            overlayColor: AppTheme.primary.withOpacity(0.2),
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
                          style: AppTheme.label.copyWith(color: AppTheme.textSecondary),
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

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Notes', style: AppTheme.label),
            const SizedBox(width: AppTheme.spaceSM),
            Text('optional', style: AppTheme.label.copyWith(color: AppTheme.textMuted.withOpacity(0.6))),
          ],
        ),
        const SizedBox(height: AppTheme.spaceSM),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(color: AppTheme.surfaceBorder),
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 2,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Anything else to remember...',
              hintStyle: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted.withOpacity(0.5)),
              border: InputBorder.none,
              contentPadding: AppTheme.cardPadding,
            ),
          ),
        ),
      ],
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
