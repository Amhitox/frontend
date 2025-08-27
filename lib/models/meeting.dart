import 'meetingtype.dart';

class Meeting {
  final String title;
  final String time;
  final String duration;
  final List<String> attendees;
  final MeetingType type;

  Meeting({
    required this.title,
    required this.time,
    required this.duration,
    required this.attendees,
    required this.type,
  });
}
