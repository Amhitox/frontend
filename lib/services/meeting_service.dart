import 'package:dio/dio.dart';
import '../models/attendee.dart';

class MeetingService {
  final Dio _dio;

  MeetingService({required Dio dio}) : _dio = dio;

  Future<Response> getMeetings(String date) async {
    try {
      final response = await _dio.get(
        "/api/calendar/events",
        queryParameters: {"date": date},
      );
      return response;
    } on DioException catch (e) {
      return e.response ??
          Response(
            data: {'error': 'Network error'},
            statusCode: 500,
            requestOptions: RequestOptions(path: '/api/calendar/events'),
          );
    }
  }

  Future<Response> getAllMeetings() async {
    try {
      final response = await _dio.get("/api/calendar/events");
      return response;
    } on DioException catch (e) {
      return e.response ??
          Response(
            data: {'error': 'Network error'},
            statusCode: 500,
            requestOptions: RequestOptions(path: '/api/calendar/events'),
          );
    }
  }

  Future<Response> addMeeting(
    String title,
    String description,
    String startDateTime,
    String endDateTime,
    List<Attendee> attendees,
    String location,
    String timezoneOffset, // Timezone offset in format "+05:30" or "-05:00"
  ) async {
    try {
      final response = await _dio.post(
        "/api/calendar/events",
        data: {
          "title": title,
          "description": description,
          "startTime": startDateTime,
          "endTime": endDateTime,
          "location": location,
          "attendees": attendees.map((e) => e.toJson()).toList(), // Include attendees for notifications
          "timezoneOffset": timezoneOffset, // Send timezone offset for accurate scheduling
        },
      );
      return response;
    } on DioException catch (e) {
      return Response(
        data: e.response?.data ?? {'error': 'Network error'},
        statusCode: e.response?.statusCode ?? 500,
        requestOptions: e.requestOptions,
      );
    }
  }

  Future<Response> updateMeeting(
    String meetingId,
    String title,
    String description,
    String startDateTime,
    String endDateTime,
    List<Attendee> attendees,
    String location,
    String timezoneOffset, // Timezone offset in format "+05:30" or "-05:00"
  ) async {
    try {
      final response = await _dio.put(
        "/api/calendar/events/$meetingId",
        data: {
          "title": title,
          "description": description,
          "startTime": startDateTime,
          "endTime": endDateTime,
          "location": location,
          "attendees": attendees.map((e) => e.toJson()).toList(), // Include attendees for notifications
          "timezoneOffset": timezoneOffset, // Send timezone offset for accurate scheduling
        },
      );
      return response;
    } on DioException catch (e) {
      return Response(
        data: e.response?.data ?? {'error': 'Network error'},
        statusCode: e.response?.statusCode ?? 500,
        requestOptions: e.requestOptions,
      );
    }
  }

  Future<Response> deleteMeeting(String meetingId) async {
    try {
      final response = await _dio.delete("/api/calendar/events/$meetingId");
      return response;
    } on DioException catch (e) {
      return Response(
        data: e.response?.data ?? {'error': 'Network error'},
        statusCode: e.response?.statusCode ?? 500,
        requestOptions: e.requestOptions,
      );
    }
  }

  Future<Response> getSuggestedAttendees({String? query}) async {
    try {
      final response = await _dio.get(
        "/api/calendar/attendees",
        queryParameters: query != null && query.isNotEmpty ? {"q": query} : null,
      );
      return response;
    } on DioException catch (e) {
      return e.response ??
          Response(
            data: {'error': 'Network error'},
            statusCode: 500,
            requestOptions: RequestOptions(path: '/api/calendar/attendees'),
          );
    }
  }
}
