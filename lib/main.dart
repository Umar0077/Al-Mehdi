import 'package:al_mehdi_online_school/constants/colors.dart';
import 'package:al_mehdi_online_school/providers/admin/admin_main_screen_provider.dart';
import 'package:al_mehdi_online_school/services/deep_link_service.dart';
import 'package:al_mehdi_online_school/services/remote_config_service.dart';
import 'package:al_mehdi_online_school/services/session_helper.dart';
import 'package:al_mehdi_online_school/services/theme_service.dart';
import 'package:al_mehdi_online_school/views/students/student_home_screen/student_home_screen.dart';
import 'package:al_mehdi_online_school/views/teachers/teacher_home_screen/teacher_home_screen.dart';
import 'package:al_mehdi_online_school/views/admin_dashboard/admin_home_view.dart';
import 'package:al_mehdi_online_school/views/authentication/login_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart'
    show Persistence;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart'; // ✅ Import generated config
import 'providers/unassigned_user/admin_home_provider.dart';
import 'services/notification_service.dart';
import 'services/onboarding_service.dart';
import 'views/authentication/auth_view.dart';
import 'views/onboarding/onboarding_view.dart';
import 'views/splash/splash_view.dart';

// ✅ Global theme notifier
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Remote Config Service
  await RemoteConfigService.instance.initialize();

  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

    // Initialize Deep Link Service with Remote Config values
    DeepLinkService.initialize();

    // Optional: Print config values in debug mode
    if (kDebugMode) {
      print('🔧 Remote Config Values:');
      RemoteConfigService.instance.printAllValues();
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => AdminMainScreenProvider()),
        ChangeNotifierProvider(
          create: (_) => AdminHomeProvider(),
        ), // <-- Add this line
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'Al - Mehdi Online School',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.black),
              bodyMedium: TextStyle(color: Colors.black),
              displayLarge: TextStyle(color: Colors.black),
              displayMedium: TextStyle(color: Colors.black),
            ),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              foregroundColor: Colors.black,
            ),
            useMaterial3: true,
            fontFamily: 'Roboto',
            scaffoldBackgroundColor: Colors.white,
            cardColor: Colors.white,
            dividerTheme: DividerThemeData(color: Colors.grey),
            progressIndicatorTheme: const ProgressIndicatorThemeData(
              color: appGreen,
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: appGreen,
              unselectedItemColor: Colors.black,
            ),
            iconTheme: const IconThemeData(color: Colors.black),
            tabBarTheme: const TabBarThemeData(
              labelColor: Colors.black,
              unselectedLabelColor: Colors.black,
            ),
          ),
          darkTheme: ThemeData(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            appBarTheme: AppBarTheme(
              backgroundColor: darkBackground,
              surfaceTintColor: Colors.transparent,
              foregroundColor: Colors.white,
            ),
            cardColor: darkBackground.withOpacity(0.95),
            shadowColor: Colors.white,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: darkBackground,
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white),
              displayLarge: TextStyle(color: Colors.white),
              displayMedium: TextStyle(color: Colors.white),
            ),
            dividerTheme: DividerThemeData(color: Colors.grey),
            progressIndicatorTheme: const ProgressIndicatorThemeData(
              color: appGreen,
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: darkBackground,
              selectedItemColor: appGreen,
              unselectedItemColor: Colors.white,
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            tabBarTheme: const TabBarThemeData(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white,
            ),
          ),
          themeMode: mode,
          home: const AppInitializer(),
        );
      },
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  _AppInitializerState createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize services with error handling
    try {
      await NotificationService.initialize();
      await NotificationService().updateClassStatuses();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Notification service initialization failed: $e');
        print('Continuing with app initialization...');
      }
    }

    // Load saved theme preference
    try {
      final savedTheme = await ThemeService.instance.loadTheme();
      themeNotifier.value = savedTheme;
      if (kDebugMode) {
        print('✅ Loaded theme: $savedTheme');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to load theme, using default: $e');
      }
      themeNotifier.value = ThemeMode.light;
    }

    // Navigate after a delay
    await Future.delayed(const Duration(seconds: 3));
    _navigateAfterSplash();
  }

  void _navigateAfterSplash() async {
    // Check admin session first for both web and mobile
    if (await getAdminSessionFlag()) {
      // Validate admin session (optional: check if session is not too old)
      final loginTime = await getAdminLoginTime();
      final adminEmail = await getAdminEmail();

      if (loginTime != null && adminEmail != null) {
        // Check if session is valid (e.g., not older than 30 days)
        final sessionAge = DateTime.now().difference(loginTime).inDays;
        if (sessionAge < 30) {
          print(
            'Valid admin session found. Email: $adminEmail, Login time: $loginTime',
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminHomeView()),
          );
          return;
        } else {
          // Session expired, clear it
          print('Admin session expired, clearing session');
          await clearAdminSession();
        }
      }
    }

    // Check if user has seen onboarding
    final hasSeenOnboarding =
        await OnboardingService.instance.hasSeenOnboarding();

    final user = FirebaseAuth.instance.currentUser;

    if (kIsWeb) {
      if (user != null) {
        // User is logged in, check role and navigate to appropriate home screen
        final studentDoc =
            await FirebaseFirestore.instance
                .collection('students')
                .doc(user.uid)
                .get();
        if (studentDoc.exists) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const StudentHomeScreen()),
          );
          return;
        }
        final teacherDoc =
            await FirebaseFirestore.instance
                .collection('teachers')
                .doc(user.uid)
                .get();
        if (teacherDoc.exists) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TeacherHomeScreen()),
          );
          return;
        }
        // If neither role found, fallback to login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginView()),
        );
      } else {
        // User not logged in - check if they've seen onboarding
        if (!hasSeenOnboarding) {
          // First time user - show onboarding
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ChangeNotifierProvider(
                    create: (_) => OnboardingProvider(),
                    child: const OnboardingView(),
                  ),
            ),
          );
        } else {
          // Returning user - go directly to login
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginView()),
          );
        }
      }
    } else {
      // Mobile - check user status
      if (user != null) {
        // User is logged in, go to MainPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthView()),
        );
      } else {
        // User not logged in - check if they've seen onboarding
        if (!hasSeenOnboarding) {
          // First time user - show onboarding
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ChangeNotifierProvider(
                    create: (_) => OnboardingProvider(),
                    child: const OnboardingView(),
                  ),
            ),
          );
        } else {
          // Returning user - go directly to MainPage (which will handle auth check)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AuthView()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashView();
  }
}
