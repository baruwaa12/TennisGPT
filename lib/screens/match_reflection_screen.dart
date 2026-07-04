import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/player_profile_service.dart';
import '../models/match_performance.dart';
import '../theme/app_theme.dart';
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
            style: AppTheme.bodyMediumThemed(context),
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
              style: AppTheme.bodyMediumThemed(context),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Match summary card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isWin 
                    ? AppTheme.win.withValues(alpha: 0.12)
                    : AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isWin
                          ? Icons.emoji_events_outlined
                          : Icons.insights_outlined,
                      color: isWin ? AppTheme.win : AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
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
            
            const SizedBox(height: 24),
            
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
            const SizedBox(height: 8),
            _buildOtherInput(
              hint: 'Other strength...',
              onChanged: (v) => setState(() => _otherStrength = v),
            ),
            
            const SizedBox(height: 24),
            
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
            const SizedBox(height: 8),
            _buildOtherInput(
              hint: 'Other area to improve...',
              onChanged: (v) => setState(() => _otherWeakness = v),
            ),
            
            const SizedBox(height: 32),
            
            // Get tactical advice button
            GestureDetector(
              onTap: _isGettingAdvice ? null : _getTacticalAdvice,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.ctaGlow,
                ),
                child: Center(
                  child: _isGettingAdvice
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.surfaceDark),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Analyzing...',
                              style: AppTheme.headingSmallThemed(context)
                                  .copyWith(color: AppTheme.surfaceDark),
                            ),
                          ],
                        )
                      : Text(
                          'Get Tactical Advice',
                          style: AppTheme.headingSmallThemed(context)
                              .copyWith(color: AppTheme.surfaceDark),
                        ),
                ),
              ),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderColor(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.psychology, color: AppTheme.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Based on Your Reflection',
                        style: AppTheme.headingSmallThemed(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    _tacticalAdvice!,
                    style: AppTheme.bodyMediumThemed(context).copyWith(
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            GestureDetector(
              onTap: _done,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.ctaGlow,
                ),
                child: Center(
                  child: Text(
                    'Done',
                    style: AppTheme.headingSmallThemed(context)
                        .copyWith(color: AppTheme.surfaceDark),
                  ),
                ),
              ),
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
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option['id']);
        return GestureDetector(
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.2)
                  : AppTheme.elevatedBackground(context),
              borderRadius: BorderRadius.circular(12),
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
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? accentColor : AppTheme.textSecondaryColor(context),
                  ),
                ),
              ],
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
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTheme.bodySmallThemed(context),
        filled: true,
        fillColor: AppTheme.elevatedBackground(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderColor(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderColor(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
