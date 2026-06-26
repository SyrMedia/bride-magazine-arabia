// lib/src/core/app_cache.dart
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class AppCache {
  static late AppCache _instance;
  final Box<String> _box;

  AppCache._(this._box);

  static Future<void> init() async {
    final box = await Hive.openBox<String>('api_cache');
    _instance = AppCache._(box);
  }

  static AppCache get I => _instance;

  // يحفظ أي كائن (Map/List) كنص JSON مع ختم وقت و TTL بالثواني
  Future<void> put(String key, Object data, Duration ttl) async {
    final wrap = {
      'ts': DateTime.now().millisecondsSinceEpoch,
      'ttl': ttl.inSeconds,
      'data': data,
    };
    await _box.put(key, jsonEncode(wrap));
  }

  // يقرأ ويعيد "data" فقط إذا كان صالح (ضمن TTL)، وإلا null
  T? getValid<T>(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (map['ts'] as num?)?.toInt() ?? 0;
      final ttl = (map['ttl'] as num?)?.toInt() ?? 0;
      final ageSec =
      ((DateTime.now().millisecondsSinceEpoch - ts) / 1000).floor();
      if (ageSec <= ttl) {
        return map['data'] as T;
      }
    } catch (_) {}
    return null;
  }

  // يرجع آخر نسخة حتى لو منتهية الصلاحية (fallback)
  T? getStale<T>(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map['data'] as T;
    } catch (_) {
      return null;
    }
  }

  Future<void> remove(String key) => _box.delete(key);
  Future<void> clear() => _box.clear();
}
