import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:purchases_flutter/purchases_flutter.dart';
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

  /// True when the API key for the **current** store is set (not both keys).
  static bool get isConfigured {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return _revenueCatApiKeyApple != _placeholderApple;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _revenueCatApiKeyGoogle != _placeholderGoogle;
    }
    return false;
  }

  static const String _inventoryUrl =
      'https://tennisgpt-production.up.railway.app/api/subscription/founder-inventory';

  // Product identifiers
  static const String founderMonthlyProductId = 'composure_founder_monthly';
  static const String monthlyProductId = 'composure_monthly';
  static const String annualProductId = 'composure_annual';

  // Offering identifiers
  static const String founderOfferingId = 'founder';
  static const String defaultOfferingId = 'default';

  // Entitlement identifier
  static const String premiumEntitlement = 'premium';

  bool _isInitialized = false;
  bool _isPremium = false;
  bool _isLoading = false;
  String? _error;
  Offerings? _offerings;
  CustomerInfo? _customerInfo;
  int _founderSpotsTaken = 0;
  int _founderSpotsTotal = AppConfig.founderSpotsTotal;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Offerings? get offerings => _offerings;
  CustomerInfo? get customerInfo => _customerInfo;

  // Founder plan getters (server-authoritative via [refreshFounderInventory])
  int get founderSpotsTaken => _founderSpotsTaken;
  int get founderSpotsRemaining =>
      (_founderSpotsTotal - _founderSpotsTaken).clamp(0, _founderSpotsTotal);
  bool get isFounderAvailable => founderSpotsRemaining > 0;

  /// Initialize RevenueCat SDK
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isLoading = true;
      notifyListeners();

      await refreshFounderInventory();

      // Skip if RevenueCat is not configured (placeholder keys)
      if (!isConfigured) {
        if (kDebugMode) {
          print(
            'PurchaseService: RevenueCat not configured for this platform (placeholder key)',
          );
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
        if (kDebugMode) {
          print('PurchaseService: Platform not supported for purchases');
        }
        _isInitialized = true;
        _isLoading = false;
        notifyListeners();
        return;
      }

      await Purchases.configure(configuration);

      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _updateCustomerInfo(customerInfo);
      });

      await _fetchCustomerInfo();
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

  /// Loads founder spot counts from the backend (public endpoint).
  Future<void> refreshFounderInventory() async {
    try {
      final response = await http
          .get(Uri.parse(_inventoryUrl))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) return;

      final claimed = data['spotsClaimed'];
      final total = data['spotsTotal'];
      if (claimed is num) {
        _founderSpotsTaken = claimed.toInt();
      }
      if (total is num) {
        _founderSpotsTotal = total.toInt();
      }
      notifyListeners();

      if (kDebugMode) {
        print(
          'PurchaseService: Founder inventory $_founderSpotsTaken / $_founderSpotsTotal',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('PurchaseService: Founder inventory fetch failed: $e');
      }
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
    _isPremium =
        customerInfo.entitlements.active.containsKey(premiumEntitlement);

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
          print(
            'PurchaseService: Current offering: ${_offerings!.current!.identifier}',
          );
          for (var package in _offerings!.current!.availablePackages) {
            print(
              'PurchaseService: Package: ${package.identifier} - ${package.storeProduct.priceString}',
            );
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
    final founderOffering = _offerings?.getOffering(founderOfferingId);
    if (founderOffering != null) {
      for (var package in founderOffering.availablePackages) {
        if (package.storeProduct.identifier == founderMonthlyProductId) {
          return package;
        }
      }
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
    return founderMonthlyPackage?.storeProduct.priceString ??
        AppConfig.founderMonthlyPriceDisplay;
  }

  /// Get monthly price string
  String get monthlyPriceString {
    return monthlyPackage?.storeProduct.priceString ??
        AppConfig.regularMonthlyPriceDisplay;
  }

  /// Get annual price string
  String get annualPriceString {
    return annualPackage?.storeProduct.priceString ??
        AppConfig.annualPriceDisplay;
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

    return await _purchasePackage(package);
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

  static String _messageForPurchasesCode(
    PurchasesErrorCode code, [
    String? detail,
  ]) {
    switch (code) {
      case PurchasesErrorCode.purchaseCancelledError:
        return 'Purchase cancelled';
      case PurchasesErrorCode.storeProblemError:
        return 'The store could not complete the purchase. Try again in a moment.';
      case PurchasesErrorCode.purchaseNotAllowedError:
        return 'Purchases are not allowed on this device or account.';
      case PurchasesErrorCode.purchaseInvalidError:
        return 'This purchase could not be started. Check your store account and try again.';
      case PurchasesErrorCode.productNotAvailableForPurchaseError:
        return 'That plan is not available right now.';
      case PurchasesErrorCode.productAlreadyPurchasedError:
        return 'You already have an active subscription. Use Restore purchases.';
      case PurchasesErrorCode.networkError:
      case PurchasesErrorCode.offlineConnectionError:
        return 'Check your internet connection and try again.';
      case PurchasesErrorCode.invalidCredentialsError:
      case PurchasesErrorCode.configurationError:
        return 'Subscription service is not configured correctly. Please contact support.';
      case PurchasesErrorCode.paymentPendingError:
        return 'Payment is pending. You will get access when the store confirms it.';
      default:
        final extra = (detail != null && detail.isNotEmpty) ? ' ($detail)' : '';
        return 'Could not complete purchase. Please try again.$extra';
    }
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

      await refreshFounderInventory();

      return _isPremium;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      _error = _messageForPurchasesCode(code, e.message);

      if (kDebugMode) {
        print('PurchaseService: Purchase error - $code ${e.message}');
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
      await refreshFounderInventory();

      if (kDebugMode) {
        print('PurchaseService: Restore successful, premium: $_isPremium');
      }

      return _isPremium;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      _error = _messageForPurchasesCode(code, e.message);
      if (kDebugMode) {
        print('PurchaseService: Restore error - $code');
      }
      return false;
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

  /// Prefer [AppConfig.hasPremiumAccess] at feature gates; this is RevenueCat only.
  bool hasActiveSubscription() {
    return _isPremium;
  }

  /// Get subscription expiration date (if any)
  DateTime? get expirationDate {
    final entitlement =
        _customerInfo?.entitlements.active[premiumEntitlement];
    if (entitlement?.expirationDate != null) {
      return DateTime.parse(entitlement!.expirationDate!);
    }
    return null;
  }

  /// Check if subscription will renew
  bool get willRenew {
    final entitlement =
        _customerInfo?.entitlements.active[premiumEntitlement];
    return entitlement?.willRenew ?? false;
  }
}
