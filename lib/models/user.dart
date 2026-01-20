class User {
  String? uid;
  String? email;
  String? lang;
  String? lastName;
  final String? status;
  String? firstName;
  final String? id;
  String? workEmail;
  DateTime? birthday;
  String? subscriptionStatus;
  DateTime? currentPeriodEnd;
  String? subscriptionTier;
  String? subscriptionPeriod;
  DateTime? trialEndDate;
  String? jobTitle;
  Map<String, dynamic>? voicePreferences;

  User({
    this.uid,
    this.email,
    this.lang,
    this.firstName,
    this.lastName,
    this.id,
    this.workEmail,
    this.birthday,
    this.status,
    this.subscriptionTier,
    this.subscriptionStatus,
    this.trialEndDate,
    this.subscriptionPeriod,
    this.jobTitle,
    this.voicePreferences,
    this.currentPeriodEnd,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: (json['uid'] ?? json['id']) as String?,
      email: json['email'] as String?,
      lang: json['lang'] as String?,
      lastName: json['lastName'] as String?,
      status: json['status'] as String?,
      firstName: json['firstName'] as String?,
      id: (json['id'] ?? json['uid']) as String?,
      workEmail: json['workEmail'] as String?,
      subscriptionTier: json['subscriptionTier'] as String?,
      subscriptionStatus: json['subscriptionStatus'] as String?,
      subscriptionPeriod: json['subscriptionPeriod'] as String?,
      trialEndDate: json['trialEndDate'] is String ? DateTime.parse(json['trialEndDate']) : null,
      currentPeriodEnd: json['currentPeriodEnd'] is String ? DateTime.parse(json['currentPeriodEnd']) : null,
      jobTitle: json['jobTitle'] as String?,
      voicePreferences: json['voicePreferences'] as Map<String, dynamic>?,
    );
  }
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (uid != null) json['uid'] = uid;
    if (email != null) json['email'] = email;
    if (lang != null) json['lang'] = lang;
    if (lastName != null) json['lastName'] = lastName;
    if (status != null) json['status'] = status;
    if (firstName != null) json['firstName'] = firstName;
    if (id != null) json['id'] = id;
    if (workEmail != null && workEmail!.isNotEmpty) {
      json['workEmail'] = workEmail;
    }
    if (subscriptionTier != null) json['subscriptionTier'] = subscriptionTier;
    if (subscriptionStatus != null) json['subscriptionStatus'] = subscriptionStatus;
    if (subscriptionPeriod != null) json['subscriptionPeriod'] = subscriptionPeriod;
    if (trialEndDate != null) json['trialEndDate'] = trialEndDate!.toIso8601String();
    if (currentPeriodEnd != null) json['currentPeriodEnd'] = currentPeriodEnd!.toIso8601String();
    if (jobTitle != null) json['jobTitle'] = jobTitle;
    if (voicePreferences != null) json['voicePreferences'] = voicePreferences;
    return json;
  }

  User copyWith({
    String? uid,
    String? email,
    String? lang,
    String? lastName,
    String? status,
    String? firstName,
    String? id,
    String? workEmail,
    String? subscriptionTier,
    String? subscriptionStatus,
    String? subscriptionPeriod,
    DateTime? trialEndDate,
    DateTime? currentPeriodEnd,
    String? jobTitle,
    Map<String, dynamic>? voicePreferences,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      lang: lang ?? this.lang,
      lastName: lastName ?? this.lastName,
      status: status ?? this.status,
      firstName: firstName ?? this.firstName,
      id: id ?? this.id,
      workEmail: workEmail ?? this.workEmail,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionPeriod: subscriptionPeriod ?? this.subscriptionPeriod,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      currentPeriodEnd: currentPeriodEnd ?? this.currentPeriodEnd,
      jobTitle: jobTitle ?? this.jobTitle,
      voicePreferences: voicePreferences ?? this.voicePreferences,
    );
  }
}
