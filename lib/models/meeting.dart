import 'package:hive/hive.dart';
import 'meeting_location.dart';
part 'meeting.g.dart';
@HiveType(typeId: 2)
class Meeting extends HiveObject {
  @HiveField(0)
  String? id;
  @HiveField(1)
  final String? title;
  @HiveField(2)
  final String? description;
  @HiveField(3)
  final String? date;
  @HiveField(4)
  final String? startTime;
  @HiveField(5)
  final String? endTime;
  @HiveField(6)
  final List<String>? attendees;
  @HiveField(7)
  final MeetingLocation? location;
  Meeting({
    this.id,
    this.title,
    this.description,
    this.date,
    this.startTime,
    this.endTime,
    this.attendees,
    this.location,
  });
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'attendees': attendees,
      'location': location,
    };
  }
  factory Meeting.fromJson(Map<String, dynamic> json) {
    String? normalizedDate = json['date'];
    String? startTime = json['startTime'];
    
    if (normalizedDate == null && startTime != null && startTime.contains('T')) {
       normalizedDate = startTime.split('T').first;
    } else if (normalizedDate != null && normalizedDate.contains('T')) {
       normalizedDate = normalizedDate.split('T').first;
    }
    
    return Meeting(
      id: json['eventId'] ?? json['id'] ?? '', 
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      date: normalizedDate ?? '',
      startTime: startTime ?? '',
      endTime: json['endTime'] ?? '',
      attendees: (json['attendees'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [], // Safe cast
      location: _parseLocation(json['location']),
    );
  }
  static MeetingLocation _parseLocation(String? locationString) {
    switch (locationString?.toLowerCase()) {
      case 'online':
        return MeetingLocation.online;
      case 'onsite':
        return MeetingLocation.onsite;
      default:
        return MeetingLocation.online;
    }
  }
  Meeting copyWith({
    String? id,
    String? title,
    String? description,
    String? date,
    String? startTime,
    String? endTime,
    List<String>? attendees,
    MeetingLocation? location,
  }) {
    return Meeting(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      attendees: attendees ?? this.attendees,
      location: location ?? this.location,
    );
  }
}
