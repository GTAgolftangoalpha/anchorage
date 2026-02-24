import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PremiumService {
  PremiumService._();
  static final PremiumService instance = PremiumService._();

  final ValueNotifier<bool> isPremium = ValueNotifier(false);

  Future<void> init() async {
    Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);
    await _refreshStatus();
  }

  void _onCustomerInfoUpdated(CustomerInfo info) {
    isPremium.value = info.entitlements.all['premium']?.isActive ?? false;
  }

  Future<void> _refreshStatus() async {
    try {
      final info = await Purchases.getCustomerInfo();
      isPremium.value = info.entitlements.all['premium']?.isActive ?? false;
    } catch (e) {
      debugPrint('[PremiumService] refreshStatus error: $e');
    }
  }

  /// Fetches RevenueCat offerings (products configured in the dashboard).
  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('[PremiumService] getOfferings error: $e');
      return null;
    }
  }

  /// Purchases a RevenueCat package. Returns true if premium is now active.
  Future<bool> purchasePackage(Package package) async {
    try {
      final info = await Purchases.purchasePackage(package);
      isPremium.value = info.entitlements.all['premium']?.isActive ?? false;
      return isPremium.value;
    } on PlatformException catch (e) {
      // Error code 1 = user cancelled — not a real error
      if (e.code != '1') {
        debugPrint('[PremiumService] purchase error: $e');
      }
      return false;
    }
  }

  /// Restores purchases. Returns true if premium is now active.
  Future<bool> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      isPremium.value = info.entitlements.all['premium']?.isActive ?? false;
      return isPremium.value;
    } catch (e) {
      debugPrint('[PremiumService] restore error: $e');
      return false;
    }
  }
}
