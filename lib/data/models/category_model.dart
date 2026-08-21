import 'package:flutter/material.dart';

class CategoryModel {
  final int id;
  final String name;
  final String color; // Hex string (e.g. #6C63FF)
  final int iconCode; // Flutter IconData codePoint
  final int createdBy;
  final int taskCount;

  CategoryModel({
    required this.id,
    required this.name,
    required this.color,
    required this.iconCode,
    required this.createdBy,
    required this.taskCount,
  });

  // Convert Hex string color from DB to Flutter Color
  Color get colorValue {
    try {
      final hex = color.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse("FF$hex", radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF6C63FF); // Fallback color
  }

  // Convert icon codepoint to Flutter IconData
  IconData get iconData {
    // ignore: non_const_argument_for_const_parameter
    return IconData(iconCode, fontFamily: 'MaterialIcons');
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      color: json['color'] ?? '#6C63FF',
      iconCode: json['icon_code'] ?? 57415, // Default list icon (0xe197 in material icons)
      createdBy: json['created_by'] ?? 0,
      taskCount: json['task_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'icon_code': iconCode,
    };
  }
}
