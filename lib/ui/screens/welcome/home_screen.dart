import 'package:flutter/material.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/task_provider.dart';
import 'package:frontend/providers/meeting_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:frontend/services/connectivity_service.dart';

import 'package:frontend/services/firabasesync_service.dart';
import 'package:frontend/ui/widgets/dragable_menu.dart';
import 'package:frontend/ui/widgets/side_menu.dart';
import 'package:frontend/utils/localization.dart';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/ai_response.dart';
import 'package:frontend/models/email_message.dart';
import 'package:frontend/services/ai_service.dart';
import 'package:frontend/services/transcription_service.dart';
import 'package:frontend/routes/app_router.dart';

import 'package:frontend/utils/quota_dialog.dart';
import 'package:frontend/providers/sub_provider.dart';
import 'package:frontend/ui/widgets/side_menu_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isListening = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _breathingController;
  late AnimationController _waveController;
  late AnimationController _subtleController;
  late AnimationController _pulseController;
  late AnimationController _orbitalController;
  late AnimationController _glowController;
  late ConnectivityService connectivityService;
  late FirebaseSyncService firebaseSyncService;
  
  late TranscriptionService _transcriptionService;
  late AiService _aiService;
  bool _isProcessing = false;
  String? _transcribedText;
  String _typewriterText = '';
  bool _isOnline = true;


  // Debug - Audio Playback


  @override
  void initState() {
    super.initState();
    _transcriptionService = TranscriptionService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _subtleController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _orbitalController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _breathingController.repeat(reverse: true);
    _subtleController.repeat();
    _pulseController.repeat(reverse: true);
    _orbitalController.repeat();
    _glowController.repeat(reverse: true);

    Connectivity().checkConnectivity().then((results) {
      final isConnected = results.any((r) => r != ConnectivityResult.none);
      if (mounted) setState(() => _isOnline = isConnected);
    });

    Connectivity().onConnectivityChanged.listen((results) {
      final isConnected = results.any((r) => r != ConnectivityResult.none);
      if (mounted) setState(() => _isOnline = isConnected);
    });
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _waveController.dispose();
    _subtleController.dispose();
    _pulseController.dispose();
    _orbitalController.dispose();
    _glowController.dispose();
    _transcriptionService.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isProcessing) return; // Ignore taps while processing

    setState(() => _isListening = !_isListening);
    
    if (_isListening) {
      _waveController.repeat();
      try {
        await _transcriptionService.startRecording(
          onSilenceDetected: () {
            // This runs on a timer/background isolate usually, safeguard with mounted check
            if (mounted) {
              print('🎙️ Silence detected callback received.');
              // We need to stop recording. _toggleListening handles the toggle logic.
              // But we are already in "Listening" state. calling it will flip it to false/stop.
              _toggleListening(); 
            }
          },
        );
      } catch (e) {
        print('Error starting recording: $e');
        if (mounted) {
          setState(() => _isListening = false);
          _waveController.stop();
          _waveController.reset();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not access microphone: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      _waveController.stop();
      _waveController.reset();
      
      try {
        final path = await _transcriptionService.stopRecording();
        if (path != null && mounted) {
          _processAudio(path);
        }
      } catch (e) {
        print('Error stopping recording: $e');
      }
    }
  }

  Future<void> _processAudio(String path) async {
    if (!mounted) return;
    setState(() {
       _isProcessing = true;
    });
    
    // Optional: Cancelable operation? For now just show processing state.
    
    try {
      final text = await _transcriptionService.transcribe(path);
      
      if (text != null && text.isNotEmpty) {
        if (mounted) {
           // Start typewriter effect
           _transcribedText = text;
           _typewriterText = ''; // Reset
           setState(() {});
           
           final words = text.split(' ');
           for (int i = 0; i < words.length; i++) {
             if (!mounted || !_isProcessing) break;
             await Future.delayed(const Duration(milliseconds: 200)); 
             setState(() {
               _typewriterText += '${words[i]} ';
             });
           }

           await _processAiRequest(text);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not understand audio'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _transcribedText = null;
          _typewriterText = '';
        });
      }
    }
  }



  Future<void> _processAiRequest(String text) async {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id ?? 'guest';
    
    // Calculate timezone offset
    final offset = DateTime.now().timeZoneOffset;
    final timezoneOffset = _formatTimezoneOffset(offset);
    
    final response = await _aiService.processQuery(text, userId, timezoneOffset);
    if (!mounted) return;

    if (response != null) {
      // 1. Construct concise message and refresh data
      // 1. Process actions
      String message = '';
      bool taskUpdated = false;
      bool eventUpdated = false;

      if (response.actions != null && response.actions!.isNotEmpty) {
        for (final action in response.actions!) {
           // Task Actions
           if (action.type == 'task') {
             if (action.deletedId != null) {
               await context.read<TaskProvider>().deleteTask(action.deletedId!);
               message += 'Task deleted. ';
             } else {
               taskUpdated = true;
               message += 'Task processed. '; 
             }
           }
           
           // Event Actions
           if (action.type == 'event') {
             if (action.deletedId != null) {
               await context.read<MeetingProvider>().deleteMeeting(action.deletedId!);
                message += 'Meeting deleted. ';
             } else {
               eventUpdated = true;
               message += 'Meeting scheduled. ';
             }
           }
           
           if (action.type == 'email') {
              message += 'Email drafted. ';
           }
           
           if (action.type == 'list_tasks') {
              message += 'Opening tasks... ';
              if (mounted) context.pushNamed('task');
           }
           
           if (action.type == 'list_events') {
              message += 'Opening calendar... ';
              if (mounted) context.pushNamed('calendar');
           }

           // Quota Check
           if (action.quotaExceeded == true) {
             if (mounted) {
               QuotaDialog.show(context, message: action.error ?? 'Quota exceeded');
             }
             return; // Stop processing further actions
           }
        }
        
        // Sync if needed
        if (taskUpdated && mounted) context.read<TaskProvider>().forceSync();
        if (eventUpdated && mounted) context.read<MeetingProvider>().forceSync();

        // Refresh quota status
        if (mounted) context.read<SubProvider>().fetchQuotaStatus();
      }
      
      if (message.isEmpty && response.summary != null) {
         message = response.summary!;
      }

      if (message.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
               message.trim(),
               style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green, // Use green for success
          ),
        );
      }

      // 2. Handle generated email
      if (response.generatedEmail != null) {
        final emailData = response.generatedEmail!;
        final draft = EmailMessage(
          id: 'ai_draft_${DateTime.now().millisecondsSinceEpoch}',
          threadId: '',
          sender: 'Me', 
          senderEmail: '',
          subject: emailData.subject ?? '',
          snippet: emailData.body ?? '',
          body: emailData.body ?? '',
          date: DateTime.now(),
          isUnread: false,
          labelIds: [],
          hasAttachments: false,
        );
      context.push(
        AppRoutes.composemail, 
        extra: {
          'draft': draft,
          'isFromAi': response.isFromAi ?? true,
        }
      );
      return;
    }

      // 3. Actions (tasks/events) - Status is "success" so we can refresh
      if (response.actions != null && response.actions!.isNotEmpty) {
         // Refresh data providers basically
         // We can do this silently in background
         // Assuming backend handled DB updates, local providers need fetch
         // But TaskProvider and MeetingProvider handle local DB + Sync
         // connectivityService.syncService.fullSync(context); // This might be too heavy?
         // Let's rely on standard refresh or next load
      }
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI request failed'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
       );
    }
  }

  Future<void> _initializeServices() async {
    try {
      final authProvider = context.read<AuthProvider>();
      // Initialize AiService with AuthProvider's dio
      _aiService = AiService(dio: authProvider.dio);

      final taskProvider = context.read<TaskProvider>();
      final meetingProvider = context.read<MeetingProvider>();
      if (authProvider.user?.id != null) {
        await taskProvider.init(authProvider.user!.id!);
        await meetingProvider.init(authProvider.user!.id!);
        firebaseSyncService = FirebaseSyncService(
          userId: authProvider.user!.id!,
        );
        connectivityService = ConnectivityService(
          syncService: firebaseSyncService,
          onConnectivityRestored: () {
            if (mounted) {
              firebaseSyncService.fullSync(
                context.read<TaskProvider>(),
                context.read<MeetingProvider>(),
              );
            }
          },
        );
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargeScreen = screenSize.width > 900;
    return Scaffold(
      key: _scaffoldKey,
      drawer: const SideMenu(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            stops: [0.0, 0.4],
          ),
        ),
        child: Stack(
          children: [
            _buildBackgroundElements(screenSize),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    children: [
                      _buildExecutiveAppBar(isTablet, isLargeScreen),
                      Expanded(
                        child: _buildMainContent(
                          constraints,
                          isTablet,
                          isLargeScreen,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const DraggableMenu(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundElements(Size screenSize) {
    return Stack(
      children: [
        ...List.generate(
          20,
          (index) => _buildFloatingParticle(index, screenSize),
        ),
        _buildOrbitalElements(screenSize),
        _buildAmbientGlow(screenSize),
      ],
    );
  }

  Widget _buildFloatingParticle(int index, Size screenSize) {
    return AnimatedBuilder(
      animation: _subtleController,
      builder: (context, child) {
        final offset = (_subtleController.value + (index * 0.05)) % 1.0;
        final horizontalOffset = math.sin(offset * 2 * math.pi + index) * 50;
        final baseX = (index * 67.0) % screenSize.width;
        return Positioned(
          left: (baseX + horizontalOffset).clamp(0, screenSize.width - 10),
          top: screenSize.height * offset,
          child: Container(
            width: 1.5 + (index % 4) * 0.5,
            height: 1.5 + (index % 4) * 0.5,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(
                alpha: 0.05 + (math.sin(offset * math.pi) * 0.05),
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  blurRadius: 4,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrbitalElements(Size screenSize) {
    return AnimatedBuilder(
      animation: _orbitalController,
      builder: (context, child) {
        return Stack(
          children: List.generate(3, (index) {
            final angle =
                (_orbitalController.value * 2 * math.pi) +
                (index * 2 * math.pi / 3);
            final radius = 120.0 + (index * 40);
            final centerX = screenSize.width / 2;
            final centerY = screenSize.height / 2;
            return Positioned(
              left: centerX + math.cos(angle) * radius - 3,
              top: centerY + math.sin(angle) * radius - 3,
              child: Container(
                width: 6.0 - index,
                height: 6.0 - index,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3 - index * 0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildAmbientGlow(Size screenSize) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Positioned(
          top: screenSize.height * 0.3,
          left: screenSize.width * 0.2,
          child: Container(
            width: screenSize.width * 0.6,
            height: screenSize.height * 0.4,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(
                    alpha: 0.05 + (_glowController.value * 0.03),
                  ),
                  Colors.transparent,
                ],
                stops: [0.0, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExecutiveAppBar(bool isTablet, bool isLargeScreen) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isLargeScreen
            ? 32
            : isTablet
            ? 28
            : 24,
        20,
        isLargeScreen
            ? 32
            : isTablet
            ? 28
            : 24,
        0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildMenu(isTablet),
          _buildPremiumBadge(isTablet, isLargeScreen),
        ],
      ),
    );
  }


  Widget _buildMenu(bool isTablet) {
    return SideMenuButton(isTablet: isTablet);
  }

  Widget _buildPremiumBadge(bool isTablet, bool isLargeScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLargeScreen ? 18 : isTablet ? 16 : 14,
        vertical: isTablet ? 10 : 8,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9966), Color(0xFFFF5E62)], // Sunset orange gradient
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5E62).withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.science_rounded,
            color: Colors.white,
            size: isTablet ? 16 : 14,
          ),
          SizedBox(width: isTablet ? 8 : 6),
          Text(
            'BETA',
            style: TextStyle(
              color: Colors.white,
              fontSize: isLargeScreen ? 13 : isTablet ? 12 : 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(
    BoxConstraints constraints,
    bool isTablet,
    bool isLargeScreen,
  ) {
    final spacing =
        isLargeScreen
            ? 80.0
            : isTablet
            ? 70.0
            : 60.0;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: constraints.maxHeight),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(height: spacing * 0.5),
          _buildWelcomeSection(isTablet, isLargeScreen),
          _buildCentralMicrophone(isTablet, isLargeScreen),
           if (_isProcessing && _transcribedText != null)
             _buildTranscribedText(isTablet),
          _buildVoiceIndicator(isTablet),

          // _buildQuickActions(isTablet, isLargeScreen),
          SizedBox(height: spacing * 0.3),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(bool isTablet, bool isLargeScreen) {
    final user = context.watch<AuthProvider>().user;
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal:
            isLargeScreen
                ? 60
                : isTablet
                ? 50
                : 40,
      ),
      child: Column(
        children: [
          Text(
            _getGreeting(),
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize:
                  isLargeScreen
                      ? 20
                      : isTablet
                      ? 18
                      : 16,
              fontWeight: FontWeight.w300,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 6),
          ShaderMask(
            shaderCallback:
                (bounds) => LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.onSurface,
                    Theme.of(context).colorScheme.primary,
                  ],
                ).createShader(bounds),
            child: Text(
              '${user?.firstName ?? 'test'} ${user?.lastName ?? 'test'}',
              style: TextStyle(
                color: Colors.white,
                fontSize:
                    isLargeScreen
                        ? 28
                        : isTablet
                        ? 26
                        : 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20 : 16,
              vertical: isTablet ? 10 : 8,
            ),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).readyToAssistYou,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.8),
                    fontSize: isTablet ? 14 : 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppLocalizations.of(context).goodMorning;
    if (hour < 17) return AppLocalizations.of(context).goodAfternoon;
    return AppLocalizations.of(context).goodEvening;
  }

  Widget _buildCentralMicrophone(bool isTablet, bool isLargeScreen) {
    final micSize =
        isLargeScreen
            ? 130.0
            : isTablet
            ? 120.0
            : 110.0;
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_isOnline)
          AnimatedBuilder(
          animation: _breathingController,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: 1.0 + (_breathingController.value * 0.15),
                  child: Container(
                    width: micSize * 1.8,
                    height: micSize * 1.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(
                          alpha: 0.1 - (_breathingController.value * 0.05),
                        ),
                        width: 1,
                      ),
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 1.0 + (_breathingController.value * 0.12),
                  child: Container(
                    width: micSize * 1.6,
                    height: micSize * 1.6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(
                          alpha: 0.15 - (_breathingController.value * 0.07),
                        ),
                        width: 1,
                      ),
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 1.0 + (_breathingController.value * 0.08),
                  child: Container(
                    width: micSize * 1.4,
                    height: micSize * 1.4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(
                          alpha: 0.2 - (_breathingController.value * 0.09),
                        ),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        GestureDetector(
          onTap: () {
             if (!_isOnline) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context).offlineMessage),
                  duration: const Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            _toggleListening();
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            width: micSize,
            height: micSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: !_isOnline ? Colors.grey.withOpacity(0.3) : null,
              gradient: !_isOnline ? null : (_isProcessing 
                  ? LinearGradient(
                      colors: [Colors.grey.shade400, Colors.grey.shade600],
                    )
                  : (_isListening
                      ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.8),
                        ],
                      )
                      : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.15),
                          Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.08),
                        ],
                      ))),
              border: Border.all(
                color: !_isOnline 
                    ? Colors.grey 
                    : (_isListening
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.25)),
                width: _isListening ? 2 : 1.5,
              ),
              boxShadow:
                  _isListening && _isOnline
                      ? [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 25,
                          spreadRadius: 3,
                        ),
                      ]
                      : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 15,
                          offset: Offset(0, 8),
                        ),
                      ],
            ),
            child: _isProcessing 
                ? const SizedBox(
                    width: 24, 
                    height: 24, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                : Icon(
                    _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    size: isTablet ? 40 : 36,
                    color: !_isOnline 
                        ? Colors.grey 
                        : (_isListening
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85)),
                  ),
            ),
          ),
      ],
    );
  }

  Widget _buildVoiceIndicator(bool isTablet) {
    return SizedBox(
      height: isTablet ? 60 : 50,
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(9, (index) {
              double height =
                  _isListening
                      ? 4 +
                          math.sin(
                                (_waveController.value * 3 * math.pi) +
                                    (index * 0.5),
                              ) *
                              (isTablet ? 12 : 10)
                      : 3;
              return Container(
                width: isTablet ? 6 : 5,
                height: height.abs(),
                margin: EdgeInsets.symmetric(horizontal: isTablet ? 4 : 3),
                decoration: BoxDecoration(
                  gradient:
                      _isListening
                          ? LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.9),
                              Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.6),
                            ],
                          )
                          : LinearGradient(
                            colors: [
                              Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.3),
                              Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.1),
                            ],
                          ),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildTranscribedText(bool isTablet) {
    return FadeTransition(
      opacity: _glowController, 
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        margin: const EdgeInsets.only(top: 10, bottom: 10),
        child: Text(
          '"$_typewriterText"',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }



  String _formatTimezoneOffset(Duration offset) {
    final totalMinutes = offset.inMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes.remainder(60).abs();
    final sign = totalMinutes >= 0 ? '+' : '-';
    return '$sign${hours.abs().toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}
