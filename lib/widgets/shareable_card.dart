import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';

enum ShareableCardType {
  tacticalAnalysis,
  matchResult,
  streak,
  insight,
}

/// A branded card that can be shared to social media
class ShareableCard extends StatelessWidget {
  final ShareableCardType type;
  final String title;
  final String content;
  final String? subtitle;
  final Color? accentColor;

  const ShareableCard({
    super.key,
    required this.type,
    required this.title,
    required this.content,
    this.subtitle,
    this.accentColor,
  });

  String get _emoji {
    switch (type) {
      case ShareableCardType.tacticalAnalysis:
        return '🎯';
      case ShareableCardType.matchResult:
        return '🎾';
      case ShareableCardType.streak:
        return '🔥';
      case ShareableCardType.insight:
        return '📊';
    }
  }

  Color get _color => accentColor ?? _defaultColor;

  Color get _defaultColor {
    switch (type) {
      case ShareableCardType.tacticalAnalysis:
        return AppTheme.primary;
      case ShareableCardType.matchResult:
        return AppTheme.primary;
      case ShareableCardType.streak:
        return Colors.orange;
      case ShareableCardType.insight:
        return AppTheme.primaryDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _color.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_color.withOpacity(0.8), _color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Text(_emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Composure',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle != null) ...[
                  Text(
                    subtitle!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  content,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.grey[800],
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '🎾 Powered by Composure',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Share button that opens the share dialog
class ShareButton extends StatelessWidget {
  final String shareText;
  final String? subject;
  final VoidCallback? onShareComplete;
  final Widget? child;
  final Color? color;

  const ShareButton({
    super.key,
    required this.shareText,
    this.subject,
    this.onShareComplete,
    this.child,
    this.color,
  });

  Future<void> _share() async {
    HapticFeedback.mediumImpact();
    
    await Share.share(
      shareText,
      subject: subject ?? 'My Composure Insight',
    );
    
    onShareComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (child != null) {
      return GestureDetector(
        onTap: _share,
        child: child,
      );
    }
    
    return TextButton.icon(
      onPressed: _share,
      icon: Icon(Icons.share, size: 18, color: color ?? AppTheme.primary),
      label: Text(
        'Share',
        style: GoogleFonts.poppins(
          color: color ?? AppTheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Helper class to generate share text
class ShareTextGenerator {
  // Set this when you have a landing page
  static const String? websiteUrl = null; // e.g., 'composure.app'
  
  static String get _websiteText => 
      websiteUrl != null ? '\n\n🎾 $websiteUrl' : '';

  static String tacticalAnalysis(String analysis) {
    // Extract first meaningful sentence or key insight
    final summary = _extractSummary(analysis, maxLength: 150);
    return '''🎯 Composure Analysis

"$summary"$_websiteText''';
  }

  static String matchResult({
    required String result,
    required String opponent,
    required int setsWon,
    required int setsLost,
    String? scoreLine,
    String? insight,
  }) {
    final emoji = result.toLowerCase() == 'win' ? '🏆' : '💪';
    final insightText = insight != null ? '\n\nAI Insight: "$insight"' : '';
    final scoreText = (scoreLine != null && scoreLine.isNotEmpty)
        ? scoreLine
        : '$setsWon-$setsLost';
    return '''$emoji Match ${result.toUpperCase()}!

vs $opponent: $scoreText$insightText$_websiteText''';
  }

  static String streak(int days) {
    final emoji = days >= 7 ? '🏆' : '🔥';
    return '''$emoji $days-day streak on Composure!

Logging matches and getting AI tactical insights every day.$_websiteText''';
  }

  static String winRate(double rate, int totalMatches) {
    return '''📊 My Composure Stats

Win Rate: ${rate.toStringAsFixed(0)}%
Matches Logged: $totalMatches$_websiteText''';
  }

  static String _extractSummary(String text, {int maxLength = 150}) {
    // Remove markdown headers
    var cleaned = text.replaceAll(RegExp(r'\*\*[^*]+\*\*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'#+\s'), '');
    cleaned = cleaned.trim();
    
    // Get first sentence or truncate
    final sentences = cleaned.split(RegExp(r'[.!?]'));
    if (sentences.isNotEmpty && sentences.first.length <= maxLength) {
      return sentences.first.trim();
    }
    
    if (cleaned.length <= maxLength) {
      return cleaned;
    }
    
    return '${cleaned.substring(0, maxLength - 3)}...';
  }
}
