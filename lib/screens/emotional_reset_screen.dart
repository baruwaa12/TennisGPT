import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/purchase_service.dart';
import '../services/usage_service.dart';
import '../utils/tennis_validator.dart';
import '../utils/ai_disclosure_consent.dart';
import '../utils/paywall_navigation.dart';
import '../widgets/voice_input_button.dart';

/// Post-Match Debrief Screen
///
/// UX Philosophy: Calm coach debrief, not venting or self-criticism
///
/// Key principles:
/// - Neutral language (no blame, no judgment)
/// - Focus on patterns and controllables, not identity
/// - Safe to open after a loss
/// - Error messages are human-readable, never technical
class EmotionalResetScreen extends StatefulWidget {
  const EmotionalResetScreen({super.key});

  @override
  State<EmotionalResetScreen> createState() => _EmotionalResetScreenState();
}

class _EmotionalResetScreenState extends State<EmotionalResetScreen> {
  final TextEditingController _customController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _responseCardKey = GlobalKey();
  String? _selectedSituation;
  bool _showCustomInput = false;
  String? _localError;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _showSavedTab = false;
  List<Map<String, dynamic>> _savedEntries = [];
  int? _expandedCardIndex;
  String? _debriefResponse;

  /// Debrief options - neutral, coach-like framing
  /// Focus on patterns and situations, not blame or identity
  final List<Map<String, dynamic>> _situations = [
    {
      'icon': Icons.timer_outlined,
      'title': 'Struggled under pressure',
      'description': 'Tight moments didn\'t go my way',
      'prompt':
          'I struggled to perform under pressure during key moments in the match. Help me understand what happened and how to handle these situations better.',
    },
    {
      'icon': Icons.sports_tennis_outlined,
      'title': 'Game plan didn\'t execute',
      'description': 'Strategy fell apart during play',
      'prompt':
          'My tactical game plan didn\'t translate into match play. Help me analyze what went wrong and how to better execute my strategy.',
    },
    {
      'icon': Icons.error_outline_rounded,
      'title': 'Too many unforced errors',
      'description': 'Consistency let me down',
      'prompt':
          'I made too many unforced errors during the match. Help me understand the patterns and what I can work on to improve consistency.',
    },
    {
      'icon': Icons.psychology_outlined,
      'title': 'Focus dropped mid-match',
      'description': 'Concentration wavered at key times',
      'prompt':
          'I lost focus and concentration during key moments of the match. Help me understand what triggered this and how to maintain better mental presence.',
    },
    {
      'icon': Icons.sync_problem_outlined,
      'title': 'Couldn\'t find my rhythm',
      'description': 'Timing and flow felt off',
      'prompt':
          'I struggled to find my rhythm and timing during the match. My shots felt off and I couldn\'t settle into my game. Help me understand what happened.',
    },
    {
      'icon': Icons.trending_down_rounded,
      'title': 'Level dropped after lead',
      'description': 'Momentum shifted away',
      'prompt':
          'I had a lead but my level dropped and I couldn\'t maintain the momentum. Help me analyze what changed and how to stay consistent when ahead.',
    },
  ];

  @override
  void dispose() {
    _customController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToResponse() {
    // Use post-frame callback to ensure widget is built first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_responseCardKey.currentContext != null) {
          Scrollable.ensureVisible(
            _responseCardKey.currentContext!,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            alignment: 0.1,
          );
        } else if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground(context),
      body: Consumer<ApiService>(
        builder: (context, apiService, child) {
          // Show saved tab
          if (_showSavedTab) {
            return _buildSavedView(context);
          }

          // Show response view if we have a response
          if (_debriefResponse != null) {
            return _buildResponseView(context);
          }

          // Show input view
          return _buildInputView(context, apiService);
        },
      ),
    );
  }

  Widget _buildInputView(BuildContext context, ApiService apiService) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: CustomScrollView(
        controller: _scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          // Subtle header
          SliverAppBar(
            backgroundColor: AppTheme.scaffoldBackground(context),
            elevation: 0,
            pinned: true,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: AppTheme.textSecondaryColor(context)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Match Debrief',
              style: AppTheme.headingSmallThemed(context).copyWith(
                color: AppTheme.textSecondaryColor(context),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _showSavedTab = true);
                  _loadSavedDebriefs();
                },
                child: Text(
                  'Saved',
                  style: AppTheme.labelThemed(context).copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          SliverPadding(
            padding: AppTheme.screenPadding,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Intro card - calm, supportive tone
                _buildIntroCard(),

                const SizedBox(height: AppTheme.spaceLG),

                // Situation selection
                Text(
                  'What happened?',
                  style: AppTheme.headingMediumThemed(context),
                ),
                const SizedBox(height: AppTheme.spaceXS),
                Text(
                  'Select what best describes your match',
                  style: AppTheme.bodySmallThemed(context),
                ),

                const SizedBox(height: AppTheme.spaceMD),

                // Situation cards
                ...List.generate(_situations.length, (index) {
                  final situation = _situations[index];
                  final isSelected = _selectedSituation == situation['prompt'];

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom:
                          index < _situations.length - 1 ? AppTheme.spaceSM : 0,
                    ),
                    child: _buildSituationCard(
                      icon: situation['icon'] as IconData,
                      title: situation['title'] as String,
                      description: situation['description'] as String,
                      isSelected: isSelected,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedSituation = situation['prompt'];
                          _showCustomInput = false;
                          _localError = null;
                        });
                      },
                    ),
                  );
                }),

                const SizedBox(height: AppTheme.spaceSM),

                // Custom option
                _buildCustomOption(),

                // Custom input field
                if (_showCustomInput) ...[
                  const SizedBox(height: AppTheme.spaceMD),
                  _buildCustomInput(),
                ],

                const SizedBox(height: AppTheme.spaceLG),

                // Error display - human-readable
                if (_localError != null || apiService.error != null) ...[
                  _buildErrorCard(_localError ?? apiService.error!),
                  const SizedBox(height: AppTheme.spaceMD),
                ],

                // Primary CTA
                _buildPrimaryCTA(apiService),

                const SizedBox(height: AppTheme.spaceXXL),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: AppTheme.cardPaddingLarge,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMD),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sports_tennis_rounded,
              size: 32,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Text(
            'Let\'s review your match',
            style: AppTheme.headingMediumThemed(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            'Every match is a learning opportunity. Let\'s break down what happened and find actionable takeaways.',
            textAlign: TextAlign.center,
            style: AppTheme.bodyMediumThemed(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSituationCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.1)
              : AppTheme.cardBackground(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(
            color:
                isSelected ? AppTheme.primary : AppTheme.borderColor(context),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceSM),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withValues(alpha: 0.2)
                    : AppTheme.elevatedBackground(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? AppTheme.primary
                    : AppTheme.textSecondaryColor(context),
              ),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.headingSmallThemed(context).copyWith(
                      color: isSelected
                          ? AppTheme.textPrimaryColor(context)
                          : AppTheme.textSecondaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTheme.bodySmallThemed(context),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomOption() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _showCustomInput = true;
          _selectedSituation = null;
          _localError = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        decoration: BoxDecoration(
          color: _showCustomInput
              ? AppTheme.primary.withValues(alpha: 0.1)
              : AppTheme.cardBackground(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(
            color: _showCustomInput
                ? AppTheme.primary
                : AppTheme.borderColor(context),
            width: _showCustomInput ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceSM),
              decoration: BoxDecoration(
                color: _showCustomInput
                    ? AppTheme.primary.withValues(alpha: 0.2)
                    : AppTheme.elevatedBackground(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: Icon(
                Icons.edit_note_rounded,
                size: 20,
                color: _showCustomInput
                    ? AppTheme.primary
                    : AppTheme.textSecondaryColor(context),
              ),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: Text(
                'Describe something else',
                style: AppTheme.headingSmallThemed(context).copyWith(
                  color: _showCustomInput
                      ? AppTheme.textPrimaryColor(context)
                      : AppTheme.textSecondaryColor(context),
                ),
              ),
            ),
            if (_showCustomInput)
              Icon(
                Icons.check_circle_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Voice input hint (matches Tactical screen)
        Row(
          children: [
            Icon(
              Icons.mic,
              size: 14,
              color: AppTheme.textMutedColor(context).withValues(alpha: 0.5),
            ),
            const SizedBox(width: 4),
            Text(
              'Voice enabled',
              style: AppTheme.labelThemed(context).copyWith(
                fontSize: 11,
                color: AppTheme.textMutedColor(context).withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceSM),

        // VoiceTextField - same component as Tactical screen
        VoiceTextField(
          controller: _customController,
          hintText: 'Describe what happened in your match...',
          maxLines: 3,
          style: AppTheme.bodyMediumThemed(context).copyWith(
            color: AppTheme.textPrimaryColor(context),
          ),
          onChanged: (value) {
            setState(() {
              _selectedSituation = value.isNotEmpty ? value : null;
              _localError = null;
            });
          },
        ),
      ],
    );
  }

  /// Error card - human-readable, with retry option
  Widget _buildErrorCard(String error) {
    // Convert technical errors to human-readable messages
    String humanMessage = _humanizeError(error);

    return Container(
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: AppTheme.loss.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.loss.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppTheme.loss.withValues(alpha: 0.8),
            size: 20,
          ),
          const SizedBox(width: AppTheme.spaceSM),
          Expanded(
            child: Text(
              humanMessage,
              style: AppTheme.bodySmallThemed(context).copyWith(
                color: AppTheme.textSecondaryColor(context),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() => _localError = null);
              context.read<ApiService>().clearError();
            },
            child: Text(
              'Dismiss',
              style: AppTheme.labelThemed(context)
                  .copyWith(color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  /// Convert technical/raw errors to human-friendly messages
  String _humanizeError(String error) {
    final lowerError = error.toLowerCase();

    if (lowerError.contains('500') || lowerError.contains('server')) {
      return 'We couldn\'t generate your debrief right now. Please try again in a moment.';
    }
    if (lowerError.contains('timeout') || lowerError.contains('timed out')) {
      return 'This is taking longer than expected. Please try again.';
    }
    if (lowerError.contains('network') || lowerError.contains('connection')) {
      return 'Please check your connection and try again.';
    }
    if (lowerError.contains('401') || lowerError.contains('unauthorized')) {
      return 'Please sign in again to continue.';
    }

    // Default friendly message
    return 'Something went wrong. Please try again.';
  }

  Widget _buildPrimaryCTA(ApiService apiService) {
    final hasSelection =
        _selectedSituation != null && _selectedSituation!.isNotEmpty;
    final isLoading = _isLoading || apiService.isLoading;

    return GestureDetector(
      onTap: isLoading || !hasSelection
          ? null
          : () => _handleDebrief(context, apiService),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: hasSelection
              ? AppTheme.primary
              : AppTheme.elevatedBackground(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: hasSelection
              ? null
              : Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Center(
          child: isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: hasSelection
                            ? AppTheme.surfaceDark
                            : AppTheme.textMutedColor(context),
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceSM),
                    Text(
                      'Reviewing match...',
                      style: AppTheme.headingSmallThemed(context).copyWith(
                        color: hasSelection
                            ? AppTheme.surfaceDark
                            : AppTheme.textMutedColor(context),
                      ),
                    ),
                  ],
                )
              : Text(
                  'Review match debrief',
                  style: AppTheme.headingSmallThemed(context).copyWith(
                    color: hasSelection
                        ? AppTheme.surfaceDark
                        : AppTheme.textMutedColor(context),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildResponseView(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverAppBar(
          backgroundColor: AppTheme.scaffoldBackground(context),
          elevation: 0,
          pinned: true,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: AppTheme.textSecondaryColor(context)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Match Debrief',
            style: AppTheme.headingSmallThemed(context).copyWith(
              color: AppTheme.textSecondaryColor(context),
            ),
          ),
        ),

        SliverPadding(
          padding: AppTheme.screenPadding,
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Success indicator
              Container(
                padding: AppTheme.cardPadding,
                decoration: BoxDecoration(
                  color: AppTheme.win.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  border:
                      Border.all(color: AppTheme.win.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppTheme.win,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spaceSM),
                    Text(
                      'Debrief complete',
                      style: AppTheme.headingSmallThemed(context).copyWith(
                        color: AppTheme.win,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spaceLG),

              // Response card
              Container(
                key: _responseCardKey,
                padding: AppTheme.cardPaddingLarge,
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  border: Border.all(color: AppTheme.borderColor(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spaceSM),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSM),
                          ),
                          child: Icon(
                            Icons.lightbulb_outline_rounded,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spaceSM),
                        Text(
                          'Coach Feedback',
                          style: AppTheme.headingMediumThemed(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceMD),
                    Divider(color: AppTheme.borderColor(context), height: 1),
                    const SizedBox(height: AppTheme.spaceMD),
                    Text(
                      _debriefResponse!,
                      style: AppTheme.bodyLargeThemed(context).copyWith(
                        height: 1.7,
                        color: AppTheme.textSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spaceLG),

              // Save button
              GestureDetector(
                onTap: _isSaving
                    ? null
                    : () => _saveCurrentDebrief(_debriefResponse!),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground(context),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSaving)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primary,
                          ),
                        )
                      else
                        Icon(Icons.bookmark_outline_rounded,
                            size: 18, color: AppTheme.primary),
                      const SizedBox(width: AppTheme.spaceSM),
                      Text(
                        _isSaving ? 'Saving...' : 'Save debrief',
                        style: AppTheme.headingSmallThemed(context)
                            .copyWith(color: AppTheme.primary),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spaceMD),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _selectedSituation = null;
                          _showCustomInput = false;
                          _customController.clear();
                          _localError = null;
                          _debriefResponse = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground(context),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMD),
                          border:
                              Border.all(color: AppTheme.borderColor(context)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.refresh_rounded,
                              size: 18,
                              color: AppTheme.textSecondaryColor(context),
                            ),
                            const SizedBox(width: AppTheme.spaceSM),
                            Text(
                              'New debrief',
                              style:
                                  AppTheme.headingSmallThemed(context).copyWith(
                                color: AppTheme.textSecondaryColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMD),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMD),
                        ),
                        child: Center(
                          child: Text(
                            'Done',
                            style:
                                AppTheme.headingSmallThemed(context).copyWith(
                              color: AppTheme.surfaceDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.spaceXXL),
            ]),
          ),
        ),
      ],
    );
  }

  Future<void> _handleDebrief(
    BuildContext context,
    ApiService apiService,
  ) async {
    if (_selectedSituation == null) return;

    // Check usage limits (respects feature flags)
    final purchaseService =
        Provider.of<PurchaseService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final usageService = Provider.of<UsageService>(context, listen: false);

    // Validate tennis-related content for custom input
    if (_showCustomInput) {
      final validationError = TennisValidator.validate(_selectedSituation!);
      if (validationError != null) {
        HapticFeedback.mediumImpact();
        setState(() => _localError = validationError);
        return;
      }
    }

    final consented = await AiDisclosureConsent.ensureAccepted(context);
    if (!consented) {
      return;
    }
    if (!mounted) return;

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      final response = await apiService.emotionalReset(_selectedSituation!);

      setState(() {
        _isLoading = false;
        _debriefResponse = response;
      });

      if (response == null) {
        if (apiService.requiresUpgrade) {
          if (!mounted) return;
          // ignore: use_build_context_synchronously
          await presentPaywall(context, trigger: PaywallTrigger.serverQuota);
          if (!mounted) return;
        } else if (apiService.error != null) {
          setState(() => _localError = apiService.error);
        }
      }

      // Record usage for free users
      if (response != null &&
          !AppConfig.hasPremiumAccess(
            revenueCatPremium: purchaseService.isPremium,
            backendPremium: authService.isPremium,
            email: authService.userEmail,
          )) {
        await usageService.recordDebrief();
      }

      if (response != null && mounted) {
        _scrollToResponse();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _localError = e.toString();
      });
    }
  }

  // ============ Save + Saved Tab ============

  Future<void> _saveCurrentDebrief(String content) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.lightImpact();

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final success = await apiService.saveDebrief(content);

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Saved (max 3 stored)' : 'Could not save. Try again.',
              style: AppTheme.bodyMediumThemed(context)
                  .copyWith(color: Colors.white),
            ),
            backgroundColor: success ? AppTheme.win : AppTheme.loss,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _loadSavedDebriefs() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final entries = await apiService.getSavedDebriefs();
    if (mounted) {
      setState(() => _savedEntries = entries);
    }
  }

  Widget _buildSavedView(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: AppTheme.scaffoldBackground(context),
          elevation: 0,
          pinned: true,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: AppTheme.textSecondaryColor(context)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Match Debrief',
            style: AppTheme.headingSmallThemed(context)
                .copyWith(color: AppTheme.textSecondaryColor(context)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _showSavedTab = false);
              },
              child: Text(
                'Back',
                style: AppTheme.labelThemed(context).copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SliverPadding(
          padding: AppTheme.screenPadding,
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (_savedEntries.isEmpty) ...[
                const SizedBox(height: AppTheme.spaceXL),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.bookmark_border_rounded,
                          size: 48, color: AppTheme.textMutedColor(context)),
                      const SizedBox(height: AppTheme.spaceMD),
                      Text('No saved debriefs yet',
                          style: AppTheme.headingSmallThemed(context)),
                      const SizedBox(height: AppTheme.spaceXS),
                      Text(
                        'Generate a debrief and tap Save to keep it here.',
                        style: AppTheme.bodySmallThemed(context),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text('Saved Debriefs',
                    style: AppTheme.headingMediumThemed(context)),
                const SizedBox(height: AppTheme.spaceXS),
                Text('Most recent first (max 3)',
                    style: AppTheme.bodySmallThemed(context)),
                const SizedBox(height: AppTheme.spaceMD),
                ...List.generate(_savedEntries.length, (index) {
                  final entry = _savedEntries[index];
                  final content = entry['content'] as String? ?? '';
                  final createdAt = entry['createdAtUtc'] as String? ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spaceMD),
                    child: _buildExpandableSavedCard(index, content, createdAt),
                  );
                }),
              ],
              const SizedBox(height: AppTheme.spaceXXL),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableSavedCard(
      int index, String content, String createdAt) {
    final isExpanded = _expandedCardIndex == index;

    String dateLabel = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt);
        final diff = DateTime.now().toUtc().difference(dt);
        if (diff.inDays == 0) {
          dateLabel = 'Today';
        } else if (diff.inDays == 1) {
          dateLabel = 'Yesterday';
        } else {
          dateLabel = '${diff.inDays}d ago';
        }
      } catch (_) {}
    }

    final needsExpansion = content.length > 200;
    final previewText =
        needsExpansion ? '${content.substring(0, 200).trimRight()}…' : content;

    return GestureDetector(
      onTap: needsExpansion
          ? () {
              HapticFeedback.selectionClick();
              setState(() {
                _expandedCardIndex = isExpanded ? null : index;
              });
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: AppTheme.cardPaddingLarge,
        decoration: BoxDecoration(
          color: AppTheme.cardBackground(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          border: Border.all(
            color: isExpanded
                ? AppTheme.primary.withValues(alpha: 0.4)
                : AppTheme.borderColor(context),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (dateLabel.isNotEmpty)
                  Text(
                    dateLabel,
                    style: AppTheme.labelThemed(context).copyWith(
                      color: AppTheme.textMutedColor(context),
                    ),
                  ),
                if (needsExpansion)
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 20,
                      color: AppTheme.textMutedColor(context),
                    ),
                  ),
              ],
            ),
            if (dateLabel.isNotEmpty || needsExpansion)
              const SizedBox(height: AppTheme.spaceSM),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: isExpanded || !needsExpansion
                  ? Text(
                      content,
                      style: AppTheme.bodyMediumThemed(context)
                          .copyWith(height: 1.5),
                    )
                  : Text(
                      previewText,
                      style: AppTheme.bodyMediumThemed(context)
                          .copyWith(height: 1.5),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            if (needsExpansion && !isExpanded) ...[
              const SizedBox(height: AppTheme.spaceXS),
              Text(
                'Tap to read more',
                style: AppTheme.labelThemed(context).copyWith(
                  color: AppTheme.primary.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
