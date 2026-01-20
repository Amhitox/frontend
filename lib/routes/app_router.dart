import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/managers/task_manager.dart';
import 'package:frontend/models/meeting.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/meeting_provider.dart';
import 'package:frontend/services/mail_service.dart';
import 'package:frontend/models/email_message.dart';
import 'package:provider/provider.dart';
import 'package:frontend/ui/screens/auth/resetpassword_screen.dart';
import 'package:frontend/ui/screens/auth/emailverification_screen.dart';
import 'package:frontend/ui/screens/mail/maildetails_screen.dart' as mailDetail;
import 'package:frontend/ui/screens/settings/setting_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ui/screens/welcome/home_screen.dart';
import '../ui/screens/auth/login_screen.dart';
import '../ui/screens/auth/signup_screen.dart';
import '../ui/screens/calendar/calendar_screen.dart';
import '../ui/screens/task/task_screen.dart';
import '../ui/screens/mail/mail_screen.dart';
import '../ui/screens/mail/composemail_screen.dart' as compose;


import '../ui/screens/welcome/current_plan_screen.dart';
import '../ui/screens/welcome/subscription_screen.dart';
import '../ui/screens/calendar/addschedule_screen.dart';
import '../ui/screens/task/addtask_screen.dart';
import '../ui/screens/analytic/analytic_screen.dart';
import '../ui/screens/welcome/notification_screen.dart';
import '../ui/screens/settings/profile_screen.dart';
import '../ui/screens/settings/security_screen.dart';
import '../ui/screens/welcome/splash_screen.dart';
import '../ui/screens/welcome/onboarding_screen.dart';
import '../ui/screens/auth/forgetpassword_screen.dart';
import '../models/task.dart';
import '../ui/screens/settings/priority_emails_screen.dart';
import '../ui/screens/settings/terms_screen.dart';
import '../ui/screens/settings/privacy_policy_screen.dart';
import '../ui/screens/settings/general_conditions_screen.dart';
import '../ui/screens/settings/support_screen.dart';
import '../ui/screens/welcome/access_gate_screen.dart';

class AppRoutes {
  static final AppRoutes _instance = AppRoutes._internal();
  factory AppRoutes() => _instance;
  AppRoutes._internal();
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
  static const String currentPlan = '/currentPlan';
  static const String addSchedule = '/addSchedule';
  static const String addTask = '/addTask';
  static const String analytics = '/analytics';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String security = '/security';
  static const String terms = '/terms';
  static const String privacy = '/privacy';
  static const String generalConditions = '/generalConditions';
  static const String accessGate = '/accessGate';
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static late SharedPreferences pref;
  bool firstOpen = true;
  List<Task> tasks = <Task>[];
  List<Meeting> meetings = <Meeting>[];
  
  AuthProvider? _authProvider;

  Future<void> init(AuthProvider authProvider) async {
    _authProvider = authProvider;
    pref = await SharedPreferences.getInstance();
    firstOpen = pref.getBool('firstOpen') ?? true;
  }

  GoRouter? _router;

  GoRouter get router {
    _router ??= _createRouter();
    return _router!;
  }

  GoRouter _createRouter() {
    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: splash,
      refreshListenable: _authProvider,
      redirect: (context, state) {
        final auth = _authProvider;
        if (auth == null) return null;

        final isLoggedIn = auth.isLoggedIn;
        final location = state.uri.toString();
        
        final isLoggingIn = location == login;
        final isSigningUp = location == signup;
        final isSplash = location == splash;
        final isOnboarding = location == onboarding;
        final isReset = location.startsWith('/__/auth/action') || location == forgetPassword;

        if (!isLoggedIn) {
          if (isLoggingIn || isSigningUp || isSplash || isOnboarding || isReset) {
            return null;
          }
          return login;
        }

        final canAccess = auth.canAccessApp;
        final isAccessGate = location == accessGate;
        final isSubscription = location == subscription;
        final isCallback = location == '/callback';

        if (!canAccess) {
             if (isAccessGate) return null;
             if (isSubscription) return null;
             if (isCallback) return null;
             
             return accessGate;
        }

        if (isAccessGate || isLoggingIn || isSplash) {
          return home;
        }

        return null;
      },
      routes: [
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
        GoRoute(
          path: accessGate,
          name: 'accessGate',
          builder: (context, state) => const AccessGateScreen(),
        ),
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
          path: '/__/auth/action',
          name: 'handleEmailRedirecting',
          builder: (context, state) {
            var token = state.uri.queryParameters['oobCode'];
            var mode = state.uri.queryParameters['mode'];
            if (mode == 'resetPassword') {
              return ResetPasswordScreen(token: token);
            } else if (mode == 'verifyEmail') {
              return EmailVerificationScreen(token: token);
            }
            return const LoginScreen();
          },
        ),

        GoRoute(
          path: '/callback',
          name: 'callback',
          builder: (context, state) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (!context.mounted) return;

              final callbackData = DeepLinkService.getPendingCallbackData();

              String? message;
              bool isError = false;

              try {
                final prefs = await SharedPreferences.getInstance();
                final userJson = prefs.getString('user');

                if (callbackData == null) {
                  print('⚠️ No callback data available');
                  message = '⚠️ No callback data received';
                  isError = true;
                } else if (userJson == null) {
                  print('❌ User not found in SharedPreferences');
                  message = '❌ Please log in first';
                  isError = true;
                } else {
                  final success = callbackData['success'] == true;
                  final email = callbackData['email'] as String?;
                  final error = callbackData['error'] as String?;

                  if (success && email != null) {
                    final userMap =
                        jsonDecode(userJson) as Map<String, dynamic>;
                    userMap['workEmail'] = email;

                    await prefs.setString('user', jsonEncode(userMap));

                    // Update AuthProvider in memory if possible
                    if (context.mounted) {
                      try {
                        final authProvider = context.read<AuthProvider>();
                        final updatedUser = User.fromJson(userMap);
                        authProvider.updateUserInSession(updatedUser);
                      } catch (e) {
                        debugPrint('⚠️ Could not update AuthProvider: $e');
                      }
                    }

                    print('✅ Gmail connected: $email');
                    message = '✅ Gmail connected: $email';
                    isError = false;
                  } else {
                    final errorMsg = error ?? 'Gmail connection failed';
                    print('❌ $errorMsg');
                    message = '❌ $errorMsg';
                    isError = true;
                  }
                }
              } catch (e, stackTrace) {
                debugPrint('Error in callback handler: $e');
                debugPrint('Stack trace: $stackTrace');
                message = '❌ Connection failed: $e';
                isError = true;
              }
              DeepLinkService.clearPendingCallbackData();

              await Future.delayed(const Duration(milliseconds: 300));

              if (context.mounted) {
                context.pushReplacement(
                  '/mail',
                  extra: {
                    'showSnackbar': true,
                    'message': message,
                    'isError': isError,
                  },
                );
              }
            });

            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        ),
        GoRoute(
          path: home,
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: calendar,
          name: 'calendar',
          builder: (context, state) {
            final date = state.extra as DateTime? ?? DateTime.now();
            final meetingProvider = context.read<MeetingProvider>();
            final dateString = date.toIso8601String().split('T').first;
            final meetings = meetingProvider.getMeetings(dateString);
            return CalendarPage(meetings: meetings, date: date);
          },
        ),
        GoRoute(
          path: '/task',
          name: 'task',
          builder: (context, state) {
            final date = state.extra as DateTime? ?? DateTime.now();
            final manager = TaskManager();
            if (!manager.isInitialized) {
              return TaskScreen(tasks: [], date: date);
            }
            final listenable = manager.listenable();
            if (listenable == null) {
              return TaskScreen(tasks: [], date: date);
            }
            return ValueListenableBuilder(
              valueListenable: listenable,
              builder: (context, Box<Task> box, _) {
                final cachedTasks =
                    box.values.where((task) {
                      if (task.dueDate == null) return false;
                      try {
                        final taskDate = DateTime.parse(task.dueDate!);
                        return taskDate.year == date.year &&
                            taskDate.month == date.month &&
                            taskDate.day == date.day;
                      } catch (e) {
                        return false;
                      }
                    }).toList();
                return TaskScreen(tasks: cachedTasks, date: date);
              },
            );
          },
        ),

        GoRoute(
          path: '/mail',
          name: 'mail',
          builder: (context, state) {
            return MailScreen(
              initialExtra: state.extra as Map<String, dynamic>?,
            );
          },
        ),
        GoRoute(
          path: maildetail,
          name: 'maildetail',
          builder: (context, state) {
            EmailMessage? email;
            String? audioUrl;
            bool autoPlay = false;

            if (state.extra is EmailMessage) {
              email = state.extra as EmailMessage;
            } else if (state.extra is Map<String, dynamic>) {
              final map = state.extra as Map<String, dynamic>;
              email = map['email'] as EmailMessage?;
              audioUrl = map['audioUrl'] as String?;
              autoPlay = map['autoPlay'] == true;
            }

            if (email == null) {
              return const MailScreen();
            }
            return mailDetail.MailDetailScreen(
              email: email, 
              audioUrl: audioUrl,
              autoPlay: autoPlay
            );
          },
        ),
        GoRoute(
          path: composemail,
          name: 'composemail',
          builder: (context, state) {
            compose.MailItem? mailItem;
            EmailMessage? draft;
            bool isFromAi = false;

            if (state.extra is compose.MailItem) {
              mailItem = state.extra as compose.MailItem;
            } else if (state.extra is EmailMessage) {
              draft = state.extra as EmailMessage;
            } else if (state.extra is Map<String, dynamic>) {
              final map = state.extra as Map<String, dynamic>;
              if (map['draft'] != null) {
                draft = map['draft'] as EmailMessage;
              }
              if (map['isFromAi'] == true) {
                isFromAi = true;
              }
            }

            return compose.ComposeMailScreen(
              editingMail: mailItem, 
              draft: draft,
              isFromAi: isFromAi,
            );
          },
        ),

        GoRoute(
          path: currentPlan,
          name: 'currentPlan',
          builder: (context, state) => const CurrentPlanScreen(),
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
        GoRoute(
          path: terms,
          name: 'terms',
          builder: (context, state) => const TermsScreen(),
        ),
        GoRoute(
          path: privacy,
          name: 'privacy',
          builder: (context, state) => const PrivacyPolicyScreen(),
        ),
        GoRoute(
          path: generalConditions,
          name: 'generalConditions',
          builder: (context, state) => const GeneralConditionsScreen(),
        ),
      GoRoute(
          path: '/settings/priority',
          name: 'priorityEmails',
          builder: (context, state) => const PriorityEmailsScreen(),
        ),
        GoRoute(
          path: '/support',
          name: 'support',
          builder: (context, state) => const SupportScreen(),
        ),

      ],
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
                    onPressed: () => context.push(home),
                    child: const Text('Go Home'),
                  ),
                ],
              ),
            ),
          ),
      debugLogDiagnostics: false,
    );
  }
}
