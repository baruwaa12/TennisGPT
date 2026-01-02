import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/purchase_service.dart';

enum PaywallTrigger {
  matchLimit,
  tacticalAnalysisLimit,
  prepSessionLimit,
  debriefLimit,
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

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isAnnualSelected = true;

  String get _triggerMessage {
    switch (widget.trigger) {
      case PaywallTrigger.matchLimit:
        return "You've logged 5 matches!\nUnlock unlimited tracking.";
      case PaywallTrigger.tacticalAnalysisLimit:
        return "You've used your 4 free analyses.\nUnlock unlimited tactical insights.";
      case PaywallTrigger.prepSessionLimit:
        return "You've used your 4 free analyses.\nUnlock unlimited preparation.";
      case PaywallTrigger.debriefLimit:
        return "You've used your 4 free analyses.\nUnlock unlimited post-match analysis.";
      case PaywallTrigger.general:
        return "Level up your tennis game";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
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
                
                // Header
                const SizedBox(height: 8),
                Text(
                  '🎯',
                  style: const TextStyle(fontSize: 56),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Unlock Full Tactical Power',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _triggerMessage,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Free vs Premium comparison
                _buildComparisonCard(),
                
                const SizedBox(height: 24),
                
                // Pricing options
                _buildPricingOptions(),
                
                const SizedBox(height: 24),
                
                // Subscribe button
                _buildSubscribeButton(),
                
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
                
                const SizedBox(height: 16),
                
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
                      onPressed: () {/* TODO: Open terms */},
                      child: Text(
                        'Terms of Use',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    Text(' • ', style: TextStyle(color: Colors.grey[400])),
                    TextButton(
                      onPressed: () {/* TODO: Open privacy */},
                      child: Text(
                        'Privacy Policy',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Free section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lock_open, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'FREE',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFeatureRow('5 matches logged', false),
                _buildFeatureRow('4 free AI analyses', false),
                _buildFeatureRow('Basic performance stats', false),
              ],
            ),
          ),
          
          // Premium section
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.star, color: Colors.amber, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PREMIUM',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFeatureRow('Unlimited match logging', true),
                _buildFeatureRow('Unlimited tactical analysis', true),
                _buildFeatureRow('Opponent scouting', true),
                _buildFeatureRow('Advanced analytics', true),
                _buildFeatureRow('AI weekly insights', true),
                _buildFeatureRow('Export your data', true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String text, bool isPremium) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isPremium ? Icons.check_circle : Icons.remove_circle_outline,
            color: isPremium ? Colors.green : Colors.grey[400],
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isPremium ? Colors.grey[800] : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingOptions() {
    final purchaseService = Provider.of<PurchaseService>(context);
    
    return Column(
      children: [
        // Annual option (BEST VALUE)
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _isAnnualSelected = true);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isAnnualSelected ? Colors.green.shade50 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isAnnualSelected ? Colors.green : Colors.grey.shade300,
                width: _isAnnualSelected ? 2 : 1,
              ),
              boxShadow: _isAnnualSelected
                  ? [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isAnnualSelected ? Colors.green : Colors.grey,
                      width: 2,
                    ),
                    color: _isAnnualSelected ? Colors.green : Colors.transparent,
                  ),
                  child: _isAnnualSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Annual',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'SAVE 50%',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Best value for serious players',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  purchaseService.annualPriceString,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isAnnualSelected ? Colors.green : Colors.grey[800],
                  ),
                ),
                Text(
                  '/yr',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Monthly option
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _isAnnualSelected = false);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: !_isAnnualSelected ? Colors.blue.shade50 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: !_isAnnualSelected ? Colors.blue : Colors.grey.shade300,
                width: !_isAnnualSelected ? 2 : 1,
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
                      color: !_isAnnualSelected ? Colors.blue : Colors.grey,
                      width: 2,
                    ),
                    color: !_isAnnualSelected ? Colors.blue : Colors.transparent,
                  ),
                  child: !_isAnnualSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Flexible option',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  purchaseService.monthlyPriceString,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: !_isAnnualSelected ? Colors.blue : Colors.grey[800],
                  ),
                ),
                Text(
                  '/mo',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscribeButton() {
    final purchaseService = Provider.of<PurchaseService>(context);
    final isLoading = purchaseService.isLoading;
    
    return GestureDetector(
      onTap: isLoading ? null : _subscribe,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isAnnualSelected
                ? [Colors.green.shade500, Colors.green.shade700]
                : [Colors.blue.shade500, Colors.blue.shade700],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (_isAnnualSelected ? Colors.green : Colors.blue).withOpacity(0.3),
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
                  'Start Premium 🎯',
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

  Future<void> _subscribe() async {
    HapticFeedback.mediumImpact();
    
    final purchaseService = Provider.of<PurchaseService>(context, listen: false);
    
    bool success;
    if (_isAnnualSelected) {
      success = await purchaseService.purchaseAnnual();
    } else {
      success = await purchaseService.purchaseMonthly();
    }
    
    if (success && mounted) {
      HapticFeedback.heavyImpact();
      Navigator.pop(context, true); // Return true to indicate successful purchase
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 Welcome to Premium! Unlimited access unlocked.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
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
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Purchases restored! Welcome back.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
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
