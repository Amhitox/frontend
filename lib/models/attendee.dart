import 'package:hive/hive.dart';

part 'attendee.g.dart';

@HiveType(typeId: 4)
class Attendee extends HiveObject {
  @HiveField(0)
  final String email;

  @HiveField(1)
  final String name;

  Attendee({
    required this.email,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
    };
  }

  factory Attendee.fromJson(Map<String, dynamic> json) {
    return Attendee(
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  @override
  String toString() => email;
}
