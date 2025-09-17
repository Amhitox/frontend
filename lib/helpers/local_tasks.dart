import 'dart:convert';

import 'package:frontend/models/user.dart';
import 'package:frontend/utils/data_key.dart';
import 'package:frontend/models/task.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, List<String>>> addLocalTasks(
  String userId,
  Task task,
  DateTime selectedDate,
  bool isCompleted,
) async {
  final pref = await SharedPreferences.getInstance();
  final tasksJson = pref.getString('tasks_$userId');
  Map<String, List<String>> tasksMap =
      tasksJson != null
          ? Map<String, List<String>>.from(
            jsonDecode(
              tasksJson,
            ).map((k, v) => MapEntry(k, List<String>.from(v))),
          )
          : {};

  final dateKey = DataKey.dateKey(selectedDate);
  tasksMap.putIfAbsent(dateKey, () => []);
  tasksMap[dateKey]!.add(jsonEncode(task.toJson()));

  print("Tasks map added: $tasksMap");
  await pref.setString('tasks_$userId', jsonEncode(tasksMap));
  return tasksMap;
}

Future<Map<String, List<String>>> updateLocalTasks(
  String userId,
  Task newTask,
  DateTime selectedDate,
) async {
  final pref = await SharedPreferences.getInstance();
  final tasksJson = pref.getString('tasks_$userId');
  Map<String, List<String>> tasksMap =
      tasksJson != null
          ? Map<String, List<String>>.from(
            jsonDecode(
              tasksJson,
            ).map((k, v) => MapEntry(k, List<String>.from(v))),
          )
          : {};

  String? oldDateKey;
  for (String dateKey in tasksMap.keys.toList()) {
    List<String> tasks = tasksMap[dateKey]!;
    for (int i = 0; i < tasks.length; i++) {
      Map<String, dynamic> taskJson = jsonDecode(tasks[i]);
      if (taskJson['id'] == newTask.id) {
        tasks.removeAt(i);
        oldDateKey = dateKey;

        if (tasks.isEmpty) {
          tasksMap.remove(dateKey);
        }
        break;
      }
    }
    if (oldDateKey != null) break;
  }

  final newDateKey = DataKey.dateKey(selectedDate);
  tasksMap.putIfAbsent(newDateKey, () => []);
  tasksMap[newDateKey]!.add(jsonEncode(newTask.toJson()));

  await pref.setString('tasks_$userId', jsonEncode(tasksMap));
  return tasksMap;
}

Future<Map<String, List<String>>> getLocalTasks(DateTime selectedDate) async {
  final pref = await SharedPreferences.getInstance();
  final user = User.fromJson(jsonDecode(pref.getString('user')!));
  final tasksJson = pref.getString('tasks_${user.id}');

  final tasksMap =
      tasksJson != null
          ? Map<String, List<String>>.from(
            jsonDecode(
              tasksJson,
            ).map((k, v) => MapEntry(k, List<String>.from(v))),
          )
          : <String, List<String>>{};
  return tasksMap;
}
