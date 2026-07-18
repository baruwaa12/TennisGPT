import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/player_profile_service.dart';
import '../models/match_performance.dart';
import '../theme/app_theme.dart';
import '../widgets/composure_kit.dart';
import '../utils/paywall_navigation.dart';

/// Quick post-match reflection screen with guided options
class MatchReflectionScreen extends StatefulWidget {
  final MatchPerformance match;
  
  const MatchReflectionScreen({
    super.key,
    required this.match,
  });

  @override
  State<MatchReflectionScreen> createState() => _MatchReflectionScreenState();
}

class _MatchReflectionScreenState extends State<MatchReflectionScreen> {
  // What went well
  final Set<String> _selectedStrengths = {};
  String _otherStrength = '';
  
  // What needs work
  final Set<String> _selectedWeaknesses = {};
  String _otherWeakness = '';
  
  bool _isGettingAdvice = false;
  String? _tacticalAdvice;

  static const List<Map<String, String>> strengthOptions = [
    {'id': 'serve', 'label': 'Serve was on'},
    {'id': 'movement', 'label': 'Movement was good'},
    {'id': 'shot_selection', 'label': 'Made smart shot selections'},
    {'id': 'focus', 'label': 'Stayed focused throughout'},
    {'id': 'returns', 'label': 'Returns were solid'},
    {'id': 'net_play', 'label': 'Net play was effective'},
  ];

  static const List<Map<String, String>> weaknessOptions = [
    {'id': 'errors', 'label': 'Too many unforced errors'},
    {'id': 'backhand', 'label': 'Backhand broke down'},
    {'id': 'focus', 'label': 'Lost focus in key moments'},
    {'id': 'fitness', 'label': 'Fitness or stamina issues'},
    {'id': 'serve', 'label': 'Serve was inconsistent'},
    {'id': 'nerves', 'label': 'Nerves affected play'},
  ];

  Future<void> _getTacticalAdvice() async {
    if (_selectedStrengths.isEmpty && _selectedWeaknesses.isEmpty) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Select at least one item to get advice',
            style: AppTheme.bodyMediumThemed(context)
                .copyWith(color: Colors.white),
          ),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() => _isGettingAdvice = true);
    HapticFeedback.mediumImpact();

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final profileService = Provider.of<PlayerProfileService>(context, listen: false);
      
      // Build context for AI
      final strengths = _selectedStrengths.map((id) {
        final option = strengthOptions.firstWhere((o) => o['id'] == id, orElse: () => {'label': id});
        return option['label'] ?? id;
      }).toList();
      if (_otherStrength.isNotEmpty) strengths.add(_otherStrength);
      
      final weaknesses = _selectedWeaknesses.map((id) {
        final option = weaknessOptions.firstWhere((o) => o['id'] == id, orElse: () => {'label': id});
        return option['label'] ?? id;
      }).toList();
      if (_otherWeakness.isNotEmpty) weaknesses.add(_otherWeakness);

      final playerContext = profileService.getPlayerContext();
      final matchContext = '''
$playerContext

Match Result: ${widget.match.result} vs ${widget.match.opponent}
Match Format: ${widget.match.matchFormat}
Score: ${widget.match.scoreLine.isNotEmpty ? widget.match.scoreLine : '${widget.match.setsWon}-${widget.match.setsLost}'}

What went well: ${strengths.join(', ')}
What needs work: ${weaknesses.join(', ')}

Based on this post-match reflection, provide specific tactical advice for improvement.
''';

      final response = await apiService.tacticalAnalysisSummary(matchContext, null);

      if (response == null && apiService.requiresUpgrade) {
        if (!mounted) return;
        await presentPaywall(context, trigger: PaywallTrigger.serverQuota);
      }
      
      setState(() {
        _isGettingAdvice = false;
        _tacticalAdvice = response;
      });
      
      HapticFeedback.lightImpact();
    } catch (e) {
      setState(() => _isGettingAdvice = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to generate advice. Please try again.',
              style: AppTheme.bodyMediumThemed(context)
                  .copyWith(color: Colors.white),
            ),
            backgroundColor: AppTheme.loss,
          ),
        );
      }
    }
  }

  void _skip() {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
  }

  void _done() {
    HapticFeedback.lightImpact();
    Navigator.pop(context, {
      'strengths': _selectedStrengths.toList(),
      'weaknesses': _selectedWeaknesses.toList(),
      'otherStrength': _otherStrength,
      'otherWeakness': _otherWeakness,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWin = widget.match.result.toLowerCase() == 'win';

    if (_tacticalAdvice != null) {
      return _buildAdviceView();
    }

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground(context),
      appBar: AppBar(
        title: Text(
          'Match Reflection',
          style: AppTheme.headingSmallThemed(context),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _skip,
            child: Text(
              'Skip',
              style: AppTheme.bodySmallThemed(context),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Match summary card
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              decoration: BoxDecoration(
                color: isWin 
                    ? AppTheme.win.withValues(alpha: 0.12)
                    : AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                border: Border.all(color: AppTheme.borderColor(context)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isWin
                          ? AppTheme.win.withValues(alpha: 0.18)
                          : AppTheme.primary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                    child: Icon(
                      isWin
                          ? Icons.emoji_events_outlined
                          : Icons.insights_outlined,
                      color: isWin ? AppTheme.win : AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.match.result} vs ${widget.match.opponent}',
                          style: AppTheme.headingSmallThemed(context),
                        ),
                        Text(
                          widget.match.scoreLine.isNotEmpty
                              ? widget.match.scoreLine
                              : '${widget.match.setsWon}-${widget.match.setsLost}',
                          style: AppTheme.bodySmallThemed(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spaceLG),
            
            // What went well
            Text(
              'What went well?',
              style: AppTheme.headingSmallThemed(context),
            ),
            const SizedBox(height: 12),
            _buildOptionGrid(
              options: strengthOptions,
              selected: _selectedStrengths,
              accentColor: AppTheme.win,
            ),
            const SizedBox(height: AppTheme.spaceSM),
            _buildOtherInput(
              hint: 'Other strength...',
              onChanged: (v) => setState(() => _otherStrength = v),
            ),
            
            const SizedBox(height: AppTheme.spaceLG),
            
            // What needs work
            Text(
              'What needs work?',
              style: AppTheme.headingSmallThemed(context),
            ),
            const SizedBox(height: 12),
            _buildOptionGrid(
              options: weaknessOptions,
              selected: _selectedWeaknesses,
              accentColor: AppTheme.warning,
            ),
            const SizedBox(height: AppTheme.spaceSM),
            _buildOtherInput(
              hint: 'Other area to improve...',
              onChanged: (v) => setState(() => _otherWeakness = v),
            ),
            
            const SizedBox(height: AppTheme.spaceXL),
            
            // Get tactical advice button
            CPrimaryButton(
              label: 'Get Tactical Advice',
              loading: _isGettingAdvice,
              loadingLabel: 'Analyzing...',
              onPressed: _isGettingAdvice ? null : _getTacticalAdvice,
            ),
            
            const SizedBox(height: 12),
            
            // Skip for now
            Center(
              child: TextButton(
                onPressed: _done,
                child: Text(
                  'Save without advice',
                  style: AppTheme.bodySmallThemed(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdviceView() {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground(context),
      appBar: AppBar(
        title: Text(
          'Tactical Advice',
          style: AppTheme.headingSmallThemed(context),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TGCard(
              padding: AppTheme.cardPaddingLarge,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spaceSM),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMD),
                        ),
                        child: const Icon(Icons.psychology,
                            color: AppTheme.primary, size: 24),
                      ),
                      const SizedBox(width: AppTheme.spaceMD),
                      Text(
                        'Based on Your Reflection',
                        style: AppTheme.headingSmallThemed(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceMD),
                  Divider(color: AppTheme.borderColor(context)),
                  const SizedBox(height: AppTheme.spaceMD),
                  Text(
                    _tacticalAdvice!,
                    style: AppTheme.bodyMediumThemed(context).copyWith(
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spaceLG),
            
            CPrimaryButton(
              label: 'Done',
              onPressed: _done,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionGrid({
    required List<Map<String, String>> options,
    required Set<String> selected,
    required Color accentColor,
  }) {
    return Wrap(
      spacing: AppTheme.spaceSM,
      runSpacing: AppTheme.spaceSM,
      children: options.map((option) {
        final isSelected = selected.contains(option['id']);
        return Semantics(
          button: true,
          selected: isSelected,
          label: option['label'],
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                if (isSelected) {
                  selected.remove(option['id']);
                } else {
                  selected.add(option['id']!);
                }
              });
            },
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.2)
                    : AppTheme.elevatedBackground(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(
                  color: isSelected 
                      ? accentColor 
                      : AppTheme.borderColor(context),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    option['label'] ?? '',
                    style: AppTheme.bodySmallThemed(context).copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? accentColor
                          : AppTheme.textSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOtherInput({
    required String hint,
    required Function(String) onChanged,
  }) {
    return TextField(
      onChanged: onChanged,
      style: AppTheme.bodyMediumThemed(context)
          .copyWith(color: AppTheme.textPrimaryColor(context)),
      decoration: AppTheme.inputDecorationThemed(context, hint: hint),
    );
  }
}
