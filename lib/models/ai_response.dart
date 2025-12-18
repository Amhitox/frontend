class AiResponse {
  final String? action;
  final Map<String, dynamic>? payload;
  final num? confidence;
  final List<AiAction>? actions;
  final String? summary;
  final GeneratedEmail? generatedEmail;
  final bool? isFromAi;

  AiResponse({
    this.action,
    this.payload,
    this.confidence,
    this.actions,
    this.summary,
    this.generatedEmail,
    this.isFromAi,
  });

  factory AiResponse.fromJson(Map<String, dynamic> json) {
    return AiResponse(
      action: json['action'],
      payload: json['payload'],
      confidence: json['confidence'],
      actions: json['actions'] != null
          ? (json['actions'] as List).map((i) => AiAction.fromJson(i)).toList()
          : null,
      summary: json['summary'],
      generatedEmail: json['generatedEmail'] != null
          ? GeneratedEmail.fromJson(json['generatedEmail'])
          : null,
      isFromAi: json['isFromAi'],
    );
  }
}

class AiAction {
  final String? type;
  final String? status;
  final Map<String, dynamic>? data;
  final String? message;
  final String? deletedId;

  AiAction({this.type, this.status, this.data, this.message, this.deletedId});

  factory AiAction.fromJson(Map<String, dynamic> json) {
    return AiAction(
      type: json['type'],
      status: json['status'],
      data: json['data'] is Map<String, dynamic> ? json['data'] : null,
      message: json['message'],
      deletedId: json['deletedId'],
    );
  }
}

class GeneratedEmail {
  final String? subject;
  final String? body;

  GeneratedEmail({this.subject, this.body});

  factory GeneratedEmail.fromJson(Map<String, dynamic> json) {
    return GeneratedEmail(
      subject: json['subject'],
      body: json['body'],
    );
  }

  Map<String, dynamic> toJson() {
      return {
          'subject': subject,
          'body': body,
      };
  }
}
