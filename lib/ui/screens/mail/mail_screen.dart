import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/ui/widgets/dragable_menu.dart';
import 'package:frontend/ui/widgets/side_menu.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/services/mail_service.dart';
import 'package:frontend/models/email_message.dart';
import 'package:frontend/services/notification_service.dart';
import 'package:frontend/providers/mail_provider.dart';
import 'package:frontend/ui/screens/mail/skeleton_mail_loader.dart';
import 'dart:async'; // For StreamSubscription
import 'package:provider/provider.dart';
import 'package:frontend/utils/localization.dart';

class MailScreen extends StatefulWidget {
  final Map<String, dynamic>? initialExtra;

  const MailScreen({super.key, this.initialExtra});
  @override
  _MailScreenState createState() => _MailScreenState();
}

class _MailScreenState extends State<MailScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  List<EmailMessage> _emails = [];
  String? _nextPageToken;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;

  bool _isCheckingConnection = true;
  bool _hasInitiallyLoaded = false;

  String _selectedFilter = 'Primary';
  final List<String> _filters = [
    'Primary',
    'Sent',
    'Drafts',
    'Important',
    'Spam',
    'Trash',
    'Other',
  ];

  bool _hasShownSnackbar = false;
  Stream<List<EmailMessage>>? _inboxStream;
  StreamSubscription? _notificationSub;
  late ScrollController _scrollController;
  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    if (widget.initialExtra != null &&
        widget.initialExtra!['showSnackbar'] == true &&
        !_hasShownSnackbar) {
      final message = widget.initialExtra!['message'] as String?;
      final isError = widget.initialExtra!['isError'] == true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: isError ? Colors.red : Colors.green,
              duration: Duration(seconds: isError ? 5 : 3),
            ),
          );
          _hasShownSnackbar = true;
        }
      });
    }

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();

    // Load emails via provider for All filters
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkConnectionAndLoadEmails();
    });
    
    // Listen for incoming notifications to refresh list active filter
    _notificationSub = NotificationService().messageStream.listen((message) {
      // Check if notification is related to Email
      final data = message.data;
      final notification = message.notification;
      
      bool isEmail = false;
      
      // Check data payload first (more reliable if backend sets type)
      if (data.isNotEmpty) {
        final type = data['type']?.toString().toLowerCase();
        final category = data['category']?.toString().toLowerCase();
        if (type == 'email' || type == 'gmail' || 
            category == 'email' || category == 'gmail' ||
            data.containsKey('emailId') || data.containsKey('threadId')) {
          isEmail = true;
        }
      }

      // Fallback check on notification content
      if (!isEmail && notification != null) {
        final title = notification.title?.toLowerCase() ?? '';
        final body = notification.body?.toLowerCase() ?? '';
        if (title.contains('email') || title.contains('gmail') || 
            body.contains('email') || body.contains('gmail')) {
          isEmail = true;
        }
      }

      if (isEmail) {
         context.read<MailProvider>().loadEmails(filter: _selectedFilter, forceRefresh: true);
      }
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _slideController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _notificationSub?.cancel();
    super.dispose();
  }

  List<EmailMessage> get _filteredEmails {
    final provider = context.read<MailProvider>();
    final emails = provider.getEmailsForFilter(_selectedFilter);
    final query = _searchController.text.toLowerCase();
    
    if (query.isNotEmpty) {
      return emails.where((email) {
        return email.sender.toLowerCase().contains(query) ||
            email.subject.toLowerCase().contains(query) ||
            email.snippet.toLowerCase().contains(query);
      }).toList();
    }
    return emails;
  }

  String _getBackendType(String filter) {
    switch (filter) {
      case 'Primary':
        return 'primary';
      case 'Sent':
        return 'sent';
      case 'Drafts':
        return 'drafts';
      case 'Important':
        return 'important';
      case 'Trash':
        return 'trash';
      case 'Spam':
        return 'spam';
      case 'Other':
        return 'other';
      default:
        return 'primary';
    }
  }

  String _getLocalizedFilterName(BuildContext context, String filter) {
    final loc = AppLocalizations.of(context)!;
    switch (filter) {
      case 'Primary': return loc.primary;
      case 'Sent': return loc.sent;
      case 'Drafts': return loc.drafts;
      case 'Important': return loc.important;
      case 'Trash': return loc.trash;
      case 'Spam': return loc.spam;
      case 'Other': return loc.other;
      default: return filter;
    }
  }

  Future<void> _checkConnectionAndLoadEmails() async {
    final provider = context.read<MailProvider>();
    await provider.checkConnection();
    
    if (provider.isConnected) {
        if (!_hasInitiallyLoaded) {
          provider.loadEmails(filter: _selectedFilter);
          _hasInitiallyLoaded = true;
        }
    }
    
    setState(() {
       _isCheckingConnection = false;
    });
  }

  EmailMessage _parseEmailMessage(Map<String, dynamic> data) {
    final headers = data['headers'] as Map<String, dynamic>? ?? {};

    String sender = 'Unknown Sender';
    String senderEmail = '';

    final fromHeader = headers['from'] as String? ?? '';
    if (fromHeader.isNotEmpty) {
      if (fromHeader.contains('<') && fromHeader.contains('>')) {
        final parts = fromHeader.split('<');
        sender = parts[0].trim();
        senderEmail = parts[1].replaceAll('>', '').trim();
      } else {
        senderEmail = fromHeader;
        sender = fromHeader.split('@').first;
      }
    }

    final subject = headers['subject'] as String? ?? '(No Subject)';

    final snippet = data['snippet'] as String? ?? '';
    final body = data['body'] as String? ?? snippet;

    DateTime date = DateTime.now();
    final dateString = data['date'] as String? ?? headers['date'] as String?;
    if (dateString != null) {
      try {
        date = DateTime.parse(dateString);
      } catch (e) {
        print('❌ Error parsing date: $dateString');
      }
    }

    final labelIds = data['labelIds'] as List<dynamic>? ?? [];
    final isUnread = labelIds.contains('UNREAD');

    final hasAttachments = data['hasAttachments'] == true;

    // Create EmailHeaders object
    final emailHeaders = EmailHeaders(
      subject: headers['subject'] as String?,
      from: headers['from'] as String?,
      to: headers['to'] as String?,
      date: headers['date'] as String?,
    );

    return EmailMessage(
      id: data['id'] as String? ?? '',
      threadId: data['threadId'] as String? ?? data['id'] as String? ?? '',
      draftId: data['draftId'] as String?,
      sender: sender,
      senderEmail: senderEmail,
      subject: subject,
      snippet: snippet,
      body: body,
      date: date,
      isUnread: isUnread,
      labelIds: labelIds.map((e) => e.toString()).toList(),
      hasAttachments: hasAttachments,
      attachments: null,
      headers: emailHeaders,
    );
  }

  Future<void> _loadMoreEmails() async {
    // Rely on provider's loadMore
    await context.read<MailProvider>().loadMore(filter: _selectedFilter);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreEmails();
    }
  }

  Future<void> _deleteEmail(EmailMessage email) async {
    try {
      final success = await context.read<MailProvider>().deleteEmail(email.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.emailDeletedSuccess),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.emailDeleteFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.emailDeleteError}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAsRead(EmailMessage email) async {
    try {
      await context.read<MailProvider>().markAsRead(email.id);
    } catch (e) {
      print('❌ Error marking email as read: $e');
    }
  }

  Future<void> _markAsUnread(EmailMessage email) async {
    try {
      await context.read<MailProvider>().markAsUnread(email.id);
    } catch (e) {
      print('❌ Error marking email as unread: $e');
    }
  }

  void _showEmailContextMenu(
    EmailMessage email,
    bool isTablet,
    bool isLargeScreen,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    email.isUnread
                        ? Icons.mark_email_read_rounded
                        : Icons.mark_email_unread_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    email.isUnread ? AppLocalizations.of(context)!.markAsRead : AppLocalizations.of(context)!.markAsUnread,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    if (email.isUnread) {
                      _markAsRead(email);
                    } else {
                      _markAsUnread(email);
                    }
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                  ),
                  title: Text(AppLocalizations.of(context)!.delete),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteEmail(email);
                  },
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargeScreen = screenSize.width > 900;
    return Scaffold(
      drawer: const SideMenu(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
              Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    _buildHeader(isTablet, isLargeScreen),
                    if (context.watch<MailProvider>().isConnected) ...[
                      _buildFilterTabs(isTablet, isLargeScreen),
                      _buildQuickStats(isTablet, isLargeScreen),
                    ],
                    Expanded(child: _buildMainContent(isTablet, isLargeScreen)),
                  ],
                ),
              ),
            ),
            const DraggableMenu(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTablet, bool isLargeScreen) {
    return Padding(
      padding: EdgeInsets.all(
        isLargeScreen
            ? 24
            : isTablet
            ? 20
            : 16,
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState:
                  _isSearching
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
              firstChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getLocalizedFilterName(context, _selectedFilter),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize:
                          isLargeScreen
                              ? 32
                              : isTablet
                              ? 30
                              : 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_filteredEmails.length} ${AppLocalizations.of(context)!.messages}',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: isTablet ? 16 : 14,
                    ),
                  ),
                ],
              ),
              secondChild: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() {}),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.searchMail,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.1),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: isTablet ? 12 : 8,
                    horizontal: isTablet ? 20 : 16,
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: isTablet ? 16 : 14,
                ),
              ),
            ),
          ),
          SizedBox(width: isTablet ? 12 : 8),
          _buildHeaderButton(
            _isSearching ? Icons.close : Icons.search_rounded,
            () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
            Theme.of(context),
            isTablet,
          ),
          SizedBox(width: isTablet ? 12 : 8),
          _buildHeaderButton(
            Icons.add_rounded,
            () => context.pushNamed('composemail'),
            Theme.of(context),
            isTablet,
          ),
          SizedBox(width: isTablet ? 12 : 8),
          // _buildHeaderButton(
          //   Icons.link_rounded,
          //   () async {
          //     final auth = context.read<AuthProvider>();
          //     final mailService = MailService(dio: auth.dio);
          //     final res = await mailService.connect();
          //     if (!mounted) return;
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       SnackBar(
          //         content: Text(
          //           res == null ? 'Opening Gmail connect…' : 'Connect failed',
          //         ),
          //       ),
          //     );
          //   },
          //   Theme.of(context),
          //   isTablet,
          // ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(
    IconData icon,
    VoidCallback onTap,
    ThemeData theme,
    bool isTablet,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          width: isTablet ? 48 : 40,
          height: isTablet ? 48 : 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: isTablet ? 22 : 18,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs(bool isTablet, bool isLargeScreen) {
    return Container(
      height: isTablet ? 60 : 50,
      margin: EdgeInsets.symmetric(
        horizontal:
            isLargeScreen
                ? 24
                : isTablet
                ? 20
                : 16,
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () {
              if (_selectedFilter != filter) {
                setState(() => _selectedFilter = filter);
                context.read<MailProvider>().loadEmails(filter: filter);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: isTablet ? 16 : 12),
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 20 : 16,
                vertical: isTablet ? 12 : 8,
              ),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.15)
                        : Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected
                          ? Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.3)
                          : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  _getLocalizedFilterName(context, filter),
                  style: TextStyle(
                    color:
                        isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickStats(bool isTablet, bool isLargeScreen) {
    // Watch provider to get real-time stats
    final mailProvider = context.watch<MailProvider>();
    final emails = mailProvider.getEmailsForFilter(_selectedFilter);
    
    return Container(
      margin: EdgeInsets.fromLTRB(
        isLargeScreen
            ? 24
            : isTablet
            ? 20
            : 16,
        isTablet ? 20 : 16,
        isLargeScreen
            ? 24
            : isTablet
            ? 20
            : 16,
        isTablet ? 12 : 8,
      ),
      child:
          isLargeScreen
              ? Row(
                children: [
                   Expanded(
                    child: _buildStatChip(
                      '${emails.where((e) => e.isUnread).length}',
                      AppLocalizations.of(context)!.unread,
                      Colors.blue,
                      isTablet,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatChip(
                      '${emails.where((e) => e.isImportant).length}',
                      AppLocalizations.of(context)!.important,
                      Colors.red,
                      isTablet,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatChip(
                      '${emails.length}',
                      AppLocalizations.of(context)!.total,
                      Colors.green,
                      isTablet,
                    ),
                  ),
                ],
              )
              : Row(
                children: [
                  _buildStatChip(
                    '${emails.where((e) => e.isUnread).length}',
                    AppLocalizations.of(context)!.unread,
                    Colors.blue,
                    isTablet,
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  _buildStatChip(
                    '${emails.where((e) => e.isImportant).length}',
                    AppLocalizations.of(context)!.important,
                    Colors.red,
                    isTablet,
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  _buildStatChip(
                    '${emails.length}',
                    AppLocalizations.of(context)!.total,
                    Colors.green,
                    isTablet,
                  ),
                ],
              ),
    );
  }

  Widget _buildStatChip(
    String count,
    String label,
    Color color,
    bool isTablet,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: isTablet ? 10 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isTablet ? 8 : 6,
            height: isTablet ? 8 : 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(isTablet ? 4 : 3),
            ),
          ),
          SizedBox(width: isTablet ? 8 : 6),
          Text(
            count,
            style: TextStyle(
              color: color,
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: isTablet ? 6 : 4),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: isTablet ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isTablet, bool isLargeScreen) {
    if (_isCheckingConnection) {
      return _buildLoadingState();
    }

    // Watch provider state
    final mailProvider = context.watch<MailProvider>();
    final emails = mailProvider.getEmailsForFilter(_selectedFilter);
    final isLoading = mailProvider.isLoading;
    final error = mailProvider.error;
    final isConnected = mailProvider.isConnected;

    if (!isConnected) {
      return _buildConnectView(isTablet, isLargeScreen);
    }

    if (isLoading && emails.isEmpty) {
      return _buildLoadingState();
    }

    if (error != null && emails.isEmpty) {
      return _buildErrorState(isTablet, isLargeScreen);
    }

    if (emails.isEmpty && !isLoading) {
      return _buildEmptyState(isTablet, isLargeScreen);
    }

    return _buildMailList(isTablet, isLargeScreen);
  }



  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.loading,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectView(bool isTablet, bool isLargeScreen) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 32 : 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context)!.connectEmailAccount,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 24,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: [
                  _buildProviderCard(
                    'Gmail',
                    Icons.mail_outline_rounded,
                    Colors.red,
                    () async {
                      final provider = context.read<MailProvider>();
                      await provider.setProvider('gmail');
                      final res = await provider.connectGmail();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            (res == null || (res is Map && res['authUrl'] != null))
                                ? 'Opening Gmail connect…'
                                : 'Connect failed',
                          ),
                        ),
                      );
                    },
                    isTablet,
                  ),
                  _buildProviderCard(
                    'Outlook',
                    Icons.window_sharp, // Microsoft-ish icon
                    Colors.blue,
                    () async {
                      final provider = context.read<MailProvider>();
                      await provider.setProvider('outlook');
                      final res = await provider.connectOutlook();
                      if (!mounted) return;
                     // Assuming connectOutlook also returns authUrl or similar map
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            (res == null || (res is Map && res['authUrl'] != null))
                                ? 'Opening Outlook connect…'
                                : 'Connect failed',
                          ),
                        ),
                      );
                    },
                    isTablet,
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderCard(
    String name,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isTablet,
  ) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: isTablet ? 200 : 160,
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: color),
               ),
               const SizedBox(height: 16),
               Text(
                 name,
                 style: theme.textTheme.titleMedium?.copyWith(
                   fontWeight: FontWeight.bold,
                 ),
               ),
               const SizedBox(height: 8),
               Text(
                 'Connect $name',
                 style: theme.textTheme.bodySmall?.copyWith(
                   color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isTablet, bool isLargeScreen) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          isLargeScreen
              ? 48
              : isTablet
              ? 32
              : 24,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size:
                  isLargeScreen
                      ? 80
                      : isTablet
                      ? 64
                      : 48,
            ),
            SizedBox(
              height:
                  isLargeScreen
                      ? 24
                      : isTablet
                      ? 20
                      : 16,
            ),
            Text(
              AppLocalizations.of(context)!.somethingWentWrong,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize:
                    isLargeScreen
                        ? 24
                        : isTablet
                        ? 22
                        : 20,
              ),
            ),
            SizedBox(
              height:
                  isLargeScreen
                      ? 12
                      : isTablet
                      ? 10
                      : 8,
            ),
            Text(
              context.watch<MailProvider>().error ?? 'Failed to load emails',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize:
                    isLargeScreen
                        ? 16
                        : isTablet
                        ? 15
                        : 14,
              ),
            ),
            SizedBox(
              height:
                  isLargeScreen
                      ? 24
                      : isTablet
                      ? 20
                      : 16,
            ),
            ElevatedButton.icon(
              onPressed: () => context.read<MailProvider>().loadEmails(filter: _selectedFilter, forceRefresh: true),
              icon: Icon(Icons.refresh_rounded),
              label: Text(AppLocalizations.of(context)!.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal:
                      isLargeScreen
                          ? 24
                          : isTablet
                          ? 20
                          : 16,
                  vertical:
                      isLargeScreen
                          ? 12
                          : isTablet
                          ? 10
                          : 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isTablet, bool isLargeScreen) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          isLargeScreen
              ? 48
              : isTablet
              ? 32
              : 24,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              size:
                  isLargeScreen
                      ? 80
                      : isTablet
                      ? 64
                      : 48,
            ),
            SizedBox(
              height:
                  isLargeScreen
                      ? 24
                      : isTablet
                      ? 20
                      : 16,
            ),
            Text(
              AppLocalizations.of(context)!.noEmailsFound,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize:
                    isLargeScreen
                        ? 24
                        : isTablet
                        ? 22
                        : 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(
              height:
                  isLargeScreen
                      ? 12
                      : isTablet
                      ? 10
                      : 8,
            ),
            Text(
              (){
                 final loc = AppLocalizations.of(context)!;
                 switch (_selectedFilter) {
                   case 'Primary': return loc.emptyPrimary;
                   case 'Sent': return loc.emptySent;
                   case 'Drafts': return loc.emptyDrafts;
                   case 'Important': return loc.emptyImportant;
                   case 'Trash': return loc.emptyTrash;
                   case 'Spam': return loc.emptySpam;
                   default: return loc.emptyOther;
                 }
              }(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize:
                    isLargeScreen
                        ? 16
                        : isTablet
                        ? 15
                        : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMailList(bool isTablet, bool isLargeScreen) {
    return Consumer<MailProvider>(
      builder: (context, mailProvider, child) {
        final allEmails = mailProvider.getEmailsForFilter(_selectedFilter);
        final isLoading = mailProvider.isLoading;
        final hasMore = mailProvider.hasMoreForFilter(_selectedFilter);

        if (isLoading && allEmails.isEmpty) {
          return SkeletonMailList(isTablet: isTablet);
        }

        List<Widget> listItems = allEmails.map((e) => _buildDismissibleEmailItem(e, isTablet, isLargeScreen)).toList();

        if (allEmails.isEmpty && !isLoading) {
           return _buildEmptyState(isTablet, isLargeScreen);
        }

        if (hasMore || isLoading) {
          listItems.add(_buildPaginationLoader());
        }

        return RefreshIndicator(
          onRefresh: () async {
            await mailProvider.loadEmails(
              filter: _selectedFilter,
              forceRefresh: true,
            );
          },
          color: Theme.of(context).colorScheme.primary,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            controller: _scrollController,
            padding: EdgeInsets.symmetric(
              horizontal: isLargeScreen ? 24 : isTablet ? 20 : 16,
              vertical: 16,
            ),
            itemCount: listItems.length,
            itemBuilder: (context, index) {
              return listItems[index];
            },
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, bool isTablet, bool isLargeScreen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 4.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          fontSize: isTablet ? 14 : 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // Extracted Method for cleaner code - Helper
  Widget _buildDismissibleEmailItem(EmailMessage email, bool isTablet, bool isLargeScreen) {
        return Dismissible(
          key: Key(email.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: Text(AppLocalizations.of(context)!.deleteEmail),
                    content: Text(
                      AppLocalizations.of(context)!.confirmDeleteEmail,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(AppLocalizations.of(context)!.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(
                          AppLocalizations.of(context)!.delete,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
            );
          },
          onDismissed: (direction) {
            _deleteEmail(email);
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
              size: isTablet ? 28 : 24,
            ),
          ),
          child: GestureDetector(
            onTap: () {
              // Mark as read when tapped
              if (email.isUnread) {
                _markAsRead(email);
              }

              // Check if it's a draft
              if (email.draftId != null) {
                 context.pushNamed('composemail', extra: email);
              } else {
                 // Navigate to mail details with EmailMessage
                 context.pushNamed('maildetail', extra: email);
              }
            },
            onLongPress: () {
              _showEmailContextMenu(
                email,
                isTablet,
                isLargeScreen,
              );
            },
            child: _buildMailItem(
              email,
              isTablet,
              isLargeScreen,
            ),
          ),
        );
  }



  Widget _buildPaginationLoader() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildMailItem(EmailMessage email, bool isTablet, bool isLargeScreen) {
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 12 : 8),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color:
            email.isUnread
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
                : Theme.of(context).colorScheme.surface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        border: Border.all(
          color:
              email.isUnread
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                  : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(email.sender, isTablet),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            email.sender,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize:
                                  isLargeScreen
                                      ? 17
                                      : isTablet
                                      ? 16
                                      : 15,
                              fontWeight:
                                  email.isUnread
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                            ),
                          ),
                        ),
                         if (email.isSpam)
                          Padding(
                            padding: EdgeInsets.only(left: isTablet ? 12 : 8),
                            child: Icon(
                              Icons.report_gmailerrorred_rounded,
                              color: Colors.orange,
                              size: isTablet ? 18 : 16,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email.formattedTime,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: isTablet ? 14 : 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Text(
            email.subject,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize:
                  isLargeScreen
                      ? 18
                      : isTablet
                      ? 17
                      : 16,
              fontWeight: email.isUnread ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          SizedBox(height: isTablet ? 10 : 6),
          Text(
            email.snippet,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize:
                  isLargeScreen
                      ? 16
                      : isTablet
                      ? 15
                      : 14,
              height: 1.4,
            ),
            maxLines: isTablet ? 3 : 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name, bool isTablet) {
    return Container(
      width: isTablet ? 44 : 36,
      height: isTablet ? 44 : 36,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(isTablet ? 22 : 18),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          name.trim().isEmpty 
              ? '?' 
              : name
                  .split(' ')
                  .where((n) => n.isNotEmpty)
                  .take(2)
                  .map((n) => n[0])
                  .join()
                  .toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: isTablet ? 16 : 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _cleanHtml(String html) {
    // 1. Remove HTML tags
    var text = html.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // 2. Decode basic entities
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");
        
    // 3. Remove numeric entities like &#13;
    text = text.replaceAll(RegExp(r'&#\d+;'), '');
    
    // 4. Collapse multiple spaces/newlines
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    
    return text.trim();
  }
}

class MailItem {
  final String sender;
  final String subject;
  final String preview;
  final String time;
  final bool isUnread;
  final MailPriority priority;
  MailItem({
    required this.sender,
    required this.subject,
    required this.preview,
    required this.time,
    required this.isUnread,
    required this.priority,
  });
}

enum MailPriority { high, normal, low }
