// lib/src/features/tools/food_db.dart
import 'dart:convert';
import 'package:flutter/services.dart';

class FoodItem {
  final String name;
  final List<String> aliases;
  final double calPer100g;

  FoodItem({required this.name, required this.aliases, required this.calPer100g});

  factory FoodItem.fromJson(Map<String, dynamic> j) {
    return FoodItem(
      name: (j['name'] ?? '').toString(),
      aliases: (j['aliases'] is List) ? (j['aliases'] as List).map((e) => e.toString()).toList() : [],
      calPer100g: (j['cal_per_100g'] is num) ? (j['cal_per_100g'] as num).toDouble() : double.tryParse('${j['cal_per_100g']}') ?? 0,
    );
  }
}

class FoodDatabase {
  FoodDatabase._(this._list);
  final List<FoodItem> _list;

  static FoodDatabase? _instance;

  static Future<FoodDatabase> loadFromAsset(String assetPath) async {
    if (_instance != null) return _instance!;
    final raw = await rootBundle.loadString(assetPath);
    final data = json.decode(raw) as List<dynamic>;
    final list = data.whereType<Map<String, dynamic>>().map(FoodItem.fromJson).toList();
    _instance = FoodDatabase._(list);
    return _instance!;
  }

  /// بحث بسيط: يطابق الاسم أو أي alias جزئيًا (case-insensitive)
  List<FoodItem> search(String q, {int limit = 8}) {
    final term = q.trim().toLowerCase();
    if (term.isEmpty) return [];
    final ranked = <MapEntry<FoodItem,int>>[];
    for (final f in _list) {
      final n = f.name.toLowerCase();
      final aliases = f.aliases.map((a) => a.toLowerCase()).toList();
      int score = 999;
      if (n == term) score = 0;
      else if (n.startsWith(term)) score = 1;
      else if (n.contains(term)) score = 3;
      else {
        for (final a in aliases) {
          if (a == term) { score = 1; break; }
          if (a.startsWith(term)) { score = 2; break; }
          if (a.contains(term)) { score = 4; break; }
        }
      }
      if (score != 999) ranked.add(MapEntry(f, score));
    }
    ranked.sort((a,b) => a.value.compareTo(b.value));
    return ranked.map((e) => e.key).take(limit).toList();
  }

  /// حساب السعرات من اسم عنصر وجرام (إذا عُثر على أكثر من نتيجة يعيد الأولى)
  double? caloriesFor(String name, double grams) {
    final found = search(name, limit: 1);
    if (found.isEmpty) return null;
    final base = found.first.calPer100g;
    return base * grams / 100.0;
  }
}
