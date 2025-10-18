import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:frontend/models/task.dart';
import 'package:frontend/models/taskpriority.dart';
import 'package:frontend/models/meeting.dart';
import 'package:frontend/models/meeting_location.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/task_provider.dart';
import 'package:frontend/providers/meeting_provider.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/providers/sub_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'utils/app_theme.dart';
import 'utils/localization.dart';
import 'routes/app_router.dart';
import 'services/mail_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(TaskPriorityAdapter());
  Hive.registerAdapter(MeetingAdapter());
  Hive.registerAdapter(MeetingLocationAdapter());
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

      _deepLinkService = DeepLinkService();
      await _deepLinkService!.initDeepLinks(
        onGmailConnected: (success, error, email) {
          print(
            '📨 Gmail connection callback: success=$success, email=$email, error=$error',
          );

          if (mounted && context.mounted) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted && context.mounted) {
                context.pushReplacement('/callback');
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

  @override
  void dispose() {
    _deepLinkService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final router = AppRoutes().createRouter(context);

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
