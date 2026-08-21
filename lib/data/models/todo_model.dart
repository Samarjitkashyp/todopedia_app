import 'category_model.dart';

class TodoModel {
  final int id;
  final String title;
  final String description;
  final bool isCompleted;
  final bool isImportant;
  final DateTime? dueDate;
  final int? categoryId;
  final CategoryModel? categoryDetail;
  final int createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  TodoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.isImportant,
    this.dueDate,
    this.categoryId,
    this.categoryDetail,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TodoModel.fromJson(Map<String, dynamic> json) {
    return TodoModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      isCompleted: json['is_completed'] ?? false,
      isImportant: json['is_important'] ?? false,
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']).toLocal() : null,
      categoryId: json['category'],
      categoryDetail: json['category_detail'] != null 
          ? CategoryModel.fromJson(json['category_detail']) 
          : null,
      createdBy: json['created_by'] ?? 0,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      updatedAt: DateTime.parse(json['updated_at']).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'is_completed': isCompleted,
      'is_important': isImportant,
      'due_date': dueDate?.toUtc().toIso8601String(),
      'category': categoryId,
    };
  }

  // Helper method to create a copy of the model with some fields modified (immutability helper)
  TodoModel copyWith({
    int? id,
    String? title,
    String? description,
    bool? isCompleted,
    bool? isImportant,
    DateTime? dueDate,
    int? categoryId,
    CategoryModel? categoryDetail,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TodoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      isImportant: isImportant ?? this.isImportant,
      dueDate: dueDate ?? this.dueDate,
      categoryId: categoryId ?? this.categoryId,
      categoryDetail: categoryDetail ?? this.categoryDetail,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
