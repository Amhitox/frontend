import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'mail_screen.dart';
class MailDetailScreen extends StatefulWidget {
  final MailItem email;
  const MailDetailScreen({super.key, required this.email});
  @override
  State<MailDetailScreen> createState() => _MailDetailScreenState();
}
class _MailDetailScreenState extends State<MailDetailScreen>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _showElevatedHeader = false;
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _scrollController.addListener(_onScroll);
    _animationController.forward();
  }
  void _onScroll() {
    final shouldShowElevated = _scrollController.offset > 10;
    if (shouldShowElevated != _showElevatedHeader) {
      setState(() {
        _showElevatedHeader = shouldShowElevated;
      });
    }
  }
  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow:
                  _showElevatedHeader
                      ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                      : null,
            ),
            child: SafeArea(child: _buildEnhancedHeader(theme, isTablet)),
          ),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildSubjectSection(theme, isTablet),
                  ),
                  SliverToBoxAdapter(
                    child: _buildMetadataSection(theme, isTablet),
                  ),
                  SliverToBoxAdapter(
                    child: _buildContentSection(theme, isTablet),
                  ),
                  if (_hasAttachments())
                    SliverToBoxAdapter(
                      child: _buildAttachmentsSection(theme, isTablet),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomSheet: _buildActionBottomSheet(theme, isTablet),
    );
  }
  Widget _buildEnhancedHeader(ThemeData theme, bool isTablet) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                HapticFeedback.lightImpact();
                context.goNamed('mail');
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  size: isTablet ? 24 : 22,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildEnhancedAvatar(isTablet, theme),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.email.sender,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: isTablet ? 18 : 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTime(widget.email.time),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: isTablet ? 14 : 12,
                  ),
                ),
              ],
            ),
          ),
          if (widget.email.priority == MailPriority.high)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.priority_high,
                    color: Colors.red,
                    size: isTablet ? 18 : 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'High',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: isTablet ? 12 : 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
  Widget _buildEnhancedAvatar(bool isTablet, ThemeData theme) {
    final initials = widget.email.sender
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .join()
        .toUpperCase()
        .substring(0, 2);
    return Hero(
      tag: 'avatar_${widget.email.sender}',
      child: Container(
        width: isTablet ? 56 : 48,
        height: isTablet ? 56 : 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            initials,
            style: TextStyle(
              fontSize: isTablet ? 20 : 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildSubjectSection(ThemeData theme, bool isTablet) {
    return Container(
      margin: EdgeInsets.all(isTablet ? 24 : 20),
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        widget.email.subject,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: isTablet ? 24 : 22,
          height: 1.3,
        ),
      ),
    );
  }
  Widget _buildMetadataSection(ThemeData theme, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 20),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          child: Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: isTablet ? 20 : 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'Received ${_formatTime(widget.email.time)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: isTablet ? 14 : 13,
                ),
              ),
              const Spacer(),
              if (_isUnread())
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'UNREAD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 11 : 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildContentSection(ThemeData theme, bool isTablet) {
    return Container(
      margin: EdgeInsets.all(isTablet ? 24 : 20),
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: SelectableText(
        widget.email.preview,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontSize: isTablet ? 16 : 15,
          height: 1.6,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
        ),
      ),
    );
  }
  Widget _buildAttachmentsSection(ThemeData theme, bool isTablet) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 20),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_file_rounded,
                size: isTablet ? 20 : 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Attachments',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(
            2,
            (index) => _buildAttachmentItem(theme, isTablet, index),
          ),
        ],
      ),
    );
  }
  Widget _buildAttachmentItem(ThemeData theme, bool isTablet, int index) {
    final attachmentNames = ['Document.pdf', 'Report.xlsx'];
    final icons = [Icons.picture_as_pdf, Icons.table_chart];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icons[index],
            color: theme.colorScheme.primary,
            size: isTablet ? 24 : 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              attachmentNames[index],
              style: theme.textTheme.bodyMedium,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.download_rounded,
              color: theme.colorScheme.primary,
              size: isTablet ? 20 : 18,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildActionBottomSheet(ThemeData theme, bool isTablet) {
    return Container(
      height: isTablet ? 80 : 72,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.reply_all_rounded,
                label: 'Reply All',
                onTap: () {},
                theme: theme,
                isTablet: isTablet,
              ),
              _buildActionButton(
                icon: Icons.forward_rounded,
                label: 'Forward',
                onTap: () {},
                theme: theme,
                isTablet: isTablet,
              ),
              _buildActionButton(
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
                onTap: () {},
                theme: theme,
                isTablet: isTablet,
                isDestructive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
    required bool isTablet,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : theme.colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 16 : 12,
            vertical: isTablet ? 12 : 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: isTablet ? 24 : 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: isTablet ? 12 : 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  String _formatTime(String time) {
    return time;
  }
  bool _hasAttachments() {
    return true;
  }
  bool _isUnread() {
    return false;
  }
}
