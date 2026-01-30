import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/purchase_service.dart';
import '../services/usage_service.dart';
import '../services/player_profile_service.dart';
import '../models/check_in_entry.dart';
import '../utils/tennis_validator.dart';
import '../widgets/voice_input_button.dart';
import 'paywall_screen.dart';

/// Pre-Match Prep Screen
/// 
/// UX Philosophy: Focused pre-match briefing, not gamification
/// 
/// Key principles:
/// - Clarity over complexity (1 primary tactic, optional secondary)
/// - Readiness over confidence (grounded, not ego-driven)
/// - Completable in under 60 seconds
/// - Feels like "locking in the plan"
class MentalCheckInScreen extends StatefulWidget {
  const MentalCheckInScreen({super.key});

  @override
  State<MentalCheckInScreen> createState() => _MentalCheckInScreenState();
}

class _MentalCheckInScreenState extends State<MentalCheckInScreen> {
  final TextEditingController _opponentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  int _readinessLevel = 7;
  String? _primaryTactic;
  String? _secondaryTactic;
  bool _isLoading = false;
  bool _hasSubmitted = false;
  String? _briefingResponse;
  String? _errorMessage;

  /// Tactical options - clear, intentional choices
  /// Structured for primary (pick one) + optional secondary
  static const List<Map<String, dynamic>> _tacticOptions = [
    {
      'id': 'control_rallies',
      'label': 'Control the rallies',
      'description': 'Dictate pace and direction',
      'icon': Icons.adjust_rounded,
    },
    {
      'id': 'attack_weakness',
      'label': 'Target their weakness',
      'description': 'Exploit patterns',
      'icon': Icons.gps_fixed_rounded,
    },
    {
      'id': 'stay_solid',
      'label': 'Stay solid',
      'description': 'Minimize errors, wait for openings',
      'icon': Icons.shield_outlined,
    },
    {
      'id': 'move_them',
      'label': 'Move them around',
      'description': 'Use angles and depth',
      'icon': Icons.swap_horiz_rounded,
    },
    {
      'id': 'serve_plus_one',
      'label': 'Serve + 1 patterns',
      'description': 'Win points early',
      'icon': Icons.bolt_rounded,
    },
    {
      'id': 'vary_pace',
      'label': 'Vary the pace',
      'description': 'Disrupt their timing',
      'icon': Icons.speed_rounded,
    },
  ];

  /// Readiness labels - calm, grounded (not emotional)
  String _getReadinessLabel(int level) {
    if (level <= 3) return 'Building focus';
    if (level <= 5) return 'Getting there';
    if (level <= 7) return 'Feeling steady';
    if (level <= 9) return 'Locked in';
    return 'Peak readiness';
  }

  @override
  void dispose() {
    _opponentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasSubmitted && _briefingResponse != null) {
      return _buildBriefingView();
    }
    
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground(context),
      body: GestureDetector(
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
              icon: Icon(Icons.arrow_back, color: AppTheme.textSecondaryColor(context)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Pre-Match Prep',
              style: AppTheme.headingSmallThemed(context).copyWith(
                color: AppTheme.textSecondaryColor(context),
              ),
            ),
          ),
          
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Compact intro
                _buildIntroSection(),
                
                const SizedBox(height: AppTheme.spaceMD),
                
                // Opponent (optional, compact)
                _buildOpponentInput(),
                
                const SizedBox(height: AppTheme.spaceLG),
                
                // Primary Tactic (main interaction)
                _buildTacticSection(),
                
                const SizedBox(height: AppTheme.spaceLG),
                
                // Readiness Level (reframed slider)
                _buildReadinessSection(),
                
                const SizedBox(height: AppTheme.spaceLG),
                
                // Error display
                if (_errorMessage != null) ...[
                  _buildErrorCard(),
                  const SizedBox(height: AppTheme.spaceMD),
                ],
                
                // Primary CTA
                _buildPrimaryCTA(),
                
                const SizedBox(height: AppTheme.spaceXL),
              ]),
            ),
          ),
        ],
        ),
      ),
    );
  }

  /// Compact intro - sets the tone without taking space
  Widget _buildIntroSection() {
    return Container(
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceSM),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: const Icon(
              Icons.sports_tennis_rounded,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lock in your game plan',
                  style: AppTheme.headingSmallThemed(context),
                ),
                Text(
                  'Clear focus. Calm mind. Ready to compete.',
                  style: AppTheme.bodySmallThemed(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Compact opponent input with voice support
  Widget _buildOpponentInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Opponent', style: AppTheme.labelThemed(context)),
            const SizedBox(width: AppTheme.spaceXS),
            Text(
              '(optional)',
              style: AppTheme.labelThemed(context).copyWith(
                color: AppTheme.textMutedColor(context).withOpacity(0.6),
              ),
            ),
            const Spacer(),
            Icon(
              Icons.mic,
              size: 12,
              color: AppTheme.textMutedColor(context).withOpacity(0.5),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceSM),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackground(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            border: Border.all(color: AppTheme.borderColor(context)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _opponentController,
                  style: AppTheme.bodyMediumThemed(context).copyWith(color: AppTheme.textPrimaryColor(context)),
                  decoration: InputDecoration(
                    hintText: 'Who are you playing?',
                    hintStyle: AppTheme.bodySmallThemed(context).copyWith(
                      color: AppTheme.textMutedColor(context).withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceMD,
                      vertical: AppTheme.spaceSM,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: AppTheme.spaceSM),
                child: VoiceInputButton(
                  size: 32,
                  onResult: (text) {
                    _opponentController.text = text;
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Tactic selection - primary focus, optional secondary
  Widget _buildTacticSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pick your primary focus', style: AppTheme.headingMediumThemed(context)),
        const SizedBox(height: AppTheme.spaceXS),
        Text(
          'What\'s your main approach today?',
          style: AppTheme.bodySmallThemed(context),
        ),
        const SizedBox(height: AppTheme.spaceMD),
        
        // Primary tactics grid (2 columns, compact)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.0,
          ),
          itemCount: _tacticOptions.length,
          itemBuilder: (context, index) {
            final tactic = _tacticOptions[index];
            final isPrimary = _primaryTactic == tactic['id'];
            final isSecondary = _secondaryTactic == tactic['id'];
            final isSelected = isPrimary || isSecondary;
            
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (isPrimary) {
                    // Deselect primary
                    _primaryTactic = null;
                  } else if (isSecondary) {
                    // Deselect secondary
                    _secondaryTactic = null;
                  } else if (_primaryTactic == null) {
                    // Set as primary
                    _primaryTactic = tactic['id'];
                  } else if (_secondaryTactic == null) {
                    // Set as secondary (optional)
                    _secondaryTactic = tactic['id'];
                  } else {
                    // Replace secondary
                    _secondaryTactic = tactic['id'];
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(AppTheme.spaceSM),
                decoration: BoxDecoration(
                  color: isPrimary 
                      ? AppTheme.primary.withOpacity(0.15)
                      : isSecondary
                          ? AppTheme.neutral.withOpacity(0.1)
                          : AppTheme.cardBackground(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  border: Border.all(
                    color: isPrimary 
                        ? AppTheme.primary
                        : isSecondary
                            ? AppTheme.neutral
                            : AppTheme.borderColor(context),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      tactic['icon'] as IconData,
                      size: 18,
                      color: isPrimary 
                          ? AppTheme.primary
                          : isSecondary
                              ? AppTheme.neutral
                              : AppTheme.textMutedColor(context),
                    ),
                    const SizedBox(width: AppTheme.spaceSM),
                    Expanded(
                      child: Text(
                        tactic['label'] as String,
                        style: AppTheme.bodySmallThemed(context).copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected 
                              ? AppTheme.textPrimaryColor(context)
                              : AppTheme.textSecondaryColor(context),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPrimary)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '1',
                          style: AppTheme.labelThemed(context).copyWith(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      )
                    else if (isSecondary)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.neutral,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '2',
                          style: AppTheme.labelThemed(context).copyWith(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        
        // Helper text
        if (_primaryTactic != null) ...[
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            _secondaryTactic != null
                ? 'Primary + backup selected'
                : 'Tap another for optional backup',
            style: AppTheme.labelThemed(context).copyWith(
              color: AppTheme.textMutedColor(context),
            ),
          ),
        ],
      ],
    );
  }

  /// Readiness section - grounded, not gamified
  Widget _buildReadinessSection() {
    return Container(
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Match readiness', style: AppTheme.headingSmallThemed(context)),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceSM,
                  vertical: AppTheme.spaceXS,
                ),
                decoration: BoxDecoration(
                  color: _getReadinessColor(_readinessLevel).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: Text(
                  _getReadinessLabel(_readinessLevel),
                  style: AppTheme.labelThemed(context).copyWith(
                    color: _getReadinessColor(_readinessLevel),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spaceMD),
          
          // Compact slider
          Row(
            children: [
              Text(
                '$_readinessLevel',
                style: AppTheme.statMediumThemed(context).copyWith(
                  color: _getReadinessColor(_readinessLevel),
                ),
              ),
              const SizedBox(width: AppTheme.spaceSM),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                    activeTrackColor: _getReadinessColor(_readinessLevel),
                    inactiveTrackColor: AppTheme.borderColor(context),
                    thumbColor: _getReadinessColor(_readinessLevel),
                    overlayColor: _getReadinessColor(_readinessLevel).withOpacity(0.2),
                  ),
                  child: Slider(
                    value: _readinessLevel.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: (value) {
                      HapticFeedback.selectionClick();
                      setState(() => _readinessLevel = value.round());
                    },
                  ),
                ),
              ),
              Text('/10', style: AppTheme.bodySmallThemed(context)),
            ],
          ),
          
          // Calm labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Still warming up', style: AppTheme.labelThemed(context).copyWith(fontSize: 11)),
                Text('Ready to go', style: AppTheme.labelThemed(context).copyWith(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getReadinessColor(int level) {
    if (level <= 3) return AppTheme.warning;
    if (level <= 6) return AppTheme.neutral;
    return AppTheme.win;
  }

  /// Error card
  Widget _buildErrorCard() {
    return Container(
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: AppTheme.loss.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.loss.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppTheme.loss, size: 18),
          const SizedBox(width: AppTheme.spaceSM),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTheme.bodySmallThemed(context).copyWith(color: AppTheme.textSecondaryColor(context)),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _errorMessage = null),
            child: Text('Dismiss', style: AppTheme.labelThemed(context).copyWith(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  /// Primary CTA - "locking in the plan"
  Widget _buildPrimaryCTA() {
    final hasSelection = _primaryTactic != null;
    
    return GestureDetector(
      onTap: _isLoading || !hasSelection ? null : _confirmGamePlan,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: hasSelection ? AppTheme.primary : AppTheme.elevatedBackground(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: hasSelection ? null : Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Center(
          child: _isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: hasSelection ? Colors.white : AppTheme.textMutedColor(context),
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceSM),
                    Text(
                      'Preparing briefing...',
                      style: AppTheme.headingSmallThemed(context).copyWith(
                        color: hasSelection ? Colors.white : AppTheme.textMutedColor(context),
                      ),
                    ),
                  ],
                )
              : Text(
                  'Confirm game plan',
                  style: AppTheme.headingSmallThemed(context).copyWith(
                    color: hasSelection ? Colors.white : AppTheme.textMutedColor(context),
                  ),
                ),
        ),
      ),
    );
  }

  /// Briefing result view
  Widget _buildBriefingView() {
    final primaryLabel = _tacticOptions.firstWhere(
      (t) => t['id'] == _primaryTactic,
      orElse: () => {'label': 'Custom'},
    )['label'];
    
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground(context),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppTheme.scaffoldBackground(context),
            elevation: 0,
            pinned: true,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppTheme.textSecondaryColor(context)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Game Plan',
              style: AppTheme.headingSmallThemed(context).copyWith(color: AppTheme.textSecondaryColor(context)),
            ),
          ),
          
          SliverPadding(
            padding: AppTheme.screenPadding,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Summary header
                Container(
                  padding: AppTheme.cardPadding,
                  decoration: BoxDecoration(
                    color: AppTheme.win.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    border: Border.all(color: AppTheme.win.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: AppTheme.win, size: 20),
                      const SizedBox(width: AppTheme.spaceSM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _opponentController.text.isNotEmpty
                                  ? 'vs ${_opponentController.text}'
                                  : 'Ready to compete',
                              style: AppTheme.headingSmallThemed(context).copyWith(color: AppTheme.win),
                            ),
                            Text(
                              'Focus: $primaryLabel',
                              style: AppTheme.bodySmallThemed(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppTheme.spaceLG),
                
                // Briefing content
                Container(
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
                          Text('Match Briefing', style: AppTheme.headingMediumThemed(context)),
                        ],
                      ),
                      
                      const SizedBox(height: AppTheme.spaceMD),
                      Divider(color: AppTheme.borderColor(context), height: 1),
                      const SizedBox(height: AppTheme.spaceMD),
                      
                      Text(
                        _briefingResponse!,
                        style: AppTheme.bodyLargeThemed(context).copyWith(
                          height: 1.7,
                          color: AppTheme.textSecondaryColor(context),
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
                            _hasSubmitted = false;
                            _briefingResponse = null;
                            _opponentController.clear();
                            _primaryTactic = null;
                            _secondaryTactic = null;
                            _readinessLevel = 7;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground(context),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                            border: Border.all(color: AppTheme.borderColor(context)),
                          ),
                          child: Center(
                            child: Text(
                              'New prep',
                              style: AppTheme.headingSmallThemed(context).copyWith(
                                color: AppTheme.textSecondaryColor(context),
                              ),
                            ),
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
                              'Ready to play',
                              style: AppTheme.headingSmallThemed(context).copyWith(
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
      ),
    );
  }

  Future<void> _confirmGamePlan() async {
    if (_primaryTactic == null) return;

    // Get tactic labels
    final primaryLabel = _tacticOptions.firstWhere(
      (t) => t['id'] == _primaryTactic,
    )['label'];
    final secondaryLabel = _secondaryTactic != null
        ? _tacticOptions.firstWhere((t) => t['id'] == _secondaryTactic)['label']
        : null;

    // Check usage limits
    final purchaseService = Provider.of<PurchaseService>(context, listen: false);
    final usageService = Provider.of<UsageService>(context, listen: false);
    
    if (!purchaseService.isPremium && !usageService.canUsePrepSession) {
      HapticFeedback.mediumImpact();
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const PaywallScreen(trigger: PaywallTrigger.prepSessionLimit),
        ),
      );
      if (result != true) return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    HapticFeedback.mediumImpact();

    try {
      final profileService = Provider.of<PlayerProfileService>(context, listen: false);
      final playerContext = profileService.getPlayerContext();
      
      final briefingRequest = '''
$playerContext

Pre-Match Game Plan:
- Opponent: ${_opponentController.text.isNotEmpty ? _opponentController.text : 'Unknown'}
- Primary tactic: $primaryLabel
${secondaryLabel != null ? '- Backup tactic: $secondaryLabel' : ''}
- Current readiness: $_readinessLevel/10 (${_getReadinessLabel(_readinessLevel)})

Provide a focused, actionable match briefing. Keep it concise and confidence-building.
''';

      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.mentalCheckIn(_readinessLevel, briefingRequest);
      
      if (response == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Couldn\'t generate your briefing. Please try again.';
        });
        return;
      }
      
      // Record usage
      if (!purchaseService.isPremium) {
        await usageService.recordPrepSession();
      }

      // Save to storage
      final entry = CheckInEntry(
        timestamp: DateTime.now().millisecondsSinceEpoch,
        rating: _readinessLevel,
        journalText: briefingRequest,
      );
      await StorageService.saveCheckIn(entry);

      setState(() {
        _isLoading = false;
        _hasSubmitted = true;
        _briefingResponse = response;
      });
      
      HapticFeedback.lightImpact();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }
}
