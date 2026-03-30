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
import '../widgets/voice_input_button.dart';
import '../utils/ai_disclosure_consent.dart';

/// Pre-Match Prep Screen — Weapon System
///
/// Structured around defining primary weapon + opponent weakness.
/// Clean, analytical, no hype.
///
/// Flow:
/// 1. Select primary weapon (required)
/// 2. Select secondary weapon (optional)
/// 3. Opponent weakness hypothesis (dropdown + custom)
/// 4. Serve strategy (if Serve selected as weapon)
/// 5. Optional opponent name
/// 6. Readiness level
/// 7. Generate structured briefing
class MentalCheckInScreen extends StatefulWidget {
  const MentalCheckInScreen({super.key});

  @override
  State<MentalCheckInScreen> createState() => _MentalCheckInScreenState();
}

class _MentalCheckInScreenState extends State<MentalCheckInScreen> {
  final TextEditingController _opponentController = TextEditingController();
  final TextEditingController _customWeaknessController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int _readinessLevel = 7;
  String? _primaryWeapon;
  String? _secondaryWeapon;
  String? _opponentWeakness;
  String? _serveStrategy;
  bool _isLoading = false;
  bool _hasSubmitted = false;
  String? _briefingResponse;
  String? _errorMessage;
  bool _isSaving = false;
  bool _showSavedTab = false;
  List<Map<String, dynamic>> _savedEntries = [];
  int? _expandedCardIndex;

  /// Primary/Secondary weapon options
  static const List<Map<String, dynamic>> _weaponOptions = [
    {
      'id': 'serve',
      'label': 'Serve',
      'icon': Icons.sports_tennis_rounded,
    },
    {
      'id': 'forehand',
      'label': 'Forehand',
      'icon': Icons.swipe_right_rounded,
    },
    {
      'id': 'backhand',
      'label': 'Backhand',
      'icon': Icons.swipe_left_rounded,
    },
    {
      'id': 'return',
      'label': 'Return',
      'icon': Icons.replay_rounded,
    },
    {
      'id': 'serve_volley',
      'label': 'Serve + Volley',
      'icon': Icons.bolt_rounded,
    },
    {
      'id': 'net_play',
      'label': 'Net Play',
      'icon': Icons.arrow_upward_rounded,
    },
    {
      'id': 'movement_defense',
      'label': 'Movement / Defense',
      'icon': Icons.shield_outlined,
    },
  ];

  /// Opponent weakness hypotheses
  static const List<String> _weaknessOptions = [
    'Weak backhand',
    'Weak forehand',
    'Poor movement',
    'Struggles vs heavy spin',
    'Weak second serve',
    'Poor under pressure',
    'Custom',
  ];

  /// Serve strategy options (shown when Serve is primary weapon)
  static const List<String> _serveStrategyOptions = [
    'Heavy kick wide on Ad side',
    'Body serve under pressure',
    'Flat down T surprise',
    'Target backhand return',
    'Mix spin + pace shift',
  ];

  String _getReadinessLabel(int level) {
    if (level <= 3) return 'Building focus';
    if (level <= 5) return 'Getting there';
    if (level <= 7) return 'Feeling steady';
    if (level <= 9) return 'Locked in';
    return 'Peak readiness';
  }

  Color _getReadinessColor(int level) {
    if (level <= 3) return AppTheme.warning;
    if (level <= 6) return AppTheme.neutral;
    return AppTheme.win;
  }

  @override
  void dispose() {
    _opponentController.dispose();
    _customWeaknessController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showSavedTab) {
      return _buildSavedView();
    }

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
                'Pre-Match Prep',
                style: AppTheme.headingSmallThemed(context).copyWith(
                  color: AppTheme.textSecondaryColor(context),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => _showSavedTab = true);
                    _loadSavedPlans();
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Intro
                  _buildIntroSection(),

                  const SizedBox(height: AppTheme.spaceLG),

                  // Primary Weapon (required)
                  _buildWeaponSection(),

                  const SizedBox(height: AppTheme.spaceLG),

                  // Opponent Weakness Hypothesis
                  _buildOpponentWeaknessSection(),

                  const SizedBox(height: AppTheme.spaceLG),

                  // Serve Strategy (conditional)
                  if (_primaryWeapon == 'serve') ...[
                    _buildServeStrategySection(),
                    const SizedBox(height: AppTheme.spaceLG),
                  ],

                  // Opponent name (optional)
                  _buildOpponentInput(),

                  const SizedBox(height: AppTheme.spaceLG),

                  // Readiness Level
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

  // ============ Intro Section ============

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
                  'Define your weapons',
                  style: AppTheme.headingSmallThemed(context),
                ),
                Text(
                  'Build strategy around a repeatable weapon.',
                  style: AppTheme.bodySmallThemed(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ Weapon Selection ============

  Widget _buildWeaponSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Primary Weapon',
            style: AppTheme.headingMediumThemed(context)),
        const SizedBox(height: AppTheme.spaceXS),
        Text(
          'Your main attacking asset today (required)',
          style: AppTheme.bodySmallThemed(context),
        ),
        const SizedBox(height: AppTheme.spaceMD),

        // Weapon grid (2 columns)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.4,
          ),
          itemCount: _weaponOptions.length,
          itemBuilder: (context, index) {
            final weapon = _weaponOptions[index];
            final isPrimary = _primaryWeapon == weapon['id'];
            final isSecondary = _secondaryWeapon == weapon['id'];
            final isSelected = isPrimary || isSecondary;

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (isPrimary) {
                    _primaryWeapon = null;
                    // Reset serve strategy if serve deselected
                    if (weapon['id'] == 'serve') _serveStrategy = null;
                  } else if (isSecondary) {
                    _secondaryWeapon = null;
                  } else if (_primaryWeapon == null) {
                    _primaryWeapon = weapon['id'];
                  } else if (_secondaryWeapon == null) {
                    _secondaryWeapon = weapon['id'];
                  } else {
                    _secondaryWeapon = weapon['id'];
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceSM, vertical: 6),
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
                      weapon['icon'] as IconData,
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
                        weapon['label'] as String,
                        style: AppTheme.bodySmallThemed(context).copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
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
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('1',
                            style: AppTheme.labelThemed(context)
                                .copyWith(color: Colors.white, fontSize: 10)),
                      )
                    else if (isSecondary)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.neutral,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('2',
                            style: AppTheme.labelThemed(context)
                                .copyWith(color: Colors.white, fontSize: 10)),
                      ),
                  ],
                ),
              ),
            );
          },
        ),

        // Helper text
        if (_primaryWeapon != null) ...[
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            _secondaryWeapon != null
                ? 'Primary + secondary selected'
                : 'Tap another for optional secondary weapon',
            style: AppTheme.labelThemed(context).copyWith(
              color: AppTheme.textMutedColor(context),
            ),
          ),
        ],
      ],
    );
  }

  // ============ Opponent Weakness Hypothesis ============

  Widget _buildOpponentWeaknessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Opponent Weakness',
                style: AppTheme.headingSmallThemed(context)),
            const SizedBox(width: AppTheme.spaceXS),
            Text(
              '(optional)',
              style: AppTheme.labelThemed(context).copyWith(
                color: AppTheme.textMutedColor(context).withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceSM),
        Text('Hypothesis about their vulnerability',
            style: AppTheme.bodySmallThemed(context)),
        const SizedBox(height: AppTheme.spaceSM),

        // Weakness chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _weaknessOptions.map((weakness) {
            final isSelected = _opponentWeakness == weakness;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _opponentWeakness = isSelected ? null : weakness;
                  if (weakness != 'Custom') {
                    _customWeaknessController.clear();
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary.withOpacity(0.15)
                      : AppTheme.cardBackground(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.borderColor(context),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  weakness,
                  style: AppTheme.bodySmallThemed(context).copyWith(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.textSecondaryColor(context),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        // Custom weakness input
        if (_opponentWeakness == 'Custom') ...[
          const SizedBox(height: AppTheme.spaceSM),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardBackground(context),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              border: Border.all(color: AppTheme.borderColor(context)),
            ),
            child: TextField(
              controller: _customWeaknessController,
              style: AppTheme.bodyMediumThemed(context)
                  .copyWith(color: AppTheme.textPrimaryColor(context)),
              decoration: InputDecoration(
                hintText: 'Describe their weakness...',
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
        ],
      ],
    );
  }

  // ============ Serve Strategy (conditional) ============

  Widget _buildServeStrategySection() {
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
            children: [
              Icon(Icons.sports_tennis_rounded,
                  size: 18, color: AppTheme.primary),
              const SizedBox(width: AppTheme.spaceSM),
              Text('Serve Strategy',
                  style: AppTheme.headingSmallThemed(context)),
            ],
          ),
          const SizedBox(height: AppTheme.spaceXS),
          Text('First two service game plan',
              style: AppTheme.bodySmallThemed(context)),
          const SizedBox(height: AppTheme.spaceMD),

          ...List.generate(_serveStrategyOptions.length, (index) {
            final strategy = _serveStrategyOptions[index];
            final isSelected = _serveStrategy == strategy;

            return Padding(
              padding: EdgeInsets.only(
                  bottom: index < _serveStrategyOptions.length - 1 ? 6 : 0),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(
                      () => _serveStrategy = isSelected ? null : strategy);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.borderColor(context),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        size: 18,
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.textMutedColor(context),
                      ),
                      const SizedBox(width: AppTheme.spaceSM),
                      Expanded(
                        child: Text(
                          strategy,
                          style: AppTheme.bodySmallThemed(context).copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? AppTheme.textPrimaryColor(context)
                                : AppTheme.textSecondaryColor(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ============ Opponent Input ============

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
            Icon(Icons.mic,
                size: 12,
                color: AppTheme.textMutedColor(context).withOpacity(0.5)),
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
                  style: AppTheme.bodyMediumThemed(context)
                      .copyWith(color: AppTheme.textPrimaryColor(context)),
                  decoration: InputDecoration(
                    hintText: 'Who are you playing?',
                    hintStyle: AppTheme.bodySmallThemed(context).copyWith(
                      color:
                          AppTheme.textMutedColor(context).withOpacity(0.5),
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

  // ============ Readiness Section ============

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
              Text('Match readiness',
                  style: AppTheme.headingSmallThemed(context)),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceSM,
                  vertical: AppTheme.spaceXS,
                ),
                decoration: BoxDecoration(
                  color:
                      _getReadinessColor(_readinessLevel).withOpacity(0.15),
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
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 16),
                    activeTrackColor: _getReadinessColor(_readinessLevel),
                    inactiveTrackColor: AppTheme.borderColor(context),
                    thumbColor: _getReadinessColor(_readinessLevel),
                    overlayColor: _getReadinessColor(_readinessLevel)
                        .withOpacity(0.2),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Still warming up',
                    style:
                        AppTheme.labelThemed(context).copyWith(fontSize: 11)),
                Text('Ready to go',
                    style:
                        AppTheme.labelThemed(context).copyWith(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ Error Card ============

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
              style: AppTheme.bodySmallThemed(context)
                  .copyWith(color: AppTheme.textSecondaryColor(context)),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _errorMessage = null),
            child: Text('Dismiss',
                style: AppTheme.labelThemed(context)
                    .copyWith(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  // ============ Primary CTA ============

  Widget _buildPrimaryCTA() {
    final hasSelection = _primaryWeapon != null;

    return GestureDetector(
      onTap: _isLoading || !hasSelection ? null : _confirmGamePlan,
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
          child: _isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: hasSelection
                            ? Colors.white
                            : AppTheme.textMutedColor(context),
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceSM),
                    Text(
                      'Preparing briefing...',
                      style: AppTheme.headingSmallThemed(context).copyWith(
                        color: hasSelection
                            ? Colors.white
                            : AppTheme.textMutedColor(context),
                      ),
                    ),
                  ],
                )
              : Text(
                  'Confirm game plan',
                  style: AppTheme.headingSmallThemed(context).copyWith(
                    color: hasSelection
                        ? Colors.white
                        : AppTheme.textMutedColor(context),
                  ),
                ),
        ),
      ),
    );
  }

  // ============ Briefing Result View ============

  Widget _buildBriefingView() {
    final primaryLabel = _weaponOptions.firstWhere(
      (w) => w['id'] == _primaryWeapon,
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
              icon: Icon(Icons.arrow_back,
                  color: AppTheme.textSecondaryColor(context)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Game Plan',
              style: AppTheme.headingSmallThemed(context)
                  .copyWith(color: AppTheme.textSecondaryColor(context)),
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
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMD),
                    border:
                        Border.all(color: AppTheme.win.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          color: AppTheme.win, size: 20),
                      const SizedBox(width: AppTheme.spaceSM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _opponentController.text.isNotEmpty
                                  ? 'vs ${_opponentController.text}'
                                  : 'Ready to compete',
                              style: AppTheme.headingSmallThemed(context)
                                  .copyWith(color: AppTheme.win),
                            ),
                            Text(
                              'Weapon: $primaryLabel',
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
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusXL),
                    border:
                        Border.all(color: AppTheme.borderColor(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding:
                                const EdgeInsets.all(AppTheme.spaceSM),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusSM),
                            ),
                            child: const Icon(
                              Icons.analytics_outlined,
                              color: AppTheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceSM),
                          Text('Match Briefing',
                              style:
                                  AppTheme.headingMediumThemed(context)),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spaceMD),
                      Divider(
                          color: AppTheme.borderColor(context), height: 1),
                      const SizedBox(height: AppTheme.spaceMD),
                      Text(
                        _briefingResponse!,
                        style:
                            AppTheme.bodyLargeThemed(context).copyWith(
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
                      : () => _saveCurrentPlan(_briefingResponse!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground(context),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMD),
                      border: Border.all(
                          color: AppTheme.primary.withOpacity(0.3)),
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
                          _isSaving ? 'Saving...' : 'Save plan',
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
                            _hasSubmitted = false;
                            _briefingResponse = null;
                            _opponentController.clear();
                            _customWeaknessController.clear();
                            _primaryWeapon = null;
                            _secondaryWeapon = null;
                            _opponentWeakness = null;
                            _serveStrategy = null;
                            _readinessLevel = 7;
                          });
                        },
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground(context),
                            borderRadius: BorderRadius.circular(
                                AppTheme.radiusMD),
                            border: Border.all(
                                color: AppTheme.borderColor(context)),
                          ),
                          child: Center(
                            child: Text(
                              'New prep',
                              style: AppTheme.headingSmallThemed(context)
                                  .copyWith(
                                color:
                                    AppTheme.textSecondaryColor(context),
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
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(
                                AppTheme.radiusMD),
                          ),
                          child: Center(
                            child: Text(
                              'Ready to play',
                              style: AppTheme.headingSmallThemed(context)
                                  .copyWith(color: Colors.white),
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

  // ============ Confirm Game Plan ============

  Future<void> _confirmGamePlan() async {
    if (_primaryWeapon == null) return;

    final consented = await AiDisclosureConsent.ensureAccepted(context);
    if (!consented) {
      return;
    }

    // Get weapon labels
    final primaryLabel = _weaponOptions.firstWhere(
      (w) => w['id'] == _primaryWeapon,
    )['label'];
    final secondaryLabel = _secondaryWeapon != null
        ? _weaponOptions
            .firstWhere((w) => w['id'] == _secondaryWeapon)['label']
        : null;

    // Resolve weakness text
    String? weaknessText;
    if (_opponentWeakness == 'Custom') {
      weaknessText = _customWeaknessController.text.trim();
      if (weaknessText.isEmpty) weaknessText = null;
    } else {
      weaknessText = _opponentWeakness;
    }

    // Check usage limits
    final purchaseService =
        Provider.of<PurchaseService>(context, listen: false);
    final usageService = Provider.of<UsageService>(context, listen: false);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    HapticFeedback.mediumImpact();

    try {
      final profileService =
          Provider.of<PlayerProfileService>(context, listen: false);
      final playerContext = profileService.getPlayerContext();

      final briefingRequest = '''
$playerContext

Pre-Match Weapon Plan:
- Opponent: ${_opponentController.text.isNotEmpty ? _opponentController.text : 'Unknown'}
- Primary weapon: $primaryLabel
${secondaryLabel != null ? '- Secondary weapon: $secondaryLabel' : ''}
${weaknessText != null ? '- Opponent weakness hypothesis: $weaknessText' : ''}
${_serveStrategy != null ? '- Serve strategy: $_serveStrategy' : ''}
- Current readiness: $_readinessLevel/10 (${_getReadinessLabel(_readinessLevel)})

Instructions:
- Define game plan around the primary weapon.
- Reference the opponent weakness if provided.
- Include first two service game plan.
- Include one repeatable pattern to build around.
- Keep concise. Focus on controllable elements. No hype.
''';

      final apiService = Provider.of<ApiService>(context, listen: false);
      final response =
          await apiService.mentalCheckIn(_readinessLevel, briefingRequest);

      if (response == null) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Couldn\'t generate your briefing. Please try again.';
        });
        return;
      }

      if (!purchaseService.isPremium) {
        await usageService.recordPrepSession();
      }

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

  // ============ Save + Saved Tab ============

  Future<void> _saveCurrentPlan(String content) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.lightImpact();

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final success = await apiService.savePreMatchPlan(content);

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

  Future<void> _loadSavedPlans() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final entries = await apiService.getSavedPreMatchPlans();
    if (mounted) {
      setState(() => _savedEntries = entries);
    }
  }

  Widget _buildSavedView() {
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
              icon: Icon(Icons.arrow_back,
                  color: AppTheme.textSecondaryColor(context)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Pre-Match Prep',
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (_savedEntries.isEmpty) ...[
                  const SizedBox(height: AppTheme.spaceXL),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.bookmark_border_rounded,
                            size: 48,
                            color: AppTheme.textMutedColor(context)),
                        const SizedBox(height: AppTheme.spaceMD),
                        Text('No saved plans yet',
                            style: AppTheme.headingSmallThemed(context)),
                        const SizedBox(height: AppTheme.spaceXS),
                        Text(
                          'Generate a game plan and tap Save to keep it here.',
                          style: AppTheme.bodySmallThemed(context),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Text('Saved Plans',
                      style: AppTheme.headingMediumThemed(context)),
                  const SizedBox(height: AppTheme.spaceXS),
                  Text('Most recent first (max 3)',
                      style: AppTheme.bodySmallThemed(context)),
                  const SizedBox(height: AppTheme.spaceMD),
                  ...List.generate(_savedEntries.length, (index) {
                    final entry = _savedEntries[index];
                    final content = entry['content'] as String? ?? '';
                    final createdAt =
                        entry['createdAtUtc'] as String? ?? '';
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppTheme.spaceMD),
                      child: _buildExpandableSavedCard(index, content, createdAt),
                    );
                  }),
                ],
                const SizedBox(height: AppTheme.spaceXXL),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSavedCard(int index, String content, String createdAt) {
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
    final previewText = needsExpansion
        ? '${content.substring(0, 200).trimRight()}…'
        : content;

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
                ? AppTheme.primary.withOpacity(0.4)
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
                  color: AppTheme.primary.withOpacity(0.7),
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
