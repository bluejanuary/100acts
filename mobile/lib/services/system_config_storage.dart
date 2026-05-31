import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/system_config.dart';

class SystemConfigStorage {
  static const _key = 'system_config';

  static Future<void> save(SystemConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(config.toJson()));
  }

  static Future<SystemConfig?> get() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    return SystemConfig.fromJson(jsonDecode(raw));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
