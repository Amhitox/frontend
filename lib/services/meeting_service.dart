import 'package:dio/dio.dart';

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

  Future<Response> addMeeting(
    String title,
    String description,
    String startDateTime,
    String endDateTime,
    List<String> attendees,
    String location,
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
    List<String> attendees,
    String location,
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
}
