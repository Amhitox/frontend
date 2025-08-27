import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/ui/widgets/side_menu.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
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
  bool _showEmojiPicker = false;
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

  void _onEmojiSelected(Emoji emoji) {
    final index = _bodyController.selection.baseOffset;
    final length = _bodyController.selection.extentOffset - index;
    _bodyController.replaceText(index, length, emoji.emoji, null);
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
      if (_showEmojiPicker) {
        _bodyFocus.unfocus();
      }
    });
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
            ? 20
            : 16,
        0,
        isLargeScreen
            ? 24
            : isTablet
            ? 20
            : 16,
        isTablet ? 20 : 16,
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
          SizedBox(height: isTablet ? 24 : 20),
          _buildInputFields(isTablet, isLargeScreen),
          if (_attachments.isNotEmpty)
            _buildAttachmentsSection(isTablet, isLargeScreen),
          _buildToolbar(isTablet, isLargeScreen),
          Expanded(child: _buildMessageField(isTablet, isLargeScreen)),
          _buildSendButton(isTablet, isLargeScreen),
          if (_showEmojiPicker)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _onEmojiSelected(emoji);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputFields(bool isTablet, bool isLargeScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 20),
      child: Column(
        children: [
          _buildTextField(
            controller: _toController,
            focusNode: _toFocus,
            hint: 'To',
            isTablet: isTablet,
            isRequired: true,
            suggestions: _suggestions,
          ),
          SizedBox(height: isTablet ? 16 : 12),
          if (_showCc) ...[
            _buildTextField(
              controller: TextEditingController(),
              focusNode: FocusNode(),
              hint: 'Cc',
              isTablet: isTablet,
              suggestions: _suggestions,
            ),
            SizedBox(height: isTablet ? 16 : 12),
          ],
          if (_showBcc) ...[
            _buildTextField(
              controller: TextEditingController(),
              focusNode: FocusNode(),
              hint: 'Bcc',
              isTablet: isTablet,
              suggestions: _suggestions,
            ),
            SizedBox(height: isTablet ? 16 : 12),
          ],
          Row(
            children: [
              if (!_showCc)
                GestureDetector(
                  onTap: () => setState(() => _showCc = true),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 12 : 8,
                      vertical: isTablet ? 6 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                    ),
                    child: Text(
                      'Cc',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: isTablet ? 12 : 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              if (!_showCc && !_showBcc) SizedBox(width: isTablet ? 8 : 6),
              if (!_showBcc)
                GestureDetector(
                  onTap: () => setState(() => _showBcc = true),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 12 : 8,
                      vertical: isTablet ? 6 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                    ),
                    child: Text(
                      'Bcc',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: isTablet ? 12 : 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: isTablet ? 16 : 12),
          _buildTextField(
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

  Widget _buildTextField({
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
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(
              alpha: focusNode.hasFocus ? 0.1 : 0.03,
            ),
            borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
            border: Border.all(
              color:
                  focusNode.hasFocus
                      ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.3)
                      : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.1),
              width: focusNode.hasFocus ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: isTablet ? 16 : 14,
            ),
            decoration: InputDecoration(
              hintText: '$hint${isRequired ? ' *' : ''}',
              hintStyle: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isTablet ? 16 : 12,
                vertical: isTablet ? 14 : 12,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentsSection(bool isTablet, bool isLargeScreen) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        isTablet ? 24 : 20,
        isTablet ? 16 : 12,
        isTablet ? 24 : 20,
        0,
      ),
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
                  fontSize: isTablet ? 14 : 12,
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
                  fontSize: isTablet ? 12 : 10,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 12 : 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _attachments.length,
            separatorBuilder:
                (context, index) => SizedBox(height: isTablet ? 8 : 6),
            itemBuilder: (context, index) {
              final attachment = _attachments[index];
              return Container(
                padding: EdgeInsets.all(isTablet ? 12 : 10),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
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
                      padding: EdgeInsets.all(isTablet ? 8 : 6),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
                      ),
                      child: Icon(
                        attachment.isImage ? Icons.image : Icons.attach_file,
                        color: Theme.of(context).colorScheme.primary,
                        size: isTablet ? 20 : 16,
                      ),
                    ),
                    SizedBox(width: isTablet ? 12 : 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            attachment.name,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: isTablet ? 14 : 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatFileSize(attachment.size),
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: isTablet ? 12 : 10,
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
                        size: isTablet ? 18 : 16,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: isTablet ? 32 : 28,
                        minHeight: isTablet ? 32 : 28,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(bool isTablet, bool isLargeScreen) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        isTablet ? 24 : 20,
        isTablet ? 16 : 12,
        isTablet ? 24 : 20,
        0,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: isTablet ? 12 : 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // QuillSimpleToolbar wrapped in Flexible to prevent layout conflicts
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
                multiRowsDisplay: false,
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
                customButtons: [
                  quill.QuillToolbarCustomButtonOptions(
                    icon: Icon(Icons.emoji_emotions_outlined),
                    onPressed: _toggleEmojiPicker,
                  ),
                ],
              ),
            ),
          ),

          // Custom attachment buttons
          Container(
            height: 24,
            width: 1,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.2),
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),

          // Attach files button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: _isUploadingFile ? null : _pickFiles,
              child: Container(
                padding: const EdgeInsets.all(8),
                child:
                    _isUploadingFile
                        ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
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
                          size: 18,
                        ),
              ),
            ),
          ),

          // Attach images button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: _isUploadingFile ? null : _pickImages,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.image,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                  size: 18,
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
      margin: EdgeInsets.fromLTRB(
        isTablet ? 24 : 20,
        isTablet ? 16 : 12,
        isTablet ? 24 : 20,
        0,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(
          alpha: _bodyFocus.hasFocus ? 0.1 : 0.03,
        ),
        borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
        border: Border.all(
          color:
              _bodyFocus.hasFocus
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                  : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.1),
          width: _bodyFocus.hasFocus ? 2 : 1,
        ),
      ),
      child: quill.QuillEditor.basic(
        controller: _bodyController,
        focusNode: _bodyFocus,
      ),
    );
  }

  Widget _buildSendButton(bool isTablet, bool isLargeScreen) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
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
            height: isTablet ? 56 : 48,
            decoration: BoxDecoration(
              color:
                  _isSending
                      ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.6)
                      : Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
            ),
            child: Center(
              child:
                  _isSending
                      ? SizedBox(
                        width: isTablet ? 24 : 20,
                        height: isTablet ? 24 : 20,
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
                            size: isTablet ? 20 : 18,
                          ),
                          SizedBox(width: isTablet ? 12 : 8),
                          Text(
                            widget.editingMail != null
                                ? 'Update Message'
                                : 'Send Message',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: isTablet ? 16 : 14,
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
