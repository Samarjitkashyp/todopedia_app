class StatsModel {
  final int allTasksCount;
  final int completedCount;
  final int pendingCount;
  final int importantCount;

  StatsModel({
    required this.allTasksCount,
    required this.completedCount,
    required this.pendingCount,
    required this.importantCount,
  });

  factory StatsModel.empty() {
    return StatsModel(
      allTasksCount: 0,
      completedCount: 0,
      pendingCount: 0,
      importantCount: 0,
    );
  }

  factory StatsModel.fromJson(Map<String, dynamic> json) {
    return StatsModel(
      allTasksCount: json['all_tasks_count'] ?? 0,
      completedCount: json['completed_count'] ?? 0,
      pendingCount: json['pending_count'] ?? 0,
      importantCount: json['important_count'] ?? 0,
    );
  }

  StatsModel copyWith({
    int? allTasksCount,
    int? completedCount,
    int? pendingCount,
    int? importantCount,
  }) {
    return StatsModel(
      allTasksCount: allTasksCount ?? this.allTasksCount,
      completedCount: completedCount ?? this.completedCount,
      pendingCount: pendingCount ?? this.pendingCount,
      importantCount: importantCount ?? this.importantCount,
    );
  }
}
