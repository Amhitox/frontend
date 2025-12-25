import 'package:cloud_firestore/cloud_firestore.dart';

class EmailHeaders {
  final String? subject;
  final String? from;
  final String? to;
  final String? date;
  final String? cc;
  final String? bcc;

  EmailHeaders({this.subject, this.from, this.to, this.date, this.cc, this.bcc});

  factory EmailHeaders.fromJson(Map<String, dynamic> json) {
    return EmailHeaders(
      subject: json['subject'] as String?,
      from: json['from'] as String?,
      to: json['to'] as String?,
      date: json['date'] as String?,
      cc: json['cc'] as String?,
      bcc: json['bcc'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (subject != null) 'subject': subject,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
      if (date != null) 'date': date,
      if (cc != null) 'cc': cc,
      if (bcc != null) 'bcc': bcc,
    };
  }
}

class EmailMessage {
  final String id;
  final String threadId;
  final String? draftId;
  final String sender;
  final String senderEmail;
  final String subject;
  final String snippet;
  final String body;
  final DateTime date;
  final bool isUnread;
  final bool isImportant;
  final bool isSpam;
  final List<String> labelIds;
  final bool hasAttachments;
  final List<EmailAttachment>? attachments;
  final EmailHeaders? headers;
  final String? summary;

  EmailMessage({
    required this.id,
    required this.threadId,
    this.draftId,
    required this.sender,
    required this.senderEmail,
    required this.subject,
    required this.snippet,
    required this.body,
    required this.date,
    required this.isUnread,
    this.isImportant = false,
    this.isSpam = false,
    required this.labelIds,
    required this.hasAttachments,
    this.attachments,
    this.headers,
    this.summary,
  });

  factory EmailMessage.fromJson(Map<String, dynamic> json) {
    return EmailMessage(
      id: json['id'] as String,
      threadId: json['threadId'] as String,
      draftId: json['draftId'] as String?,
      sender: json['sender'] as String,
      senderEmail: json['senderEmail'] as String,
      subject: json['subject'] as String,
      snippet: json['snippet'] as String,
      body: json['body'] as String,
      date: DateTime.parse(json['date'] as String),
      isUnread: json['isUnread'] as bool? ?? false,
      isImportant: json['isImportant'] as bool? ?? false,
      isSpam: json['isSpam'] as bool? ?? false,
      labelIds: List<String>.from(json['labelIds'] as List? ?? []),
      hasAttachments: json['hasAttachments'] as bool,
      attachments:
          json['attachments'] != null
              ? (json['attachments'] as List)
                  .map(
                    (a) => EmailAttachment.fromJson(a as Map<String, dynamic>),
                  )
                  .toList()
              : null,
      headers:
          json['headers'] != null
              ? EmailHeaders.fromJson(json['headers'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'threadId': threadId,
      if (draftId != null) 'draftId': draftId,
      'sender': sender,
      'senderEmail': senderEmail,
      'subject': subject,
      'snippet': snippet,
      'body': body,
      'date': date.toIso8601String(),
      'isUnread': isUnread,
      'isImportant': isImportant,
      'isSpam': isSpam,
      'labelIds': labelIds,
      'hasAttachments': hasAttachments,
      'attachments': attachments?.map((a) => a.toJson()).toList(),
      if (headers != null) 'headers': headers!.toJson(),
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

  factory EmailMessage.fromFirestore(Map<String, dynamic> data, String id) {
    // Parse date
    DateTime date = DateTime.now();
    if (data['date'] != null) {
      if (data['date'] is Timestamp) {
        date = (data['date'] as Timestamp).toDate();
      } else if (data['date'] is String) {
        try {
          date = DateTime.parse(data['date']);
        } catch (e) {
          print('❌ Error parsing date: ${data['date']}');
        }
      }
    }

    return EmailMessage(
      id: id,
      threadId: data['threadId'] as String? ?? id,
      draftId: null,
      sender: data['from'] as String? ?? 'Unknown',
      senderEmail: data['from'] as String? ?? '', // Parsing email from string might be needed if "Name <email>" format
      subject: data['subject'] as String? ?? '(No Subject)',
      snippet: data['snippet'] as String? ?? '',
      body: '', // Body not available in summary list
      date: date,
      isUnread: true, // Specific field might be needed in Firestore
      isImportant: false,
      isSpam: false,
      labelIds: [],
      hasAttachments: false,
      summary: data['summary'] as String?,
    );
  }
  // CopyWith method
  EmailMessage copyWith({
    String? id,
    String? threadId,
    String? draftId,
    String? sender,
    String? senderEmail,
    String? subject,
    String? snippet,
    String? body,
    DateTime? date,
    bool? isUnread,
    bool? isImportant,
    bool? isSpam,
    List<String>? labelIds,
    bool? hasAttachments,
    List<EmailAttachment>? attachments,
    EmailHeaders? headers,
    String? summary,
  }) {
    return EmailMessage(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      draftId: draftId ?? this.draftId,
      sender: sender ?? this.sender,
      senderEmail: senderEmail ?? this.senderEmail,
      subject: subject ?? this.subject,
      snippet: snippet ?? this.snippet,
      body: body ?? this.body,
      date: date ?? this.date,
      isUnread: isUnread ?? this.isUnread,
      isImportant: isImportant ?? this.isImportant,
      isSpam: isSpam ?? this.isSpam,
      labelIds: labelIds ?? this.labelIds,
      hasAttachments: hasAttachments ?? this.hasAttachments,
      attachments: attachments ?? this.attachments,
      headers: headers ?? this.headers,
      summary: summary ?? this.summary,
    );
  }
}

class EmailAttachment {
  final String filename;
  final String mimeType;
  final int size;
  final String? attachmentId;

  EmailAttachment({
    required this.filename,
    required this.mimeType,
    required this.size,
    this.attachmentId,
  });

  factory EmailAttachment.fromJson(Map<String, dynamic> json) {
    return EmailAttachment(
      filename: json['filename'] as String,
      mimeType: json['mimeType'] as String,
      size: json['size'] as int,
      attachmentId: json['attachmentId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'mimeType': mimeType,
      'size': size,
      if (attachmentId != null) 'attachmentId': attachmentId,
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
