import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import '../theme/app_theme.dart';
import '../widgets/composure_kit.dart';
import '../config/app_config.dart';

/// Send Feedback Screen
/// 
/// Allows users to send feedback via email with device info auto-included.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  String _selectedCategory = 'general';
  bool _isSending = false;
  
  static const String _supportEmail = AppConfig.supportEmail;
  static const String _appVersion = AppConfig.appVersion;
  static const String _buildNumber = AppConfig.buildNumber;

  final List<Map<String, String>> _categories = [
    {'id': 'general', 'label': 'General Feedback', 'emoji': '💬'},
    {'id': 'bug', 'label': 'Report a Bug', 'emoji': '🐛'},
    {'id': 'feature', 'label': 'Feature Request', 'emoji': '💡'},
    {'id': 'question', 'label': 'Question', 'emoji': '❓'},
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  String get _deviceInfo {
    try {
      final os = Platform.operatingSystem;
      final osVersion = Platform.operatingSystemVersion;
      return '$os $osVersion';
    } catch (_) {
      return 'Unknown device';
    }
  }

  String get _emailSubject {
    final category = _categories.firstWhere(
      (c) => c['id'] == _selectedCategory,
      orElse: () => _categories.first,
    );
    return '[Composure ${category['label']}] v$_appVersion';
  }

  String get _emailBody {
    final feedback = _feedbackController.text.trim();
    return '''
$feedback

---
App Version: $_appVersion (Build $_buildNumber)
Device: $_deviceInfo
Category: ${_categories.firstWhere((c) => c['id'] == _selectedCategory)['label']}
''';
  }

  Future<void> _sendFeedback() async {
    final feedback = _feedbackController.text.trim();
    
    if (feedback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter your feedback',
            style: AppTheme.bodyMediumThemed(context)
                .copyWith(color: Colors.white),
          ),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    HapticFeedback.mediumImpact();

    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: _supportEmail,
        query: _encodeQueryParameters({
          'subject': _emailSubject,
          'body': _emailBody,
        }),
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        
        if (mounted) {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Opening email app...',
                style: AppTheme.bodyMediumThemed(context)
                    .copyWith(color: Colors.white),
              ),
              backgroundColor: AppTheme.primary,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception('Could not open email app');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open email. Please email $_supportEmail directly.',
              style: AppTheme.bodyMediumThemed(context)
                  .copyWith(color: Colors.white),
            ),
            backgroundColor: AppTheme.loss,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground(context),
      appBar: AppBar(
        title: Text(
          'Send Feedback',
          style: AppTheme.headingSmallThemed(context)
              .copyWith(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              TGCard(
                padding: AppTheme.cardPaddingLarge,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spaceMD),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      ),
                      child: const Icon(
                        Icons.feedback_outlined,
                        color: AppTheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'We\'d love to hear from you',
                            style: AppTheme.headingSmallThemed(context)
                                .copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Your feedback helps us improve',
                            style: AppTheme.bodySmallThemed(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppTheme.spaceLG),
              
              // Category selection
              Text(
                'What\'s this about?',
                style: AppTheme.bodyMediumThemed(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor(context),
                ),
              ),
              const SizedBox(height: AppTheme.spaceMD),
              Wrap(
                spacing: AppTheme.spaceSM,
                runSpacing: AppTheme.spaceSM,
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category['id'];
                  return Semantics(
                    button: true,
                    selected: isSelected,
                    label: category['label'],
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedCategory = category['id']!);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        constraints: const BoxConstraints(minHeight: 44),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceMD,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary.withValues(alpha: 0.1)
                              : AppTheme.cardBackground(context),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.borderColor(context),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(category['emoji']!),
                            const SizedBox(width: 6),
                            Text(
                              category['label']!,
                              style: AppTheme.bodySmallThemed(context).copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? AppTheme.primary
                                    : AppTheme.textSecondaryColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: AppTheme.spaceLG),
              
              // Feedback input
              Text(
                'Your feedback',
                style: AppTheme.bodyMediumThemed(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor(context),
                ),
              ),
              const SizedBox(height: AppTheme.spaceMD),
              Container(
                decoration: AppTheme.cardDecorationThemed(context),
                child: TextField(
                  controller: _feedbackController,
                  maxLines: 6,
                  style: AppTheme.bodyMediumThemed(context).copyWith(
                    color: AppTheme.textPrimaryColor(context),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tell us what\'s on your mind...',
                    hintStyle: AppTheme.bodyMediumThemed(context).copyWith(
                      color: AppTheme.textMutedColor(context),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(AppTheme.spaceMD),
                  ),
                ),
              ),
              
              const SizedBox(height: AppTheme.spaceMD),
              
              // Device info note
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceMD),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: AppTheme.spaceSM),
                    Expanded(
                      child: Text(
                        'App version and device info will be included automatically',
                        style: AppTheme.bodySmallThemed(context).copyWith(
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppTheme.spaceLG),
              
              // Send button
              CPrimaryButton(
                label: 'Send Feedback',
                loading: _isSending,
                loadingLabel: 'Sending...',
                onPressed: _isSending ? null : _sendFeedback,
              ),
              
              const SizedBox(height: AppTheme.spaceMD),
              
              // Direct email option
              Center(
                child: Text(
                  'Or email us directly at $_supportEmail',
                  style: AppTheme.bodySmallThemed(context),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: AppTheme.spaceXL),
            ],
          ),
        ),
      ),
    );
  }
}
