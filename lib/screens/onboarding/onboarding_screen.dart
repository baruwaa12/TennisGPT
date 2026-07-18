import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/player_profile_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/composure_kit.dart';
import '../home_screen.dart';
import '../../utils/tennis_validator.dart';
import '../../utils/paywall_navigation.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Form data
  String? _selectedLevel;
  String? _selectedGoal;
  final TextEditingController _opponentController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _matchResult = 'Win';
  String? _aiInsight;
  bool _isLoadingInsight = false;

  @override
  void dispose() {
    _pageController.dispose();
    _opponentController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _getFirstInsight() async {
    if (_opponentController.text.trim().isEmpty) {
      _skipToHome();
      return;
    }

    // Validate note is tennis-related if provided
    if (_noteController.text.trim().length > 20) {
      final validationError = TennisValidator.validate(_noteController.text);
      if (validationError != null) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please describe something tennis-related about your match',
              style: AppTheme.bodyMediumThemed(context)
                  .copyWith(color: Colors.white),
            ),
            backgroundColor: AppTheme.warning,
          ),
        );
        return;
      }
    }

    setState(() => _isLoadingInsight = true);
    HapticFeedback.mediumImpact();

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final profileService =
          Provider.of<PlayerProfileService>(context, listen: false);

      final matchDescription = '''
First match logged by new user.
${profileService.getPlayerContext()}
Match Result: $_matchResult against ${_opponentController.text.trim()}
${_noteController.text.isNotEmpty ? 'Notes: ${_noteController.text}' : ''}
Please provide a brief tactical insight to show the value of the app.
      '''
          .trim();

      final response =
          await apiService.tacticalAnalysisSummary(matchDescription, []);

      if (response == null && apiService.requiresUpgrade) {
        if (context.mounted) {
          await presentPaywall(context, trigger: PaywallTrigger.serverQuota);
        }
      }

      setState(() {
        _aiInsight = response;
        _isLoadingInsight = false;
      });

      _nextPage();
    } catch (e) {
      setState(() => _isLoadingInsight = false);
      _skipToHome();
    }
  }

  void _skipToHome() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    final profileService =
        Provider.of<PlayerProfileService>(context, listen: false);

    if (_selectedLevel != null) {
      await profileService.setPlayerLevel(_selectedLevel!);
    }
    if (_selectedGoal != null) {
      await profileService.setPrimaryGoal(_selectedGoal!);
    }
    await profileService.completeOnboarding();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground(context),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceLG),
              child: Row(
                children: List.generate(5, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(
                          right: index < 4 ? AppTheme.spaceSM : 0),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? AppTheme.primary
                            : AppTheme.borderColor(context),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: [
                  _buildWelcomePage(),
                  _buildLevelPage(),
                  _buildGoalPage(),
                  _buildMatchPage(),
                  _buildInsightPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          const Text(
            '🎯',
            style: TextStyle(fontSize: 80),
          ),
          const SizedBox(height: AppTheme.spaceLG),
          Text(
            'Composure',
            style: AppTheme.headingLargeThemed(context).copyWith(fontSize: 36),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            'Your AI Tennis Strategist',
            style: AppTheme.bodyLargeThemed(context),
          ),
          const SizedBox(height: AppTheme.spaceXXL),

          // Features
          _buildFeatureRow('⚡', 'Log matches in 30 seconds'),
          const SizedBox(height: AppTheme.spaceMD),
          _buildFeatureRow('🧠', 'Get tactical analysis'),
          const SizedBox(height: AppTheme.spaceMD),
          _buildFeatureRow('📈', 'Track your improvement'),

          const Spacer(),

          // Get Started Button
          CPrimaryButton(label: 'Get Started', onPressed: _nextPage),
          const SizedBox(height: AppTheme.spaceXL),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String emoji, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: AppTheme.spaceMD),
        Text(
          text,
          style: AppTheme.bodyMediumThemed(context).copyWith(
            color: AppTheme.textSecondaryColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelPage() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppTheme.spaceLG),
          Text(
            "What's your level?",
            style: AppTheme.headingMediumThemed(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            "We'll tailor insights to your skill level",
            style: AppTheme.bodyMediumThemed(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceXL),

          ...PlayerProfileService.levelOptions.map((level) {
            final isSelected = _selectedLevel == level['id'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Semantics(
                button: true,
                selected: isSelected,
                label: level['title'],
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedLevel = level['id']);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary.withValues(alpha: 0.08)
                          : AppTheme.elevatedBackground(context),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.borderColor(context),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.textMutedColor(context),
                              width: 2,
                            ),
                            color: isSelected
                                ? AppTheme.primary
                                : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 16)
                              : null,
                        ),
                        const SizedBox(width: AppTheme.spaceMD),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                level['title']!,
                                style: AppTheme.bodyMediumThemed(context)
                                    .copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimaryColor(context),
                                ),
                              ),
                              Text(
                                level['subtitle']!,
                                style: AppTheme.bodySmallThemed(context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const Spacer(),

          CPrimaryButton(
            label: 'Continue',
            onPressed: _selectedLevel != null ? _nextPage : null,
          ),
          const SizedBox(height: 12),
          _buildSkipButton(),
        ],
      ),
    );
  }

  Widget _buildGoalPage() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppTheme.spaceLG),
          Text(
            "What's your main goal?",
            style: AppTheme.headingMediumThemed(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            "We'll focus your insights on what matters",
            style: AppTheme.bodyMediumThemed(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceXL),

          ...PlayerProfileService.goalOptions.map((goal) {
            final isSelected = _selectedGoal == goal['id'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Semantics(
                button: true,
                selected: isSelected,
                label: goal['title'],
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedGoal = goal['id']);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary.withValues(alpha: 0.08)
                          : AppTheme.elevatedBackground(context),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.borderColor(context),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(goal['emoji']!,
                            style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: AppTheme.spaceMD),
                        Text(
                          goal['title']!,
                          style:
                              AppTheme.bodyMediumThemed(context).copyWith(
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.textPrimaryColor(context),
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          const Icon(Icons.check_circle,
                              color: AppTheme.primary),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const Spacer(),

          CPrimaryButton(
            label: 'Continue',
            onPressed: _selectedGoal != null ? _nextPage : null,
          ),
          const SizedBox(height: 12),
          _buildSkipButton(),
        ],
      ),
    );
  }

  Widget _buildMatchPage() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppTheme.spaceLG),
          Text(
            "Log your last match",
            style: AppTheme.headingMediumThemed(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            "Get instant tactical insights",
            style: AppTheme.bodyMediumThemed(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceXL),

          // Opponent name
          Text(
            'Opponent',
            style: AppTheme.bodyMediumThemed(context).copyWith(
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondaryColor(context),
            ),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          TextField(
            controller: _opponentController,
            style: AppTheme.bodyMediumThemed(context)
                .copyWith(color: AppTheme.textPrimaryColor(context)),
            decoration:
                AppTheme.inputDecorationThemed(context, hint: 'Who did you play?'),
          ),
          const SizedBox(height: 20),

          // Result toggle
          Text(
            'Result',
            style: AppTheme.bodyMediumThemed(context).copyWith(
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondaryColor(context),
            ),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Row(
            children: [
              Expanded(child: _buildResultToggle('Win', '🏆 WIN', AppTheme.win)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildResultToggle('Loss', '💪 LOSS', AppTheme.loss)),
            ],
          ),
          const SizedBox(height: 20),

          // Quick note
          Text(
            'One thing that stood out',
            style: AppTheme.bodyMediumThemed(context).copyWith(
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondaryColor(context),
            ),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          TextField(
            controller: _noteController,
            style: AppTheme.bodyMediumThemed(context)
                .copyWith(color: AppTheme.textPrimaryColor(context)),
            maxLines: 2,
            decoration: AppTheme.inputDecorationThemed(
              context,
              hint:
                  'e.g., "My serve was on fire" or "Struggled with returns"',
            ),
          ),

          const Spacer(),

          CPrimaryButton(
            label: 'Get My Analysis →',
            loading: _isLoadingInsight,
            loadingLabel: 'Analyzing...',
            onPressed: _isLoadingInsight ? null : _getFirstInsight,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _skipToHome,
              child: Text(
                'Skip for now',
                style: AppTheme.bodyMediumThemed(context)
                    .copyWith(color: AppTheme.textMutedColor(context)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultToggle(String value, String label, Color activeColor) {
    final isSelected = _matchResult == value;
    return Semantics(
      button: true,
      selected: isSelected,
      label: value,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _matchResult = value);
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor
                : AppTheme.elevatedBackground(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : AppTheme.borderColor(context),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTheme.bodyMediumThemed(context).copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : AppTheme.textMutedColor(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInsightPage() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppTheme.spaceLG),
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMD),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.20)),
            ),
            child: Row(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 32)),
                const SizedBox(width: AppTheme.spaceMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your First Tactical Insight',
                        style: AppTheme.headingSmallThemed(context).copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.isDark(context)
                              ? AppTheme.primaryLight
                              : AppTheme.primaryDark,
                        ),
                      ),
                      Text(
                        'Based on your match vs ${_opponentController.text}',
                        style: AppTheme.bodySmallThemed(context)
                            .copyWith(color: AppTheme.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceLG),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.cardDecorationThemed(context),
              child: _aiInsight == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                              color: AppTheme.primary),
                          const SizedBox(height: AppTheme.spaceMD),
                          Text(
                            'Analyzing your match...',
                            style: AppTheme.bodySmallThemed(context),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Text(
                        _aiInsight!,
                        style: AppTheme.bodyMediumThemed(context).copyWith(
                          height: 1.7,
                          color: AppTheme.textPrimaryColor(context),
                        ),
                      ),
                    ),
            ),
          ),

          const SizedBox(height: AppTheme.spaceLG),

          Text(
            'Your account is ready.',
            style: AppTheme.bodyMediumThemed(context).copyWith(
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondaryColor(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceMD),

          CPrimaryButton(
            label: 'Continue to Home',
            onPressed: _completeOnboarding,
          ),
        ],
      ),
    );
  }

  Widget _buildSkipButton() {
    return Center(
      child: TextButton(
        onPressed: _skipToHome,
        child: Text(
          'Skip',
          style: AppTheme.bodyMediumThemed(context)
              .copyWith(color: AppTheme.textMutedColor(context)),
        ),
      ),
    );
  }
}
