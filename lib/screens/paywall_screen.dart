import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final purchaseService = Provider.of<PurchaseService>(context);
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.surfaceDark : Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.grey[600]),
                  ),
                ),
                
                // Founder spots banner
                if (purchaseService.isFounderAvailable) ...[
                  _buildFounderBanner(purchaseService),
                  const SizedBox(height: 20),
                ],
                
                // Title
                Text(
                  _triggerTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[900],
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _triggerSubtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // What you get (benefit-focused, not feature list)
                _buildBenefits(isDark),
                
                const SizedBox(height: 24),
                
                // Pricing options
                _buildPricingOptions(purchaseService, isDark),
                
                const SizedBox(height: 20),
                
                // Subscribe button
                _buildSubscribeButton(purchaseService),
                
                const SizedBox(height: 12),
                
                // Guarantee
                _buildGuarantee(isDark),
                
                const SizedBox(height: 16),
                
                // Restore purchases
                Center(
                  child: TextButton(
                    onPressed: _restorePurchases,
                    child: Text(
                      'Restore Purchases',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Legal text
                Text(
                  'Cancel anytime. Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[500],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
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
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    Text(' • ', style: TextStyle(color: Colors.grey[400])),
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
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade600, Colors.orange.shade700],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_fire_department, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Founder pricing: ${purchaseService.founderSpotsRemaining} of ${AppConfig.founderSpotsTotal} spots left',
              style: GoogleFonts.poppins(
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
      _BenefitItem(
        icon: Icons.insights,
        text: 'Unlimited tactical analysis after every match',
      ),
      _BenefitItem(
        icon: Icons.sports_tennis,
        text: 'Unlimited match logging & full history',
      ),
      _BenefitItem(
        icon: Icons.trending_up,
        text: 'Trends & patterns (surface, opponent type, win rate)',
      ),
      _BenefitItem(
        icon: Icons.fitness_center,
        text: 'Drills + next-match plan based on your data',
      ),
      _BenefitItem(
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
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(b.icon, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                b.text,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
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
            badgeColor: Colors.amber.shade700,
            accentColor: Colors.amber.shade700,
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
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedPlan = plan);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withOpacity(isDark ? 0.15 : 0.06)
              : (isDark ? Colors.grey[900] : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? accentColor : (isDark ? Colors.grey[800]! : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.18),
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
                  color: isSelected ? accentColor : Colors.grey,
                  width: 2,
                ),
                color: isSelected ? accentColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor ?? accentColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badgeText,
                            style: GoogleFonts.poppins(
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
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Price
            Text(
              priceText,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? accentColor : (isDark ? Colors.white : Colors.grey[800]),
              ),
            ),
            Text(
              priceSuffix,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ],
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
        gradient = [Colors.amber.shade600, Colors.orange.shade700];
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
    
    return GestureDetector(
      onTap: isLoading ? null : _subscribe,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.3),
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
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
        color: isDark ? AppTheme.primary.withOpacity(0.08) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.primary.withOpacity(0.2) : AppTheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: AppTheme.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '7-Day "3-Match" Guarantee',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppConfig.guaranteeText,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
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
          content: Text(message, style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.primary,
        ),
      );
    } else if (purchaseService.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(purchaseService.error!),
          backgroundColor: Colors.red,
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
          SnackBar(
            content: Text(
              'Purchases restored! Welcome back.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppTheme.primary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No previous purchases found.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.orange,
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
