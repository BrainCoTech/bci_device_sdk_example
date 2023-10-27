import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceService {
  final Future<SharedPreferences> _prefsFuture =
      SharedPreferences.getInstance();

  static SharedPreferenceService instance = SharedPreferenceService();

  Future<T> get<T>(String key, T defaultValue) async {
    T? result;
    if (defaultValue is bool) {
      result = (await _prefsFuture).getBool(key) as T?;
    } else if (defaultValue is String) {
      result = (await _prefsFuture).getString(key) as T?;
    } else if (defaultValue is double) {
      result = (await _prefsFuture).getDouble(key) as T?;
    } else if (defaultValue is int) {
      result = (await _prefsFuture).getInt(key) as T?;
    } else if (defaultValue is List<String>) {
      result = (await _prefsFuture).getStringList(key) as T?;
    } else {
      result = null;
      debugPrint('SharedPreferenceService: get($key, $T) not supported');
    }
    return result ?? defaultValue;
  }

  Future<dynamic> getRaw<T>(String key, T typeValue) async {
    Object? result;
    if (typeValue is bool) {
      result = (await _prefsFuture).getBool(key);
    } else if (typeValue is String) {
      result = (await _prefsFuture).getString(key);
    } else if (typeValue is double) {
      result = (await _prefsFuture).getDouble(key);
    } else if (typeValue is int) {
      result = (await _prefsFuture).getInt(key);
    } else {
      result = null;
      debugPrint('SharedPreferenceService: getRaw($key, $T) not supported');
    }
    return result;
  }

  Future set<T>(String key, T value) async {
    if (value is bool) {
      await (await _prefsFuture).setBool(key, value);
    } else if (value is String) {
      await (await _prefsFuture).setString(key, value);
    } else if (value is double) {
      await (await _prefsFuture).setDouble(key, value);
    } else if (value is int) {
      await (await _prefsFuture).setInt(key, value);
    } else if (value is List<String>) {
      await (await _prefsFuture).setStringList(key, value);
    } else {
      debugPrint(
          'SharedPreferenceService: set($key, $T) not supported, value=$value');
    }
  }

  Future<bool> clear() async {
    return (await _prefsFuture).clear();
  }

  Future<bool> remove(String key) async {
    return (await _prefsFuture).remove(key);
  }
}

class SharedPreferenceKey {
  static String lastHeadbandWifi(String headName) =>
      'last_headband_wifi_$headName';
  static const String group = 'game_group';
  static const String lastHeadbandSn = 'last_headband_sn';
  static const String isSkipHeadbandStep1 = 'is_skip_headband_step1';
}
