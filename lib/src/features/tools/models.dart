class TodoItem {
  String id;
  String title;
  bool done;
  TodoItem({required this.id, required this.title, this.done = false});

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'done': done};
  factory TodoItem.fromMap(Map m) => TodoItem(
    id: (m['id'] ?? '').toString(),
    title: (m['title'] ?? '').toString(),
    done: (m['done'] ?? false) == true,
  );
}

class ShoppingItem {
  String id;
  String title;
  bool done;
  ShoppingItem({required this.id, required this.title, this.done = false});

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'done': done};
  factory ShoppingItem.fromMap(Map m) => ShoppingItem(
    id: (m['id'] ?? '').toString(),
    title: (m['title'] ?? '').toString(),
    done: (m['done'] ?? false) == true,
  );
}

class BudgetItem {
  String id;
  String title;
  double amount;
  BudgetItem({required this.id, required this.title, required this.amount});

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'amount': amount};
  factory BudgetItem.fromMap(Map m) => BudgetItem(
    id: (m['id'] ?? '').toString(),
    title: (m['title'] ?? '').toString(),
    amount: double.tryParse((m['amount'] ?? '0').toString()) ?? 0,
  );
}
