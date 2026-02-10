import 'dart:async';

import 'package:al_mehdi_online_school/constants/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'mobile_redirect_web_helper_stub.dart'
    if (dart.library.js_interop) 'mobile_redirect_web_helper_web.dart';

/// View displayed when web app is opened on mobile browsers
/// Shows options to open the app or download from store
class MobileRedirectView extends StatefulWidget {
  const MobileRedirectView({super.key});

  @override
  State<MobileRedirectView> createState() => _MobileRedirectViewState();
}

class _MobileRedirectViewState extends State<MobileRedirectView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isAttemptingRedirect = true;
  bool _isAndroid = false;
  bool _isIOS = false;

  // App URLs
  static const String _androidScheme = 'almehdi://';
  static const String _iosScheme = 'almehdi://';
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.almehdi.onlineschool';
  static const String _appStoreUrl = 'https://apps.apple.com/app/id123456789';

  @override
  void initState() {
    super.initState();
    _detectPlatform();
    _setupAnimation();
    _attemptDeepLink();
  }

  void _detectPlatform() {
    if (!kIsWeb) return;

    final userAgent = MobileRedirectWebHelper.getUserAgent().toLowerCase();
    setState(() {
      _isAndroid = userAgent.contains('android');
      _isIOS =
          userAgent.contains('iphone') ||
          userAgent.contains('ipad') ||
          userAgent.contains('ipod');
    });
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();
  }

  Future<void> _attemptDeepLink() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (_isAndroid) {
      _tryOpenAndroidApp();
    } else if (_isIOS) {
      _tryOpenIOSApp();
    }

    // After timeout, show the UI
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isAttemptingRedirect = false;
      });
    }
  }

  void _tryOpenAndroidApp() {
    if (!kIsWeb) return;

    // Try intent URL
    final intentUrl =
        'intent://open#Intent;'
        'scheme=${_androidScheme.replaceAll('://', '')};'
        'package=com.almehdi.onlineschool;'
        'S.browser_fallback_url=$_playStoreUrl;'
        'end';

    try {
      MobileRedirectWebHelper.setLocationHref(intentUrl);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to open Android app: $e');
      }
    }
  }

  void _tryOpenIOSApp() {
    if (!kIsWeb) return;

    final deepLink = '${_iosScheme}open';

    try {
      MobileRedirectWebHelper.setLocationHref(deepLink);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to open iOS app: $e');
      }
    }
  }

  void _openStore() {
    if (!kIsWeb) return;

    final storeUrl = _isAndroid ? _playStoreUrl : _appStoreUrl;
    MobileRedirectWebHelper.openWindow(storeUrl, '_blank');
  }

  // void _continueToWeb() {
  //   // Navigate to the main web app
  //   Navigator.of(context).pushReplacementNamed('/');
  // }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              appGreen.withOpacity(0.1),
              Colors.white,
              appGreen.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child:
              _isAttemptingRedirect
                  ? _buildLoadingView()
                  : _buildRedirectOptionsView(),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App Logo
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: appGreen.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Image.asset(
              'assets/icon/icon.png',
              width: 80,
              height: 80,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.school, size: 80, color: appGreen);
              },
            ),
          ),
          const SizedBox(height: 30),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(appGreen),
          ),
          const SizedBox(height: 20),
          const Text(
            'Opening Al-Mehdi Online School...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedirectOptionsView() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: appGreen.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/icon/icon.png',
                width: 100,
                height: 100,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.school, size: 100, color: appGreen);
                },
              ),
            ),
            const SizedBox(height: 40),

            // Title
            const Text(
              'Al-Mehdi Online School',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              'Get the best experience with our mobile app',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 50),

            // Open App Button
            _buildActionButton(
              icon: Icons.open_in_new,
              label: 'Open in App',
              onPressed: () {
                if (_isAndroid) {
                  _tryOpenAndroidApp();
                } else if (_isIOS) {
                  _tryOpenIOSApp();
                }
                // Give it a moment to open
                Future.delayed(const Duration(milliseconds: 1500), () {
                  if (mounted) {
                    _openStore();
                  }
                });
              },
              isPrimary: true,
            ),
            const SizedBox(height: 16),

            // Download from Store Button
            _buildActionButton(
              icon: _isAndroid ? Icons.android : Icons.apple,
              label:
                  _isAndroid ? 'Get it on Play Store' : 'Download on App Store',
              onPressed: _openStore,
              isPrimary: false,
            ),

            const Spacer(),

            // Features
            _buildFeatures(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? appGreen : Colors.white,
          foregroundColor: isPrimary ? Colors.white : appGreen,
          elevation: isPrimary ? 4 : 0,
          shadowColor: appGreen.withOpacity(0.3),
          side: isPrimary ? null : const BorderSide(color: appGreen, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatures() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: appLightGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildFeatureItem(Icons.speed, 'Faster Performance'),
          const SizedBox(height: 12),
          _buildFeatureItem(Icons.notifications_active, 'Push Notifications'),
          const SizedBox(height: 12),
          _buildFeatureItem(Icons.offline_bolt, 'Offline Access'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: appGreen.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: appGreen, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
