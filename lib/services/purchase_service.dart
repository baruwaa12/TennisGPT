import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// PurchaseService handles all RevenueCat subscription logic.
/// 
/// Subscription Products:
/// - tennisgpt_monthly: $9.99/month
/// - tennisgpt_annual: $59.99/year (best value)
class PurchaseService extends ChangeNotifier {
  // RevenueCat API Keys
  // TODO: Replace with your actual RevenueCat API keys from https://app.revenuecat.com
  static const String _revenueCatApiKeyApple = 'YOUR_REVENUECAT_APPLE_API_KEY';
  static const String _revenueCatApiKeyGoogle = 'YOUR_REVENUECAT_GOOGLE_API_KEY';
  
  // Check if RevenueCat is configured
  static bool get isConfigured => 
      _revenueCatApiKeyApple != 'YOUR_REVENUECAT_APPLE_API_KEY' &&
      _revenueCatApiKeyGoogle != 'YOUR_REVENUECAT_GOOGLE_API_KEY';
  
  // Product identifiers
  static const String monthlyProductId = 'tennisgpt_monthly';
  static const String annualProductId = 'tennisgpt_annual';
  
  // Entitlement identifier
  static const String premiumEntitlement = 'premium';

  bool _isInitialized = false;
  bool _isPremium = false;
  bool _isLoading = false;
  String? _error;
  Offerings? _offerings;
  CustomerInfo? _customerInfo;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Offerings? get offerings => _offerings;
  CustomerInfo? get customerInfo => _customerInfo;

  /// Initialize RevenueCat SDK
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isLoading = true;
      notifyListeners();

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

  /// Get monthly subscription package
  Package? get monthlyPackage {
    return _offerings?.current?.monthly;
  }

  /// Get annual subscription package
  Package? get annualPackage {
    return _offerings?.current?.annual;
  }

  /// Get monthly price string
  String get monthlyPriceString {
    return monthlyPackage?.storeProduct.priceString ?? '\$9.99';
  }

  /// Get annual price string
  String get annualPriceString {
    return annualPackage?.storeProduct.priceString ?? '\$59.99';
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
