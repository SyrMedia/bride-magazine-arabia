// lib/src/data/models/tools_data.dart
class ToolsData {
  final List<Map<String, dynamic>> tasks;
  final List<Map<String, dynamic>> checklist;
  final List<Map<String, dynamic>> budget;

  ToolsData({
    this.tasks = const [],
    this.checklist = const [],
    this.budget = const [],
  });

  factory ToolsData.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> _toList(dynamic v) {
      if (v is List) {
        return v
            .whereType<Map>()
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return <Map<String, dynamic>>[];
    }

    return ToolsData(
      tasks: _toList(json['tasks']),
      checklist: _toList(json['checklist']),
      budget: _toList(json['budget']),
    );
  }

  Map<String, dynamic> toJson() => {
    'tasks': tasks,
    'checklist': checklist,
    'budget': budget,
  };

  // للراحة مع القوالب الثابتة
  factory ToolsData.fromMap(Map<String, dynamic> m) => ToolsData.fromJson(m);
}
