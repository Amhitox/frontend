class QuotaStatus {
  final String tier;
  final QuotaLimits limits;
  final QuotaUsage usage;
  final QuotaRemaining remaining;

  QuotaStatus({
    required this.tier,
    required this.limits,
    required this.usage,
    required this.remaining,
  });

  factory QuotaStatus.fromJson(Map<String, dynamic> json) {
    return QuotaStatus(
      tier: json['tier'] as String,
      limits: QuotaLimits.fromJson(json['limits'] as Map<String, dynamic>),
      usage: QuotaUsage.fromJson(json['usage'] as Map<String, dynamic>),
      remaining: QuotaRemaining.fromJson(json['remaining'] as Map<String, dynamic>),
    );
  }
}

class QuotaLimits {
  final int tasksPerDay;
  final int eventsPerDay;
  final int voiceEmailsPerDay;
  final int priorityEmailsTotal;

  QuotaLimits({
    required this.tasksPerDay,
    required this.eventsPerDay,
    required this.voiceEmailsPerDay,
    required this.priorityEmailsTotal,
  });

  factory QuotaLimits.fromJson(Map<String, dynamic> json) {
    return QuotaLimits(
      tasksPerDay: json['tasksPerDay'] as int,
      eventsPerDay: json['eventsPerDay'] as int,
      voiceEmailsPerDay: json['voiceEmailsPerDay'] as int,
      priorityEmailsTotal: json['priorityEmailsTotal'] as int,
    );
  }
}

class QuotaUsage {
  final int tasks;
  final int events;
  final int voiceEmails;
  final int priorityEmails;

  QuotaUsage({
    required this.tasks,
    required this.events,
    required this.voiceEmails,
    required this.priorityEmails,
  });

  factory QuotaUsage.fromJson(Map<String, dynamic> json) {
    return QuotaUsage(
      tasks: json['tasks'] as int,
      events: json['events'] as int,
      voiceEmails: json['voiceEmails'] as int,
      priorityEmails: json['priorityEmails'] as int,
    );
  }
}

class QuotaRemaining {
  final int tasks;
  final int events;
  final int voiceEmails;
  final int priorityEmails;

  QuotaRemaining({
    required this.tasks,
    required this.events,
    required this.voiceEmails,
    required this.priorityEmails,
  });

  factory QuotaRemaining.fromJson(Map<String, dynamic> json) {
    return QuotaRemaining(
      tasks: json['tasks'] as int,
      events: json['events'] as int,
      voiceEmails: json['voiceEmails'] as int,
      priorityEmails: json['priorityEmails'] as int,
    );
  }
}
