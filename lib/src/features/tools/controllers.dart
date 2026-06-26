import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models.dart';

/// أسماء الصناديق/المفاتيح
const _boxName = 'toolsBox';
const _kTasks = 'tasks';
const _kShopping = 'shopping';
const _kBudget = 'budget';
const _kCurrency = 'budgetCurrency'; // 'USD' or 'SYP'

final toolsBoxProvider = Provider<Box>((ref) => Hive.box(_boxName));

String _rid() => '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(9999)}';

/// ========= بيانات افتراضية =========
final _defaultTasks = <String>[
  'تحديد تاريخ الزفاف المبدئي',
  'تحديد الميزانية الإجمالية',
  'اختيار القاعة/المكان',
  'حجز المصوّر (فيديو/فوتو)',
  'التواصل مع منسّق الزفاف/الديكور',
  'إعداد قائمة ضيوف مبدئية',
  'اختيار فستان العروس',
  'اختيار بدلة العريس',
  'بوكيه العروس وزهور القاعة',
  'تصاميم الدعوات',
  'اختيار فرقة/دي جي',
  'حجوزات السفر (إن وجدت)',
];

final _defaultShopping = <String>[
  'فستان العروس',
  'طرحة / تاج',
  'مجوهرات العروس',
  'حذاء العروس',
  'بدلة العريس',
  'اكسسوارات العريس',
  'مكياج وتسريحة',
  'بوكيه العروس',
  'تصوير (فيديو/صور)',
  'ضيافة',
  'تزيين القاعة / الكوشة',
  'بطاقات دعوة',
];

final _defaultBudget = <String, double>{
  'القاعة': 0,
  'الضيافة': 0,
  'الديكور / الكوشة': 0,
  'التصوير (فيديو/صور)': 0,
  'الموسيقى / الدي جي': 0,
  'فستان العروس': 0,
  'بدلة العريس': 0,
  'مجوهرات / ذهب': 0,
  'بطاقات الدعوة': 0,
  'تنقّلات': 0,
  'شهر العسل': 0,
};

String currencySymbol(String code) => switch (code) {
  'USD' => r'$',
  'SYP' => 'ل.س',
  _ => '',
};

/// ========= المهام =========
final tasksProvider = StateNotifierProvider<TasksController, List<TodoItem>>((ref) {
  final box = ref.watch(toolsBoxProvider);
  final raw = (box.get(_kTasks) as List?)?.cast() ?? const [];
  var list = raw.whereType<Map>().map((m) => TodoItem.fromMap(m)).toList();

  // Seed إذا فاضي
  if (list.isEmpty) {
    list = _defaultTasks.map((t) => TodoItem(id: _rid(), title: t)).toList();
    box.put(_kTasks, list.map((e) => e.toMap()).toList());
  }
  return TasksController(ref, list);
});

class TasksController extends StateNotifier<List<TodoItem>> {
  final Ref ref;
  TasksController(this.ref, super.state);
  Box get _box => ref.read(toolsBoxProvider);
  void _persist() => _box.put(_kTasks, state.map((e) => e.toMap()).toList());

  void add(String title) {
    state = [...state, TodoItem(id: _rid(), title: title)];
    _persist();
  }

  void toggle(String id, bool v) {
    state = [
      for (final it in state) if (it.id == id) TodoItem(id: it.id, title: it.title, done: v) else it
    ];
    _persist();
  }

  void rename(String id, String title) {
    state = [
      for (final it in state) if (it.id == id) TodoItem(id: it.id, title: title, done: it.done) else it
    ];
    _persist();
  }

  void remove(String id) {
    state = state.where((e) => e.id != id).toList();
    _persist();
  }

  void reorder(int oldIndex, int newIndex) {
    final list = [...state];
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = list;
    _persist();
  }
}

/// ========= المشتريات =========
final shoppingProvider = StateNotifierProvider<ShoppingController, List<ShoppingItem>>((ref) {
  final box = ref.watch(toolsBoxProvider);
  final raw = (box.get(_kShopping) as List?)?.cast() ?? const [];
  var list = raw.whereType<Map>().map((m) => ShoppingItem.fromMap(m)).toList();

  if (list.isEmpty) {
    list = _defaultShopping.map((t) => ShoppingItem(id: _rid(), title: t)).toList();
    box.put(_kShopping, list.map((e) => e.toMap()).toList());
  }
  return ShoppingController(ref, list);
});

class ShoppingController extends StateNotifier<List<ShoppingItem>> {
  final Ref ref;
  ShoppingController(this.ref, super.state);
  Box get _box => ref.read(toolsBoxProvider);
  void _persist() => _box.put(_kShopping, state.map((e) => e.toMap()).toList());

  void add(String title) {
    state = [...state, ShoppingItem(id: _rid(), title: title)];
    _persist();
  }

  void toggle(String id, bool v) {
    state = [
      for (final it in state) if (it.id == id) ShoppingItem(id: it.id, title: it.title, done: v) else it
    ];
    _persist();
  }

  void rename(String id, String title) {
    state = [
      for (final it in state) if (it.id == id) ShoppingItem(id: it.id, title: title, done: it.done) else it
    ];
    _persist();
  }

  void remove(String id) {
    state = state.where((e) => e.id != id).toList();
    _persist();
  }

  void reorder(int oldIndex, int newIndex) {
    final list = [...state];
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = list;
    _persist();
  }
}

/// ========= الميزانية =========
final budgetProvider = StateNotifierProvider<BudgetController, List<BudgetItem>>((ref) {
  final box = ref.watch(toolsBoxProvider);
  final raw = (box.get(_kBudget) as List?)?.cast() ?? const [];
  var list = raw.whereType<Map>().map((m) => BudgetItem.fromMap(m)).toList();

  if (list.isEmpty) {
    list = _defaultBudget.entries
        .map((e) => BudgetItem(id: _rid(), title: e.key, amount: e.value))
        .toList();
    box.put(_kBudget, list.map((e) => e.toMap()).toList());
  }
  return BudgetController(ref, list);
});

class BudgetController extends StateNotifier<List<BudgetItem>> {
  final Ref ref;
  BudgetController(this.ref, super.state);
  Box get _box => ref.read(toolsBoxProvider);
  void _persist() => _box.put(_kBudget, state.map((e) => e.toMap()).toList());

  void add(String title, double amount) {
    state = [...state, BudgetItem(id: _rid(), title: title, amount: amount)];
    _persist();
  }

  void update(String id, {String? title, double? amount}) {
    state = [
      for (final it in state)
        if (it.id == id)
          BudgetItem(id: it.id, title: title ?? it.title, amount: amount ?? it.amount)
        else
          it
    ];
    _persist();
  }

  void remove(String id) {
    state = state.where((e) => e.id != id).toList();
    _persist();
  }

  void reorder(int oldIndex, int newIndex) {
    final list = [...state];
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = list;
    _persist();
  }

  double get total => state.fold(0.0, (s, e) => s + e.amount);
}

/// ========= عملة الميزانية (محفوظة) =========
final budgetCurrencyProvider = StateNotifierProvider<BudgetCurrencyController, String>((ref) {
  final box = ref.watch(toolsBoxProvider);
  final saved = (box.get(_kCurrency) as String?) ?? 'USD';
  return BudgetCurrencyController(ref, saved);
});

class BudgetCurrencyController extends StateNotifier<String> {
  final Ref ref;
  BudgetCurrencyController(this.ref, super.state);
  Box get _box => ref.read(toolsBoxProvider);
  void set(String code) {
    state = code;
    _box.put(_kCurrency, code);
  }
}
