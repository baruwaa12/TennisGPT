import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Analysis Result Screen
/// 
/// Design Philosophy:
/// - No chat bubbles or AI conversation patterns
/// - Card-based layout with clear visual hierarchy
/// - Calm, confident, coach-like presentation
/// - One clear primary action (dismiss/done)
/// 
/// Structure:
/// 1. Match context header (date, opponent, score)
/// 2. Summary card - main takeaway
/// 3. Patterns card - bullet observations
/// 4. Next focus card - actionable items

class AnalysisResultScreen extends StatelessWidget {
  final AnalysisData data;
  
  const AnalysisResultScreen({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with close action
            _buildTopBar(context),
            
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: AppTheme.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Match context header
                    _buildMatchHeader(),
                    
                    const SizedBox(height: AppTheme.spaceLG),
                    
                    // Card 1: Summary
                    _buildSummaryCard(),
                    
                    const SizedBox(height: AppTheme.spaceMD),
                    
                    // Card 2: Patterns Observed
                    _buildPatternsCard(),
                    
                    const SizedBox(height: AppTheme.spaceMD),
                    
                    // Card 3: Next Match Focus
                    _buildNextFocusCard(),
                    
                    const SizedBox(height: AppTheme.spaceXL),
                  ],
                ),
              ),
            ),
            
            // Primary action button
            _buildPrimaryAction(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMD,
        vertical: AppTheme.spaceSM,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Screen title
          Text('Match Analysis', style: AppTheme.headingMedium),
          
          // Close button
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
        ],
      ),
    );
  }

  Widget _buildMatchHeader() {
    final isWin = data.result.toLowerCase() == 'win';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date label
        Text(
          _formatDate(data.date),
          style: AppTheme.label,
        ),
        
        const SizedBox(height: AppTheme.spaceSM),
        
        // Opponent and score row
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Opponent name
            Expanded(
              child: Text(
                'vs ${data.opponent}',
                style: AppTheme.headingLarge,
              ),
            ),
            
            // Score badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMD,
                vertical: AppTheme.spaceSM,
              ),
              decoration: BoxDecoration(
                color: isWin 
                    ? AppTheme.win.withOpacity(0.15)
                    : AppTheme.loss.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                border: Border.all(
                  color: isWin ? AppTheme.win : AppTheme.loss,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isWin ? 'W' : 'L',
                    style: AppTheme.headingSmall.copyWith(
                      color: isWin ? AppTheme.win : AppTheme.loss,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceSM),
                  Text(
                    '${data.setsWon}-${data.setsLost}',
                    style: AppTheme.statMedium.copyWith(
                      color: isWin ? AppTheme.win : AppTheme.loss,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return TGCardWithHeader(
      title: 'Summary',
      icon: Icons.lightbulb_outline,
      iconColor: AppTheme.warning,
      child: Text(
        data.summary,
        style: AppTheme.bodyLarge,
      ),
    );
  }

  Widget _buildPatternsCard() {
    return TGCardWithHeader(
      title: 'Patterns Observed',
      icon: Icons.insights,
      iconColor: AppTheme.neutral,
      child: Column(
        children: data.patterns.map((pattern) => 
          TGBulletPoint(
            text: pattern,
            bulletColor: AppTheme.neutral,
          ),
        ).toList(),
      ),
    );
  }

  Widget _buildNextFocusCard() {
    return TGCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.flag_outlined,
                size: 18,
                color: AppTheme.primary,
              ),
              const SizedBox(width: AppTheme.spaceSM),
              Text('Next Match Focus', style: AppTheme.headingSmall),
            ],
          ),
          
          const SizedBox(height: AppTheme.spaceMD),
          
          // Tactical focus
          _buildFocusItem(
            label: 'TACTICAL',
            content: data.tacticalFocus,
            icon: Icons.sports_tennis,
          ),
          
          const SizedBox(height: AppTheme.spaceMD),
          
          // Divider
          Container(
            height: 1,
            color: AppTheme.surfaceBorder,
          ),
          
          const SizedBox(height: AppTheme.spaceMD),
          
          // Mental cue
          _buildFocusItem(
            label: 'MENTAL CUE',
            content: data.mentalCue,
            icon: Icons.psychology_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildFocusItem({
    required String label,
    required String content,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spaceSM),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: AppTheme.spaceMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.label.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.spaceXS),
              Text(content, style: AppTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryAction(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      child: SizedBox(
        width: double.infinity,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: Center(
              child: Text(
                'Done',
                style: AppTheme.headingSmall.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// Data model for analysis results
/// This would be populated by parsing the AI response
class AnalysisData {
  final DateTime date;
  final String opponent;
  final String result; // 'Win' or 'Loss'
  final int setsWon;
  final int setsLost;
  final String summary;
  final List<String> patterns;
  final String tacticalFocus;
  final String mentalCue;

  const AnalysisData({
    required this.date,
    required this.opponent,
    required this.result,
    required this.setsWon,
    required this.setsLost,
    required this.summary,
    required this.patterns,
    required this.tacticalFocus,
    required this.mentalCue,
  });

  /// Parse AI response into structured data
  /// This would be called after receiving the AI response
  factory AnalysisData.fromAIResponse({
    required DateTime date,
    required String opponent,
    required String result,
    required int setsWon,
    required int setsLost,
    required String aiResponse,
  }) {
    // For now, return sample parsed data
    // In production, this would parse the AI response text
    return AnalysisData(
      date: date,
      opponent: opponent,
      result: result,
      setsWon: setsWon,
      setsLost: setsLost,
      summary: _extractSummary(aiResponse),
      patterns: _extractPatterns(aiResponse),
      tacticalFocus: _extractTacticalFocus(aiResponse),
      mentalCue: _extractMentalCue(aiResponse),
    );
  }

  static String _extractSummary(String response) {
    // TODO: Parse AI response for summary section
    // For now, take first 150 chars or first paragraph
    if (response.length <= 150) return response;
    final firstParagraph = response.split('\n\n').first;
    if (firstParagraph.length <= 200) return firstParagraph;
    return '${response.substring(0, 147)}...';
  }

  static List<String> _extractPatterns(String response) {
    // TODO: Parse AI response for bullet points
    // Look for lines starting with - or • or numbered lists
    final lines = response.split('\n');
    final patterns = <String>[];
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('- ') || 
          trimmed.startsWith('• ') ||
          RegExp(r'^\d+\.').hasMatch(trimmed)) {
        patterns.add(trimmed.replaceFirst(RegExp(r'^[-•\d.]+\s*'), ''));
        if (patterns.length >= 3) break;
      }
    }
    
    // Fallback if no bullets found
    if (patterns.isEmpty) {
      return ['Review your serve consistency', 'Focus on first strike tennis', 'Manage energy in longer rallies'];
    }
    
    return patterns;
  }

  static String _extractTacticalFocus(String response) {
    // TODO: Parse AI response for tactical recommendation
    // Look for keywords like "focus on", "prioritize", "work on"
    final lowerResponse = response.toLowerCase();
    
    if (lowerResponse.contains('tactical focus')) {
      final startIndex = lowerResponse.indexOf('tactical focus');
      final endIndex = response.indexOf('\n', startIndex + 15);
      if (endIndex > startIndex) {
        return response.substring(startIndex + 15, endIndex).trim();
      }
    }
    
    return 'Attack the backhand early in rallies to create openings';
  }

  static String _extractMentalCue(String response) {
    // TODO: Parse AI response for mental cue
    if (response.toLowerCase().contains('mental')) {
      // Try to extract mental section
    }
    
    return 'Stay patient in long rallies — trust your fitness';
  }
}

