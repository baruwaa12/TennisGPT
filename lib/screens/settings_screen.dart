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
import '../config/app_config.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'help_faq_screen.dart';
import 'feedback_screen.dart';
import 'legal_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authService = Provider.of<AuthService>(context);
    final themeService = Provider.of<ThemeService>(context);
    final purchaseService = Provider.of<PurchaseService>(context);
    final profileService = Provider.of<PlayerProfileService>(context);
    final usageService = Provider.of<UsageService>(context);
    final streakService = Provider.of<StreakService>(context);

    // Treat all users as premium while payments are hidden.
    final isPremium = purchaseService.isPremium || 
                      !AppConfig.paymentsEnabled ||
                      AppConfig.isCompedUser(email: authService.userEmail);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.surfaceDark : Colors.grey[50],
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
              iconColor: AppTheme.primary,
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
              iconColor: AppTheme.primary,
              title: 'Send Feedback',
              subtitle: 'Help us improve Composure',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FeedbackScreen()),
              ),
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
            
            // Account
            _buildSectionTitle('Account', isDark),
            _buildSettingsTile(
              icon: Icons.delete_forever_outlined,
              iconColor: Colors.red,
              title: 'Delete Account',
              subtitle: 'Permanently remove your account and data',
              onTap: () => _deleteAccount(authService),
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
            
            const SizedBox(height: 32),
            
            // Version
            Center(
              child: Text(
                'Composure v1.0.0 (Build 47)',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
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
        color: isDark ? AppTheme.surfaceCard : Colors.white,
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
            backgroundColor: AppTheme.primary.withOpacity(0.15),
            backgroundImage: authService.userPhotoURL != null
                ? NetworkImage(authService.userPhotoURL!)
                : null,
            child: authService.userPhotoURL == null
                ? Text(
                    (authService.userDisplayName ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.primaryLight,
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
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.workspace_premium, 
                    size: 14, 
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'PRO',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade800,
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
        color: isDark ? AppTheme.surfaceCard : Colors.white,
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
          color: isDark ? AppTheme.surfaceCard : Colors.white,
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
                  ? Icon(Icons.check, color: AppTheme.primary) : null,
              onTap: () {
                themeService.setThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: Text('Light', style: GoogleFonts.poppins()),
              trailing: themeService.themeMode == ThemeMode.light 
                  ? Icon(Icons.check, color: AppTheme.primary) : null,
              onTap: () {
                themeService.setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: Text('Dark', style: GoogleFonts.poppins()),
              trailing: themeService.themeMode == ThemeMode.dark 
                  ? Icon(Icons.check, color: AppTheme.primary) : null,
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
                  ? Icon(Icons.check, color: AppTheme.primary) : null,
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
                  ? Icon(Icons.check, color: AppTheme.primary) : null,
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

  Future<void> _deleteAccount(AuthService authService) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'This permanently deletes your account and all associated app data. This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await authService.deleteAccount();
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account deleted successfully', style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.primary,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          authService.error ?? 'Could not delete account right now.',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
}
