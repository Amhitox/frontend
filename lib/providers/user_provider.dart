import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService userService;

  UserProvider({required Dio dio}) : userService = UserService(dio: dio);

  Future<dynamic> updateUser(String? id, User user) async {
    try {
      final response = userService.updateUser(id, user);
      print(response);
      return response;
    } on DioException catch (e) {
      print('$e');
      return null;
    }
  }
}
