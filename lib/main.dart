import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/task_provider.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'utils/app_theme.dart';
import 'routes/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // mobile version
  await dotenv.load(fileName: '.env');
  // await dotenv.load();

  final authProvider = AuthProvider();
  await authProvider.init();
  await AppRoutes().init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(
          create: (_) => TaskProvider(dio: authProvider.dio),
        ),
        ChangeNotifierProvider(
          create: (_) => UserProvider(dio: authProvider.dio),
        ),
      ],
      child: MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final router = AppRoutes().createRouter(context);

    return MaterialApp.router(
      title: 'ELYO AI',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        FlutterQuillLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('fr')],
    );
  }
}
