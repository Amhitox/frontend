import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/ui/widgets/dragable_menu.dart';
import 'package:frontend/ui/widgets/side_menu.dart';
class MailScreen extends StatefulWidget {
  const MailScreen({super.key});
  @override
  _MailScreenState createState() => _MailScreenState();
}
class _MailScreenState extends State<MailScreen> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final List<MailItem> _emails = [
    MailItem(
      sender: "Sarah Chen",
      subject: "Q4 Strategic Review Meeting",
      preview:
          "The board meeting has been scheduled for next Thursday at 2 PM...",
      time: "2m ago",
      isUnread: true,
      priority: MailPriority.high,
    ),
    MailItem(
      sender: "Marcus Thompson",
      subject: "Partnership Proposal - TechCorp",
      preview: "I've reviewed the contract terms and have some suggestions...",
      time: "15m ago",
      isUnread: true,
      priority: MailPriority.normal,
    ),
    MailItem(
      sender: "Lisa Rodriguez",
      subject: "Budget Approval Request",
      preview:
          "Please review the attached budget proposal for the new initiative...",
      time: "1h ago",
      isUnread: false,
      priority: MailPriority.normal,
    ),
    MailItem(
      sender: "David Park",
      subject: "Security Protocol Update",
      preview: "New security measures will be implemented starting Monday...",
      time: "3h ago",
      isUnread: false,
      priority: MailPriority.low,
    ),
    MailItem(
      sender: "Emma Wilson",
      subject: "Team Performance Metrics",
      preview: "The latest performance reports are ready for your review...",
      time: "5h ago",
      isUnread: false,
      priority: MailPriority.normal,
    ),
  ];
  String _selectedFilter = 'Primary';
  final List<String> _filters = ['Primary', 'Sent', 'Draft', 'Spam'];
  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();
  }
  @override
  void dispose() {
    _slideController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  List<MailItem> get _filteredEmails {
    final query = _searchController.text.toLowerCase();
    final allEmails = _emails.toList();
    if (query.isNotEmpty) {
      return allEmails.where((email) {
        return email.sender.toLowerCase().contains(query) ||
            email.subject.toLowerCase().contains(query);
      }).toList();
    }
    switch (_selectedFilter) {
      case 'Primary':
        return allEmails.where((email) => email.isUnread).toList();
      case 'Sent':
        return allEmails
            .where((email) => email.priority == MailPriority.high)
            .toList();
      case 'Draft':
        return allEmails
            .where(
              (email) =>
                  email.time.contains('m ago') || email.time.contains('h ago'),
            )
            .toList();
      case 'Spam':
        return allEmails
            .where(
              (email) =>
                  email.time.contains('m ago') || email.time.contains('h ago'),
            )
            .toList();
      default:
        return allEmails;
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
                    _buildFilterTabs(isTablet, isLargeScreen),
                    _buildQuickStats(isTablet, isLargeScreen),
                    Expanded(child: _buildMailList(isTablet, isLargeScreen)),
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
            onTap: () => setState(() => _selectedFilter = filter),
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
                      '${_emails.where((e) => e.priority == MailPriority.high).length}',
                      'Priority',
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
                    '${_emails.where((e) => e.priority == MailPriority.high).length}',
                    'Priority',
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
  Widget _buildMailList(bool isTablet, bool isLargeScreen) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal:
            isLargeScreen
                ? 24
                : isTablet
                ? 20
                : 16,
      ),
      itemCount: _filteredEmails.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
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
  Widget _buildMailItem(MailItem email, bool isTablet, bool isLargeScreen) {
    return GestureDetector(
      onTap: () {
        context.pushNamed('maildetail', extra: email);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: isTablet ? 12 : 8),
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        decoration: BoxDecoration(
          color:
              email.isUnread
                  ? Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.05)
                  : Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
          border: Border.all(
            color:
                email.isUnread
                    ? Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1)
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
                          if (email.priority == MailPriority.high)
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
                        email.time,
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
              email.preview,
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
