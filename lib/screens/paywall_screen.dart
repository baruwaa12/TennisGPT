import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/purchase_service.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';
import 'legal_screen.dart';

enum PaywallTrigger {
  matchLimit,
  tacticalAnalysisLimit,
  prepSessionLimit,
  debriefLimit,
  serverQuota,
  general,
}

class PaywallScreen extends StatefulWidget {
  final PaywallTrigger trigger;
  
  const PaywallScreen({
    super.key,
    this.trigger = PaywallTrigger.general,
  });

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

enum _SelectedPlan { founder, monthly, annual }

class _PaywallScreenState extends State<PaywallScreen> {
  _SelectedPlan _selectedPlan = _SelectedPlan.founder;

  /// Founder "gold" accent — a meaningful tier signal, kept as a deliberate
  /// brand accent (paired with text badges so it is never a color-only cue).
  static const Color _founderAccent = Color(0xFFB45309); // amber 700
  static const List<Color> _founderGradient = [
    Color(0xFFD97706), // amber 600
    Color(0xFFC2410C), // orange 700
  ];

  String get _triggerTitle {
    switch (widget.trigger) {
      case PaywallTrigger.matchLimit:
        return "You've hit the free match limit";
      case PaywallTrigger.tacticalAnalysisLimit:
      case PaywallTrigger.prepSessionLimit:
      case PaywallTrigger.debriefLimit:
      case PaywallTrigger.serverQuota:
        return "You've used your free analyses";
      case PaywallTrigger.general:
        return 'Become a Founder Member';
    }
  }

  String get _triggerSubtitle {
    switch (widget.trigger) {
      case PaywallTrigger.matchLimit:
        return 'Unlock unlimited match logging and tactical insights.';
      case PaywallTrigger.tacticalAnalysisLimit:
      case PaywallTrigger.prepSessionLimit:
      case PaywallTrigger.debriefLimit:
      case PaywallTrigger.serverQuota:
        return 'Unlock unlimited tactical analysis after every match.';
      case PaywallTrigger.general:
        return 'Lock in founder pricing before spots run out.';
    }
  }

  @override
  void initState() {
    super.initState();
    final purchaseService = Provider.of<PurchaseService>(context, listen: false);
    // Default to founder if available, otherwise annual
    if (!purchaseService.isFounderAvailable) {
      _selectedPlan = _SelectedPlan.annual;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final purchaseService = Provider.of<PurchaseService>(context);
    
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground(context),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceLG,
              vertical: AppTheme.spaceMD,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                    icon: Icon(Icons.close,
                        color: AppTheme.textMutedColor(context)),
                  ),
                ),
                
                // Founder spots banner
                if (purchaseService.isFounderAvailable) ...[
                  _buildFounderBanner(purchaseService),
                  const SizedBox(height: AppTheme.spaceLG),
                ],
                
                // Title
                Text(
                  _triggerTitle,
                  style: AppTheme.headingMediumThemed(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spaceSM),
                Text(
                  _triggerSubtitle,
                  style: AppTheme.bodyMediumThemed(context),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppTheme.spaceLG),
                
                // What you get (benefit-focused, not feature list)
                _buildBenefits(isDark),
                
                const SizedBox(height: AppTheme.spaceLG),
                
                // Pricing options
                _buildPricingOptions(purchaseService, isDark),
                
                const SizedBox(height: AppTheme.spaceLG),
                
                // Subscribe button
                _buildSubscribeButton(purchaseService),
                
                const SizedBox(height: AppTheme.spaceSM),
                
                // Guarantee
                _buildGuarantee(isDark),
                
                const SizedBox(height: AppTheme.spaceMD),
                
                // Restore purchases
                Center(
                  child: TextButton(
                    onPressed: _restorePurchases,
                    child: Text(
                      'Restore Purchases',
                      style: AppTheme.bodyMediumThemed(context).copyWith(
                        color: AppTheme.textMutedColor(context),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: AppTheme.spaceMD),
                
                // Legal text
                Text(
                  'Cancel anytime. Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period.',
                  style: AppTheme.bodySmallThemed(context).copyWith(
                    fontSize: 11,
                    color: AppTheme.textMutedColor(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppTheme.spaceSM),
                
                // Terms & Privacy
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LegalScreen(
                            documentType: LegalDocumentType.termsOfService,
                          ),
                        ),
                      ),
                      child: Text(
                        'Terms of Use',
                        style: AppTheme.bodySmallThemed(context).copyWith(
                          fontSize: 12,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    Text(' • ',
                        style: TextStyle(color: AppTheme.textMutedColor(context))),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LegalScreen(
                            documentType: LegalDocumentType.privacyPolicy,
                          ),
                        ),
                      ),
                      child: Text(
                        'Privacy Policy',
                        style: AppTheme.bodySmallThemed(context).copyWith(
                          fontSize: 12,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceSM),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Founder spots banner (urgency)
  // ──────────────────────────────────────────────
  Widget _buildFounderBanner(PurchaseService purchaseService) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMD, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: _founderGradient),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_fire_department, color: Colors.white, size: 18),
          const SizedBox(width: AppTheme.spaceSM),
          Flexible(
            child: Text(
              'Founder pricing: ${purchaseService.founderSpotsRemaining} of ${AppConfig.founderSpotsTotal} spots left',
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontVariations: AppTheme.fontVariationsSemiExpanded,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Benefits (outcome-focused copy)
  // ──────────────────────────────────────────────
  Widget _buildBenefits(bool isDark) {
    final benefits = [
      const _BenefitItem(
        icon: Icons.insights,
        text: 'Unlimited tactical analysis after every match',
      ),
      const _BenefitItem(
        icon: Icons.sports_tennis,
        text: 'Unlimited match logging & full history',
      ),
      const _BenefitItem(
        icon: Icons.trending_up,
        text: 'Trends & patterns (surface, opponent type, win rate)',
      ),
      const _BenefitItem(
        icon: Icons.fitness_center,
        text: 'Drills + next-match plan based on your data',
      ),
      const _BenefitItem(
        icon: Icons.star_outline,
        text: 'Early access to new features',
      ),
    ];

    return Column(
      children: benefits.map((b) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: Icon(b.icon, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: Text(
                b.text,
                style: AppTheme.bodyMediumThemed(context).copyWith(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor(context),
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  // ──────────────────────────────────────────────
  // Pricing options (Founder + Monthly + Annual)
  // ──────────────────────────────────────────────
  Widget _buildPricingOptions(PurchaseService purchaseService, bool isDark) {
    return Column(
      children: [
        // Founder option (if spots available)
        if (purchaseService.isFounderAvailable)
          _buildPlanTile(
            plan: _SelectedPlan.founder,
            title: 'Founder',
            subtitle: 'Locks in forever. Limited spots.',
            priceText: purchaseService.founderMonthlyPriceString,
            priceSuffix: '/mo',
            badgeText: 'BEST DEAL',
            badgeColor: _founderAccent,
            accentColor: _founderAccent,
            isDark: isDark,
          ),
        
        if (purchaseService.isFounderAvailable)
          const SizedBox(height: 10),
        
        // Annual option
        _buildPlanTile(
          plan: _SelectedPlan.annual,
          title: 'Annual',
          subtitle: 'Best value for committed players',
          priceText: purchaseService.annualPriceString,
          priceSuffix: '/yr',
          badgeText: 'SAVE 50%',
          badgeColor: AppTheme.primary,
          accentColor: AppTheme.primary,
          isDark: isDark,
        ),
        
        const SizedBox(height: 10),
        
        // Monthly option
        _buildPlanTile(
          plan: _SelectedPlan.monthly,
          title: 'Monthly',
          subtitle: 'Flexible option',
          priceText: purchaseService.monthlyPriceString,
          priceSuffix: '/mo',
          accentColor: AppTheme.primaryLight,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildPlanTile({
    required _SelectedPlan plan,
    required String title,
    required String subtitle,
    required String priceText,
    required String priceSuffix,
    String? badgeText,
    Color? badgeColor,
    required Color accentColor,
    required bool isDark,
  }) {
    final isSelected = _selectedPlan == plan;
    
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title plan, $priceText $priceSuffix',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _selectedPlan = plan);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: isDark ? 0.15 : 0.06)
                : AppTheme.cardBackground(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(
              color: isSelected ? accentColor : AppTheme.borderColor(context),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Radio indicator
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isSelected ? accentColor : AppTheme.borderColor(context),
                    width: 2,
                  ),
                  color: isSelected ? accentColor : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(width: AppTheme.spaceMD),
              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontVariations: AppTheme.fontVariationsSemiExpanded,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor(context),
                          ),
                        ),
                        if (badgeText != null) ...[
                          const SizedBox(width: AppTheme.spaceSM),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spaceSM, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor ?? accentColor,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMD),
                            ),
                            child: Text(
                              badgeText,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontVariations:
                                    AppTheme.fontVariationsSemiExpanded,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
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
              // Price
              Text(
                priceText,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontVariations: AppTheme.fontVariationsSemiExpanded,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? accentColor
                      : AppTheme.textPrimaryColor(context),
                ),
              ),
              Text(
                priceSuffix,
                style: AppTheme.bodySmallThemed(context).copyWith(
                  fontSize: 13,
                  color: AppTheme.textMutedColor(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Subscribe button (direct-response CTA)
  // ──────────────────────────────────────────────
  Widget _buildSubscribeButton(PurchaseService purchaseService) {
    final isLoading = purchaseService.isLoading;
    
    String buttonText;
    List<Color> gradient;
    
    switch (_selectedPlan) {
      case _SelectedPlan.founder:
        buttonText = 'Become a Founder';
        gradient = _founderGradient;
        break;
      case _SelectedPlan.annual:
        buttonText = 'Get Annual Access';
        gradient = [AppTheme.primary, AppTheme.primaryDark];
        break;
      case _SelectedPlan.monthly:
        buttonText = 'Start Monthly';
        gradient = [AppTheme.primaryLight, AppTheme.primary];
        break;
    }
    
    return Semantics(
      button: true,
      enabled: !isLoading,
      label: buttonText,
      child: GestureDetector(
        onTap: isLoading ? null : _subscribe,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    buttonText,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontVariations: AppTheme.fontVariationsSemiExpanded,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Guarantee box (risk reversal)
  // ──────────────────────────────────────────────
  Widget _buildGuarantee(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.primary.withValues(alpha: 0.08)
            : AppTheme.brandSofter,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(
          color: isDark
              ? AppTheme.primary.withValues(alpha: 0.2)
              : AppTheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: AppTheme.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '7-Day "3-Match" Guarantee',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontVariations: AppTheme.fontVariationsSemiExpanded,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppConfig.guaranteeText,
                  style: AppTheme.bodySmallThemed(context).copyWith(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor(context),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Actions
  // ──────────────────────────────────────────────
  Future<void> _subscribe() async {
    HapticFeedback.mediumImpact();
    
    final purchaseService = Provider.of<PurchaseService>(context, listen: false);
    
    bool success;
    switch (_selectedPlan) {
      case _SelectedPlan.founder:
        success = await purchaseService.purchaseFounderMonthly();
        break;
      case _SelectedPlan.annual:
        success = await purchaseService.purchaseAnnual();
        break;
      case _SelectedPlan.monthly:
        success = await purchaseService.purchaseMonthly();
        break;
    }
    
    if (success && mounted) {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      await apiService.syncSubscriptionWithBackend();
      await purchaseService.refreshFounderInventory();
      await authService.refreshProfile();

      if (!mounted) return;

      HapticFeedback.heavyImpact();
      Navigator.pop(context, true);

      final message = _selectedPlan == _SelectedPlan.founder
          ? 'Welcome, Founder! Unlimited access unlocked.'
          : 'Welcome to Premium! Unlimited access unlocked.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontVariations: AppTheme.fontVariationsSemiExpanded,
            ),
          ),
          backgroundColor: AppTheme.primary,
        ),
      );
    } else if (purchaseService.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(purchaseService.error!),
          backgroundColor: AppTheme.loss,
        ),
      );
      purchaseService.clearError();
    }
  }

  Future<void> _restorePurchases() async {
    HapticFeedback.lightImpact();
    
    final purchaseService = Provider.of<PurchaseService>(context, listen: false);
    final success = await purchaseService.restorePurchases();
    
    if (mounted) {
      if (success) {
        final apiService = Provider.of<ApiService>(context, listen: false);
        final authService = Provider.of<AuthService>(context, listen: false);
        await apiService.syncSubscriptionWithBackend();
        await purchaseService.refreshFounderInventory();
        await authService.refreshProfile();

        if (!mounted) return;

        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Purchases restored! Welcome back.',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontVariations: AppTheme.fontVariationsSemiExpanded,
              ),
            ),
            backgroundColor: AppTheme.primary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No previous purchases found.',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontVariations: AppTheme.fontVariationsSemiExpanded,
              ),
            ),
            backgroundColor: AppTheme.warning,
          ),
        );
      }
    }
  }
}

class _BenefitItem {
  final IconData icon;
  final String text;
  const _BenefitItem({required this.icon, required this.text});
}
