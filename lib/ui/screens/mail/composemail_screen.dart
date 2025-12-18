import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/ui/widgets/side_menu.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:file_picker/file_picker.dart';
import 'package:frontend/services/mail_service.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/email_message.dart';
import 'package:frontend/providers/mail_provider.dart';
import 'package:frontend/services/transcription_service.dart';
import 'dart:convert'; // For encoding/decoding if needed

class ComposeMailScreen extends StatefulWidget {
  final MailItem? editingMail;
  final EmailMessage? draft;
  final bool isFromAi;
  const ComposeMailScreen({
    super.key, 
    this.editingMail, 
    this.draft,
    this.isFromAi = false,
  });
  @override
  _ComposeMailScreenState createState() => _ComposeMailScreenState();
}

class _ComposeMailScreenState extends State<ComposeMailScreen>
    with TickerProviderStateMixin {
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _ccController = TextEditingController();
  final TextEditingController _bccController = TextEditingController();
  
  late quill.QuillController _bodyController;
  final FocusNode _toFocus = FocusNode();
  final FocusNode _subjectFocus = FocusNode();
  final FocusNode _ccFocus = FocusNode();
  final FocusNode _bccFocus = FocusNode();
  
  // AI Refinement State
  final TranscriptionService _transcriptionService = TranscriptionService();
  int _refinementAttempts = 0;
  bool _isRefining = false;
  bool _isRecording = false;
  final FocusNode _bodyFocus = FocusNode();

  // Selected recipients lists
  final List<String> _toRecipients = [];
  final List<String> _ccRecipients = [];
  final List<String> _bccRecipients = [];

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _isSending = false;
  bool _showCc = false;
  bool _showBcc = false;
  bool _isUploadingFile = false;
  final List<AttachmentItem> _attachments = [];
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
    
    // Initialize body controller with content if available
    if (widget.editingMail != null && widget.editingMail!.preview.isNotEmpty) {
      final cleanText = _stripHtml(widget.editingMail!.preview);
      final doc = quill.Document()..insert(0, cleanText);
      _bodyController = quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    } else {
      _bodyController = quill.QuillController.basic();
    }

    if (widget.editingMail != null) {
      if (widget.editingMail!.sender.isNotEmpty) {
        _toRecipients.addAll(
            widget.editingMail!.sender.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty)
        );
      }
      _subjectController.text = widget.editingMail!.subject;
      if (widget.editingMail!.cc != null && widget.editingMail!.cc!.isNotEmpty) {
         _ccRecipients.addAll(
             widget.editingMail!.cc!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty)
         );
        _showCc = true;
      }
      if (widget.editingMail!.bcc != null && widget.editingMail!.bcc!.isNotEmpty) {
        _bccRecipients.addAll(
             widget.editingMail!.bcc!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty)
        );
        _showBcc = true;
      }
    } else if (widget.draft != null) {
      if (widget.draft!.headers != null) {
        final h = widget.draft!.headers!;
        if (h.to != null && h.to!.isNotEmpty) {
           _toRecipients.addAll(h.to!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
        }
        if (h.cc != null && h.cc!.isNotEmpty) {
           _ccRecipients.addAll(h.cc!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
           _showCc = true;
        }
        if (h.bcc != null && h.bcc!.isNotEmpty) {
           _bccRecipients.addAll(h.bcc!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
           _showBcc = true;
        }
        _subjectController.text = h.subject ?? widget.draft!.subject;
      } else {
        // Fallback if headers missing
         _subjectController.text = widget.draft!.subject;
      }
      
      // Body handling
      String bodyText = widget.draft!.body.isNotEmpty ? widget.draft!.body : widget.draft!.snippet;
      bodyText = _stripHtml(bodyText); // Strip HTML here too if needed
      
      if (_bodyController.document.isEmpty() && bodyText.isNotEmpty) {
          _bodyController.document.insert(0, bodyText);
      }
    }
    _slideController.forward();
  }

  String _stripHtml(String htmlString) {
    if (htmlString.isEmpty) return '';
    final RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    // Replace <br> and <p> with newlines for better text formatting before stripping
    String intermediate = htmlString.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
                                  .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n');
    return intermediate.replaceAll(exp, '').trim();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _toController.dispose();
    _subjectController.dispose();
    _ccController.dispose();
    _bccController.dispose();
    _bodyController.dispose();
    _toFocus.dispose();
    _subjectFocus.dispose();
    _ccFocus.dispose();
    _bccFocus.dispose();
    _transcriptionService.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  Future<void> _sendMail() async {
    final pendingTo = _toController.text.trim();
    if (pendingTo.isNotEmpty && !_toRecipients.contains(pendingTo)) {
      _toRecipients.add(pendingTo);
    }
    
    if (_toRecipients.isEmpty) {
      _showFeedback('Please add at least one recipient', isError: true);
      return;
    }
    if (_subjectController.text.isEmpty) {
      _showFeedback('Please add a subject', isError: true);
      return;
    }

    setState(() => _isSending = true);

    try {
      final provider = context.read<MailProvider>();
      await provider.checkConnection();
      
      final pendingCc = _ccController.text.trim();
      if (pendingCc.isNotEmpty && !_ccRecipients.contains(pendingCc)) {
        _ccRecipients.add(pendingCc);
      }
      final pendingBcc = _bccController.text.trim();
      if (pendingBcc.isNotEmpty && !_bccRecipients.contains(pendingBcc)) {
        _bccRecipients.add(pendingBcc);
      }

      final body = _bodyController.document.toPlainText();
      
      List<Map<String, dynamic>>? attachmentData;
      if (_attachments.isNotEmpty) {
        attachmentData = _attachments
            // Allow if bytes exist OR path exists
            .where((att) => (att.bytes != null && att.bytes!.isNotEmpty) || (att.path != null && att.path!.isNotEmpty))
            .map((att) => {
                  'name': att.name,
                  'bytes': att.bytes,
                  'path': att.path,
                  'mimeType': _getMimeTypeFromFilename(att.name),
                })
            .toList();
      }

      final result = await provider.sendEmail(
        _toRecipients.join(','),
        _subjectController.text,
        body,
        attachmentData,
        cc: _ccRecipients.isNotEmpty ? _ccRecipients.join(',') : null,
        bcc: _bccRecipients.isNotEmpty ? _bccRecipients.join(',') : null,
      );

      if (mounted) {
        if (result != null && result['error'] == null) {
          _showFeedback('Message sent successfully');
          context.pop();
        } else {
           final errorMsg = result?['error'] ?? 'Unknown error';
          _showFeedback(errorMsg.toString(), isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showFeedback('Error sending message: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  String _getMimeTypeFromFilename(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    final mimeTypes = {
      'pdf': 'application/pdf',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'jpg': 'image/jpeg',
      'png': 'image/png',
      // ... Add other mimes as needed
    };
    return mimeTypes[extension] ?? 'application/octet-stream';
  }

  Future<void> _saveDraft() async {
    final pendingTo = _toController.text.trim();
    if (pendingTo.isNotEmpty && !_toRecipients.contains(pendingTo)) {
      _toRecipients.add(pendingTo);
    }
    
    // Draft needs at least a recipient or subject or body
    if (_toRecipients.isEmpty && _subjectController.text.isEmpty && _bodyController.document.toPlainText().trim().isEmpty) {
      _showFeedback('Draft is empty', isError: true);
      return;
    }

    setState(() => _isSending = true);

    try {
      final auth = context.read<AuthProvider>();
      final mailService = MailService(dio: auth.dio);
      await mailService.initialize();

      final pendingCc = _ccController.text.trim();
      if (pendingCc.isNotEmpty && !_ccRecipients.contains(pendingCc)) {
        _ccRecipients.add(pendingCc);
      }
      final pendingBcc = _bccController.text.trim();
      if (pendingBcc.isNotEmpty && !_bccRecipients.contains(pendingBcc)) {
        _bccRecipients.add(pendingBcc);
      }

      final body = _bodyController.document.toPlainText();
      
      List<Map<String, dynamic>>? attachmentData;
      if (_attachments.isNotEmpty) {
        attachmentData = _attachments
            .where((att) => (att.bytes != null && att.bytes!.isNotEmpty) || (att.path != null && att.path!.isNotEmpty))
            .map((att) => {
                  'name': att.name,
                  'bytes': att.bytes,
                  'path': att.path,
                  'mimeType': _getMimeTypeFromFilename(att.name),
                })
            .toList();
      }

      final result = await mailService.createDraft(
        _toRecipients.join(','),
        _subjectController.text,
        body,
        attachmentData,
        cc: _ccRecipients.isNotEmpty ? _ccRecipients.join(',') : null,
        bcc: _bccRecipients.isNotEmpty ? _bccRecipients.join(',') : null,
      );

      if (mounted) {
        if (result != null && (result['success'] == true || result['draftId'] != null)) {
          HapticFeedback.lightImpact();
          _showFeedback('Draft saved successfully');
          context.pop();
        } else {
           final errorMsg = result?['error'] ?? 'Failed to save draft';
          _showFeedback(errorMsg.toString(), isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showFeedback('Error saving draft: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _pickFiles() async {
    try {
      setState(() => _isUploadingFile = true);
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );
      if (result != null) {
        for (PlatformFile file in result.files) {
          if (file.size > 25 * 1024 * 1024) {
            _showFeedback('File "${file.name}" is too large (max 25MB)', isError: true);
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  String _formatFileSize(int bytes) {
     if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isTablet, isLargeScreen),
              Expanded(child: _buildContent(isTablet, isLargeScreen)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTablet, bool isLargeScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: isTablet ? 12 : 8,
      ),
      child: Row(
        children: [
          _buildHeaderButton(
            Icons.arrow_back_ios_new,
            () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.push('/mail');
              }
            },
            Theme.of(context),
            isTablet,
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.editingMail != null ? 'Edit Message' : 'Compose',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize:
                        isLargeScreen
                            ? 24
                            : isTablet
                            ? 22
                            : 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (widget.isFromAi) ...[
            _buildHeaderButton(
              _isRecording ? Icons.stop_circle_outlined : Icons.auto_awesome,
              _isRecording ? _stopAndRefine : _startVoiceRefinement,
              Theme.of(context),
              isTablet,
              color: _isRecording ? Colors.red : Theme.of(context).colorScheme.primary,
            ),
            SizedBox(width: isTablet ? 12 : 8),
          ],
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
    bool isTablet, {
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          width: isTablet ? 40 : 36,
          height: isTablet ? 40 : 36,
          decoration: BoxDecoration(
            color: (color ?? theme.colorScheme.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: (color ?? theme.colorScheme.primary).withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: _isRefining 
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
              )
            : Icon(
                icon,
                color: color ?? theme.colorScheme.primary,
                size: isTablet ? 20 : 18,
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
          _buildCompactInputFields(isTablet, isLargeScreen),
          if (_attachments.isNotEmpty)
            _buildAttachmentsSection(isTablet, isLargeScreen),
          _buildCompactToolbar(isTablet, isLargeScreen),
          Expanded(child: _buildMessageField(isTablet, isLargeScreen)),
          _buildSendButton(isTablet, isLargeScreen),
        ],
      ),
    );
  }

  Widget _buildCompactInputFields(bool isTablet, bool isLargeScreen) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 24 : 16,
        isTablet ? 16 : 12,
        isTablet ? 24 : 16,
        isTablet ? 8 : 4,
      ),
      child: Column(
        children: [
          _buildChipInput(
            controller: _toController,
            focusNode: _toFocus,
            selectedValues: _toRecipients,
            hint: 'To',
            isTablet: isTablet,
            isRequired: true,
            suggestions: _suggestions,
          ),
          SizedBox(height: isTablet ? 8 : 6),
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
          if (_showCc) ...[
            _buildChipInput(
              controller: _ccController,
              focusNode: _ccFocus,
              selectedValues: _ccRecipients,
              hint: 'Cc',
              isTablet: isTablet,
              suggestions: _suggestions,
            ),
            SizedBox(height: isTablet ? 8 : 6),
          ],
          if (_showBcc) ...[
            _buildChipInput(
              controller: _bccController,
              focusNode: _bccFocus,
              selectedValues: _bccRecipients,
              hint: 'Bcc',
              isTablet: isTablet,
              suggestions: _suggestions,
            ),
            SizedBox(height: isTablet ? 8 : 6),
          ],
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
  }) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, child) {
        return Container(
          height: isTablet ? 42 : 36,
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

  Widget _buildChipInput({
  required TextEditingController controller,
  required FocusNode focusNode,
  required List<String> selectedValues,
  required String hint,
  required bool isTablet,
  List<String>? suggestions,
  bool isRequired = false,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      return RawAutocomplete<String>(
        textEditingController: controller,
        focusNode: focusNode,
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<String>.empty();
          }
          final input = textEditingValue.text.toLowerCase();
          if (suggestions != null) {
            return suggestions.where((String option) {
              return option.toLowerCase().contains(input) && 
                     !selectedValues.contains(option);
            });
          }
          return const Iterable<String>.empty();
        },
        onSelected: (String selection) {
          setState(() {
            if (!selectedValues.contains(selection)) {
              selectedValues.add(selection);
            }
            controller.clear();
          });
          focusNode.requestFocus();
        },
        fieldViewBuilder: (
          BuildContext context,
          TextEditingController fieldTextEditingController,
          FocusNode fieldFocusNode,
          VoidCallback onFieldSubmitted,
        ) {
          return AnimatedBuilder(
            animation: fieldFocusNode,
            builder: (context, child) {
              final isFocused = fieldFocusNode.hasFocus;
              
              return GestureDetector(
                onTap: () {
                  fieldFocusNode.requestFocus();
                },
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(minHeight: isTablet ? 40 : 36),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isFocused 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                        width: isFocused ? 2 : 1,
                      ),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: isTablet ? 6 : 4,
                  ),
                  child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ...selectedValues.map((recipient) {
                      final initial = recipient.isNotEmpty 
                        ? recipient[0].toUpperCase() 
                        : '?';
                      
                      return Container(
                        height: isTablet ? 28 : 24,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                             color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                             width: 0.5,
                          ),
                        ),
                        padding: const EdgeInsets.only(left: 2, right: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: isTablet ? 11 : 10,
                              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                              child: Text(
                                initial,
                                style: TextStyle(
                                  fontSize: isTablet ? 10 : 9,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 200),
                              child: Text(
                                recipient,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: isTablet ? 13 : 12,
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  selectedValues.remove(recipient);
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    IntrinsicWidth(
                      child: TextField(
                        controller: fieldTextEditingController,
                        focusNode: fieldFocusNode,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: isTablet ? 15 : 14,
                        ),
                        decoration: InputDecoration(
                          hintText: selectedValues.isEmpty 
                            ? '$hint${isRequired ? ' *' : ''}' 
                            : '',
                          hintStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: isTablet ? 15 : 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 3, // slightly better vertical alignment
                          ),
                        ),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            setState(() {
                              if (!selectedValues.contains(value.trim())) {
                                selectedValues.add(value.trim());
                              }
                              fieldTextEditingController.clear();
                            });
                            fieldFocusNode.requestFocus();
                          }
                        },
                        onChanged: (value) {
                          if (value.endsWith(',') || value.endsWith(';')) {
                            final clean = value.replaceAll(RegExp(r'[,;]'), '').trim();
                            if (clean.isNotEmpty) {
                              setState(() {
                                if (!selectedValues.contains(clean)) {
                                  selectedValues.add(clean);
                                }
                                fieldTextEditingController.clear();
                              });
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
            },
          );
        },
        optionsViewBuilder: (
          BuildContext context,
          AutocompleteOnSelected<String> onSelected,
          Iterable<String> options,
        ) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 8.0,
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surface,
              shadowColor: Colors.black.withValues(alpha: 0.2),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 240),
                width: constraints.maxWidth,
                margin: const EdgeInsets.only(top: 4),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: options.length,
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, int index) {
                    final String option = options.elementAt(index);
                    return InkWell(
                      onTap: () => onSelected(option),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                              child: Text(
                                option.isNotEmpty ? option[0].toUpperCase() : '?',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: isTablet ? 15 : 14,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
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
          Container(
            height: 16,
            width: 1,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.2),
            margin: const EdgeInsets.symmetric(horizontal: 6),
          ),
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
           onPressed: _isSending ? null : _sendMail,
           icon: _isSending 
             ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
             : const Icon(Icons.send),
           label: Text(_isSending ? 'Sending...' : 'Send'),
        ),
      ),
    );
  }

  // AI Refinement Methods
  Future<void> _startVoiceRefinement() async {
    if (_refinementAttempts >= 2) {
      _showFeedback('Voice refinement limit reached (2/2). Edit manually.', isError: true);
      return;
    }

    try {
      setState(() => _isRecording = true);
      await _transcriptionService.startRecording(
        onSilenceDetected: () async {
          await _stopAndRefine();
        },
      );
      _showFeedback('Listening... Tap stop to refine.');
    } catch (e) {
      setState(() => _isRecording = false);
      _showFeedback('Failed to start recording: $e', isError: true);
    }
  }

  Future<void> _stopAndRefine() async {
    if (!_isRecording) return;
    
    try {
      final path = await _transcriptionService.stopRecording();
      setState(() => _isRecording = false);
      
      if (path != null) {
        _showFeedback('Transcribing...', isError: false);
        final instruction = await _transcriptionService.transcribe(path);
        if (instruction != null && instruction.isNotEmpty) {
           _refineWithInstruction(instruction);
        } else {
           _showFeedback('No voice detected', isError: true);
        }
      }
    } catch (e) {
      setState(() => _isRecording = false);
      _showFeedback('Refinement failed: $e', isError: true);
    }
  }
  
  Future<void> _refineWithInstruction(String instruction) async {
    setState(() {
      _isRefining = true;
      _refinementAttempts++;
    });

    try {
       // Get current content
       final currentSubject = _subjectController.text;
       final currentBody = _bodyController.document.toPlainText();
       
       final provider = context.read<MailProvider>();
       final result = await provider.refineEmail(currentSubject, currentBody, instruction);
       
       if (result != null && !result.containsKey('error')) {
          final newSubject = result['subject'];
          final newBodyHtml = result['body']; 
          
          // Update Subject
          if (newSubject != null) {
             _subjectController.text = newSubject;
          }
          
          // Update Body - Strip HTML for Quill (Basic approach)
          if (newBodyHtml != null) {
             String plainText = newBodyHtml
                .replaceAll(RegExp(r'<br\s*/?>'), '\n')
                .replaceAll(RegExp(r'</p>'), '\n\n')
                .replaceAll(RegExp(r'<[^>]*>'), '')
                .trim();
                
             _bodyController.clear();
             _bodyController.document.insert(0, plainText);
          }
          
          _showFeedback('Email refined by AI');
       } else {
          _showFeedback(result?['error'] ?? 'Refinement failed', isError: true);
       }
    } catch (e) {
       _showFeedback('Error during refinement: $e', isError: true);
    } finally {
       if (mounted) {
         setState(() => _isRefining = false);
       }
    }
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
  final String? cc;
  final String? bcc;
  MailItem({
    required this.sender,
    required this.subject,
    required this.preview,
    required this.time,
    required this.isUnread,
    required this.priority,
    this.cc,
    this.bcc,
  });
}

enum MailPriority { high, normal, low }
