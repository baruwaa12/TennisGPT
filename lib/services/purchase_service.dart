import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

/// PurchaseService handles all RevenueCat subscription logic.
/// 
/// Subscription Products:
/// - composure_founder_monthly: £4.99/month (first 200 users, locked forever)
/// - composure_monthly: £9.99/month
/// - composure_annual: £59.99/year (best value)
class PurchaseService extends ChangeNotifier {
  static const String _placeholderApple = 'YOUR_REVENUECAT_APPLE_API_KEY';
  static const String _placeholderGoogle = 'YOUR_REVENUECAT_GOOGLE_API_KEY';

  /// Set via `--dart-define=REVENUECAT_APPLE_KEY=appl_...` (and Google) in CI/release builds.
  static const String _revenueCatApiKeyApple = String.fromEnvironment(
    'REVENUECAT_APPLE_KEY',
    defaultValue: _placeholderApple,
  );
  static const String _revenueCatApiKeyGoogle = String.fromEnvironment(
    'REVENUECAT_GOOGLE_KEY',
    defaultValue: _placeholderGoogle,
  );

  static bool get isConfigured =>
      _revenueCatApiKeyApple != _placeholderApple &&
      _revenueCatApiKeyGoogle != _placeholderGoogle;
  
  // Product identifiers
  static const String founderMonthlyProductId = 'composure_founder_monthly';
  static const String monthlyProductId = 'composure_monthly';
  static const String annualProductId = 'composure_annual';
  
  // Offering identifiers
  static const String founderOfferingId = 'founder';
  static const String defaultOfferingId = 'default';
  
  // Entitlement identifier
  static const String premiumEntitlement = 'premium';
  
  // Founder spots tracking key
  static const String _founderSpotsTakenKey = 'founder_spots_taken';

  bool _isInitialized = false;
  bool _isPremium = false;
  bool _isLoading = false;
  String? _error;
  Offerings? _offerings;
  CustomerInfo? _customerInfo;
  int _founderSpotsTaken = 0;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Offerings? get offerings => _offerings;
  CustomerInfo? get customerInfo => _customerInfo;
  
  // Founder plan getters
  int get founderSpotsTaken => _founderSpotsTaken;
  int get founderSpotsRemaining => 
      (AppConfig.founderSpotsTotal - _founderSpotsTaken).clamp(0, AppConfig.founderSpotsTotal);
  bool get isFounderAvailable => founderSpotsRemaining > 0;

  /// Initialize RevenueCat SDK
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isLoading = true;
      notifyListeners();
      
      // Load founder spots count from local storage
      await _loadFounderSpots();

      // Skip if RevenueCat is not configured (placeholder keys)
      if (!isConfigured) {
        if (kDebugMode) {
          print('PurchaseService: RevenueCat not configured (using placeholder keys)');
        }
        _isInitialized = true;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Configure RevenueCat
      late PurchasesConfiguration configuration;
      
      if (defaultTargetPlatform == TargetPlatform.iOS || 
          defaultTargetPlatform == TargetPlatform.macOS) {
        configuration = PurchasesConfiguration(_revenueCatApiKeyApple);
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        configuration = PurchasesConfiguration(_revenueCatApiKeyGoogle);
      } else {
        // Web or other platforms - skip initialization
        if (kDebugMode) {
          print('PurchaseService: Platform not supported for purchases');
        }
        _isInitialized = true;
        _isLoading = false;
        notifyListeners();
        return;
      }

      await Purchases.configure(configuration);
      
      // Listen to customer info updates
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _updateCustomerInfo(customerInfo);
      });

      // Get initial customer info
      await _fetchCustomerInfo();
      
      // Get available offerings
      await _fetchOfferings();

      _isInitialized = true;
      
      if (kDebugMode) {
        print('PurchaseService: Initialized successfully');
        print('PurchaseService: Premium status: $_isPremium');
        print('PurchaseService: Founder spots remaining: $founderSpotsRemaining');
      }
    } catch (e) {
      _error = 'Failed to initialize purchases: $e';
      if (kDebugMode) {
        print('PurchaseService: Error - $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Load founder spots count from local storage
  /// In production, consider fetching this from your backend for accuracy
  Future<void> _loadFounderSpots() async {
    final prefs = await SharedPreferences.getInstance();
    _founderSpotsTaken = prefs.getInt(_founderSpotsTakenKey) ?? 0;
  }
  
  /// Increment founder spots taken (call after successful founder purchase)
  Future<void> _recordFounderPurchase() async {
    _founderSpotsTaken++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_founderSpotsTakenKey, _founderSpotsTaken);
    notifyListeners();
    
    if (kDebugMode) {
      print('PurchaseService: Founder spot claimed. Remaining: $founderSpotsRemaining');
    }
  }

  /// Fetch current customer info and check premium status
  Future<void> _fetchCustomerInfo() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _updateCustomerInfo(customerInfo);
    } catch (e) {
      if (kDebugMode) {
        print('PurchaseService: Error fetching customer info - $e');
      }
    }
  }

  /// Update customer info and premium status
  void _updateCustomerInfo(CustomerInfo customerInfo) {
    _customerInfo = customerInfo;
    _isPremium = customerInfo.entitlements.active.containsKey(premiumEntitlement);
    
    if (kDebugMode) {
      print('PurchaseService: Premium status updated: $_isPremium');
    }
    
    notifyListeners();
  }

  /// Fetch available subscription offerings
  Future<void> _fetchOfferings() async {
    try {
      _offerings = await Purchases.getOfferings();
      
      if (kDebugMode) {
        print('PurchaseService: Offerings fetched');
        if (_offerings?.current != null) {
          print('PurchaseService: Current offering: ${_offerings!.current!.identifier}');
          for (var package in _offerings!.current!.availablePackages) {
            print('PurchaseService: Package: ${package.identifier} - ${package.storeProduct.priceString}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('PurchaseService: Error fetching offerings - $e');
      }
    }
  }

  /// Get founder monthly subscription package
  Package? get founderMonthlyPackage {
    // Try to get from 'founder' offering first
    final founderOffering = _offerings?.getOffering(founderOfferingId);
    if (founderOffering != null) {
      for (var package in founderOffering.availablePackages) {
        if (package.storeProduct.identifier == founderMonthlyProductId) {
          return package;
        }
      }
      // Fall back to monthly package in founder offering
      return founderOffering.monthly;
    }
    return null;
  }

  /// Get monthly subscription package
  Package? get monthlyPackage {
    return _offerings?.current?.monthly;
  }

  /// Get annual subscription package
  Package? get annualPackage {
    return _offerings?.current?.annual;
  }

  /// Get founder monthly price string
  String get founderMonthlyPriceString {
    return founderMonthlyPackage?.storeProduct.priceString ?? AppConfig.founderMonthlyPriceDisplay;
  }

  /// Get monthly price string
  String get monthlyPriceString {
    return monthlyPackage?.storeProduct.priceString ?? AppConfig.regularMonthlyPriceDisplay;
  }

  /// Get annual price string
  String get annualPriceString {
    return annualPackage?.storeProduct.priceString ?? AppConfig.annualPriceDisplay;
  }

  /// Purchase founder monthly subscription
  Future<bool> purchaseFounderMonthly() async {
    if (!isFounderAvailable) {
      _error = 'Founder spots are no longer available';
      notifyListeners();
      return false;
    }
    
    final package = founderMonthlyPackage;
    if (package == null) {
      _error = 'Founder package not available';
      notifyListeners();
      return false;
    }
    
    final success = await _purchasePackage(package);
    if (success) {
      await _recordFounderPurchase();
    }
    return success;
  }

  /// Purchase monthly subscription
  Future<bool> purchaseMonthly() async {
    final package = monthlyPackage;
    if (package == null) {
      _error = 'Monthly package not available';
      notifyListeners();
      return false;
    }
    return await _purchasePackage(package);
  }

  /// Purchase annual subscription
  Future<bool> purchaseAnnual() async {
    final package = annualPackage;
    if (package == null) {
      _error = 'Annual package not available';
      notifyListeners();
      return false;
    }
    return await _purchasePackage(package);
  }

  /// Purchase a specific package
  Future<bool> _purchasePackage(Package package) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final purchaseResult = await Purchases.purchasePackage(package);
      _updateCustomerInfo(purchaseResult.customerInfo);
      
      if (kDebugMode) {
        print('PurchaseService: Purchase successful');
      }
      
      return _isPremium;
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        _error = 'Purchase cancelled';
      } else {
        _error = 'Purchase failed: $e';
      }
      
      if (kDebugMode) {
        print('PurchaseService: Purchase error - $e');
      }
      
      return false;
    } catch (e) {
      _error = 'Purchase failed: $e';
      
      if (kDebugMode) {
        print('PurchaseService: Purchase error - $e');
      }
      
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Restore previous purchases
  Future<bool> restorePurchases() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final customerInfo = await Purchases.restorePurchases();
      _updateCustomerInfo(customerInfo);
      
      if (kDebugMode) {
        print('PurchaseService: Restore successful, premium: $_isPremium');
      }
      
      return _isPremium;
    } catch (e) {
      _error = 'Restore failed: $e';
      
      if (kDebugMode) {
        print('PurchaseService: Restore error - $e');
      }
      
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Identify user with RevenueCat (call after authentication)
  Future<void> identifyUser(String userId) async {
    try {
      final customerInfo = await Purchases.logIn(userId);
      _updateCustomerInfo(customerInfo.customerInfo);
      
      if (kDebugMode) {
        print('PurchaseService: User identified: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('PurchaseService: Error identifying user - $e');
      }
    }
  }

  /// Log out user from RevenueCat
  Future<void> logOut() async {
    try {
      final customerInfo = await Purchases.logOut();
      _updateCustomerInfo(customerInfo);
      
      if (kDebugMode) {
        print('PurchaseService: User logged out');
      }
    } catch (e) {
      if (kDebugMode) {
        print('PurchaseService: Error logging out - $e');
      }
    }
  }

  /// Clear any error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Check if user has active subscription (for gating features)
  bool hasActiveSubscription() {
    return _isPremium;
  }

  /// Get subscription expiration date (if any)
  DateTime? get expirationDate {
    final entitlement = _customerInfo?.entitlements.active[premiumEntitlement];
    if (entitlement?.expirationDate != null) {
      return DateTime.parse(entitlement!.expirationDate!);
    }
    return null;
  }

  /// Check if subscription will renew
  bool get willRenew {
    final entitlement = _customerInfo?.entitlements.active[premiumEntitlement];
    return entitlement?.willRenew ?? false;
  }
}
