import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'controllers.dart';
import 'models.dart';
import 'food_db.dart';
import 'style_quiz_screen.dart';

// ============================================
// 1. تعريف المودلز (Models)
// ============================================

class _SkinAnalyzerResult {
  final String title;
  final String description;
  final String icon;
  _SkinAnalyzerResult({required this.title, required this.description, required this.icon});
}

class _BeautyAppointment {
  final String title;
  final DateTime dateTime;
  _BeautyAppointment({required this.title, required this.dateTime});
  Map<String, dynamic> toJson() => {'title': title, 'date': dateTime.toIso8601String()};
  static _BeautyAppointment fromJson(Map<String, dynamic> j) => _BeautyAppointment(title: j['title'], dateTime: DateTime.parse(j['date']));
}

class _RoutineItem {
  String title;
  bool done;
  _RoutineItem(this.title, {this.done = false});
  Map<String, dynamic> toJson() => {'title': title, 'done': done};
  static _RoutineItem fromJson(Map<String, dynamic> j) => _RoutineItem(j['title'], done: j['done'] ?? false);
}

class _CaloriesEntry {
  final String title;
  final double calories;
  _CaloriesEntry({required this.title, required this.calories});
  Map<String, dynamic> toJson() => {'title': title, 'calories': calories};
  static _CaloriesEntry fromJson(Map<String, dynamic> j) => _CaloriesEntry(title: j['title'], calories: (j['calories'] as num).toDouble());
}

// ============================================
// 2. الشاشة الرئيسية
// ============================================

class ToolsScreen extends ConsumerStatefulWidget {
  const ToolsScreen({super.key});

  @override
  ConsumerState<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends ConsumerState<ToolsScreen>
    with TickerProviderStateMixin {
  late final TabController _brideTab;
  ToolsMainMode _mode = ToolsMainMode.personal;

  @override
  void initState() {
    super.initState();
    _brideTab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _brideTab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الأدوات'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          // ===== سوبر سويتش: أدوات كل صبية / أدوات العروس =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('أدوات كل صبية'),
                    selected: _mode == ToolsMainMode.personal,
                    onSelected: (_) {
                      setState(() => _mode = ToolsMainMode.personal);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('أدوات العروس'),
                    selected: _mode == ToolsMainMode.bride,
                    onSelected: (_) {
                      setState(() => _mode = ToolsMainMode.bride);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ===== المحتوى الرئيسي =====
          Expanded(
            child: _mode == ToolsMainMode.personal
                ? const _PersonalToolsSection()
                : _BrideToolsSection(tabController: _brideTab),
          ),
        ],
      ),

      // زر إضافة يظهر فقط في أدوات العروس
      floatingActionButton: _mode == ToolsMainMode.bride
          ? FloatingActionButton.extended(
        onPressed: () async {
          switch (_brideTab.index) {
            case 0:
              final title = await _promptText(context, 'مهمة جديدة');
              if (title != null && title.trim().isNotEmpty) {
                ref.read(tasksProvider.notifier).add(title.trim());
              }
              break;
            case 1:
              final title =
              await _promptText(context, 'عنصر مشتريات جديد');
              if (title != null && title.trim().isNotEmpty) {
                ref.read(shoppingProvider.notifier).add(title.trim());
              }
              break;
            case 2:
              final res = await _promptBudget(context);
              if (res != null) {
                ref.read(budgetProvider.notifier).add(res.$1, res.$2);
              }
              break;
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('إضافة'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      )
          : null,
    );
  }
}

enum ToolsMainMode { personal, bride }

// ============================================
// محتوى أدوات كل صبية
// ============================================

class _PersonalToolsSection extends StatelessWidget {
  const _PersonalToolsSection();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'أدواتي اليومية',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),

            _MiniToolCardBeautyRoutine(),
            SizedBox(height: 12),
            _MiniToolCardBeautyAppointments(),
            SizedBox(height: 12),
            _MiniToolCardPeriod(),
            SizedBox(height: 12),
            _MiniToolCardCalories(),
            SizedBox(height: 12),
            _MiniToolCardSkinAnalyzer(),
            SizedBox(height: 12),
            _MiniToolCardStyleAnalyzer(),
          ],
        ),
      ),
    );
  }
}

// ============================================
// 🛠️ ويدجت الكرت المنسدل الموحد
// ============================================
class _ExpandableToolCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool initiallyExpanded;

  const _ExpandableToolCard({
    required this.title,
    required this.icon,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color cardColor = isDark ? const Color(0xFF4A4A4A) : const Color(0xFFE9BBB6);
    final Color titleColor = isDark ? const Color(0xFFE9BBB6) : const Color(0xFF4A4A4A);
    final Color iconColor = isDark ? const Color(0xFFE9BBB6) : const Color(0xFF4A4A4A);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardColor,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          iconColor: iconColor,
          collapsedIconColor: iconColor,
          leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.white24,
                  borderRadius: BorderRadius.circular(8)
              ),
              child: Icon(icon, color: iconColor, size: 22)
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: titleColor,
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            )
          ],
        ),
      ),
    );
  }
}

// ===================================================================
//  الأدوات الشخصية
// ===================================================================

/// ---------- روتيني الجمالي ----------
class _MiniToolCardBeautyRoutine extends StatefulWidget {
  const _MiniToolCardBeautyRoutine();
  @override
  State<_MiniToolCardBeautyRoutine> createState() => _MiniToolCardBeautyRoutineState();
}

class _MiniToolCardBeautyRoutineState extends State<_MiniToolCardBeautyRoutine> {
  final List<_RoutineItem> _items = [];
  static const _prefsKey = 'personal_routine_v2';

  static const List<String> _kSuggested = [
    'تنظيف البشرة', 'تونر', 'سيروم/عناية', 'مرطب', 'كريم العين', 'مرطب شفاه', 'سيروم الشعر'
  ];

  @override
  void initState() {
    super.initState();
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_prefsKey);
    if (s == null) return;
    try {
      final list = jsonDecode(s) as List<dynamic>;
      final loaded = list.map((e) => _RoutineItem.fromJson((e as Map).cast<String, dynamic>())).toList();
      if (mounted) setState(() => _items.addAll(loaded));
    } catch (_) {}
  }

  Future<void> _saveToPrefs() async {
    final sp = await SharedPreferences.getInstance();
    final list = _items.map((e) => e.toJson()).toList();
    await sp.setString(_prefsKey, jsonEncode(list));
  }

  Future<void> _addItem(BuildContext context) async {
    final res = await _promptText(context, 'إضافة خطوة في الروتين', initial: '');
    if (res != null && res.trim().isNotEmpty) {
      setState(() => _items.add(_RoutineItem(res.trim())));
      _saveToPrefs();
    }
  }

  void _resetToday() {
    setState(() { for (final it in _items) it.done = false; });
    _saveToPrefs();
  }

  void _clearAll() {
    setState(() => _items.clear());
    _saveToPrefs();
  }

  Future<void> _importSuggested() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('استيراد خطوات مقترحة'),
        content: const Text(
            'هل تريد استيراد مجموعة الخطوات المقترحة للروتين؟ سيتم إضافتها إلى قائمتك.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('استيراد')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      for (final s in _kSuggested) {
        if (!_items.any((it) => it.title.toLowerCase() == s.toLowerCase())) {
          _items.add(_RoutineItem(s));
        }
      }
    });
    _saveToPrefs();
  }

  @override
  Widget build(BuildContext context) {
    // لون سلة المهملات
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color deleteColor = isDark ? const Color(0xFFE9BBB6) : const Color(0xFF4A4A4A);

    return _ExpandableToolCard(
      title: 'روتيني الجمالي',
      icon: Icons.favorite_border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _importSuggested,
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('استيراد مقترح', style: TextStyle(fontSize: 11)),
                style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
              OutlinedButton.icon(
                onPressed: () => _addItem(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('إضافة', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
              TextButton(
                onPressed: _clearAll,
                child: const Text('مسح الكل', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_items.isEmpty)
            const Text(
              'لا توجد خطوات حالياً.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            )
          else
            ListView.separated(
              itemCount: _items.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final it = _items[i];
                return Row(
                  children: [
                    Checkbox(
                      value: it.done,
                      onChanged: (v) {
                        setState(() => it.done = v ?? false);
                        _saveToPrefs();
                      },
                    ),
                    Expanded(
                      child: Text(
                        it.title,
                        style: TextStyle(
                          decoration: it.done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: deleteColor,
                      onPressed: () {
                        setState(() => _items.removeAt(i));
                        _saveToPrefs();
                      },
                    ),
                  ],
                );
              },
            ),
          if (_items.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _resetToday,
                child: const Text('إعادة تعيين اليوم', style: TextStyle(fontSize: 11)),
              ),
            ),
        ],
      ),
    );
  }
}

/// ---------- مواعيدي الجمالية ----------
class _MiniToolCardBeautyAppointments extends StatefulWidget {
  const _MiniToolCardBeautyAppointments();
  @override
  State<_MiniToolCardBeautyAppointments> createState() => _MiniToolCardBeautyAppointmentsState();
}

class _MiniToolCardBeautyAppointmentsState extends State<_MiniToolCardBeautyAppointments> {
  final List<_BeautyAppointment> _appointments = [];
  static const _prefsKey = 'personal_appointments_v1';

  @override
  void initState() {
    super.initState();
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_prefsKey);
    if (s == null) return;
    try {
      final list = jsonDecode(s) as List<dynamic>;
      final loaded = list.map((e) => _BeautyAppointment.fromJson((e as Map).cast<String, dynamic>())).toList();
      if (mounted) setState(() => _appointments.addAll(loaded));
    } catch (_) {}
  }

  Future<void> _saveToPrefs() async {
    final sp = await SharedPreferences.getInstance();
    final list = _appointments.map((e) => e.toJson()).toList();
    await sp.setString(_prefsKey, jsonEncode(list));
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month}-${dt.day}  ${dt.hour}:${dt.minute.toString().padLeft(2,'0')}';
  }

  Future<void> _addAppointment(BuildContext context) async {
    final titleCtrl = TextEditingController();
    DateTime? pickedDate;
    TimeOfDay? pickedTime;
    final res = await showDialog<_BeautyAppointment>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('موعد جديد'),
        content: StatefulBuilder(builder: (ctx, setInner) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'العنوان')),
            const SizedBox(height: 10),
            Row(children: [
              TextButton(onPressed: () async {
                final d = await showDatePicker(context: ctx, firstDate: DateTime.now(), lastDate: DateTime(2030), initialDate: DateTime.now());
                if(d!=null) setInner(()=>pickedDate=d);
              }, child: Text(pickedDate==null?'التاريخ': '${pickedDate!.year}-${pickedDate!.month}-${pickedDate!.day}')),
              TextButton(onPressed: () async {
                final t = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
                if(t!=null) setInner(()=>pickedTime=t);
              }, child: Text(pickedTime==null?'الوقت': '${pickedTime!.hour}:${pickedTime!.minute}')),
            ])
          ],
        )),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(onPressed: (){
            if(titleCtrl.text.isNotEmpty && pickedDate!=null && pickedTime!=null){
              Navigator.pop(ctx, _BeautyAppointment(
                  title: titleCtrl.text,
                  dateTime: DateTime(pickedDate!.year, pickedDate!.month, pickedDate!.day, pickedTime!.hour, pickedTime!.minute)
              ));
            }
          }, child: const Text('حفظ'))
        ],
      ),
    );
    if (res != null) {
      setState(() => _appointments.add(res));
      await _saveToPrefs();
    }
  }

  @override
  Widget build(BuildContext context) {
    _appointments.sort((a,b)=> a.dateTime.compareTo(b.dateTime));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color deleteColor = isDark ? const Color(0xFFE9BBB6) : const Color(0xFF4A4A4A);

    return _ExpandableToolCard(
      title: 'مواعيدي الجمالية',
      icon: Icons.calendar_month_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _addAppointment(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('إضافة موعد', style: TextStyle(fontSize: 12)),
            ),
          ),
          if (_appointments.isEmpty)
            const Text('لا توجد مواعيد قادمة.', style: TextStyle(fontSize: 12)),

          ..._appointments.map((a) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(_formatDateTime(a.dateTime)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              color: deleteColor,
              onPressed: () async {
                setState(() => _appointments.remove(a));
                await _saveToPrefs();
              },
            ),
          )).toList()
        ],
      ),
    );
  }
}

/// ---------- الدورة الشهرية ----------
class _MiniToolCardPeriod extends StatefulWidget {
  const _MiniToolCardPeriod();
  @override
  State<_MiniToolCardPeriod> createState() => _MiniToolCardPeriodState();
}

class _MiniToolCardPeriodState extends State<_MiniToolCardPeriod> {
  DateTime? _lastStart;
  int _cycleDays = 28;
  static const _prefsKey = 'personal_period_v1';

  @override
  void initState() {
    super.initState();
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_prefsKey);
    if (s == null) return;
    try {
      final j = jsonDecode(s) as Map<String, dynamic>;
      final last = j['lastStart'] as String?;
      final cycle = j['cycleDays'] as int?;
      if (last != null) _lastStart = DateTime.tryParse(last);
      if (cycle != null) _cycleDays = cycle;
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _saveToPrefs() async {
    final sp = await SharedPreferences.getInstance();
    final j = {'lastStart': _lastStart?.toIso8601String(), 'cycleDays': _cycleDays};
    await sp.setString(_prefsKey, jsonEncode(j));
  }

  @override
  Widget build(BuildContext context) {
    final nextDate = _lastStart?.add(Duration(days: _cycleDays));

    return _ExpandableToolCard(
      title: 'الدورة الشهرية',
      icon: Icons.water_drop_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_lastStart == null ? 'لم يتم التحديد' : 'آخر دورة: ${_lastStart!.year}-${_lastStart!.month}-${_lastStart!.day}'),
              TextButton(
                onPressed: () async {
                  final d = await showDatePicker(context: context, initialDate: _lastStart ?? DateTime.now(), firstDate: DateTime(2023), lastDate: DateTime.now());
                  if(d!=null) {
                    setState(() => _lastStart = d);
                    await _saveToPrefs();
                  }
                },
                child: const Text('تعديل التاريخ'),
              )
            ],
          ),
          if (nextDate != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.next_plan, size: 20),
                  const SizedBox(width: 8),
                  Text('الموعد المتوقع: ${nextDate.year}-${nextDate.month}-${nextDate.day}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('طول الدورة:'),
              Expanded(
                child: Slider(
                  value: _cycleDays.toDouble(), min: 21, max: 35, divisions: 14,
                  label: '$_cycleDays',
                  onChanged: (v) { setState(()=> _cycleDays = v.round()); _saveToPrefs(); },
                ),
              ),
              Text('$_cycleDays يوم'),
            ],
          )
        ],
      ),
    );
  }
}

/// ---------- السعرات الحرارية ----------
class _MiniToolCardCalories extends StatefulWidget {
  const _MiniToolCardCalories();
  @override
  State<_MiniToolCardCalories> createState() => _MiniToolCardCaloriesState();
}

class _MiniToolCardCaloriesState extends State<_MiniToolCardCalories> {
  final List<_CaloriesEntry> _entries = [];
  double _target = 1800;
  static const _prefsKey = 'personal_calories_v1';

  @override
  void initState() {
    super.initState();
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_prefsKey);
    if (s == null) return;
    try {
      final j = jsonDecode(s) as Map<String, dynamic>;
      final list =
          (j['entries'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      final loaded = list.map((e) => _CaloriesEntry.fromJson(e)).toList();
      final t = (j['target'] as num?)?.toDouble() ?? 1800;
      if (mounted)
        setState(() {
          _entries.clear();
          _entries.addAll(loaded);
          _target = t;
        });
    } catch (_) {}
  }

  Future<void> _saveToPrefs() async {
    final sp = await SharedPreferences.getInstance();
    final j = {
      'entries': _entries.map((e) => e.toJson()).toList(),
      'target': _target,
    };
    await sp.setString(_prefsKey, jsonEncode(j));
  }

  Future<void> _setTarget(BuildContext context) async {
    final ctrl = TextEditingController(text: _target.round().toString());
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل الهدف اليومي'),
        content: TextField(
          controller: ctrl,
          textDirection: TextDirection.rtl,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          decoration:
          const InputDecoration(labelText: 'الهدف بالسعرات الحرارية'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (res != null) {
      final newTarget = double.tryParse(res) ?? 0;
      if (newTarget > 1000) {
        setState(() => _target = newTarget);
        await _saveToPrefs();
      }
    }
  }

  Future<void> _addMeal(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final gramsCtrl = TextEditingController();
    final manualCtrl = TextEditingController();

    FoodDatabase? db;
    try {
      db = await FoodDatabase.loadFromAsset('assets/foods.json');
    } catch (_) {
      db = null;
    }

    List<FoodItem> suggestions = [];

    final res = await showDialog<_CaloriesEntry>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: const Text('إضافة أكلة'),
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'اسم الأكلة (مثال: بيضة، هامبرغر...)',
                  ),
                  onChanged: (v) {
                    if (db != null && v.trim().length >= 2) {
                      final s = db.search(v.trim());
                      setInner(() => suggestions = s);
                    } else {
                      setInner(() => suggestions = []);
                    }
                  },
                ),
                const SizedBox(height: 8),
                if (suggestions.isNotEmpty)
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      itemCount: suggestions.length,
                      itemBuilder: (_, i) {
                        final it = suggestions[i];
                        return ListTile(
                          dense: true,
                          title: Text(it.name),
                          subtitle: Text('${it.calPer100g.round()} kcal /100g'),
                          onTap: () {
                            nameCtrl.text = it.name;
                            setInner(() => suggestions = []);
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: gramsCtrl,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'الكمية بالغرام (مثال: 80، 150...)',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'لو الأكلة غير موجودة اضغطي "إدخال يدوي" وأكتبي السعرات مباشرة.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
                TextField(
                  controller: manualCtrl,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'السعرات الحرارية (اختياري)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final grams =
                    double.tryParse(gramsCtrl.text.replaceAll(',', '.')) ?? 0;
                final manual =
                double.tryParse(manualCtrl.text.replaceAll(',', '.'));

                double? cals;
                if (db != null && grams > 0) {
                  cals = db.caloriesFor(name, grams);
                }
                if (cals == null && manual != null) {
                  cals = manual;
                }
                if (cals == null) {
                  return;
                }

                Navigator.pop(ctx, _CaloriesEntry(title: name, calories: cals));
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    if (res != null) {
      setState(() => _entries.add(res));
      await _saveToPrefs();
    }
  }

  void _resetDay() async {
    setState(() => _entries.clear());
    await _saveToPrefs();
  }

  @override
  Widget build(BuildContext context) {
    double total = _entries.fold(0, (p, e) => p + e.calories);
    double progress = _target == 0 ? 0 : (total / _target).clamp(0.0, 1.0);

    // لون أيقونة الحذف في الـ Chips
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color deleteColor = isDark ? const Color(0xFFE9BBB6) : const Color(0xFF4A4A4A);

    return _ExpandableToolCard(
      title: 'سعراتي اليوم',
      icon: Icons.local_fire_department_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('المستهلك: ${total.round()} / ${_target.round()}'),
              TextButton(
                  onPressed: () => _setTarget(context),
                  child: const Text('تعديل الهدف'))
            ],
          ),
          LinearProgressIndicator(
              value: progress, minHeight: 8, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 10),
          Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                  onPressed: () => _addMeal(context),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة أكلة'))),
          if (_entries.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: _entries
                  .map(
                    (e) => Chip(
                  label: Text('${e.title} • ${e.calories.round()}'),
                  deleteIconColor: deleteColor,
                  onDeleted: () {
                    setState(() => _entries.remove(e));
                    _saveToPrefs();
                  },
                ),
              )
                  .toList(),
            ),
            const SizedBox(height: 8),
            TextButton(
                onPressed: _resetDay, child: const Text('مسح السجل اليومي'))
          ],
        ],
      ),
    );
  }
}

/// ---------- محلل البشرة ----------
class _MiniToolCardSkinAnalyzer extends StatefulWidget {
  const _MiniToolCardSkinAnalyzer();
  @override
  State<_MiniToolCardSkinAnalyzer> createState() => _MiniToolCardSkinAnalyzerState();
}

class _MiniToolCardSkinAnalyzerState extends State<_MiniToolCardSkinAnalyzer> {
  int _currentQuestion = 0;
  List<String> _answers = [];
  _SkinAnalyzerResult? _result;
  bool _started = false;

  static const List<Map<String, dynamic>> _questions = [
    {
      'question': 'بعد غسل وجهك بساعة، كيف تشعرين؟',
      'options': {
        'A': 'مشدود، جاف، وأحياناً يتقشر',
        'B': 'مريح، لا شد ولا لمعان',
        'C': 'لمعان خفيف في الجبين والأنف (منطقة T)',
        'D': 'لمعان شديد وملمس دهني في الوجه كله',
      }
    },
    {
      'question': 'كيف يبدو المكياج (كريم الأساس/الكونسيلر) خلال النهار؟',
      'options': {
        'A': 'يتشقق ويتقشر في مناطق جافة',
        'B': 'ثابت ويدوم لساعات طويلة',
        'C': 'يحتاج لمسة بودرة في منتصف اليوم',
        'D': 'يذوب ويتلطخ بسرعة، خاصة في الحرارة',
      }
    },
    {
      'question': 'ما مدى ظهور المسام والرؤوس السوداء لديك؟',
      'options': {
        'A': 'المسام صغيرة جداً، لا توجد رؤوس سوداء تقريباً',
        'B': 'مسام طبيعية، لا مشاكل بارزة',
        'C': 'مسام واسعة قليلاً في منطقة T، ورؤوس سوداء خفيفة',
        'D': 'مسام واسعة ومفتوحة في معظم مناطق الوجه',
      }
    },
  ];

  static final Map<String, _SkinAnalyzerResult> _skinResults = {
    'A': _SkinAnalyzerResult(
        title: 'بشرة جافة 🌵',
        icon: 'star_border',
        description: 'بشرتكِ تحتاج ترطيباً عميقاً وزيوت مغذية. ركّزي على المرطبات الكريمية الثقيلة، واستخدمي واقي شمسي لحمايتها من التشققات.'
    ),
    'B': _SkinAnalyzerResult(
        title: 'بشرة عادية ✨',
        icon: 'check_circle_outline',
        description: 'بشرتكِ متوازنة! حافظي على روتين أساسي بسيط (تنظيف وترطيب وحماية) لتجنب أي مشاكل.'
    ),
    'C': _SkinAnalyzerResult(
        title: 'بشرة مختلطة 🌓',
        icon: 'spa',
        description: 'أنتِ تجمعين بين النوعين! استخدمي منظف لطيف، وطبقي مرطبات مائية خفيفة على منطقة T، ومرطب أغنى على الخدين.'
    ),
    'D': _SkinAnalyzerResult(
        title: 'بشرة دهنية 💧',
        icon: 'opacity',
        description: 'بشرتكِ تنتج زيوت بكمية كبيرة. الأفضل لكِ: منتجات مطفية (Matte)، منظفات جل، واستخدام برايمر مطفي قبل المكياج.'
    ),
  };

  void _startTest() {
    setState(() {
      _started = true;
      _currentQuestion = 0;
      _answers = [];
      _result = null;
    });
  }

  void _submitAnswer(String answerCode) {
    _answers.add(answerCode);
    if (_currentQuestion < _questions.length - 1) {
      setState(() => _currentQuestion++);
    } else {
      _analyzeResult();
    }
  }

  void _analyzeResult() {
    final counts = <String, int>{};
    for (final ans in _answers) {
      counts[ans] = (counts[ans] ?? 0) + 1;
    }
    String determinedType = 'B';
    if (counts.isNotEmpty) {
      int maxCount = 0;
      for (final v in counts.values) {
        if (v > maxCount) maxCount = v;
      }
      final winners = counts.entries.where((e) => e.value == maxCount).map((e) => e.key).toSet();
      if (winners.contains('D')) determinedType = 'D';
      else if (winners.contains('C')) determinedType = 'C';
      else if (winners.contains('A')) determinedType = 'A';
      else determinedType = 'B';
    }

    setState(() {
      _result = _skinResults[determinedType];
      _started = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _ExpandableToolCard(
        title: 'محلل نوع البشرة',
        icon: Icons.face_retouching_natural,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_result != null)
              _buildResultContent(scheme)
            else if (_started)
              _buildQuestionContent(scheme)
            else
              _buildStartContent(scheme),
          ],
        )
    );
  }

  Widget _buildStartContent(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'أجيبي على 3 أسئلة بسيطة لنحدد نوع بشرتكِ (جافة، دهنية، مختلطة، عادية) ونقدم لكِ نصائح فورية للعناية والمكياج!',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
              onPressed: _startTest,
              icon: const Icon(Icons.play_arrow),
              label: const Text('ابدأ الاختبار')
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionContent(ColorScheme scheme) {
    final qData = _questions[_currentQuestion];
    final options = qData['options'] as Map<String, String>;
    final questionNumber = _currentQuestion + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'السؤال $questionNumber من ${_questions.length}',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: scheme.primary),
        ),
        const SizedBox(height: 4),
        Text(qData['question'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...options.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: OutlinedButton(
              onPressed: () => _submitAnswer(entry.key),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('${entry.key}) ${entry.value}', textAlign: TextAlign.right),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildResultContent(ColorScheme scheme) {
    final result = _result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star, color: scheme.primary),
            const SizedBox(width: 8),
            Text('نوع بشرتكِ: ${result.title}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: scheme.primary)),
          ],
        ),
        const Divider(height: 16),
        Text('نصيحة العناية والمكياج:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: scheme.onSurface.withOpacity(0.8))),
        const SizedBox(height: 4),
        Text(result.description, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: _startTest, child: const Text('أعد الاختبار')),
        ),
      ],
    );
  }
}

/// ---------- مستشارتك الشخصية (Style Analyzer) ----------
class _MiniToolCardStyleAnalyzer extends StatelessWidget {
  const _MiniToolCardStyleAnalyzer();

  @override
  Widget build(BuildContext context) {
    return _ExpandableToolCard(
      title: 'محلل الفستان المناسب',
      icon: Icons.checkroom,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'محتارة بموديل الفستان؟ جاوبي على أسئلة بسيطة ورح نحلل شكل جسمك وننصحك بأفضل القصات.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const StyleQuizScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white10 : Colors.black87,
                foregroundColor: Colors.white,
              ),
              child: const Text('جربي الآن'),
            ),
          ),
        ],
      ),
    );
  }
}


// --- Bride Tools Sections (Tasks, Shopping, Budget) ---
class _BrideToolsSection extends ConsumerWidget {
  final TabController tabController;
  const _BrideToolsSection({required this.tabController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          color: scheme.surfaceVariant.withOpacity(0.4),
          child: TabBar(
            controller: tabController,
            labelColor: scheme.primary,
            unselectedLabelColor: scheme.onSurface.withOpacity(0.6),
            indicatorColor: scheme.primary,
            tabs: const [Tab(text: 'المهام'), Tab(text: 'المشتريات'), Tab(text: 'الميزانية')],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: const [_TasksTab(), _ShoppingTab(), _BudgetTab()],
          ),
        ),
      ],
    );
  }
}

class _TasksTab extends ConsumerWidget {
  const _TasksTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(tasksProvider);
    final ctrl = ref.read(tasksProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    // ✅ إصلاح مشكلة عدم ظهور خط الشطب على النصوص العربية
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // في الوضع الليلي نستخدم اللون الوردي الترابي للشطب ليكون واضحاً
    // في الوضع النهاري نستخدم الفحمي
    final Color strikeColor = isDark ? const Color(0xFFE9BBB6) : const Color(0xFF4A4A4A);

    if (list.isEmpty) {
      return const Center(child: Text('أضف مهامك الأولى ✨'));
    }
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: list.length,
      onReorder: ctrl.reorder,
      itemBuilder: (c, i) {
        final it = list[i];
        return Dismissible(
          key: ValueKey(it.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red.shade400,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => ctrl.remove(it.id),
          child: ListTile(
            leading: Checkbox(
              value: it.done,
              onChanged: (v) => ctrl.toggle(it.id, v ?? false),
            ),
            title: Text(
                it.title,
                style: TextStyle(
                  decoration: it.done ? TextDecoration.lineThrough : TextDecoration.none,
                  decorationColor: strikeColor, // ✅ لون شطب واضح جداً
                  decorationThickness: 2.5,     // ✅ زيادة سماكة الخط
                  color: it.done ? scheme.onSurface.withOpacity(0.5) : scheme.onSurface, // ✅ تغميق النص المنجز
                )
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final t = await _promptText(context, 'تعديل المهمة', initial: it.title);
                if (t != null && t.trim().isNotEmpty) ctrl.rename(it.id, t.trim());
              },
            ),
          ),
        );
      },
    );
  }
}

class _ShoppingTab extends ConsumerWidget {
  const _ShoppingTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(shoppingProvider);
    final ctrl = ref.read(shoppingProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    // ✅ نفس إصلاح الشطب في المشتريات
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color strikeColor = isDark ? const Color(0xFFE9BBB6) : const Color(0xFF4A4A4A);

    if (list.isEmpty) {
      return const Center(child: Text('أضف عناصر المشتريات ✨'));
    }
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: list.length,
      onReorder: ctrl.reorder,
      itemBuilder: (c, i) {
        final it = list[i];
        return Dismissible(
          key: ValueKey(it.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red.shade400,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => ctrl.remove(it.id),
          child: ListTile(
            leading: Checkbox(
              value: it.done,
              onChanged: (v) => ctrl.toggle(it.id, v ?? false),
            ),
            title: Text(
                it.title,
                style: TextStyle(
                  decoration: it.done ? TextDecoration.lineThrough : TextDecoration.none,
                  decorationColor: strikeColor, // ✅ لون شطب واضح
                  decorationThickness: 2.5,     // ✅ سماكة عالية
                  color: it.done ? scheme.onSurface.withOpacity(0.5) : scheme.onSurface,
                )
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final t = await _promptText(context, 'تعديل العنصر', initial: it.title);
                if (t != null && t.trim().isNotEmpty) ctrl.rename(it.id, t.trim());
              },
            ),
          ),
        );
      },
    );
  }
}

class _BudgetTab extends ConsumerWidget {
  const _BudgetTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(budgetProvider);
    final ctrl = ref.read(budgetProvider.notifier);
    final currency = ref.watch(budgetCurrencyProvider);
    final symbol = currencySymbol(currency);
    final total = ref.watch(budgetProvider.select((s) => s.fold<double>(0, (p, e) => p + e.amount)));

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              const Icon(Icons.summarize_outlined),
              const SizedBox(width: 8),
              Text('المجموع:', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 8),
              Text('$symbol ${total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: currency,
                  onChanged: (v) { if (v != null) ref.read(budgetCurrencyProvider.notifier).state = v; },
                  items: const [
                    DropdownMenuItem(value: 'USD', child: Text('دولار (USD)')),
                    DropdownMenuItem(value: 'SYP', child: Text('ليرة سوري (SYP)')),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('أضف بنود الميزانية ✨'))
              : ReorderableListView.builder(
            itemCount: list.length,
            onReorder: ctrl.reorder,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (c, i) {
              final it = list[i];
              return Dismissible(
                key: ValueKey(it.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red.shade400,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => ctrl.remove(it.id),
                child: ListTile(
                  title: Text(it.title),
                  subtitle: Text('$symbol ${it.amount.toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final res = await _promptBudget(context, initialTitle: it.title, initialAmount: it.amount);
                      if (res != null) ctrl.update(it.id, title: res.$1, amount: res.$2);
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// --- Dialogs ---
Future<String?> _promptText(BuildContext context, String title, {String? initial}) async {
  final ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(controller: ctrl, textDirection: TextDirection.rtl, decoration: const InputDecoration(hintText: '...'), autofocus: true),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('إلغاء')),
        FilledButton(onPressed: ()=>Navigator.pop(ctx, ctrl.text.trim()), child: const Text('حفظ')),
      ],
    ),
  );
}

Future<(String, double)?> _promptBudget(BuildContext context, {String? initialTitle, double? initialAmount}) async {
  final nameCtrl = TextEditingController(text: initialTitle ?? '');
  final amountCtrl = TextEditingController(text: initialAmount?.toString() ?? '');
  final res = await showDialog<(String, double)>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('بند ميزانية'),
      content: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'العنوان')),
            const SizedBox(height: 8),
            TextField(controller: amountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'القيمة')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('إلغاء')),
        FilledButton(onPressed: () {
          final t = nameCtrl.text.trim();
          final a = double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0;
          if (t.isEmpty) return;
          Navigator.pop(ctx, (t, a));
        },
          child: const Text('حفظ'),
        ),
      ],
    ),
  );
  return res;
}