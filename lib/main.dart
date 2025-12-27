import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:frontend/models/task.dart';
import 'package:frontend/models/email_message.dart';
import 'package:frontend/models/taskpriority.dart';
import 'package:frontend/models/meeting.dart';
import 'package:frontend/models/meeting_location.dart';
import 'package:frontend/models/attendee.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/task_provider.dart';
import 'package:frontend/providers/meeting_provider.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/providers/sub_provider.dart';
import 'package:frontend/providers/analytic_provider.dart';
import 'package:frontend/providers/notification_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'utils/app_theme.dart';
import 'utils/localization.dart';
import 'routes/app_router.dart';
import 'services/mail_service.dart';
import 'services/notification_service.dart';
import 'providers/mail_provider.dart';
import 'package:frontend/providers/audio_provider.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📨 Background message received: ${message.messageId}');
}




Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize notification service
  await NotificationService().initialize();

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(TaskPriorityAdapter());
  Hive.registerAdapter(MeetingAdapter());
  Hive.registerAdapter(MeetingLocationAdapter());
  Hive.registerAdapter(AttendeeAdapter());
  await dotenv.load(fileName: '.env');
  Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']!;
  final authProvider = AuthProvider();
  await authProvider.init();
  await AppRoutes().init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(
          create: (_) => TaskProvider(dio: authProvider.dio),
        ),
        ChangeNotifierProvider(
          create: (_) => MeetingProvider(dio: authProvider.dio),
        ),
        ChangeNotifierProvider(
          create: (_) => UserProvider(dio: authProvider.dio),
        ),
        ChangeNotifierProvider(
          create: (_) => SubProvider(dio: authProvider.dio),
        ),
        ChangeNotifierProvider(
          create: (_) => AnalyticProvider(dio: authProvider.dio),
        ),
        ChangeNotifierProvider(
          create: (_) => MailProvider(dio: authProvider.dio),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(dio: authProvider.dio),
        ),
        ChangeNotifierProvider(create: (_) => AudioProvider()), // Register AudioProvider
      ],
      child: MainApp(),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  DeepLinkService? _deepLinkService;
  bool _isDeepLinkInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final languageProvider = context.read<LanguageProvider>();

      if (authProvider.user?.lang != null) {
        languageProvider.setLanguageFromUser(authProvider.user!.lang);
      }
      
      // Pre-fetch priority emails for UI
      if (authProvider.isLoggedIn) {
        final user = authProvider.user;
        if (user != null) {
           final userId = user.uid ?? user.id;
           if (userId != null) {
             context.read<UserProvider>().fetchPriorityEmails(userId);
           }
        }
        
        context.read<NotificationProvider>().fetchNotifications();
      }

      // Configure interaction handling
      await _setupInteractedMessage();

      // Set up foreground message handler for FCM
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        NotificationService().handleForegroundMessage(message);
      });

      // Renew Gmail Watch if logged in
      if (authProvider.isLoggedIn) {
        // Run in background, don't await strictly to not block UI
        MailService(dio: authProvider.dio).watchGmail();
      }

      _deepLinkService = DeepLinkService();
      await _deepLinkService!.initDeepLinks(
        onGmailConnected: (success, error, email) {
          print(
            '📨 Gmail connection callback: success=$success, email=$email, error=$error',
          );

          if (mounted && context.mounted) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                 final navContext = AppRoutes.navigatorKey.currentContext;
                 if (navContext != null) {
                   GoRouter.of(navContext).pushReplacement('/callback');
                 }
              }
            });
          }
        },
      );

      setState(() {
        _isDeepLinkInitialized = true;
      });

      print('✅ Deep link service initialized successfully');
    } catch (e) {
      print('❌ Error initializing deep link service: $e');
      setState(() {
        _isDeepLinkInitialized = true;
      });
    }
  }

  Future<void> _setupInteractedMessage() async {
    // 1. Get any messages which caused the application to open from a terminated state.
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // 2. Also handle any interaction when the app is in the background via a Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    debugPrint('🔔 Handling notification interaction: ${message.data}');
    
    final data = message.data;
    final type = data['notificationType'] ?? data['type'] ?? data['category']; // Check all possible keys
    final context = AppRoutes.navigatorKey.currentContext;

    if (context == null) {
      debugPrint('⚠️ Navigator context not available for notification navigation');
      return;
    }

    // Handle email notifications
    if (type == 'email' || type == 'email_new') {
      final audioUrl = data['audioUrl']; // "https://..." or null
      // Check both 'id' and 'emailId' keys
      final emailId = data['id'] ?? data['emailId']; 
      
      if (emailId != null) {
         // Create a stub email message
         final stubEmail = EmailMessage(
            id: emailId, 
            threadId: '', 
            sender: data['title'] ?? 'Loading...', 
            senderEmail: '', 
            subject: data['body']?.toString().split('\n').first ?? 'Loading...', 
            snippet: '', 
            body: '', 
            date: DateTime.now(), 
            isUnread: false, 
            labelIds: [], 
            hasAttachments: false,
         );
         
         final extra = {
           'email': stubEmail,
           'audioUrl': audioUrl,
           'autoPlay': audioUrl != null, // Auto-play if opened from background tap
         };
         
         context.push(AppRoutes.maildetail, extra: extra);
         print('🔔 Navigating to mail detail: emailId=$emailId');
      } else {
        // No specific email, go to mail list
        context.push(AppRoutes.mail);
        print('🔔 Navigating to mail list');
      }
    } 
    // Handle task notifications
    else if (type == 'task' || type == 'task_reminder') {
      final taskId = data['taskId'];
      // TODO: If taskId is provided, could navigate to specific task detail
      context.push(AppRoutes.task);
      print('🔔 Navigating to tasks (taskId: $taskId)');
    } 
    // Handle calendar/event notifications
    else if (type == 'event' || type == 'calendar_reminder' || type == 'calendar') {
      final eventId = data['eventId'];
      // TODO: If eventId is provided, could navigate to specific event detail
      context.push(AppRoutes.calendar);
      print('🔔 Navigating to calendar (eventId: $eventId)');
    }
    // Default: go to notifications screen
    else {
      context.push(AppRoutes.notifications);
      print('🔔 Unknown notification type: $type, navigating to notifications');
    }
  }

  @override
  void dispose() {
    _deepLinkService?.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final router = AppRoutes().router;

    return MaterialApp.router(
      title: 'Aixy',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.themeMode,
      locale: languageProvider.locale,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('fr')],
    );
  }
}
