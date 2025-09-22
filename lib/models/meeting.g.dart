part of 'meeting.dart';
class MeetingAdapter extends TypeAdapter<Meeting> {
  @override
  final int typeId = 2;
  @override
  Meeting read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Meeting(
      id: fields[0] as String?,
      title: fields[1] as String?,
      description: fields[2] as String?,
      date: fields[3] as String?,
      startTime: fields[4] as String?,
      endTime: fields[5] as String?,
      attendees: (fields[6] as List?)?.cast<String>(),
      location: fields[7] as MeetingLocation?,
    );
  }
  @override
  void write(BinaryWriter writer, Meeting obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.startTime)
      ..writeByte(5)
      ..write(obj.endTime)
      ..writeByte(6)
      ..write(obj.attendees)
      ..writeByte(7)
      ..write(obj.location);
  }
  @override
  int get hashCode => typeId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeetingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
