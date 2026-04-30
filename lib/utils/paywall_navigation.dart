import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../screens/paywall_screen.dart';
import '../services/auth_service.dart';

export '../screens/paywall_screen.dart' show PaywallScreen, PaywallTrigger;

/// Central place to open the paywall when [AppConfig] allows it.
Future<void> presentPaywall(
  BuildContext context, {
  PaywallTrigger trigger = PaywallTrigger.general,
}) async {
  if (!context.mounted) return;

  final auth = Provider.of<AuthService>(context, listen: false);
  if (!AppConfig.shouldShowPaywall(
    email: auth.userEmail,
    userId: null,
  )) {
    return;
  }

  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => PaywallScreen(trigger: trigger),
    ),
  );
}
