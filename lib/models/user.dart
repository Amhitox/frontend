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
  String? subscriptionTier;
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
  });
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] as String?,
      email: json['email'] as String?,
      lang: json['lang'] as String?,
      lastName: json['lastName'] as String?,
      status: json['status'] as String?,
      firstName: json['firstName'] as String?,
      id: json['id'] as String?,
      workEmail: json['workEmail'] as String?,
      subscriptionTier: json['subscriptionTier'] as String?,
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
    return json;
  }
}
