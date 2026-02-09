import 'package:al_mehdi_online_school/services/platform_detector.dart';
import 'package:al_mehdi_online_school/services/remote_config_service.dart';
import 'package:al_mehdi_online_school/views/misc/mobile_redirect_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Wrapper widget that decides whether to show mobile redirect or main app
class MobileRedirectWrapper extends StatelessWidget {
  final Widget child;
  final bool forceShowRedirect;

  const MobileRedirectWrapper({
    super.key,
    required this.child,
    this.forceShowRedirect = false,
  });

  @override
  Widget build(BuildContext context) {
    // Only check on web platform
    if (!kIsWeb) {
      return child;
    }

    // Check if mobile redirect is enabled via Remote Config
    final isRedirectEnabled =
        RemoteConfigService.instance.isMobileRedirectEnabled;

    // Check if user is on mobile browser
    final isMobile = PlatformDetector.isMobileBrowser();

    // Check if user is in PWA mode (already installed)
    final isPWA = PlatformDetector.isPWA();

    // Show redirect view if:
    // 1. Mobile browser detected AND
    // 2. Not in PWA mode AND
    // 3. Redirect is enabled in Remote Config OR forced
    if (isMobile && !isPWA && (isRedirectEnabled || forceShowRedirect)) {
      return const MobileRedirectView();
    }

    // Otherwise show the main app
    return child;
  }
}
