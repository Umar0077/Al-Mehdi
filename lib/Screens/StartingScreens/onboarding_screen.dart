import 'package:al_mehdi_online_school/Screens/Auth%20Screens/Main_page.dart';
import 'package:al_mehdi_online_school/Screens/Auth%20Screens/login_screen.dart';
import 'package:al_mehdi_online_school/components/Custom_button.dart';
import 'package:al_mehdi_online_school/constants/colors.dart';
import 'package:al_mehdi_online_school/services/onboarding_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  final List<Map<String, String>> _onboardingData = const [
    {
      "image": "assets/images/Onboarding1.jpeg",
      "title": "Attend Live Classes",
      "subtitle": "Learn in real-time from expert tutors, anytime, anywhere.",
    },
    {
      "image": "assets/images/Onboarding2.jpeg",
      "title": "Chat with Tutors",
      "subtitle":
          "Instantly connect with tutors to ask questions or clear doubts.",
    },
    {
      "image": "assets/images/Onboarding3.jpeg",
      "title": "Track Your Progress",
      "subtitle":
          "Monitor attendance, performance and stay on top of your schedule.",
    },
  ];

  void _goToMain(BuildContext context) async {
    await OnboardingService.instance.markOnboardingComplete();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainPage()),
    );
  }

  void _goToLogin(BuildContext context) async {
    await OnboardingService.instance.markOnboardingComplete();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = PageController();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Center(
            child: SizedBox(
              width: constraints.maxWidth > 600 ? 600 : double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 32,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Consumer<OnboardingProvider>(
                        builder: (context, provider, _) {
                          return PageView.builder(
                            controller: controller,
                            itemCount: _onboardingData.length,
                            onPageChanged: provider.setPage,
                            itemBuilder: (context, index) {
                              final data = _onboardingData[index];
                              return Column(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: Image.asset(
                                        data["image"]!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    data["title"]!,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    data["subtitle"]!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(context).textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Consumer<OnboardingProvider>(
                      builder: (context, provider, _) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _onboardingData.length,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: provider.currentPage == i ? 12 : 8,
                              height: provider.currentPage == i ? 12 : 8,
                              decoration: BoxDecoration(
                                color:
                                    provider.currentPage == i
                                        ? appGreen
                                        : appGreen.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Consumer<OnboardingProvider>(
                      builder: (context, provider, _) {
                        final isLast =
                            provider.currentPage == _onboardingData.length - 1;
                        return isLast
                            ? CustomButton(
                                text: "Get Started",
                                onPressed: () => _goToMain(context),
                              )
                            : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () => _goToLogin(context),
                                  child: Text(
                                    "Go to Login",
                                    style: TextStyle(
                                      color: appGreen,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed:
                                      () => provider.nextPage(
                                        controller,
                                        _onboardingData.length,
                                      ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: appGreen,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    "Next",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class OnboardingProvider with ChangeNotifier {
  int _currentPage = 0;

  int get currentPage => _currentPage;

  void setPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  void nextPage(PageController controller, int totalPages) {
    if (_currentPage < totalPages - 1) {
      controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void skipToLast(PageController controller, int lastPageIndex) {
    controller.jumpToPage(lastPageIndex);
  }
}
