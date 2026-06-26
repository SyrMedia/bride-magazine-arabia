// lib/src/data/repositories/tools_repository.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/tools_data.dart';

const _kToolsStorageKey = 'tools_data_v1';

final toolsRepositoryProvider = Provider<ToolsRepository>((ref) {
  return ToolsRepository();
});

class ToolsRepository {
  Future<ToolsData?> loadMyToolsData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kToolsStorageKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return ToolsData.fromJson(map);
    } catch (_) {
      return null; // في حال بيانات قديمة/فاسدة
    }
  }

  Future<void> saveMyToolsData(ToolsData data, {String? note}) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(data.toJson());
    await prefs.setString(_kToolsStorageKey, jsonStr);
  }

  Future<void> clearToolsData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToolsStorageKey);
  }
}
