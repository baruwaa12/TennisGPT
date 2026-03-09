import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Help & FAQ Screen
/// 
/// App Store compliant help section with friendly, non-technical answers.
/// Suitable for tennis players of all ages including juniors.
class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.surfaceDark : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Help & FAQ',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.help_outline_rounded,
                      color: AppTheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How can we help?',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey[800],
                          ),
                        ),
                        Text(
                          'Find answers to common questions',
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
            
            // FAQ Items
            ..._faqItems.map((faq) => _buildFaqItem(
              context,
              question: faq['question']!,
              answer: faq['answer']!,
              isDark: isDark,
            )),
            
            const SizedBox(height: 24),
            
            // Contact section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.mail_outline_rounded,
                    color: AppTheme.primary,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Still need help?',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Contact us at ademolabaruwa09@gmail.com',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(
    BuildContext context, {
    required String question,
    required String answer,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            question,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.grey[800],
            ),
          ),
          iconColor: AppTheme.primary,
          collapsedIconColor: Colors.grey[500],
          children: [
            Text(
              answer,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const List<Map<String, String>> _faqItems = [
    {
      'question': 'What is Composure and who is it for?',
      'answer': 'Composure is a tennis companion app that helps you track your matches, analyze your game, and get personalized tactical advice. It\'s designed for tennis players of all levels — from beginners learning the basics to competitive players looking to improve their strategy.',
    },
    {
      'question': 'How does match logging work?',
      'answer': 'After you play a match, tap "Log Match" on the home screen. You\'ll select whether you won or lost, enter the score, and optionally add your opponent\'s name and any notes. It takes about 30 seconds! Your matches are saved so you can track your progress over time.',
    },
    {
      'question': 'What is the Match Debrief and how should I use it?',
      'answer': 'The Match Debrief helps you reflect on your match in a constructive way. Select what happened (like "struggled under pressure" or "too many errors") and get personalized feedback. Use it after matches — especially tough ones — to turn every game into a learning opportunity.',
    },
    {
      'question': 'Does the app use AI, and how?',
      'answer': 'Yes! Composure uses AI to analyze your match history and provide personalized tactical advice. The AI acts like a virtual coach — it looks at your patterns, strengths, and areas for improvement to give you actionable tips. Your data stays private and is only used to help you improve.',
    },
    {
      'question': 'Why does the app ask for microphone access?',
      'answer': 'The microphone is used for voice input — you can speak instead of typing when adding match notes or describing situations. This makes logging faster and easier, especially right after a match. You can always type instead if you prefer. The app only listens when you tap the microphone button.',
    },
    {
      'question': 'Is my data private?',
      'answer': 'Yes, your privacy is important to us. Your match data and personal information are stored securely and never sold to third parties. We only use your data to provide you with personalized insights and improve the app experience. See our Privacy Policy for full details.',
    },
    {
      'question': 'Can I edit or delete my match logs?',
      'answer': 'Match logs cannot be edited individually yet. To permanently remove your account data, open Settings and choose Delete Account.',
    },
    {
      'question': 'Do I need a subscription to use the app right now?',
      'answer': 'No. Composure currently provides full access to all core features in this version.',
    },
    {
      'question': 'What should I do if something isn\'t working?',
      'answer': 'First, try closing and reopening the app. Make sure you have a stable internet connection for AI features. If the problem continues, please send us feedback through Settings -> Send Feedback, or email ademolabaruwa09@gmail.com. Include what happened and we\'ll help you out!',
    },
  ];
}

