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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid ?? '',
      'email': email ?? '',
      'lang': lang ?? '',
      'lastName': lastName ?? '',
      'status': status ?? '',
      'firstName': firstName ?? '',
      'id': id ?? '',
      'workEmail': workEmail ?? '',
    };
  }
}
