import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../data/models/category_model.dart';
import '../data/models/todo_model.dart';
import '../data/models/stats_model.dart';

enum TaskFilter { all, completed, pending, important }

class TodoProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<TodoModel> _todos = [];
  List<TodoModel> _allTodos = []; // cache master list of all tasks
  List<CategoryModel> _categories = [];
  StatsModel _stats = StatsModel.empty();
  
  bool _isLoadingTodos = false;
  bool _isLoadingCategories = false;
  bool _isLoadingStats = false;
  
  String? _todoError;
  
  // Filtering states
  TaskFilter _selectedFilter = TaskFilter.all;
  CategoryModel? _selectedCategory;
  String _searchQuery = "";

  void _sortTodos() {
    _todos.sort((a, b) {
      // 1. Sort by isImportant: true before false
      if (a.isImportant && !b.isImportant) return -1;
      if (!a.isImportant && b.isImportant) return 1;

      // 2. Sort by isCompleted: pending (false) before completed (true)
      if (!a.isCompleted && b.isCompleted) return -1;
      if (a.isCompleted && !b.isCompleted) return 1;

      // 3. Sort by dueDate: earlier first, nulls last
      if (a.dueDate != null && b.dueDate == null) return -1;
      if (a.dueDate == null && b.dueDate != null) return 1;
      if (a.dueDate != null && b.dueDate != null) {
        final comp = a.dueDate!.compareTo(b.dueDate!);
        if (comp != 0) return comp;
      }

      // 4. Sort by createdAt: newer first (descending)
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  // Getters
  List<TodoModel> get todos => _todos;
  List<CategoryModel> get categories => _categories;
  StatsModel get stats => _stats;
  
  bool get isLoadingTodos => _isLoadingTodos;
  bool get isLoadingCategories => _isLoadingCategories;
  bool get isLoadingStats => _isLoadingStats;
  
  String? get todoError => _todoError;
  TaskFilter get selectedFilter => _selectedFilter;
  CategoryModel? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  // Setters for filters
  void setFilter(TaskFilter filter) {
    _selectedFilter = filter;
    _selectedCategory = null; // Clear category filter if status tab selected
    if (_allTodos.isNotEmpty) {
      _todos = List.from(_allTodos);
      if (filter == TaskFilter.completed) {
        _todos = _todos.where((t) => t.isCompleted).toList();
      } else if (filter == TaskFilter.pending) {
        _todos = _todos.where((t) => !t.isCompleted).toList();
      } else if (filter == TaskFilter.important) {
        _todos = _todos.where((t) => t.isImportant).toList();
      }
      _sortTodos();
    }
    notifyListeners();
    fetchTodos();
  }

  void setCategoryFilter(CategoryModel? category) {
    _selectedCategory = category;
    if (category != null && _allTodos.isNotEmpty) {
      _todos = _allTodos.where((t) => t.categoryId == category.id).toList();
      _sortTodos();
    }
    notifyListeners();
    fetchTodos();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    if (_allTodos.isNotEmpty) {
      _todos = _allTodos.where((t) => 
        t.title.toLowerCase().contains(query.toLowerCase()) || 
        t.description.toLowerCase().contains(query.toLowerCase())
      ).toList();
      _sortTodos();
    }
    notifyListeners();
    fetchTodos();
  }

  void clearAllFilters() {
    _selectedFilter = TaskFilter.all;
    _selectedCategory = null;
    _searchQuery = "";
    notifyListeners();
  }

  // Fetch Dashboard statistics
  Future<void> fetchStats() async {
    _isLoadingStats = true;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(ApiEndpoints.stats);
      if (response.statusCode == 200) {
        _stats = StatsModel.fromJson(response.data);
      }
    } catch (e) {
      // Quietly ignore stats errors, keeps UI robust
    }

    _isLoadingStats = false;
    notifyListeners();
  }

  // Fetch Categories
  Future<void> fetchCategories() async {
    _isLoadingCategories = true;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(ApiEndpoints.categories);
      if (response.statusCode == 200) {
        final List data = response.data;
        _categories = data.map((json) => CategoryModel.fromJson(json)).toList();
      }
    } catch (e) {
      // Ignore
    }

    _isLoadingCategories = false;
    notifyListeners();
  }

  // Fetch Todos with current filter parameters applied
  Future<void> fetchTodos({bool isTodayOnly = false}) async {
    _isLoadingTodos = true;
    _todoError = null;
    notifyListeners();

    try {
      final Map<String, dynamic> queryParams = {};
      
      // Apply Search
      if (_searchQuery.isNotEmpty) {
        queryParams['search'] = _searchQuery;
      }

      // Apply Category filter
      if (_selectedCategory != null) {
        queryParams['category'] = _selectedCategory!.id;
      }

      // Apply tab/status filters
      if (isTodayOnly) {
        queryParams['today'] = 'true';
      } else {
        switch (_selectedFilter) {
          case TaskFilter.completed:
            queryParams['completed'] = 'true';
            break;
          case TaskFilter.pending:
            queryParams['completed'] = 'false';
            break;
          case TaskFilter.important:
            queryParams['important'] = 'true';
            break;
          case TaskFilter.all:
            // No extra param
            break;
        }
      }

      final response = await _apiClient.dio.get(
        ApiEndpoints.todos,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List data = response.data;
        _todos = data.map((json) => TodoModel.fromJson(json)).toList();
        _sortTodos();
        
        // Update/Merge into the master cache
        if (_selectedCategory == null && _searchQuery.isEmpty && _selectedFilter == TaskFilter.all && !isTodayOnly) {
          _allTodos = List.from(_todos);
        } else {
          for (var todo in _todos) {
            final idx = _allTodos.indexWhere((t) => t.id == todo.id);
            if (idx != -1) {
              _allTodos[idx] = todo;
            } else {
              _allTodos.add(todo);
            }
          }
        }
      }
    } on DioException catch (_) {
      _todoError = "Failed to fetch tasks. Please verify backend connection.";
    } catch (_) {
      _todoError = "An unexpected error occurred.";
    }

    _isLoadingTodos = false;
    notifyListeners();
  }

  // Create a new Todo
  Future<bool> createTodo({
    required String title,
    String? description,
    DateTime? dueDate,
    int? categoryId,
    bool isImportant = false,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.todos,
        data: {
          'title': title,
          'description': description,
          'due_date': dueDate?.toUtc().toIso8601String(),
          'category': categoryId,
          'is_important': isImportant,
        },
      );

      if (response.statusCode == 201) {
        final newTodo = TodoModel.fromJson(response.data);
        
        // Add locally and sort
        _todos.add(newTodo);
        _sortTodos();

        // Add to master cache
        final exists = _allTodos.any((t) => t.id == newTodo.id);
        if (!exists) {
          _allTodos.add(newTodo);
        }
        
        // Update stats instantly in memory
        _stats = _stats.copyWith(
          allTasksCount: _stats.allTasksCount + 1,
          pendingCount: _stats.pendingCount + 1,
          importantCount: _stats.importantCount + (newTodo.isImportant ? 1 : 0),
        );
        
        notifyListeners();
        
        // Quietly fetch actual values in the background to ensure sync
        fetchStats();
        fetchCategories();
        return true;
      }
    } catch (e) {
      // Handle error
    }
    return false;
  }

  // Toggle isCompleted status
  Future<void> toggleTodoStatus(TodoModel todo) async {
    final updatedStatus = !todo.isCompleted;
    
    // Optimistic UI update
    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index != -1) {
      _todos[index] = _todos[index].copyWith(isCompleted: updatedStatus);
      _sortTodos();
      
      // Update stats instantly in memory
      _stats = _stats.copyWith(
        completedCount: _stats.completedCount + (updatedStatus ? 1 : -1),
        pendingCount: _stats.pendingCount + (updatedStatus ? -1 : 1),
      );
    }
    // Also update in master cache!
    final allIndex = _allTodos.indexWhere((t) => t.id == todo.id);
    if (allIndex != -1) {
      _allTodos[allIndex] = _allTodos[allIndex].copyWith(isCompleted: updatedStatus);
    }
    notifyListeners();

    try {
      final response = await _apiClient.dio.patch(
        "${ApiEndpoints.todos}${todo.id}/",
        data: {'is_completed': updatedStatus},
      );
      if (response.statusCode == 200) {
        fetchStats();
        fetchCategories();
      }
    } catch (e) {
      // Revert on error
      if (index != -1) {
        _todos[index] = _todos[index].copyWith(isCompleted: !updatedStatus);
        _sortTodos();
        
        _stats = _stats.copyWith(
          completedCount: _stats.completedCount + (!updatedStatus ? 1 : -1),
          pendingCount: _stats.pendingCount + (!updatedStatus ? -1 : 1),
        );
      }
      final allIndex = _allTodos.indexWhere((t) => t.id == todo.id);
      if (allIndex != -1) {
        _allTodos[allIndex] = _allTodos[allIndex].copyWith(isCompleted: !updatedStatus);
      }
      notifyListeners();
    }
  }

  // Toggle isImportant status
  Future<void> toggleTodoImportant(TodoModel todo) async {
    final updatedImportant = !todo.isImportant;

    // Optimistic UI update
    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index != -1) {
      _todos[index] = _todos[index].copyWith(isImportant: updatedImportant);
      _sortTodos();
      
      // Update stats instantly in memory
      _stats = _stats.copyWith(
        importantCount: _stats.importantCount + (updatedImportant ? 1 : -1),
      );
    }
    // Also update in master cache!
    final allIndex = _allTodos.indexWhere((t) => t.id == todo.id);
    if (allIndex != -1) {
      _allTodos[allIndex] = _allTodos[allIndex].copyWith(isImportant: updatedImportant);
    }
    notifyListeners();

    try {
      final response = await _apiClient.dio.patch(
        "${ApiEndpoints.todos}${todo.id}/",
        data: {'is_important': updatedImportant},
      );
      if (response.statusCode == 200) {
        fetchStats();
      }
    } catch (e) {
      // Revert on error
      if (index != -1) {
        _todos[index] = _todos[index].copyWith(isImportant: !updatedImportant);
        _sortTodos();
        
        _stats = _stats.copyWith(
          importantCount: _stats.importantCount + (!updatedImportant ? 1 : -1),
        );
      }
      final allIndex = _allTodos.indexWhere((t) => t.id == todo.id);
      if (allIndex != -1) {
        _allTodos[allIndex] = _allTodos[allIndex].copyWith(isImportant: !updatedImportant);
      }
      notifyListeners();
    }
  }

  // Delete a Todo
  Future<bool> deleteTodo(int todoId) async {
    try {
      // Find the todo to deduct stats before deletion
      final todoToDelete = _todos.firstWhere(
        (t) => t.id == todoId,
        orElse: () => TodoModel(
          id: -1,
          title: '',
          description: '',
          isCompleted: false,
          isImportant: false,
          createdBy: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final response = await _apiClient.dio.delete("${ApiEndpoints.todos}$todoId/");
      if (response.statusCode == 204) {
        _todos.removeWhere((todo) => todo.id == todoId);
        _allTodos.removeWhere((todo) => todo.id == todoId);
        
        // Update stats instantly in memory
        if (todoToDelete.id != -1) {
          _stats = _stats.copyWith(
            allTasksCount: _stats.allTasksCount - 1,
            completedCount: _stats.completedCount - (todoToDelete.isCompleted ? 1 : 0),
            pendingCount: _stats.pendingCount - (todoToDelete.isCompleted ? 0 : 1),
            importantCount: _stats.importantCount - (todoToDelete.isImportant ? 1 : 0),
          );
        }
        
        notifyListeners();
        
        // Quietly fetch actual values in the background to ensure sync
        fetchStats();
        fetchCategories();
        return true;
      }
    } catch (e) {
      // Handle error
    }
    return false;
  }

  // Create a new Category
  Future<bool> createCategory({
    required String name,
    required String colorHex,
    required int iconCode,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.categories,
        data: {
          'name': name,
          'color': colorHex,
          'icon_code': iconCode,
        },
      );

      if (response.statusCode == 201) {
        await fetchCategories();
        return true;
      }
    } catch (e) {
      // Handle error
    }
    return false;
  }
}
