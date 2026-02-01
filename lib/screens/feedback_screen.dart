import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

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
  
  static const String _supportEmail = 'ademolabaruwa09@gmail.com';
  static const String _appVersion = '1.0.0';
  static const String _buildNumber = '44';

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
          content: Text('Please enter your feedback', style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
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
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
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
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Send Feedback',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.feedback_outlined,
                        color: Colors.teal,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'We\'d love to hear from you',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.grey[800],
                            ),
                          ),
                          Text(
                            'Your feedback helps us improve',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Category selection
              Text(
                'What\'s this about?',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category['id'];
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCategory = category['id']!);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.teal.withOpacity(0.1)
                            : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.teal : Colors.grey.shade300,
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
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected
                                  ? Colors.teal
                                  : (isDark ? Colors.white : Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),
              
              // Feedback input
              Text(
                'Your feedback',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _feedbackController,
                  maxLines: 6,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.grey[800],
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tell us what\'s on your mind...',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Device info note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'App version and device info will be included automatically',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Send button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _sendFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Send Feedback',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Direct email option
              Center(
                child: Text(
                  'Or email us directly at $_supportEmail',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

