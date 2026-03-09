import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

enum LegalDocumentType {
  termsOfService,
  privacyPolicy,
}

/// Legal Document Screen
/// 
/// Displays Terms of Service or Privacy Policy.
/// App Store compliant, readable, and non-intimidating.
class LegalScreen extends StatelessWidget {
  final LegalDocumentType documentType;
  
  const LegalScreen({
    super.key,
    required this.documentType,
  });

  String get _title {
    switch (documentType) {
      case LegalDocumentType.termsOfService:
        return 'Terms of Service';
      case LegalDocumentType.privacyPolicy:
        return 'Privacy Policy';
    }
  }

  String get _content {
    switch (documentType) {
      case LegalDocumentType.termsOfService:
        return _termsOfService;
      case LegalDocumentType.privacyPolicy:
        return _privacyPolicy;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.surfaceDark : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              height: 1.6,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TERMS OF SERVICE
  // ============================================================
  static const String _termsOfService = '''
Terms of Service
Last updated: February 2026

Welcome to Composure! These Terms of Service ("Terms") govern your use of the Composure mobile application ("App"). By using the App, you agree to these Terms.

1. ACCEPTANCE OF TERMS

By downloading, installing, or using Composure, you agree to be bound by these Terms. If you do not agree, please do not use the App.

2. DESCRIPTION OF SERVICE

Composure is a tennis companion app that helps you:
• Track your tennis matches
• Receive AI-powered tactical analysis
• Review and improve your game

3. PROVIDED "AS IS"

The App is provided "as is" without warranties of any kind. We do our best to provide accurate and helpful information, but we cannot guarantee that the App will always be available, error-free, or meet your specific needs.

4. NOT PROFESSIONAL ADVICE

Important: Composure provides general tennis insights and suggestions. It is NOT a substitute for professional coaching, medical advice, or fitness guidance. 

• The AI-generated content is for informational purposes only
• Always consult qualified professionals for training programs
• You are responsible for your own training decisions and safety
• We are not liable for any injuries or outcomes from following suggestions in the App

5. AI-GENERATED CONTENT

The App uses artificial intelligence to analyze your data and provide suggestions. Please understand that:
• AI responses may not always be accurate or applicable to your situation
• The AI does not know your physical condition, injuries, or limitations
• Use AI suggestions as one input among many, not as definitive advice

6. USER RESPONSIBILITIES

You agree to:
• Provide accurate information when using the App
• Use the App only for its intended purpose (tennis improvement)
• Not attempt to misuse, hack, or reverse-engineer the App
• Not use the App for any illegal or harmful purposes

7. ACCOUNT AND DATA

• You are responsible for maintaining the security of your account
• We may suspend or terminate accounts that violate these Terms
• You can delete your account and data anytime from Settings > Delete Account

8. CHANGES TO THE APP

We reserve the right to:
• Modify, update, or discontinue features at any time
• Change pricing or subscription terms with notice
• Update these Terms (continued use means acceptance)

9. SUBSCRIPTIONS AND PAYMENTS

If you purchase a subscription:
• Payment is processed through Apple App Store or Google Play
• Subscriptions auto-renew unless cancelled 24 hours before renewal
• Refunds are handled according to the respective store's policies

10. LIMITATION OF LIABILITY

To the maximum extent permitted by law, Composure and its creators shall not be liable for any indirect, incidental, or consequential damages arising from your use of the App.

11. CONTACT US

Questions about these Terms? Contact us at:
ademolabaruwa09@gmail.com

Thank you for using Composure! 🎾
''';

  // ============================================================
  // PRIVACY POLICY
  // ============================================================
  static const String _privacyPolicy = '''
Privacy Policy
Last updated: February 2026

Your privacy matters to us. This Privacy Policy explains how Composure ("we", "us", "our") collects, uses, and protects your information.

1. INFORMATION WE COLLECT

Account Information:
• Email address (from Google Sign-In)
• Display name and profile photo (from Google)
• Account creation date

Match Data:
• Match results (win/loss)
• Scores and opponent names
• Notes you add about matches
• Dates of matches

Usage Data:
• Features you use and how often
• AI prompts and responses
• App preferences and settings

Voice Input (if used):
• Voice recordings are processed in real-time for transcription
• We do NOT store audio recordings
• Only the transcribed text is saved with your match notes

Device Information:
• Device type and operating system
• App version
• General location (country/region, not precise location)

2. HOW WE USE YOUR INFORMATION

We use your data to:
• Provide personalized tennis insights and analysis
• Track your match history and progress
• Improve the AI coaching features
• Send important app updates (with your permission)
• Analyze app usage to improve features
• Provide customer support

3. AI AND DATA PROCESSING

When you use AI features:
• Your match data and prompts are sent to our AI service
• The AI analyzes your data to provide personalized advice
• We may use anonymized, aggregated data to improve AI quality
• Your individual data is never shared with other users

4. DATA SHARING

We do NOT sell your personal data. We may share data with:

Service Providers:
• Cloud hosting (to store your data securely)
• AI services (to provide analysis features)
• Analytics tools (to understand app usage)

These providers are bound by confidentiality agreements.

Legal Requirements:
We may disclose data if required by law or to protect our rights.

5. DATA SECURITY

We protect your data using:
• Encrypted connections (HTTPS)
• Secure cloud infrastructure
• Access controls and authentication
• Regular security reviews

However, no system is 100% secure. Please use a strong password and keep your device secure.

6. DATA RETENTION

• Your data is kept as long as you have an active account
• Match history is retained to provide long-term insights
• You can request data deletion at any time
• Deleted data is removed within 30 days

7. YOUR RIGHTS

You have the right to:
• Access your data (see what we have)
• Correct inaccurate data
• Delete your data
• Export your data
• Opt out of marketing communications

To exercise these rights, use the in-app controls where available (including Settings > Delete Account) or contact ademolabaruwa09@gmail.com

8. CHILDREN'S PRIVACY

Composure is suitable for tennis players of all ages. For users under 13:
• We collect minimal data necessary for the app to function
• We do not knowingly collect sensitive personal information
• Parents/guardians can contact us to manage their child's data

9. THIRD-PARTY SERVICES

The App uses:
• Google Sign-In (for authentication)
• OpenAI (for AI analysis features)
• RevenueCat (for subscription management)
• Apple/Google (for app distribution and payments)

Each service has its own privacy policy.

10. CHANGES TO THIS POLICY

We may update this Privacy Policy. We'll notify you of significant changes through the App or email. Continued use after changes means acceptance.

11. CONTACT US

Privacy questions or concerns? Contact us at:
ademolabaruwa09@gmail.com

We typically respond within 48 hours.

Thank you for trusting Composure with your tennis journey! 🎾
''';
}

