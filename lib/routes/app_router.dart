import 'package:flutter/material.dart';
import 'package:frontend/ui/screens/auth/resetpassword_screen.dart';
import 'package:frontend/ui/screens/mail/maildetails_screen.dart' as mailDetail;
import 'package:frontend/ui/screens/settings/setting_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ui/screens/welcome/home_screen.dart';
import '../ui/screens/auth/login_screen.dart';
import '../ui/screens/auth/signup_screen.dart';
import '../ui/screens/calendar/calendar_screen.dart';
import '../ui/screens/task/task_screen.dart';
import '../ui/screens/mail/mail_screen.dart';
import '../ui/screens/mail/composemail_screen.dart' hide MailItem;
import '../ui/screens/welcome/subscription_screen.dart';
import '../ui/screens/calendar/addschedule_screen.dart';
import '../ui/screens/task/addtask_screen.dart';
import '../ui/screens/welcome/analytics_screen.dart';
import '../ui/screens/welcome/notification_screen.dart';
import '../ui/screens/settings/profile_screen.dart';
import '../ui/screens/settings/security_screen.dart';
import '../ui/screens/welcome/splash_screen.dart';
import '../ui/screens/welcome/onboarding_screen.dart';
import '../ui/screens/auth/forgetpassword_screen.dart';
import '../models/meeting.dart';
import '../models/task.dart';

class AppRoutes {
  // Singleton pattern
  static final AppRoutes _instance = AppRoutes._internal();
  factory AppRoutes() => _instance;
  AppRoutes._internal();

  // Route paths as constants
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String home = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgetPassword = '/forgetPassword';
  static const String calendar = '/calendar';
  static const String task = '/task';
  static const String mail = '/mail';
  static const String maildetail = '/maildetail';
  static const String composemail = '/composemail';
  static const String subscription = '/subscription';
  static const String addSchedule = '/addSchedule';
  static const String addTask = '/addTask';
  static const String analytics = '/analytics';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String security = '/security';

  bool firstOpen = true;

  Future<void> init() async {
    final pref = await SharedPreferences.getInstance();
    firstOpen = pref.getBool('firstOpen') ?? true;
  }

  // Go Router configuration
  GoRouter createRouter(BuildContext context) {
    return GoRouter(
      // Initial route determination
      initialLocation: splash,

      // Define all routes
      routes: [
        // Splash and Onboarding Routes
        GoRoute(
          path: splash,
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: onboarding,
          name: 'onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),

        // Auth Routes
        GoRoute(
          path: login,
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: signup,
          name: 'signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: forgetPassword,
          name: 'forgetPassword',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/reset-password',
          name: 'resetPassword',
          builder:
              (context, state) => ResetPasswordScreen(
                token: state.uri.queryParameters['token'],
              ),
        ),

        // Main App Routes (Protected)
        GoRoute(
          path: home,
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: calendar,
          name: 'calendar',
          builder: (context, state) => const CalendarPage(),
        ),
        GoRoute(
          path: task,
          name: 'task',
          builder: (context, state) => const TaskScreen(),
        ),
        GoRoute(
          path: mail,
          name: 'mail',
          builder: (context, state) => const MailScreen(),
        ),
        GoRoute(
          path: maildetail,
          name: 'maildetail',
          builder: (context, state) {
            final email = state.extra as MailItem?;
            if (email == null) {
              // Handle null case - redirect to mail screen
              return const MailScreen();
            }
            return mailDetail.MailDetailScreen(email: email);
          },
        ),
        GoRoute(
          path: composemail,
          name: 'composemail',
          builder: (context, state) => const ComposeMailScreen(),
        ),
        GoRoute(
          path: subscription,
          name: 'subscription',
          builder: (context, state) => const SubscriptionPlansScreen(),
        ),
        GoRoute(
          path: addSchedule,
          name: 'addSchedule',
          builder: (context, state) {
            final meeting = state.extra as Meeting?;
            return AddScheduleScreen(meeting: meeting);
          },
        ),
        GoRoute(
          path: addTask,
          name: 'addTask',
          builder: (context, state) {
            final task = state.extra as Task?;
            return AddTaskScreen(editingTask: task);
          },
        ),
        GoRoute(
          path: analytics,
          name: 'analytics',
          builder: (context, state) => const AnalyticsScreen(),
        ),
        GoRoute(
          path: settings,
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: notifications,
          name: 'notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: profile,
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: security,
          name: 'security',
          builder: (context, state) => const SecurityScreen(),
        ),
      ],

      // Error handling
      errorBuilder:
          (context, state) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Page not found: ${state.matchedLocation}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go(home),
                    child: const Text('Go Home'),
                  ),
                ],
              ),
            ),
          ),

      // Debug logging (remove in production)
      debugLogDiagnostics: true,
    );
  }

  // String _getInitialRoute(BuildContext context) {
  //   if (firstOpen) {
  //     return splash;
  //   }

  //   final auth = context.read<AuthProvider>();
  //   if (!auth.isLoggedIn) {
  //     return login;
  //   }

  //   return home;
  // }
}
