import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/purchase_service.dart';
import '../services/usage_service.dart';
import '../utils/tennis_validator.dart';
import 'paywall_screen.dart';

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

  /// Debrief options - neutral, coach-like framing
  /// Focus on patterns and situations, not blame or identity
  final List<Map<String, dynamic>> _situations = [
    {
      'icon': Icons.timer_outlined,
      'title': 'Struggled under pressure',
      'description': 'Tight moments didn\'t go my way',
      'prompt': 'I struggled to perform under pressure during key moments in the match. Help me understand what happened and how to handle these situations better.',
    },
    {
      'icon': Icons.sports_tennis_outlined,
      'title': 'Game plan didn\'t execute',
      'description': 'Strategy fell apart during play',
      'prompt': 'My tactical game plan didn\'t translate into match play. Help me analyze what went wrong and how to better execute my strategy.',
    },
    {
      'icon': Icons.error_outline_rounded,
      'title': 'Too many unforced errors',
      'description': 'Consistency let me down',
      'prompt': 'I made too many unforced errors during the match. Help me understand the patterns and what I can work on to improve consistency.',
    },
    {
      'icon': Icons.psychology_outlined,
      'title': 'Focus dropped mid-match',
      'description': 'Concentration wavered at key times',
      'prompt': 'I lost focus and concentration during key moments of the match. Help me understand what triggered this and how to maintain better mental presence.',
    },
    {
      'icon': Icons.sync_problem_outlined,
      'title': 'Couldn\'t find my rhythm',
      'description': 'Timing and flow felt off',
      'prompt': 'I struggled to find my rhythm and timing during the match. My shots felt off and I couldn\'t settle into my game. Help me understand what happened.',
    },
    {
      'icon': Icons.trending_down_rounded,
      'title': 'Level dropped after lead',
      'description': 'Momentum shifted away',
      'prompt': 'I had a lead but my level dropped and I couldn\'t maintain the momentum. Help me analyze what changed and how to stay consistent when ahead.',
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
      backgroundColor: AppTheme.surfaceDark,
      body: Consumer<ApiService>(
        builder: (context, apiService, child) {
          // Show response view if we have a response
          if (apiService.lastResponse != null) {
            return _buildResponseView(context, apiService);
          }

          // Show input view
          return _buildInputView(context, apiService);
        },
      ),
    );
  }

  Widget _buildInputView(BuildContext context, ApiService apiService) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Subtle header
        SliverAppBar(
          backgroundColor: AppTheme.surfaceDark,
          elevation: 0,
          pinned: true,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textSecondary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Match Debrief',
            style: AppTheme.headingSmall.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
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
                style: AppTheme.headingMedium,
              ),
              const SizedBox(height: AppTheme.spaceXS),
              Text(
                'Select what best describes your match',
                style: AppTheme.bodySmall,
              ),
              
              const SizedBox(height: AppTheme.spaceMD),
              
              // Situation cards
              ...List.generate(_situations.length, (index) {
                final situation = _situations[index];
                final isSelected = _selectedSituation == situation['prompt'];
                
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < _situations.length - 1 ? AppTheme.spaceSM : 0,
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
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: AppTheme.cardPaddingLarge,
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMD),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sports_tennis_rounded,
              size: 32,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Text(
            'Let\'s review your match',
            style: AppTheme.headingMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            'Every match is a learning opportunity. Let\'s break down what happened and find actionable takeaways.',
            textAlign: TextAlign.center,
            style: AppTheme.bodyMedium,
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
              ? AppTheme.primary.withOpacity(0.1)
              : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.surfaceBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceSM),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppTheme.primary.withOpacity(0.2)
                    : AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.headingSmall.copyWith(
                      color: isSelected 
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
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
              ? AppTheme.primary.withOpacity(0.1)
              : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(
            color: _showCustomInput ? AppTheme.primary : AppTheme.surfaceBorder,
            width: _showCustomInput ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceSM),
              decoration: BoxDecoration(
                color: _showCustomInput 
                    ? AppTheme.primary.withOpacity(0.2)
                    : AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: Icon(
                Icons.edit_note_rounded,
                size: 20,
                color: _showCustomInput ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: Text(
                'Describe something else',
                style: AppTheme.headingSmall.copyWith(
                  color: _showCustomInput 
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                ),
              ),
            ),
            if (_showCustomInput)
              const Icon(
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
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: TextField(
        controller: _customController,
        style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Describe what happened in your match...',
          hintStyle: AppTheme.bodySmall.copyWith(
            color: AppTheme.textMuted.withOpacity(0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(AppTheme.spaceMD),
        ),
        onChanged: (value) {
          setState(() {
            _selectedSituation = value.isNotEmpty ? value : null;
            _localError = null;
          });
        },
      ),
    );
  }

  /// Error card - human-readable, with retry option
  Widget _buildErrorCard(String error) {
    // Convert technical errors to human-readable messages
    String humanMessage = _humanizeError(error);
    
    return Container(
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: AppTheme.loss.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.loss.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppTheme.loss.withOpacity(0.8),
            size: 20,
          ),
          const SizedBox(width: AppTheme.spaceSM),
          Expanded(
            child: Text(
              humanMessage,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondary,
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
              style: AppTheme.label.copyWith(color: AppTheme.primary),
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
    final hasSelection = _selectedSituation != null && _selectedSituation!.isNotEmpty;
    final isLoading = _isLoading || apiService.isLoading;
    
    return GestureDetector(
      onTap: isLoading || !hasSelection 
          ? null 
          : () => _handleDebrief(context, apiService),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: hasSelection ? AppTheme.primary : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: hasSelection 
              ? null 
              : Border.all(color: AppTheme.surfaceBorder),
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
                        color: hasSelection ? Colors.white : AppTheme.textMuted,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceSM),
                    Text(
                      'Reviewing match...',
                      style: AppTheme.headingSmall.copyWith(
                        color: hasSelection ? Colors.white : AppTheme.textMuted,
                      ),
                    ),
                  ],
                )
              : Text(
                  'Review match debrief',
                  style: AppTheme.headingSmall.copyWith(
                    color: hasSelection ? Colors.white : AppTheme.textMuted,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildResponseView(BuildContext context, ApiService apiService) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverAppBar(
          backgroundColor: AppTheme.surfaceDark,
          elevation: 0,
          pinned: true,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textSecondary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Match Debrief',
            style: AppTheme.headingSmall.copyWith(
              color: AppTheme.textSecondary,
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
                  color: AppTheme.win.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  border: Border.all(color: AppTheme.win.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppTheme.win,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spaceSM),
                    Text(
                      'Debrief complete',
                      style: AppTheme.headingSmall.copyWith(
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
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spaceSM),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                          ),
                          child: const Icon(
                            Icons.lightbulb_outline_rounded,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spaceSM),
                        Text(
                          'Coach Feedback',
                          style: AppTheme.headingMedium,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppTheme.spaceMD),
                    Divider(color: AppTheme.surfaceBorder, height: 1),
                    const SizedBox(height: AppTheme.spaceMD),
                    
                    Text(
                      apiService.lastResponse!,
                      style: AppTheme.bodyLarge.copyWith(
                        height: 1.7,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppTheme.spaceLG),
              
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
                        });
                        apiService.clearResponse();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                          border: Border.all(color: AppTheme.surfaceBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.refresh_rounded,
                              size: 18,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: AppTheme.spaceSM),
                            Text(
                              'New debrief',
                              style: AppTheme.headingSmall.copyWith(
                                color: AppTheme.textSecondary,
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
                          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        ),
                        child: Center(
                          child: Text(
                            'Done',
                            style: AppTheme.headingSmall.copyWith(
                              color: Colors.white,
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

    // Validate tennis-related content for custom input
    if (_showCustomInput) {
      final validationError = TennisValidator.validate(_selectedSituation!);
      if (validationError != null) {
        HapticFeedback.mediumImpact();
        setState(() => _localError = validationError);
        return;
      }
    }

    // Check usage limits
    final purchaseService = Provider.of<PurchaseService>(context, listen: false);
    final usageService = Provider.of<UsageService>(context, listen: false);
    
    if (!purchaseService.isPremium && !usageService.canUseDebrief) {
      HapticFeedback.mediumImpact();
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const PaywallScreen(
            trigger: PaywallTrigger.debriefLimit,
          ),
        ),
      );
      
      if (result != true) return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();
    
    try {
      final response = await apiService.emotionalReset(_selectedSituation!);
      
      setState(() => _isLoading = false);
      
      // Record usage for free users
      if (!purchaseService.isPremium && response != null) {
        await usageService.recordDebrief();
      }
      
      if (response != null && context.mounted) {
        _scrollToResponse();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _localError = e.toString();
      });
    }
  }
}
