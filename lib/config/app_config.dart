/// App Configuration
/// 
/// Central place for feature flags and app-wide settings.
/// Easy to toggle for testing vs production.
class AppConfig {
  // ============================================================
  // FEATURE FLAGS
  // ============================================================
  
  /// Whether payments/subscriptions are enabled.
  /// Disabled for current iOS App Review submission.
  static const bool paymentsEnabled = false;
  
  /// Whether to show paywall screens.
  /// Keep false while payments are hidden.
  static const bool showPaywalls = false;
  
  /// Whether to enforce usage limits.
  /// When false, limits are not enforced (unlimited for testers).
  static const bool enforceLimits = true;
  
  // ============================================================
  // DAILY LIMITS (when enforceLimits = true)
  // ============================================================
  
  /// Maximum AI analyses per day (protects OpenAI costs)
  static const int dailyAIAnalysisLimit = 10;
  
  /// Maximum matches logged per day
  static const int dailyMatchLogLimit = 20;
  
  // ============================================================
  // FOUNDER PLAN CONFIG
  // ============================================================
  
  /// Total founder spots available (once gone, only regular pricing)
  static const int founderSpotsTotal = 200;
  
  /// Founder pricing display strings (actual prices set in App Store Connect / RevenueCat)
  static const String founderMonthlyPriceDisplay = '£4.99';
  static const String regularMonthlyPriceDisplay = '£9.99';
  static const String annualPriceDisplay = '£59.99';
  
  /// Guarantee text
  static const String guaranteeText =
      'Log 3 matches in your first 7 days. If Composure isn\'t useful, email us for a full refund.';
  
  // ============================================================
  // COMPED USERS (lifetime free access)
  // ============================================================
  
  /// List of emails that get lifetime free access.
  /// These users bypass ALL paywalls and limits.
  static const List<String> compedEmails = [
    'ademolabaruwa09@gmail.com', // Founder
    // Add more comped users here
  ];
  
  /// List of user IDs that get lifetime free access.
  /// Alternative to email-based comping.
  static const List<String> compedUserIds = [
    // Add user IDs here if needed
  ];
  
  // ============================================================
  // APP INFO
  // ============================================================
  
  static const String appName = 'Composure';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '55';
  static const String supportEmail = 'ademolabaruwa09@gmail.com';
  static const String termsUrl = 'https://composure.app/terms';
  static const String privacyUrl = 'https://composure.app/privacy';
  
  // ============================================================
  // HELPER METHODS
  // ============================================================
  
  /// Check if a user is comped (lifetime free)
  static bool isCompedUser({String? email, String? userId}) {
    if (email != null && compedEmails.contains(email.toLowerCase())) {
      return true;
    }
    if (userId != null && compedUserIds.contains(userId)) {
      return true;
    }
    return false;
  }
  
  /// Check if user should see paywalls
  static bool shouldShowPaywall({String? email, String? userId}) {
    // Never show paywall if payments disabled
    if (!paymentsEnabled || !showPaywalls) return false;
    
    // Never show paywall to comped users
    if (isCompedUser(email: email, userId: userId)) return false;
    
    return true;
  }
  
  /// Check if limits should be enforced for user
  static bool shouldEnforceLimits({String? email, String? userId}) {
    // Never enforce limits if disabled
    if (!enforceLimits) return false;
    
    // Never enforce limits for comped users
    if (isCompedUser(email: email, userId: userId)) return false;
    
    return true;
  }
}

