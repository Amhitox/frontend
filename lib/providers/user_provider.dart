import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  final UserService userService;
  UserProvider({required Dio dio}) : userService = UserService(dio: dio);
  Future<dynamic> updateUser(String? id, User user) async {
    try {
      final response = userService.updateUser(id, user);
      return response;
    } on DioException {
      return null;
    }
  }

  Future<void> updateUserData(User updatedUser) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(updatedUser.toJson()));
    } catch (e) {}
  }
}
