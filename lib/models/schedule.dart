import 'package:flutter/material.dart';
import 'meetingtype.dart';

class Schedule {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final MeetingType type;
  final List<String>? attendees;

  Schedule({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.attendees,
  });
}
