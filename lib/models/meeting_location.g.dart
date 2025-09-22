part of 'meeting_location.dart';
class MeetingLocationAdapter extends TypeAdapter<MeetingLocation> {
  @override
  final int typeId = 3;
  @override
  MeetingLocation read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MeetingLocation.online;
      case 1:
        return MeetingLocation.onsite;
      default:
        return MeetingLocation.online;
    }
  }
  @override
  void write(BinaryWriter writer, MeetingLocation obj) {
    switch (obj) {
      case MeetingLocation.online:
        writer.writeByte(0);
        break;
      case MeetingLocation.onsite:
        writer.writeByte(1);
        break;
    }
  }
  @override
  int get hashCode => typeId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeetingLocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
