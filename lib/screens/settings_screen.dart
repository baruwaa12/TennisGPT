import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../services/purchase_service.dart';
import '../services/player_profile_service.dart';
import '../services/usage_service.dart';
import '../services/streak_service.dart';
import '../services/match_history_service.dart';
import '../config/app_config.dart';
import 'login_screen.dart';
import 'paywall_screen.dart';
import 'help_faq_screen.dart';
import 'feedback_screen.dart';
import 'legal_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _versionTapCount = 0;
  bool _showDevTools = false;
  bool _forcePremiumEnabled = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authService = Provider.of<AuthService>(context);
    final themeService = Provider.of<ThemeService>(context);
    final purchaseService = Provider.of<PurchaseService>(context);
    final profileService = Provider.of<PlayerProfileService>(context);
    final usageService = Provider.of<UsageService>(context);
    final streakService = Provider.of<StreakService>(context);

    // Dev mode: Force premium override
    // Also check if payments are disabled (testing mode = everyone is premium)
    final isPremium = _forcePremiumEnabled || 
                      purchaseService.isPremium || 
                      !AppConfig.paymentsEnabled ||
                      AppConfig.isCompedUser(email: authService.userEmail);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Settings',
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
            // Profile Card
            _buildProfileCard(authService, profileService, isPremium, isDark),
            
            const SizedBox(height: 24),
            
            // Stats Overview
            _buildStatsCard(usageService, streakService, isDark),
            
            const SizedBox(height: 24),
            
            // Subscription Section (hidden during testing mode)
            if (AppConfig.paymentsEnabled) ...[
              _buildSectionTitle('Subscription', isDark),
              _buildSettingsTile(
                icon: Icons.workspace_premium,
                iconColor: Colors.amber,
                title: isPremium ? 'Premium Active' : 'Upgrade to Premium',
                subtitle: isPremium 
                    ? 'Unlimited access to all features'
                    : 'Get unlimited AI analyses',
                onTap: isPremium ? null : () => _openPaywall(),
                trailing: isPremium 
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.arrow_forward_ios, size: 16),
                isDark: isDark,
              ),
              const SizedBox(height: 24),
            ] else ...[
              // Testing mode indicator
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.science_outlined, color: Colors.green, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Testing Mode',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                            ),
                          ),
                          Text(
                            'Full access enabled for testers',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.green[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Appearance Section
            _buildSectionTitle('Appearance', isDark),
            _buildSettingsTile(
              icon: themeService.themeMode == ThemeMode.dark 
                  ? Icons.dark_mode 
                  : Icons.light_mode,
              iconColor: Colors.blue,
              title: 'Theme',
              subtitle: _getThemeLabel(themeService.themeMode),
              onTap: () => _showThemePicker(themeService),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              isDark: isDark,
            ),
            
            const SizedBox(height: 24),
            
            // Player Profile Section
            _buildSectionTitle('Player Profile', isDark),
            _buildSettingsTile(
              icon: Icons.sports_tennis,
              iconColor: Colors.green,
              title: 'Skill Level',
              subtitle: _getLevelLabel(profileService.playerLevel),
              onTap: () => _showLevelPicker(profileService),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              isDark: isDark,
            ),
            _buildSettingsTile(
              icon: Icons.flag,
              iconColor: Colors.purple,
              title: 'Primary Goal',
              subtitle: _getGoalLabel(profileService.primaryGoal),
              onTap: () => _showGoalPicker(profileService),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              isDark: isDark,
            ),
            
            const SizedBox(height: 24),
            
            // Support Section
            _buildSectionTitle('Support', isDark),
            _buildSettingsTile(
              icon: Icons.help_outline,
              iconColor: Colors.orange,
              title: 'Help & FAQ',
              subtitle: 'Get answers to common questions',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpFaqScreen()),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              isDark: isDark,
            ),
            _buildSettingsTile(
              icon: Icons.feedback_outlined,
              iconColor: Colors.teal,
              title: 'Send Feedback',
              subtitle: 'Help us improve Composure',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FeedbackScreen()),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              isDark: isDark,
            ),
            _buildSettingsTile(
              icon: Icons.star_outline,
              iconColor: Colors.amber,
              title: 'Rate the App',
              subtitle: 'Love Composure? Let us know!',
              onTap: () => _showComingSoon('Rate App'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              isDark: isDark,
            ),
            
            const SizedBox(height: 24),
            
            // Legal Section
            _buildSectionTitle('Legal', isDark),
            _buildSettingsTile(
              icon: Icons.description_outlined,
              iconColor: Colors.grey,
              title: 'Terms of Service',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LegalScreen(
                    documentType: LegalDocumentType.termsOfService,
                  ),
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              isDark: isDark,
            ),
            _buildSettingsTile(
              icon: Icons.privacy_tip_outlined,
              iconColor: Colors.grey,
              title: 'Privacy Policy',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LegalScreen(
                    documentType: LegalDocumentType.privacyPolicy,
                  ),
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              isDark: isDark,
            ),
            
            const SizedBox(height: 24),
            
            // Sign Out
            _buildSettingsTile(
              icon: Icons.logout,
              iconColor: Colors.red,
              title: 'Sign Out',
              onTap: () => _signOut(authService),
              isDark: isDark,
            ),
            
            // DEV TOOLS (hidden by default, shown after 5 taps on version)
            if (_showDevTools || kDebugMode) ...[
              const SizedBox(height: 24),
              _buildDevToolsSection(usageService, isDark),
            ],
            
            const SizedBox(height: 32),
            
            // Version (tap 5 times to reveal dev tools)
            Center(
              child: GestureDetector(
                onTap: _handleVersionTap,
                child: Text(
                  'Composure v1.0.0 (Build 42)',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _handleVersionTap() {
    _versionTapCount++;
    if (_versionTapCount >= 5) {
      HapticFeedback.mediumImpact();
      setState(() => _showDevTools = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Developer tools unlocked', style: GoogleFonts.poppins()),
          backgroundColor: Colors.purple,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildDevToolsSection(UsageService usageService, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Developer Tools', isDark),
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.purple, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dev tools - for testing only',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.purple,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Force Premium toggle
        _buildSettingsTile(
          icon: Icons.star,
          iconColor: Colors.amber,
          title: 'Force Premium',
          subtitle: _forcePremiumEnabled ? 'ON - Treating as premium user' : 'OFF - Normal subscription check',
          onTap: () {
            HapticFeedback.mediumImpact();
            setState(() => _forcePremiumEnabled = !_forcePremiumEnabled);
          },
          trailing: Switch(
            value: _forcePremiumEnabled,
            onChanged: (value) {
              HapticFeedback.mediumImpact();
              setState(() => _forcePremiumEnabled = value);
            },
            activeColor: Colors.amber,
          ),
          isDark: isDark,
        ),
        
        // Reset Usage Counters
        _buildSettingsTile(
          icon: Icons.refresh,
          iconColor: Colors.orange,
          title: 'Reset Usage Counters',
          subtitle: 'Reset AI analysis count (${usageService.aiAnalysesUsed}/${UsageService.freeAIAnalysesLimit} used)',
          onTap: () => _showResetUsageDialog(usageService),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          isDark: isDark,
        ),
        
        // Reset All Data
        _buildSettingsTile(
          icon: Icons.delete_forever,
          iconColor: Colors.red,
          title: 'Reset All Test Data',
          subtitle: 'Clear matches, usage, and AI responses',
          onTap: () => _showFullResetDialog(usageService),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          isDark: isDark,
        ),
        
        // Usage Stats
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Usage',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Matches: ${usageService.matchCount}/${UsageService.freeMatchesLimit}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'AI Analyses: ${usageService.aiAnalysesUsed}/${UsageService.freeAIAnalysesLimit} (lifetime)',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'Can use AI: ${usageService.canUseTacticalAnalysis ? "Yes" : "No (paywall)"}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: usageService.canUseTacticalAnalysis ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showResetUsageDialog(UsageService usageService) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Usage Counters?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'This will reset your AI analysis count to 0, allowing you to test the free tier flow again.\n\nMatch count will also be reset.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Reset', style: GoogleFonts.poppins(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Use deleteUsageData to actually delete the stored data (not just reset in-memory)
      await usageService.deleteUsageData();
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usage counters reset - restart screens to see changes', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _showFullResetDialog(UsageService usageService) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset All Test Data?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'This will reset:\n\n• Usage counters\n• Match history\n• Saved AI responses\n\nThis action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Reset Everything', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Delete usage data (not just reset in-memory)
      await usageService.deleteUsageData();
      
      // Delete match history using the provider instance
      final matchService = Provider.of<MatchHistoryService>(context, listen: false);
      await matchService.deleteAllMatches();
      
      // Reset streak
      final streakService = Provider.of<StreakService>(context, listen: false);
      await streakService.resetStreak();
      
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All test data reset - navigate to other screens to see changes', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Widget _buildProfileCard(
    AuthService authService,
    PlayerProfileService profileService,
    bool isPremium,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.green.shade100,
            backgroundImage: authService.userPhotoURL != null
                ? NetworkImage(authService.userPhotoURL!)
                : null,
            child: authService.userPhotoURL == null
                ? Text(
                    (authService.userDisplayName ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authService.userDisplayName ?? 'Player',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[800],
                  ),
                ),
                Text(
                  authService.userEmail ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          if (isPremium)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _forcePremiumEnabled 
                    ? Colors.purple.shade100 
                    : Colors.amber.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.workspace_premium, 
                    size: 14, 
                    color: _forcePremiumEnabled ? Colors.purple : Colors.amber,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _forcePremiumEnabled ? 'DEV' : 'PRO',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _forcePremiumEnabled 
                          ? Colors.purple.shade800 
                          : Colors.amber.shade800,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(UsageService usageService, StreakService streakService, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('🔥', '${streakService.currentStreak}', 'Streak', isDark),
          _buildStatItem('📊', '${usageService.matchCount}', 'Matches', isDark),
          _buildStatItem('🎯', '${usageService.aiAnalysesRemaining}', 'Free analyses', isDark),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label, bool isDark) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey[800],
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[500],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    Color? iconColor,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap != null ? () {
        HapticFeedback.selectionClick();
        onTap();
      } : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? Colors.grey).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor ?? Colors.grey, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.grey[800],
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  String _getLevelLabel(String level) {
    final option = PlayerProfileService.levelOptions.firstWhere(
      (o) => o['id'] == level,
      orElse: () => {'title': 'Not set'},
    );
    return option['title'] ?? 'Not set';
  }

  String _getGoalLabel(String goal) {
    final option = PlayerProfileService.goalOptions.firstWhere(
      (o) => o['id'] == goal,
      orElse: () => {'title': 'Not set'},
    );
    return option['title'] ?? 'Not set';
  }

  void _showThemePicker(ThemeService themeService) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Theme',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: Text('System', style: GoogleFonts.poppins()),
              trailing: themeService.themeMode == ThemeMode.system 
                  ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                themeService.setThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: Text('Light', style: GoogleFonts.poppins()),
              trailing: themeService.themeMode == ThemeMode.light 
                  ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                themeService.setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: Text('Dark', style: GoogleFonts.poppins()),
              trailing: themeService.themeMode == ThemeMode.dark 
                  ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                themeService.setThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLevelPicker(PlayerProfileService profileService) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Skill Level',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...PlayerProfileService.levelOptions.map((option) => ListTile(
              title: Text(option['title']!, style: GoogleFonts.poppins()),
              subtitle: Text(option['subtitle']!, style: GoogleFonts.poppins(fontSize: 12)),
              trailing: profileService.playerLevel == option['id'] 
                  ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                profileService.setPlayerLevel(option['id']!);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showGoalPicker(PlayerProfileService profileService) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Primary Goal',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...PlayerProfileService.goalOptions.map((option) => ListTile(
              leading: Text(option['emoji']!, style: const TextStyle(fontSize: 24)),
              title: Text(option['title']!, style: GoogleFonts.poppins()),
              trailing: profileService.primaryGoal == option['id'] 
                  ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                profileService.setPrimaryGoal(option['id']!);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _openPaywall() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PaywallScreen(trigger: PaywallTrigger.general),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!', style: GoogleFonts.poppins()),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _signOut(AuthService authService) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to sign out?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sign Out', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}
