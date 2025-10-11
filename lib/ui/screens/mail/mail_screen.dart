import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/ui/widgets/dragable_menu.dart';
import 'package:frontend/ui/widgets/side_menu.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/services/mail_service.dart';
import 'package:frontend/models/email_message.dart';
import 'package:provider/provider.dart';

class MailScreen extends StatefulWidget {
  final Map<String, dynamic>? initialExtra;

  const MailScreen({super.key, this.initialExtra});
  @override
  _MailScreenState createState() => _MailScreenState();
}

class _MailScreenState extends State<MailScreen> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  List<EmailMessage> _emails = [];
  String? _nextPageToken;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;

  bool _isConnected = false;
  bool _isCheckingConnection = true;

  String _selectedFilter = 'Inbox';
  final List<String> _filters = [
    'Inbox',
    'Sent',
    'Drafts',
    'Important',
    'Trash',
    'Other',
  ];

  bool _hasShownSnackbar = false;
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

    _checkConnectionAndLoadEmails();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<EmailMessage> get _filteredEmails {
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      return _emails.where((email) {
        return email.sender.toLowerCase().contains(query) ||
            email.subject.toLowerCase().contains(query) ||
            email.snippet.toLowerCase().contains(query);
      }).toList();
    }
    return _emails;
  }

  String _getBackendType(String filter) {
    switch (filter) {
      case 'Inbox':
        return 'inbox';
      case 'Sent':
        return 'sent';
      case 'Drafts':
        return 'drafts';
      case 'Important':
        return 'important';
      case 'Trash':
        return 'trash';
      case 'Other':
        return 'other';
      default:
        return 'inbox';
    }
  }

  Future<void> _checkConnectionAndLoadEmails() async {
    try {
      final auth = context.read<AuthProvider>();
      final mailService = MailService(dio: auth.dio);

      await mailService.initialize();

      final tokenData = await mailService.checkTokens();

      if (tokenData != null && tokenData['hasTokens'] == true) {
        print('✅ User has email tokens, connected');
        setState(() {
          _isConnected = true;
          _isCheckingConnection = false;
        });

        await _fetchEmails();
      } else {
        print('⚠️ No email tokens found, showing connect button');
        setState(() {
          _isConnected = false;
          _isCheckingConnection = false;
        });
      }
    } catch (e) {
      print('❌ Error checking connection: $e');
      setState(() {
        _isConnected = false;
        _isCheckingConnection = false;
        _errorMessage = 'Failed to check connection status';
      });
    }
  }

  Future<void> _fetchEmails({bool isRefresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      if (isRefresh) {
        _emails.clear();
        _nextPageToken = null;
        _hasMore = true;
      }
    });

    try {
      final auth = context.read<AuthProvider>();
      final mailService = MailService(dio: auth.dio);
      final type = _getBackendType(_selectedFilter);

      final response = await mailService.listMails(
        type: type,
        maxResults: 20,
        pageToken: _nextPageToken,
      );

      if (response != null && response['messages'] != null) {
        final messagesList = response['messages'] as List;
        final List<EmailMessage> newEmails =
            messagesList.map((messageData) {
              return _parseEmailMessage(messageData as Map<String, dynamic>);
            }).toList();

        setState(() {
          if (isRefresh) {
            _emails = newEmails;
          } else {
            _emails.addAll(newEmails);
          }
          _nextPageToken = response['nextPageToken'] as String?;
          _hasMore = _nextPageToken != null;
        });
      } else if (response != null && response['messages'] == null) {
        setState(() {
          if (isRefresh) {
            _emails = [];
          }
          _nextPageToken = null;
          _hasMore = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load emails';
        });
      }
    } catch (e) {
      print('❌ Error fetching emails: $e');
      setState(() {
        _errorMessage = 'Error loading emails: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  EmailMessage _parseEmailMessage(Map<String, dynamic> data) {
    return EmailMessage(
      id: data['id'] ?? '',
      threadId: data['threadId'] ?? data['id'] ?? '',
      sender: data['from'] ?? 'Unknown Sender',
      senderEmail: data['fromEmail'] ?? '',
      subject: data['subject'] ?? '(No Subject)',
      snippet: data['snippet'] ?? '',
      body: data['body'] ?? data['snippet'] ?? '',
      date:
          data['date'] != null ? DateTime.parse(data['date']) : DateTime.now(),
      isUnread: data['unread'] == true,
      labelIds: data['labels'] != null ? List<String>.from(data['labels']) : [],
      hasAttachments: data['hasAttachments'] == true,
      attachments: null,
    );
  }

  Future<void> _loadMoreEmails() async {
    if (!_hasMore || _isLoading || _nextPageToken == null) return;
    await _fetchEmails();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreEmails();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    if (_isConnected) ...[
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
                    'Inbox',
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
                    '${_filteredEmails.length} messages',
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
                  hintText: 'Search mail...',
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
          _buildHeaderButton(
            Icons.link_rounded,
            () async {
              final auth = context.read<AuthProvider>();
              final mailService = MailService(dio: auth.dio);
              final res = await mailService.connect();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    res == null ? 'Opening Gmail connect…' : 'Connect failed',
                  ),
                ),
              );
            },
            Theme.of(context),
            isTablet,
          ),
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
                _fetchEmails(isRefresh: true);
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
                  filter,
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
                      '${_emails.where((e) => e.isUnread).length}',
                      'Unread',
                      Colors.blue,
                      isTablet,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatChip(
                      '${_emails.where((e) => e.labelIds.contains('IMPORTANT')).length}',
                      'Important',
                      Colors.red,
                      isTablet,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatChip(
                      '${_emails.length}',
                      'Total',
                      Colors.green,
                      isTablet,
                    ),
                  ),
                ],
              )
              : Row(
                children: [
                  _buildStatChip(
                    '${_emails.where((e) => e.isUnread).length}',
                    'Unread',
                    Colors.blue,
                    isTablet,
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  _buildStatChip(
                    '${_emails.where((e) => e.labelIds.contains('IMPORTANT')).length}',
                    'Important',
                    Colors.red,
                    isTablet,
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  _buildStatChip(
                    '${_emails.length}',
                    'Total',
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

    if (!_isConnected) {
      return _buildConnectGmailView(isTablet, isLargeScreen);
    }

    if (_isLoading && _emails.isEmpty) {
      return _buildLoadingState();
    }

    if (_errorMessage != null && _emails.isEmpty) {
      return _buildErrorState(isTablet, isLargeScreen);
    }

    if (_emails.isEmpty && !_isLoading) {
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
            'Loading...',
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

  Widget _buildConnectGmailView(bool isTablet, bool isLargeScreen) {
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
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: EdgeInsets.all(
              isLargeScreen
                  ? 48
                  : isTablet
                  ? 32
                  : 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width:
                      isLargeScreen
                          ? 120
                          : isTablet
                          ? 100
                          : 80,
                  height:
                      isLargeScreen
                          ? 120
                          : isTablet
                          ? 100
                          : 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red, Colors.red.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.mail_outline_rounded,
                    color: Colors.white,
                    size:
                        isLargeScreen
                            ? 60
                            : isTablet
                            ? 50
                            : 40,
                  ),
                ),
                SizedBox(
                  height:
                      isLargeScreen
                          ? 32
                          : isTablet
                          ? 24
                          : 20,
                ),
                Text(
                  'Connect Your Gmail',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize:
                        isLargeScreen
                            ? 28
                            : isTablet
                            ? 24
                            : 22,
                  ),
                ),
                SizedBox(
                  height:
                      isLargeScreen
                          ? 16
                          : isTablet
                          ? 12
                          : 10,
                ),
                Text(
                  'Connect your Gmail account to start managing your emails efficiently. Access your inbox, drafts, sent items, and more.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize:
                        isLargeScreen
                            ? 18
                            : isTablet
                            ? 16
                            : 15,
                    height: 1.5,
                  ),
                ),
                SizedBox(
                  height:
                      isLargeScreen
                          ? 32
                          : isTablet
                          ? 24
                          : 20,
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final auth = context.read<AuthProvider>();
                    final mailService = MailService(dio: auth.dio);
                    final res = await mailService.connect();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          res == null
                              ? 'Opening Gmail connect…'
                              : 'Connect failed',
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.link_rounded),
                  label: Text(
                    'Connect Gmail',
                    style: TextStyle(
                      fontSize:
                          isLargeScreen
                              ? 18
                              : isTablet
                              ? 16
                              : 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          isLargeScreen
                              ? 32
                              : isTablet
                              ? 24
                              : 20,
                      vertical:
                          isLargeScreen
                              ? 16
                              : isTablet
                              ? 14
                              : 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ],
            ),
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
              'Something went wrong',
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
              _errorMessage ?? 'Failed to load emails',
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
              onPressed: () => _fetchEmails(isRefresh: true),
              icon: Icon(Icons.refresh_rounded),
              label: Text('Retry'),
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
              'No emails found',
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
              'Your ${_selectedFilter.toLowerCase()} folder is empty',
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
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(
        horizontal:
            isLargeScreen
                ? 24
                : isTablet
                ? 20
                : 16,
      ),
      itemCount: _filteredEmails.length + (_hasMore && _isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        // Show loading indicator at bottom
        if (index == _filteredEmails.length) {
          return _buildPaginationLoader();
        }

        return GestureDetector(
          onTap: () {
            // Navigate to mail details with EmailMessage
            context.pushNamed('maildetail', extra: _filteredEmails[index]);
          },
          child: _buildMailItem(
            _filteredEmails[index],
            isTablet,
            isLargeScreen,
          ),
        );
      },
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
                        if (email.labelIds.contains('IMPORTANT'))
                          Container(
                            margin: EdgeInsets.only(left: isTablet ? 12 : 8),
                            width: isTablet ? 8 : 6,
                            height: isTablet ? 8 : 6,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
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
          name.split(' ').map((n) => n[0]).join().toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: isTablet ? 16 : 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
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
