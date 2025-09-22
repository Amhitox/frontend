import 'package:hive/hive.dart';
part 'meeting_location.g.dart';
@HiveType(typeId: 3)
enum MeetingLocation {
  @HiveField(0)
  online,
  @HiveField(1)
  onsite,
}
