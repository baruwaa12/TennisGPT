import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../services/court_service.dart';
import '../services/purchase_service.dart';
import '../services/player_profile_service.dart';
import '../services/usage_service.dart';
import '../services/streak_service.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';
import '../widgets/composure_kit.dart';
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
    final authService = Provider.of<AuthService>(context);
    final themeService = Provider.of<ThemeService>(context);
    final courtService = Provider.of<CourtService>(context);
    final purchaseService = Provider.of<PurchaseService>(context);
    final profileService = Provider.of<PlayerProfileService>(context);
    final usageService = Provider.of<UsageService>(context);
    final streakService = Provider.of<StreakService>(context);

    final isPremium = AppConfig.hasPremiumAccess(
      revenueCatPremium: purchaseService.isPremium,
      backendPremium: authService.isPremium,
      email: authService.userEmail,
    );

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground(context),
      appBar: AppBar(
        title: Text(
          'Settings',
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
            // Profile Card (authenticated only)
            if (!authService.isGuest) ...[
              _buildProfileCard(authService, profileService, isPremium),
              const SizedBox(height: AppTheme.spaceLG),
              _buildStatsCard(usageService, streakService),
              const SizedBox(height: AppTheme.spaceLG),
            ],

            // Guest sign-in prompt
            if (authService.isGuest) ...[
              _buildSettingsTile(
                icon: Icons.login_rounded,
                iconColor: AppTheme.primary,
                title: 'Sign In',
                subtitle: 'Create a free account to unlock all features',
                onTap: () {
                  authService.exitGuestMode();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                trailing: Icon(Icons.arrow_forward_ios,
                    size: 16, color: AppTheme.textMutedColor(context)),
              ),
              const SizedBox(height: AppTheme.spaceLG),
            ],

            // Appearance Section
            _buildSectionTitle('Appearance'),
            _buildSettingsTile(
              icon: themeService.themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
              iconColor: AppTheme.primary,
              title: 'Theme',
              subtitle: _getThemeLabel(themeService.themeMode),
              onTap: () => _showThemePicker(themeService),
              trailing: Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppTheme.textMutedColor(context)),
            ),
            _buildSettingsTile(
              icon: Icons.sports_tennis_outlined,
              iconColor: AppTheme.primary,
              title: 'Court surface',
              subtitle: courtService.displayName,
              onTap: () => _showCourtSurfacePicker(courtService),
              trailing: Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppTheme.textMutedColor(context)),
            ),

            const SizedBox(height: AppTheme.spaceLG),

            // Player Profile Section (authenticated only)
            if (!authService.isGuest) ...[
              _buildSectionTitle('Player Profile'),
              _buildSettingsTile(
                icon: Icons.sports_tennis,
                iconColor: AppTheme.primary,
                title: 'Skill Level',
                subtitle: _getLevelLabel(profileService.playerLevel),
                onTap: () => _showLevelPicker(profileService),
                trailing: Icon(Icons.arrow_forward_ios,
                    size: 16, color: AppTheme.textMutedColor(context)),
              ),
              _buildSettingsTile(
                icon: Icons.flag,
                iconColor: AppTheme.primary,
                title: 'Primary Goal',
                subtitle: _getGoalLabel(profileService.primaryGoal),
                onTap: () => _showGoalPicker(profileService),
                trailing: Icon(Icons.arrow_forward_ios,
                    size: 16, color: AppTheme.textMutedColor(context)),
              ),
              const SizedBox(height: AppTheme.spaceLG),
            ],

            // Support Section
            _buildSectionTitle('Support'),
            _buildSettingsTile(
              icon: Icons.help_outline,
              iconColor: AppTheme.primary,
              title: 'Help & FAQ',
              subtitle: 'Get answers to common questions',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpFaqScreen()),
              ),
              trailing: Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppTheme.textMutedColor(context)),
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
              trailing: Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppTheme.textMutedColor(context)),
            ),
            const SizedBox(height: AppTheme.spaceLG),

            // Legal Section
            _buildSectionTitle('Legal'),
            _buildSettingsTile(
              icon: Icons.description_outlined,
              iconColor: AppTheme.textMutedColor(context),
              title: 'Terms of Service',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LegalScreen(
                    documentType: LegalDocumentType.termsOfService,
                  ),
                ),
              ),
              trailing: Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppTheme.textMutedColor(context)),
            ),
            _buildSettingsTile(
              icon: Icons.privacy_tip_outlined,
              iconColor: AppTheme.textMutedColor(context),
              title: 'Privacy Policy',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LegalScreen(
                    documentType: LegalDocumentType.privacyPolicy,
                  ),
                ),
              ),
              trailing: Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppTheme.textMutedColor(context)),
            ),
            if (!authService.isGuest && AppConfig.paymentsEnabled)
              _buildSettingsTile(
                icon: Icons.manage_accounts_outlined,
                iconColor: AppTheme.primary,
                title: 'Manage Subscription',
                subtitle: 'View, change, or cancel your plan',
                onTap: _openSubscriptionManagement,
                trailing: Icon(Icons.open_in_new,
                    size: 16, color: AppTheme.textMutedColor(context)),
              ),

            // Account section (authenticated only)
            if (!authService.isGuest) ...[
              const SizedBox(height: AppTheme.spaceLG),
              _buildSectionTitle('Account'),
              _buildSettingsTile(
                icon: Icons.delete_forever_outlined,
                iconColor: AppTheme.loss,
                title: 'Delete Account',
                subtitle: 'Permanently remove your account and data',
                onTap: () => _deleteAccount(authService),
              ),
              const SizedBox(height: AppTheme.spaceLG),
              _buildSettingsTile(
                icon: Icons.logout,
                iconColor: AppTheme.loss,
                title: 'Sign Out',
                onTap: () => _signOut(authService),
              ),
            ],

            const SizedBox(height: AppTheme.spaceXL),

            // Version
            Center(
              child: Text(
                'Composure v${AppConfig.appVersion} (Build ${AppConfig.buildNumber})',
                style: AppTheme.bodySmallThemed(context).copyWith(
                  fontSize: 12,
                  color: AppTheme.textMutedColor(context),
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spaceMD),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(
    AuthService authService,
    PlayerProfileService profileService,
    bool isPremium,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: AppTheme.cardDecorationThemed(context),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
            backgroundImage: authService.userPhotoURL != null
                ? NetworkImage(authService.userPhotoURL!)
                : null,
            child: authService.userPhotoURL == null
                ? Text(
                    (authService.userDisplayName ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontVariations: AppTheme.fontVariationsSemiExpanded,
                      color: AppTheme.primaryLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authService.userDisplayName ?? 'Player',
                  style: AppTheme.headingSmallThemed(context)
                      .copyWith(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Text(
                  authService.userEmail ?? '',
                  style: AppTheme.bodySmallThemed(context).copyWith(
                    fontSize: 13,
                    color: AppTheme.textMutedColor(context),
                  ),
                ),
              ],
            ),
          ),
          if (AppConfig.paymentsEnabled && isPremium)
            const CBadge(
              label: 'PRO',
              variant: CBadgeVariant.warning,
              icon: Icons.workspace_premium,
              pill: true,
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(
      UsageService usageService, StreakService streakService) {
    return Container(
      padding: AppTheme.cardPadding,
      decoration: AppTheme.cardDecorationThemed(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('🔥', '${streakService.currentStreak}', 'Streak'),
          _buildStatItem('📊', '${usageService.matchCount}', 'Matches'),
          _buildStatItem(
              '🎯', '${usageService.aiAnalysesRemaining}', 'Free analyses'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: AppTheme.spaceXS),
        Text(
          value,
          style: AppTheme.statMediumThemed(context).copyWith(fontSize: 20),
        ),
        Text(
          label,
          style: AppTheme.bodySmallThemed(context).copyWith(
            fontSize: 12,
            color: AppTheme.textMutedColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CEyebrow(title, color: AppTheme.textMutedColor(context)),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    Color? iconColor,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final tint = iconColor ?? AppTheme.textMutedColor(context);
    return Semantics(
      button: onTap != null,
      label: title,
      child: GestureDetector(
        onTap: onTap != null
            ? () {
                HapticFeedback.selectionClick();
                onTap();
              }
            : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spaceSM),
          padding: AppTheme.cardPadding,
          constraints: const BoxConstraints(minHeight: 44),
          decoration: AppTheme.cardDecorationThemed(context),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceSM),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: Icon(icon, color: tint, size: 20),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.bodyMediumThemed(context).copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimaryColor(context),
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: AppTheme.bodySmallThemed(context).copyWith(
                          fontSize: 12,
                          color: AppTheme.textMutedColor(context),
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
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
      backgroundColor: AppTheme.cardBackground(context),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLG)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Theme',
              style: AppTheme.headingSmallThemed(context)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            ListTile(
              leading: Icon(Icons.brightness_auto,
                  color: AppTheme.textSecondaryColor(context)),
              title:
                  Text('System', style: AppTheme.bodyMediumThemed(context)),
              trailing: themeService.themeMode == ThemeMode.system
                  ? const Icon(Icons.check, color: AppTheme.primary)
                  : null,
              onTap: () {
                themeService.setThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.light_mode,
                  color: AppTheme.textSecondaryColor(context)),
              title: Text('Light', style: AppTheme.bodyMediumThemed(context)),
              trailing: themeService.themeMode == ThemeMode.light
                  ? const Icon(Icons.check, color: AppTheme.primary)
                  : null,
              onTap: () {
                themeService.setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.dark_mode,
                  color: AppTheme.textSecondaryColor(context)),
              title: Text('Dark', style: AppTheme.bodyMediumThemed(context)),
              trailing: themeService.themeMode == ThemeMode.dark
                  ? const Icon(Icons.check, color: AppTheme.primary)
                  : null,
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

  void _showCourtSurfacePicker(CourtService courtService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground(context),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLG)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Court Surface',
              style: AppTheme.headingSmallThemed(context)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppTheme.spaceSM),
            Text(
              'Changes the home screen background. The Quick Match button uses a complementary colour for each court.',
              style: AppTheme.bodySmallThemed(context).copyWith(
                fontSize: 13,
                color: AppTheme.textMutedColor(context),
              ),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            ListTile(
              leading: Icon(Icons.terrain_outlined,
                  color: AppTheme.surfaceAccent('clay')),
              title: Text('Clay', style: AppTheme.bodyMediumThemed(context)),
              subtitle: Text('Roland Garros - blue button',
                  style: AppTheme.bodySmallThemed(context)
                      .copyWith(fontSize: 12)),
              trailing: courtService.surface == CourtSurface.clay
                  ? const Icon(Icons.check, color: AppTheme.primary)
                  : null,
              onTap: () {
                courtService.setSurface(CourtSurface.clay);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.sports_tennis_outlined,
                  color: AppTheme.surfaceAccent('hard')),
              title: Text('Hard (Blue)',
                  style: AppTheme.bodyMediumThemed(context)),
              subtitle: Text('US / Australian Open - red button',
                  style: AppTheme.bodySmallThemed(context)
                      .copyWith(fontSize: 12)),
              trailing: courtService.surface == CourtSurface.hard
                  ? const Icon(Icons.check, color: AppTheme.primary)
                  : null,
              onTap: () {
                courtService.setSurface(CourtSurface.hard);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.grass_outlined,
                  color: AppTheme.surfaceAccent('grass')),
              title: Text('Grass', style: AppTheme.bodyMediumThemed(context)),
              subtitle: Text('Wimbledon - navy button',
                  style: AppTheme.bodySmallThemed(context)
                      .copyWith(fontSize: 12)),
              trailing: courtService.surface == CourtSurface.grass
                  ? const Icon(Icons.check, color: AppTheme.primary)
                  : null,
              onTap: () {
                courtService.setSurface(CourtSurface.grass);
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
      backgroundColor: AppTheme.cardBackground(context),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLG)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Skill Level',
              style: AppTheme.headingSmallThemed(context)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            ...PlayerProfileService.levelOptions.map((option) => ListTile(
                  title: Text(option['title']!,
                      style: AppTheme.bodyMediumThemed(context)),
                  subtitle: Text(option['subtitle']!,
                      style: AppTheme.bodySmallThemed(context)
                          .copyWith(fontSize: 12)),
                  trailing: profileService.playerLevel == option['id']
                      ? const Icon(Icons.check, color: AppTheme.primary)
                      : null,
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
      backgroundColor: AppTheme.cardBackground(context),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLG)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Primary Goal',
              style: AppTheme.headingSmallThemed(context)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            ...PlayerProfileService.goalOptions.map((option) => ListTile(
                  leading: Text(option['emoji']!,
                      style: const TextStyle(fontSize: 24)),
                  title: Text(option['title']!,
                      style: AppTheme.bodyMediumThemed(context)),
                  trailing: profileService.primaryGoal == option['id']
                      ? const Icon(Icons.check, color: AppTheme.primary)
                      : null,
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
        backgroundColor: AppTheme.cardBackground(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          side: BorderSide(color: AppTheme.borderColor(context)),
        ),
        title: Text('Sign Out',
            style: AppTheme.headingSmallThemed(context)
                .copyWith(fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to sign out?',
            style: AppTheme.bodyMediumThemed(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('Cancel', style: AppTheme.bodyMediumThemed(context)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sign Out',
                style: AppTheme.bodyMediumThemed(context).copyWith(
                    color: AppTheme.loss, fontWeight: FontWeight.w600)),
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
        backgroundColor: AppTheme.cardBackground(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          side: BorderSide(color: AppTheme.borderColor(context)),
        ),
        title: Text('Delete Account?',
            style: AppTheme.headingSmallThemed(context)
                .copyWith(fontWeight: FontWeight.w600)),
        content: Text(
          'This permanently deletes your account and all associated app data. This action cannot be undone.',
          style: AppTheme.bodyMediumThemed(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('Cancel', style: AppTheme.bodyMediumThemed(context)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: AppTheme.bodyMediumThemed(context).copyWith(
                    color: AppTheme.loss, fontWeight: FontWeight.w600)),
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
          content: Text('Account deleted successfully',
              style: AppTheme.bodyMediumThemed(context)
                  .copyWith(color: Colors.white)),
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
          style: AppTheme.bodyMediumThemed(context)
              .copyWith(color: Colors.white),
        ),
        backgroundColor: AppTheme.loss,
      ),
    );
  }

  Future<void> _openSubscriptionManagement() async {
    final Uri uri;
    if (kIsWeb) {
      uri = Uri.parse('https://apps.apple.com/account/subscriptions');
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      uri = Uri.parse('https://apps.apple.com/account/subscriptions');
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      uri = Uri.parse('https://play.google.com/store/account/subscriptions');
    } else {
      uri = Uri.parse('https://support.apple.com/en-us/118428');
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open subscription settings right now.',
            style: AppTheme.bodyMediumThemed(context)
                .copyWith(color: Colors.white),
          ),
          backgroundColor: AppTheme.loss,
        ),
      );
    }
  }
}
