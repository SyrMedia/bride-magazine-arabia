class UpcomingIssue {
  final int id;
  final String title;
  final String cover;
  final String releaseDate;

  const UpcomingIssue({
    required this.id,
    required this.title,
    required this.cover,
    required this.releaseDate,
  });

  factory UpcomingIssue.fromJson(Map<String, dynamic> j) {
    return UpcomingIssue(
      id: (j['id'] is num) ? (j['id'] as num).toInt() : 0,
      title: (j['title'] ?? '').toString(),
      cover: (j['cover'] ?? '').toString(),
      releaseDate: (j['release_date'] ?? '').toString(),
    );
  }
}

class MagazineLanding {
  final String currentCover;
  final String currentTitle;
  final int? currentIssueId;
  final UpcomingIssue? previous;
  final List<UpcomingIssue> upcoming;

  const MagazineLanding({
    required this.currentCover,
    required this.currentTitle,
    required this.currentIssueId,
    required this.previous,
    required this.upcoming,
  });

  factory MagazineLanding.fromJson(Map<String, dynamic> j) {
    final prevJson = j['previous'];
    UpcomingIssue? prev;
    if (prevJson is Map<String, dynamic>) {
      prev = UpcomingIssue.fromJson(prevJson);
    }

    final upList = (j['upcoming'] is List)
        ? (j['upcoming'] as List)
        .whereType<Map<String, dynamic>>()
        .map(UpcomingIssue.fromJson)
        .toList()
        : <UpcomingIssue>[];

    return MagazineLanding(
      currentCover: (j['current_cover'] ?? '').toString(),
      currentTitle: (j['current_title'] ?? '').toString(),
      currentIssueId: (j['current_issue_id'] is num)
          ? (j['current_issue_id'] as num).toInt()
          : null,
      previous: prev,
      upcoming: upList,
    );
  }
}
