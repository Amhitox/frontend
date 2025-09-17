// ignore_for_file: constant_identifier_names

import 'dart:convert';

import 'package:frontend/models/task.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/providers/task_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheManager {
  final TaskProvider taskprovider;
  static const int CACHE_DAYS_RANGE = 7;
  static const String LAST_CLEANUP_KEY = 'last_cache_cleanup';
  static const String APP_VERSION_KEY = 'app_version';
  static const String CURRENT_APP_VERSION = '1.0.0';

  CacheManager(this.taskprovider);

  Future<void> runCacheManager() async {
    final pref = await SharedPreferences.getInstance();

    final firstOpen = pref.getBool("firstOpen");
    final mustSync = pref.getBool("mustSync") ?? false;

    if (firstOpen == null || firstOpen == true) {
      print('First launch detected. Setting up cache without syncing...');
      await pref.setString(APP_VERSION_KEY, CURRENT_APP_VERSION);
      await pref.setString(LAST_CLEANUP_KEY, DateTime.now().toIso8601String());
      print('First launch setup completed - data will be loaded on demand');
      return;
    } else if (mustSync == true) {
      print('Manual sync requested. Syncing cache...');

      await _clearAllCache();
      await _syncCacheFromServer();
      await pref.setBool("mustSync", false);
      await pref.setString(LAST_CLEANUP_KEY, DateTime.now().toIso8601String());

      print('Manual sync completed');
      return;
    } else {
      await _performDailyCleanupIfNeeded();
      return;
    }
  }

  Future<void> requestSync() async {
    final pref = await SharedPreferences.getInstance();
    await pref.setBool("mustSync", true);
    print('Sync requested for next app launch');
  }

  Future<void> _syncCacheFromServer() async {
    try {
      final now = DateTime.now();

      for (int i = -CACHE_DAYS_RANGE; i <= CACHE_DAYS_RANGE; i++) {
        final targetDate = now.add(Duration(days: i));
        await _syncTasksForDate(targetDate);

        await Future.delayed(const Duration(milliseconds: 150));
      }

      print('Successfully synced ${CACHE_DAYS_RANGE * 2 + 1} days of tasks');
    } catch (e) {
      print('Error syncing cache from server: $e');
    }
  }

  Future<void> _syncTasksForDate(DateTime date) async {
    try {
      final tasks = await taskprovider.getTasks(DataKey.dateKey(date));

      if (tasks.isNotEmpty) {
        await _cacheTasksForDate(tasks, date);
      }
    } catch (e) {
      print('Failed to sync tasks for ${date.toIso8601String()}: $e');
    }
  }

  Future<void> _cacheTasksForDate(List<Task> tasks, DateTime date) async {
    final pref = await SharedPreferences.getInstance();
    final user = User.fromJson(jsonDecode(pref.getString('user') ?? '{}'));

    final tasksJson = pref.getString('tasks_${user.id}');
    Map<String, List<String>> tasksMap =
        tasksJson != null
            ? Map<String, List<String>>.from(
              jsonDecode(
                tasksJson,
              ).map((k, v) => MapEntry(k, List<String>.from(v))),
            )
            : {};

    final dateKey = DataKey.dateKey(date);
    tasksMap[dateKey] = tasks.map((task) => jsonEncode(task.toJson())).toList();

    await pref.setString('tasks_${user.id}', jsonEncode(tasksMap));
  }

  Future<void> _performDailyCleanupIfNeeded() async {
    final pref = await SharedPreferences.getInstance();
    final lastCleanupStr = pref.getString(LAST_CLEANUP_KEY);

    if (lastCleanupStr != null) {
      final lastCleanup = DateTime.parse(lastCleanupStr);
      final now = DateTime.now();

      if (now.difference(lastCleanup).inHours >= 24) {
        await _performDailyCleanup();
        await pref.setString(LAST_CLEANUP_KEY, now.toIso8601String());
        print('Daily cache cleanup completed');
      }
    } else {
      await _performDailyCleanup();
      await pref.setString(LAST_CLEANUP_KEY, DateTime.now().toIso8601String());
    }
  }

  Future<void> _performDailyCleanup() async {
    final pref = await SharedPreferences.getInstance();
    final user = User.fromJson(jsonDecode(pref.getString('user') ?? '{}'));
    final tasksJson = pref.getString('tasks_${user.id}');

    if (tasksJson == null) return;

    Map<String, List<String>> tasksMap = Map<String, List<String>>.from(
      jsonDecode(tasksJson).map((k, v) => MapEntry(k, List<String>.from(v))),
    );

    final now = DateTime.now();
    final keysToRemove = <String>[];
    int removedCount = 0;

    for (String dateKey in tasksMap.keys) {
      final date = DataKey.dateFromKey(dateKey);
      final daysDifference = now.difference(date).inDays;

      if (daysDifference.abs() > CACHE_DAYS_RANGE) {
        keysToRemove.add(dateKey);
        removedCount += tasksMap[dateKey]?.length ?? 0;
      }
    }

    for (String key in keysToRemove) {
      tasksMap.remove(key);
    }

    if (keysToRemove.isNotEmpty) {
      await pref.setString('tasks_${user.id}', jsonEncode(tasksMap));
      print(
        'Removed $removedCount old cached tasks from ${keysToRemove.length} dates',
      );
    }

    await _syncNewDatesInRange();
  }

  Future<void> _syncNewDatesInRange() async {
    final pref = await SharedPreferences.getInstance();
    final user = User.fromJson(jsonDecode(pref.getString('user') ?? '{}'));
    final tasksJson = pref.getString('tasks_${user.id}');

    Set<String> cachedDateKeys =
        tasksJson != null
            ? jsonDecode(tasksJson).keys.cast<String>().toSet()
            : <String>{};

    final now = DateTime.now();

    for (int i = -CACHE_DAYS_RANGE; i <= CACHE_DAYS_RANGE; i++) {
      final targetDate = now.add(Duration(days: i));
      final dateKey = DataKey.dateKey(targetDate);

      if (!cachedDateKeys.contains(dateKey)) {
        await _syncTasksForDate(targetDate);
      }
    }
  }

  Future<void> _clearAllCache() async {
    final pref = await SharedPreferences.getInstance();
    final user = User.fromJson(jsonDecode(pref.getString('user') ?? '{}'));

    await pref.remove('tasks_${user.id}');
    print('Cleared all cached tasks');
  }

  bool shouldCacheDate(DateTime date) {
    final now = DateTime.now();
    final daysDifference = now.difference(date).inDays.abs();
    return daysDifference <= CACHE_DAYS_RANGE;
  }

  Future<void> refreshCache() async {
    print('Manual cache refresh initiated');
    await _clearAllCache();
    await _syncCacheFromServer();

    final pref = await SharedPreferences.getInstance();
    await pref.setString(LAST_CLEANUP_KEY, DateTime.now().toIso8601String());
  }
}

class DataKey {
  static String dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static DateTime dateFromKey(String key) {
    final parts = key.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}
