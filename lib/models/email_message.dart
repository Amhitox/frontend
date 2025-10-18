class EmailMessage {
  final String id;
  final String threadId;
  final String sender;
  final String senderEmail;
  final String subject;
  final String snippet;
  final String body;
  final DateTime date;
  final bool isUnread;
  final List<String> labelIds;
  final bool hasAttachments;
  final List<EmailAttachment>? attachments;

  EmailMessage({
    required this.id,
    required this.threadId,
    required this.sender,
    required this.senderEmail,
    required this.subject,
    required this.snippet,
    required this.body,
    required this.date,
    required this.isUnread,
    required this.labelIds,
    required this.hasAttachments,
    this.attachments,
  });

  factory EmailMessage.fromJson(Map<String, dynamic> json) {
    return EmailMessage(
      id: json['id'] as String,
      threadId: json['threadId'] as String,
      sender: json['sender'] as String,
      senderEmail: json['senderEmail'] as String,
      subject: json['subject'] as String,
      snippet: json['snippet'] as String,
      body: json['body'] as String,
      date: DateTime.parse(json['date'] as String),
      isUnread: json['isUnread'] as bool,
      labelIds: List<String>.from(json['labelIds'] as List),
      hasAttachments: json['hasAttachments'] as bool,
      attachments:
          json['attachments'] != null
              ? (json['attachments'] as List)
                  .map(
                    (a) => EmailAttachment.fromJson(a as Map<String, dynamic>),
                  )
                  .toList()
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'threadId': threadId,
      'sender': sender,
      'senderEmail': senderEmail,
      'subject': subject,
      'snippet': snippet,
      'body': body,
      'date': date.toIso8601String(),
      'isUnread': isUnread,
      'labelIds': labelIds,
      'hasAttachments': hasAttachments,
      'attachments': attachments?.map((a) => a.toJson()).toList(),
    };
  }

  // Helper method to get formatted time string
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Helper method to get sender initials
  String get senderInitials {
    final parts = sender.split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class EmailAttachment {
  final String filename;
  final String mimeType;
  final int size;
  final String attachmentId;

  EmailAttachment({
    required this.filename,
    required this.mimeType,
    required this.size,
    required this.attachmentId,
  });

  factory EmailAttachment.fromJson(Map<String, dynamic> json) {
    return EmailAttachment(
      filename: json['filename'] as String,
      mimeType: json['mimeType'] as String,
      size: json['size'] as int,
      attachmentId: json['attachmentId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'mimeType': mimeType,
      'size': size,
      'attachmentId': attachmentId,
    };
  }

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get fileIcon {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'xls':
      case 'xlsx':
        return '📊';
      case 'ppt':
      case 'pptx':
        return '📋';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return '🖼️';
      case 'zip':
      case 'rar':
        return '📦';
      default:
        return '📎';
    }
  }
}

class EmailListResponse {
  final List<EmailMessage> messages;
  final String? nextPageToken;
  final int resultSizeEstimate;

  EmailListResponse({
    required this.messages,
    this.nextPageToken,
    required this.resultSizeEstimate,
  });

  factory EmailListResponse.fromJson(Map<String, dynamic> json) {
    return EmailListResponse(
      messages:
          (json['messages'] as List)
              .map((m) => EmailMessage.fromJson(m as Map<String, dynamic>))
              .toList(),
      nextPageToken: json['nextPageToken'] as String?,
      resultSizeEstimate: json['resultSizeEstimate'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messages': messages.map((m) => m.toJson()).toList(),
      'nextPageToken': nextPageToken,
      'resultSizeEstimate': resultSizeEstimate,
    };
  }
}
