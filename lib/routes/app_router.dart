import 'package:flutter/material.dart';
import 'package:frontend/ui/screens/mail/maildetails_screen.dart' as mailDetail;
import 'package:frontend/ui/screens/settings/setting_screen.dart';
import 'package:go_router/go_router.dart';
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
  // Go Router configuration
  static final GoRouter router = GoRouter(
    // Initial route when app starts
    initialLocation: splash, // Start with login screen
    // Define all routes
    routes: [
      // Home Route
      GoRoute(
        path: home,
        name: 'home', // Optional: gives route a name
        builder: (BuildContext context, GoRouterState state) {
          return HomeScreen();
        },
      ),

      // Login Route
      GoRoute(
        path: login,
        name: 'login',
        builder: (BuildContext context, GoRouterState state) {
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: signup,
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: forgetPassword,
        name: 'forgetPassword',
        builder: (context, state) => ForgotPasswordScreen(),
      ),
      GoRoute(
        path: calendar,
        name: 'calendar',
        builder: (context, state) => CalendarPage(),
      ),
      GoRoute(
        path: task,
        name: 'task',
        builder: (context, state) => TaskScreen(),
      ),
      GoRoute(
        path: mail,
        name: 'mail',
        builder: (context, state) => MailScreen(),
      ),
      GoRoute(
        path: '/maildetail',
        builder: (context, state) {
          // Receive the single MailItem via `extra`
          final email = state.extra as MailItem;
          return mailDetail.MailDetailScreen(email: email);
        },
      ),
      GoRoute(
        path: composemail,
        name: 'composemail',
        builder: (context, state) => ComposeMailScreen(),
      ),
      GoRoute(
        path: subscription,
        name: 'subscription',
        builder: (context, state) => SubscriptionPlansScreen(),
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
        builder: (context, state) => AnalyticsScreen(),
      ),
      GoRoute(
        path: settings,
        name: 'settings',
        builder: (context, state) => SettingsScreen(),
      ),
      GoRoute(
        path: notifications,
        name: 'notifications',
        builder: (context, state) => NotificationsScreen(),
      ),
      GoRoute(
        path: profile,
        name: 'profile',
        builder: (context, state) => ProfileScreen(),
      ),
      GoRoute(
        path: security,
        name: 'security',
        builder: (context, state) => SecurityScreen(),
      ),
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (context, state) => SplashScreen(),
      ),
      GoRoute(
        path: onboarding,
        name: 'onboarding',
        builder: (context, state) => OnboardingScreen(),
      ),
    ],

    // Optional: Handle unknown routes
    errorBuilder:
        (context, state) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Page not found: ${state.matchedLocation}',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go(home),
                  child: Text('Go Home'),
                ),
              ],
            ),
          ),
        ),

    // Optional: Debug logging (remove in production)
    debugLogDiagnostics: true,
  );
}
