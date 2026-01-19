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

  Future<dynamic> updateVoicePreference(String voiceId) async {
    try {
      final data = {
        "voicePreferences": {
          "defaultTtsVoiceId": voiceId
        }
      };
      final response = await userService.updateProfile(data);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserData(User updatedUser) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(updatedUser.toJson()));
    } catch (e) {}
  }
  List<String> _priorityEmails = [];
  List<String> get priorityEmails => _priorityEmails;

  Future<void> fetchPriorityEmails(String userId) async {
    try {
      _priorityEmails = await userService.getPriorityEmails(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching priority emails: $e');
    }
  }

  Future<void> addPriorityEmail(String userId, String email) async {
    try {
      await userService.addPriorityEmail(userId, email);
      if (!_priorityEmails.contains(email)) {
        _priorityEmails.add(email);
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removePriorityEmail(String userId, String email) async {
    try {
      await userService.removePriorityEmail(userId, email);
      if (_priorityEmails.contains(email)) {
        _priorityEmails.remove(email);
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> changePassword(String oldPassword, String newPassword, String confirmPassword) async {
    try {
      final response = await userService.changePassword(oldPassword, newPassword, confirmPassword);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
