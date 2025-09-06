import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/ui/widgets/side_menu.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:file_picker/file_picker.dart';

class ComposeMailScreen extends StatefulWidget {
  final MailItem? editingMail;

  const ComposeMailScreen({super.key, this.editingMail});

  @override
  _ComposeMailScreenState createState() => _ComposeMailScreenState();
}

class _ComposeMailScreenState extends State<ComposeMailScreen>
    with TickerProviderStateMixin {
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final quill.QuillController _bodyController = quill.QuillController.basic();

  final FocusNode _toFocus = FocusNode();
  final FocusNode _subjectFocus = FocusNode();
  final FocusNode _bodyFocus = FocusNode();

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  bool _isSending = false;
  bool _showCc = false;
  bool _showBcc = false;
  bool _isUploadingFile = false;

  final List<AttachmentItem> _attachments = [];

  // Predefined recipients for auto-completion
  final List<String> _suggestions = [
    'john.doe@company.com',
    'sarah.chen@company.com',
    'marcus.thompson@company.com',
    'lisa.rodriguez@company.com',
    'david.park@company.com',
    'emma.wilson@company.com',
  ];

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

    if (widget.editingMail != null) {
      _toController.text = widget.editingMail!.sender;
      _subjectController.text = widget.editingMail!.subject;
      _bodyController.document.insert(0, widget.editingMail!.preview);
    }

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _toController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    _toFocus.dispose();
    _subjectFocus.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  void _sendMail() async {
    if (_toController.text.isEmpty ||
        _subjectController.text.isEmpty ||
        _bodyController.document.isEmpty()) {
      _showFeedback('Please complete all required fields', isError: true);
      return;
    }

    setState(() => _isSending = true);

    // Simulate API call with attachments
    await Future.delayed(const Duration(milliseconds: 1500));

    // Here you would upload attachments to your server
    // for (var attachment in _attachments) {
    //   await uploadAttachment(attachment);
    // }

    _showFeedback(
      'Message sent successfully with ${_attachments.length} attachments',
    );
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) context.go('/mail');
  }

  void _saveDraft() async {
    _showFeedback('Draft saved with ${_attachments.length} attachments');
    HapticFeedback.lightImpact();
  }

  Future<void> _pickFiles() async {
    try {
      setState(() => _isUploadingFile = true);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        allowedExtensions: null,
      );

      if (result != null) {
        for (PlatformFile file in result.files) {
          if (file.size > 25 * 1024 * 1024) {
            // 25MB limit
            _showFeedback(
              'File "${file.name}" is too large (max 25MB)',
              isError: true,
            );
            continue;
          }

          final attachment = AttachmentItem(
            name: file.name,
            path: file.path,
            size: file.size,
            bytes: file.bytes,
          );

          setState(() {
            _attachments.add(attachment);
          });
        }

        if (result.files.isNotEmpty) {
          _showFeedback('Added ${result.files.length} file(s)');
          HapticFeedback.lightImpact();
        }
      }
    } catch (e) {
      _showFeedback('Error picking files: $e', isError: true);
    } finally {
      setState(() => _isUploadingFile = false);
    }
  }

  Future<void> _pickImages() async {
    try {
      setState(() => _isUploadingFile = true);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
      );

      if (result != null) {
        for (PlatformFile file in result.files) {
          if (file.size > 10 * 1024 * 1024) {
            // 10MB limit for images
            _showFeedback(
              'Image "${file.name}" is too large (max 10MB)',
              isError: true,
            );
            continue;
          }

          final attachment = AttachmentItem(
            name: file.name,
            path: file.path,
            size: file.size,
            bytes: file.bytes,
            isImage: true,
          );

          setState(() {
            _attachments.add(attachment);
          });
        }

        if (result.files.isNotEmpty) {
          _showFeedback('Added ${result.files.length} image(s)');
          HapticFeedback.lightImpact();
        }
      }
    } catch (e) {
      _showFeedback('Error picking images: $e', isError: true);
    } finally {
      setState(() => _isUploadingFile = false);
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
    HapticFeedback.lightImpact();
    _showFeedback('Attachment removed');
  }

  void _showFeedback(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        backgroundColor:
            isError
                ? Colors.red.withValues(alpha: 0.9)
                : Colors.green.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(milliseconds: isError ? 3000 : 2000),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
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
                    Expanded(child: _buildContent(isTablet, isLargeScreen)),
                  ],
                ),
              ),
            ),
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
          _buildHeaderButton(
            Icons.arrow_back_ios_new,
            () => context.go('/mail'),
            Theme.of(context),
            isTablet,
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.editingMail != null ? 'Edit Message' : 'Compose',
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
                  widget.editingMail != null
                      ? 'Edit and send your message'
                      : 'Create a new message',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: isTablet ? 12 : 8),
          _buildHeaderButton(
            Icons.save_outlined,
            _saveDraft,
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

  Widget _buildContent(bool isTablet, bool isLargeScreen) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        isLargeScreen
            ? 24
            : isTablet
            ? 16
            : 8,
        0,
        isLargeScreen
            ? 24
            : isTablet
            ? 16
            : 8,
        isTablet ? 16 : 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Compact input fields section
          _buildCompactInputFields(isTablet, isLargeScreen),

          // Attachments section (if any)
          if (_attachments.isNotEmpty)
            _buildAttachmentsSection(isTablet, isLargeScreen),

          // Compact toolbar
          _buildCompactToolbar(isTablet, isLargeScreen),

          // Expanded body input - takes most of the space
          Expanded(
            flex: 3, // Give more weight to the body
            child: _buildMessageField(isTablet, isLargeScreen),
          ),

          // Send button
          _buildSendButton(isTablet, isLargeScreen),
        ],
      ),
    );
  }

  Widget _buildCompactInputFields(bool isTablet, bool isLargeScreen) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 24 : 16,
        isTablet ? 20 : 12,
        isTablet ? 24 : 16,
        isTablet ? 8 : 4,
      ),
      child: Column(
        children: [
          // Compact To field
          _buildCompactTextField(
            controller: _toController,
            focusNode: _toFocus,
            hint: 'To',
            isTablet: isTablet,
            isRequired: true,
            suggestions: _suggestions,
          ),
          SizedBox(height: isTablet ? 8 : 6),

          // CC/BCC buttons row
          if (!_showCc || !_showBcc)
            Row(
              children: [
                if (!_showCc)
                  _buildSmallButton(
                    'Cc',
                    () => setState(() => _showCc = true),
                    isTablet,
                  ),
                if (!_showCc && !_showBcc) SizedBox(width: isTablet ? 8 : 6),
                if (!_showBcc)
                  _buildSmallButton(
                    'Bcc',
                    () => setState(() => _showBcc = true),
                    isTablet,
                  ),
              ],
            ),
          if (!_showCc || !_showBcc) SizedBox(height: isTablet ? 8 : 6),

          // Show CC field if enabled
          if (_showCc) ...[
            _buildCompactTextField(
              controller: TextEditingController(),
              focusNode: FocusNode(),
              hint: 'Cc',
              isTablet: isTablet,
              suggestions: _suggestions,
            ),
            SizedBox(height: isTablet ? 8 : 6),
          ],

          // Show BCC field if enabled
          if (_showBcc) ...[
            _buildCompactTextField(
              controller: TextEditingController(),
              focusNode: FocusNode(),
              hint: 'Bcc',
              isTablet: isTablet,
              suggestions: _suggestions,
            ),
            SizedBox(height: isTablet ? 8 : 6),
          ],

          // Compact Subject field
          _buildCompactTextField(
            controller: _subjectController,
            focusNode: _subjectFocus,
            hint: 'Subject',
            isTablet: isTablet,
            isRequired: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSmallButton(String text, VoidCallback onTap, bool isTablet) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 8 : 6,
          vertical: isTablet ? 4 : 3,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: isTablet ? 11 : 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required bool isTablet,
    bool isRequired = false,
    List<String>? suggestions,
  }) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, child) {
        return Container(
          height: isTablet ? 42 : 36, // Fixed compact height
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(
              alpha: focusNode.hasFocus ? 0.1 : 0.03,
            ),
            borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: isTablet ? 14 : 13,
            ),
            decoration: InputDecoration(
              hintText: '$hint${isRequired ? ' *' : ''}',
              hintStyle: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: isTablet ? 14 : 13,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isTablet ? 12 : 10,
                vertical: isTablet ? 10 : 8,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentsSection(bool isTablet, bool isLargeScreen) {
    return Container(
      margin: EdgeInsets.fromLTRB(isTablet ? 24 : 16, 0, isTablet ? 24 : 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Attachments (${_attachments.length})',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: isTablet ? 12 : 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Total: ${_formatFileSize(_attachments.fold<int>(0, (sum, item) => sum + item.size))}',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: isTablet ? 10 : 9,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 8 : 6),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _attachments.length,
            separatorBuilder:
                (context, index) => SizedBox(height: isTablet ? 6 : 4),
            itemBuilder: (context, index) {
              final attachment = _attachments[index];
              return Container(
                padding: EdgeInsets.all(isTablet ? 8 : 6),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isTablet ? 6 : 4),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(isTablet ? 6 : 4),
                      ),
                      child: Icon(
                        attachment.isImage ? Icons.image : Icons.attach_file,
                        color: Theme.of(context).colorScheme.primary,
                        size: isTablet ? 16 : 14,
                      ),
                    ),
                    SizedBox(width: isTablet ? 8 : 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            attachment.name,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: isTablet ? 12 : 11,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _formatFileSize(attachment.size),
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: isTablet ? 10 : 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeAttachment(index),
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                        size: isTablet ? 16 : 14,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: isTablet ? 24 : 20,
                        minHeight: isTablet ? 24 : 20,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: isTablet ? 8 : 6),
        ],
      ),
    );
  }

  Widget _buildCompactToolbar(bool isTablet, bool isLargeScreen) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        isTablet ? 24 : 16,
        0,
        isTablet ? 24 : 16,
        isTablet ? 8 : 6,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 12 : 8,
        vertical: isTablet ? 6 : 0,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Minimal QuillToolbar for basic formatting
          Flexible(
            child: quill.QuillSimpleToolbar(
              controller: _bodyController,
              config: quill.QuillSimpleToolbarConfig(
                showAlignmentButtons: false,
                showUndo: false,
                showRedo: false,
                showFontSize: false,
                showFontFamily: false,
                showClearFormat: false,
                showIndent: false,
                showStrikeThrough: false,
                showSubscript: false,
                showSuperscript: false,
                showInlineCode: false,
                showDividers: false,
                showColorButton: false,
                showBackgroundColorButton: false,
                multiRowsDisplay: false,
                showSearchButton: false,
                showQuote: false,
                iconTheme: quill.QuillIconTheme(
                  iconButtonSelectedData: quill.IconButtonData(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  iconButtonUnselectedData: quill.IconButtonData(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                customButtons: [],
              ),
            ),
          ),

          // Divider
          Container(
            height: 16,
            width: 1,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.2),
            margin: const EdgeInsets.symmetric(horizontal: 6),
          ),

          // Attach files button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: _isUploadingFile ? null : _pickFiles,
              child: Container(
                padding: const EdgeInsets.all(6),
                child:
                    _isUploadingFile
                        ? SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        )
                        : Icon(
                          Icons.attach_file,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                          size: isTablet ? 16 : 14,
                        ),
              ),
            ),
          ),

          // Attach images button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: _isUploadingFile ? null : _pickImages,
              child: Container(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.image,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                  size: isTablet ? 16 : 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageField(bool isTablet, bool isLargeScreen) {
    return Container(
      margin: EdgeInsets.fromLTRB(isTablet ? 24 : 16, 0, isTablet ? 24 : 16, 0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(
          alpha: _bodyFocus.hasFocus ? 0.1 : 0.03,
        ),
        borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
        border: Border.all(
          color:
              _bodyFocus.hasFocus
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                  : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.1),
          width: _bodyFocus.hasFocus ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 8 : 6),
        child: quill.QuillEditor.basic(
          controller: _bodyController,
          focusNode: _bodyFocus,
        ),
      ),
    );
  }

  Widget _buildSendButton(bool isTablet, bool isLargeScreen) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 24 : 16,
        isTablet ? 16 : 12,
        isTablet ? 24 : 16,
        isTablet ? 20 : 16,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
          onTap:
              _isSending
                  ? null
                  : () {
                    HapticFeedback.mediumImpact();
                    _sendMail();
                  },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: isTablet ? 48 : 40,
            decoration: BoxDecoration(
              color:
                  _isSending
                      ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.6)
                      : Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
            ),
            child: Center(
              child:
                  _isSending
                      ? SizedBox(
                        width: isTablet ? 20 : 16,
                        height: isTablet ? 20 : 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.send_rounded,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: isTablet ? 18 : 16,
                          ),
                          SizedBox(width: isTablet ? 8 : 6),
                          Text(
                            widget.editingMail != null
                                ? 'Update Message'
                                : 'Send Message',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: isTablet ? 14 : 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ),
      ),
    );
  }
}

class AttachmentItem {
  final String name;
  final String? path;
  final int size;
  final List<int>? bytes;
  final bool isImage;

  AttachmentItem({
    required this.name,
    this.path,
    required this.size,
    this.bytes,
    this.isImage = false,
  });
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
