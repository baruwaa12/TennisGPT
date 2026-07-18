import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Help & FAQ Screen
/// 
/// App Store compliant help section with friendly, non-technical answers.
/// Suitable for tennis players of all ages including juniors.
class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground(context),
      appBar: AppBar(
        title: Text(
          'Help & FAQ',
          style: AppTheme.headingSmallThemed(context)
              .copyWith(fontWeight: FontWeight.w600),
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
                      Icons.help_outline_rounded,
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
                          'How can we help?',
                          style: AppTheme.headingSmallThemed(context),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Find answers to common questions',
                          style: AppTheme.bodySmallThemed(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spaceLG),
            
            // FAQ Items
            ..._faqItems.map((faq) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spaceMD),
                  child: TGCollapsibleSection(
                    title: faq['question']!,
                    child: Text(
                      faq['answer']!,
                      style: AppTheme.bodyMediumThemed(context),
                    ),
                  ),
                )),
            
            const SizedBox(height: AppTheme.spaceSM),
            
            // Contact section
            TGCard(
              padding: AppTheme.cardPaddingLarge,
              child: Column(
                children: [
                  const Icon(
                    Icons.mail_outline_rounded,
                    color: AppTheme.primary,
                    size: 32,
                  ),
                  const SizedBox(height: AppTheme.spaceMD),
                  Text(
                    'Still need help?',
                    style: AppTheme.headingSmallThemed(context)
                        .copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: AppTheme.spaceXS),
                  Text(
                    'Contact us at ademolabaruwa09@gmail.com',
                    style: AppTheme.bodySmallThemed(context),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spaceXL),
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
      'answer': 'Composure includes a free tier with daily limits for some AI features. Premium unlocks unlimited analyses, match logging, and advanced coaching features.',
    },
    {
      'question': 'What should I do if something isn\'t working?',
      'answer': 'First, try closing and reopening the app. Make sure you have a stable internet connection for AI features. If the problem continues, please send us feedback through Settings -> Send Feedback, or email ademolabaruwa09@gmail.com. Include what happened and we\'ll help you out!',
    },
  ];
}
