import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_theme.dart';
import '../../viewmodels/auth_provider.dart';
import '../../viewmodels/todo_provider.dart';
import '../../data/models/todo_model.dart';
import '../widgets/add_task_bottom_sheet.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  final List<int> _tabHistory = [0];
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _calendarScrollController = ScrollController();
  DateTime _selectedCalendarDate = DateTime.now();

  void _scrollToSelectedDate() {
    if (_calendarScrollController.hasClients) {
      final dayIndex = _selectedCalendarDate.day - 1;
      final screenWidth = MediaQuery.of(context).size.width;
      final itemWidth = 63.0; // 55 width + 8 horizontal margin
      final targetOffset = (dayIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
      
      final maxScroll = _calendarScrollController.position.maxScrollExtent;
      final clampedOffset = targetOffset.clamp(0.0, maxScroll);
      
      _calendarScrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _fetchDataForTab(int index, TodoProvider todoProvider) {
    if (index == 0) {
      todoProvider.setFilter(TaskFilter.all);
    } else if (index == 1) {
      todoProvider.clearAllFilters();
      todoProvider.fetchTodos(isTodayOnly: false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelectedDate();
      });
    } else if (index == 2) {
      todoProvider.fetchCategories();
    } else if (index == 3) {
      todoProvider.fetchStats();
    }
  }

  Future<bool?> _showExitConfirmationDialog() async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    
    if (isIOS) {
      return showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(
            "Exit App",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Are you sure you want to exit the app?",
            style: GoogleFonts.outfit(),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancel", style: GoogleFonts.outfit(color: CupertinoColors.systemBlue)),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(context, true),
              child: Text("Exit", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      return showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Exit App",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Are you sure you want to exit the app?",
            style: GoogleFonts.outfit(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                "Cancel",
                style: GoogleFonts.outfit(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(
                "Exit",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }
  }

  List<DateTime> _generateCurrentMonth() {
    final DateTime now = DateTime.now();
    final int lastDay = DateTime(now.year, now.month + 1, 0).day;
    return List.generate(lastDay, (index) => DateTime(now.year, now.month, index + 1));
  }

  Widget _buildCalendarDayCard(DateTime date) {
    final isSelected = DateUtils.isSameDay(date, _selectedCalendarDate);
    final dayName = DateFormat('E').format(date); // e.g. "Tue"
    final dayNumber = DateFormat('d').format(date); // e.g. "20"
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCalendarDate = date;
        });
        _scrollToSelectedDate();
      },
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 55,
            height: 70,
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: isSelected ? AppTheme.primaryGradient : null,
              color: isSelected ? null : Colors.white.withValues(alpha: 0.7),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: AppColors.shadowDark.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(2, 2),
                      ),
                    ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayName,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white.withValues(alpha: 0.8) : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dayNumber,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Small purple indicator line underneath
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 4,
            width: 16,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationBanner(TodoProvider todoProvider, String username) {
    final completedToday = todoProvider.todos.where((t) => t.isCompleted && DateUtils.isSameDay(t.updatedAt, DateTime.now())).length;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFFE8EBFA), Color(0xFFF1F4FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowDark.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.track_changes_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Keep it up, $username! 🎯",
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "You've completed $completedToday task${completedToday == 1 ? '' : 's'} today.",
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final todoProvider = Provider.of<TodoProvider>(context, listen: false);
      todoProvider.fetchStats();
      todoProvider.fetchCategories();
      todoProvider.fetchTodos();
      _scrollToSelectedDate();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _calendarScrollController.dispose();
    super.dispose();
  }

  // Get greeting text based on time of day
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final todoProvider = Provider.of<TodoProvider>(context);

    // If user got logged out (due to token expiry in background), pop to Login
    if (!authProvider.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        if (_tabHistory.length > 1) {
          setState(() {
            _tabHistory.removeLast();
            _currentTab = _tabHistory.last;
          });
          _fetchDataForTab(_currentTab, todoProvider);
        } else {
          final shouldExit = await _showExitConfirmationDialog();
          if (shouldExit == true) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        extendBody: true,
        body: Container(
        decoration: AppTheme.pageBackgroundGradient,
        height: double.infinity,
        width: double.infinity,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header Greeting (Same for most tabs)
              _buildHeader(authProvider),
              
              // Dynamic Tab Body
              Expanded(
                child: IndexedStack(
                  index: _currentTab,
                  children: [
                    _buildDashboardTab(todoProvider),
                    _buildTodayTab(todoProvider),
                    _buildCategoriesTab(todoProvider),
                    _buildProfileTab(authProvider, todoProvider),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // Custom Gradient Floating Action Button (FAB)
      floatingActionButton: _currentTab == 0 // Show only on Home tab
          ? Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () => _openAddTaskSheet(),
                elevation: 0,
                highlightElevation: 0,
                backgroundColor: Colors.transparent,
                shape: const CircleBorder(),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 36),
              ),
            )
          : null,
      bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  // --- HEADER WIDGET (Dynamic based on Tab) ---
  Widget _buildHeader(AuthProvider authProvider) {
    final username = authProvider.user?.displayName ?? "Samarjit";
    final isTodayTab = _currentTab == 1;
    final isProfileTab = _currentTab == 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (isProfileTab) ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Profile",
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Manage your account and preferences",
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Dynamic Greeting / Today Title
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isTodayTab) ...[
                      Text(
                        "Today",
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMMM d, y').format(DateTime.now()),
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else ...[
                      Text(
                        "${_getGreeting()},",
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        "$username 👋",
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Let's make today productive 🚀",
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Right Side: Avatar
            GestureDetector(
              onTap: () {
                setState(() {
                  _currentTab = 3;
                  _tabHistory.add(3);
                });
              },
              child: Stack(
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.1),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  Positioned(
                    bottom: 1,
                    right: 1,
                    child: Container(
                      height: 10,
                      width: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981), // Green active color dot
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- TAB 1: DASHBOARD TAB ---
  Widget _buildDashboardTab(TodoProvider todoProvider) {
    if (todoProvider.isLoadingTodos && todoProvider.todos.isEmpty) {
      return Column(
        children: [
          _buildDashboardStats(todoProvider),
          Expanded(child: _buildShimmerLoading()),
        ],
      );
    }

    final int headerCount = 2;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: todoProvider.todos.isEmpty ? headerCount + 1 : todoProvider.todos.length + headerCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildDashboardStats(todoProvider);
        } else if (index == 1) {
          return _buildDashboardHeading(todoProvider);
        }

        if (todoProvider.todos.isEmpty) {
          return _buildEmptyState();
        }

        final todoIndex = index - headerCount;
        final todo = todoProvider.todos[todoIndex];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: _buildTaskItem(todo, todoProvider),
        );
      },
    );
  }

  Widget _buildDashboardStats(TodoProvider todoProvider) {
    return SizedBox(
      height: 75,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
        child: Row(
          children: [
            _buildStatCard(
              icon: Icons.list_alt_rounded,
              iconColor: AppColors.allTasksIcon,
              bgColor: AppColors.allTasksBg,
              count: todoProvider.stats.allTasksCount,
              label: "All",
              isActive: todoProvider.selectedFilter == TaskFilter.all && todoProvider.selectedCategory == null,
              onTap: () => todoProvider.setFilter(TaskFilter.all),
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              icon: Icons.check_circle_outline_rounded,
              iconColor: AppColors.completedIcon,
              bgColor: AppColors.completedBg,
              count: todoProvider.stats.completedCount,
              label: "Done",
              isActive: todoProvider.selectedFilter == TaskFilter.completed,
              onTap: () => todoProvider.setFilter(TaskFilter.completed),
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              icon: Icons.access_time_rounded,
               iconColor: AppColors.pendingIcon,
              bgColor: AppColors.pendingBg,
              count: todoProvider.stats.pendingCount,
              label: "Pending",
              isActive: todoProvider.selectedFilter == TaskFilter.pending,
              onTap: () => todoProvider.setFilter(TaskFilter.pending),
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              icon: Icons.flag_rounded,
              iconColor: AppColors.importantIcon,
              bgColor: AppColors.importantBg,
              count: todoProvider.stats.importantCount,
              label: "Starred",
              isActive: todoProvider.selectedFilter == TaskFilter.important,
              onTap: () => todoProvider.setFilter(TaskFilter.important),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardHeading(TodoProvider todoProvider) {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0, bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _getFilterHeading(todoProvider),
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (todoProvider.selectedCategory != null || todoProvider.selectedFilter != TaskFilter.all)
            GestureDetector(
              onTap: () => todoProvider.setFilter(TaskFilter.all),
              child: Text(
                "Clear filter",
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.spa_rounded, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            "No tasks found",
            style: GoogleFonts.outfit(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            "Enjoy your day or add a new action item!",
            style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  // Helper to determine active list header
  String _getFilterHeading(TodoProvider provider) {
    if (provider.selectedCategory != null) {
      return "${provider.selectedCategory!.name} Tasks";
    }
    switch (provider.selectedFilter) {
      case TaskFilter.completed:
        return "Completed Tasks";
      case TaskFilter.pending:
        return "Pending Tasks";
      case TaskFilter.important:
        return "Important Tasks";
      case TaskFilter.all:
        return "Today's Tasks";
    }
  }

  // --- TAB 2: TODAY'S TASKS TAB (Matching Mockup Design) ---
  Widget _buildTodayTab(TodoProvider todoProvider) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final username = authProvider.user?.displayName ?? "Samarjit";

    // Filter todos by the selected calendar date
    final filteredTodos = todoProvider.todos.where((todo) {
      if (todo.dueDate == null) {
        return DateUtils.isSameDay(todo.createdAt, _selectedCalendarDate);
      }
      return DateUtils.isSameDay(todo.dueDate!, _selectedCalendarDate);
    }).toList();

    final int headerCount = 2;
    final int footerCount = 1;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: filteredTodos.isEmpty 
          ? headerCount + 1 + footerCount 
          : filteredTodos.length + headerCount + footerCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildTodayCalendarSection();
        } else if (index == 1) {
          return _buildTodayHeadingSection(todoProvider);
        }

        if (filteredTodos.isEmpty) {
          if (index == 2) {
            return _buildTodayEmptyState();
          }
          return _buildMotivationBanner(todoProvider, username);
        }

        final todoIndex = index - headerCount;
        if (todoIndex < filteredTodos.length) {
          final todo = filteredTodos[todoIndex];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: _buildTaskItem(todo, todoProvider),
          );
        }

        return _buildMotivationBanner(todoProvider, username);
      },
    );
  }

  // --- CALENDAR SCROLL SECTION ---
  Widget _buildTodayCalendarSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Center(
        child: SingleChildScrollView(
          controller: _calendarScrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: _generateCurrentMonth().map((date) => _buildCalendarDayCard(date)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayHeadingSection(TodoProvider todoProvider) {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0, bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            "Tasks for Today",
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.playlist_add_check_rounded,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 8),
          Text(
            "No tasks scheduled",
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 3: CATEGORIES TAB ---
  Widget _buildCategoriesTab(TodoProvider todoProvider) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "My Categories",
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 28),
                onPressed: () => _openCreateCategoryDialog(todoProvider),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: todoProvider.categories.length,
            itemBuilder: (context, index) {
              final cat = todoProvider.categories[index];
              return GestureDetector(
                onTap: () {
                  todoProvider.setCategoryFilter(cat);
                  setState(() {
                    _currentTab = 0; // Redirect to dashboard tab to show items
                    _tabHistory.add(0);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.neumorphicDecoration(borderRadius: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: cat.colorValue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(cat.iconData, color: cat.colorValue, size: 24),
                          ),
                          Text(
                            "${cat.taskCount} active",
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        cat.name,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- TAB 4: PROFILE & LOGOUT TAB (Mockup Matching) ---
  Widget _buildProfileTab(AuthProvider auth, TodoProvider todo) {
    final username = auth.user?.displayName ?? "Samarjit Kashyap";
    
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 120),
      children: [
        // Profile Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.neumorphicDecoration(borderRadius: 24),
          child: Row(
            children: [
              // Avatar with camera icon
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 3),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 40,
                ),
              ),
              const SizedBox(width: 16),
              // Name, email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      auth.user?.email ?? "samarjit@example.com",
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // User Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFF9D62FD),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "User",
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF9D62FD),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
        
        // Account Settings Group
        _buildSettingsGroupHeader("Account"),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: AppTheme.neumorphicDecoration(borderRadius: 20),
          child: Column(
            children: [
              _buildSettingsItem(
                icon: Icons.person_outline_rounded,
                iconColor: const Color(0xFF5b84ff),
                title: "Personal Information",
                subtitle: "Update your personal details",
                onTap: () => _openUpdatePersonalBottomSheet(auth),
              ),
              Divider(color: AppColors.textSecondary.withValues(alpha: 0.1), height: 1),
              _buildSettingsItem(
                icon: Icons.shield_outlined,
                iconColor: const Color(0xFF10b981),
                title: "Security",
                subtitle: "Change password and security settings",
                onTap: () => _openChangePasswordBottomSheet(auth),
              ),
            ],
          ),
        ),
        
        // More Settings Group
        _buildSettingsGroupHeader("More"),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: AppTheme.neumorphicDecoration(borderRadius: 20),
          child: Column(
            children: [
              _buildSettingsItem(
                icon: Icons.help_outline_rounded,
                iconColor: const Color(0xFF9d62fd),
                title: "Help & Support",
                subtitle: "FAQs, help center and contact us",
                onTap: () => _openHelpSupportBottomSheet(),
              ),
              Divider(color: AppColors.textSecondary.withValues(alpha: 0.1), height: 1),
              _buildSettingsItem(
                icon: Icons.privacy_tip_rounded,
                iconColor: const Color(0xFF10b981),
                title: "Privacy Policy",
                subtitle: "Read our privacy guidelines",
                onTap: () => _openPrivacyPolicyBottomSheet(),
              ),
              Divider(color: AppColors.textSecondary.withValues(alpha: 0.1), height: 1),
              _buildSettingsItem(
                icon: Icons.info_outline_rounded,
                iconColor: const Color(0xFF5b84ff),
                title: "About App",
                subtitle: "Version 1.0.0",
                onTap: () => _openAboutAppBottomSheet(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // Log Out Button
        GestureDetector(
          onTap: () => auth.logout(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFDA4AF).withValues(alpha: 0.5), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF43F5E),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Log Out",
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFE11D48),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Sign out from your account",
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFFFB7185),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsGroupHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, top: 20.0, bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? trailingText,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: const Color(0xFF5b84ff),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // --- STATS CARD WIDGET (Pill Button Design) ---
  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required int count,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isActive ? AppColors.primary : Colors.white,
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "$count",
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Individual Task item styled neumorphically (Matching Mockup design exactly)
  Widget _buildTaskItem(TodoModel todo, TodoProvider provider) {
    final hasCategory = todo.categoryDetail != null;
    final catColor = todo.categoryDetail?.colorValue ?? AppColors.primary;

    // Determine priority chip colors
    String priorityText;
    Color priorityColor;
    Color priorityBg;
    
    if (todo.isCompleted) {
      priorityText = "Completed";
      priorityColor = AppColors.completedIcon;
      priorityBg = AppColors.completedIcon.withOpacity(0.12);
    } else if (todo.isImportant) {
      priorityText = "↑ High";
      priorityColor = const Color(0xFFFF5A79);
      priorityBg = const Color(0xFFFF5A79).withOpacity(0.12);
    } else if (todo.dueDate != null) {
      priorityText = "Medium —";
      priorityColor = const Color(0xFFFF9F1C);
      priorityBg = const Color(0xFFFF9F1C).withOpacity(0.12);
    } else {
      priorityText = "Low ↓";
      priorityColor = const Color(0xFF2EC4B6);
      priorityBg = const Color(0xFF2EC4B6).withOpacity(0.12);
    }

    final displayTime = todo.dueDate != null 
        ? DateFormat('hh:mm a').format(todo.dueDate!) 
        : DateFormat('hh:mm a').format(todo.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Dismissible(
        key: Key("todo-${todo.id}"),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24.0),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 28),
        ),
        onDismissed: (_) {
          provider.deleteTodo(todo.id);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: AppTheme.neumorphicDecoration(borderRadius: 20),
          child: Row(
            children: [
              // Circle Checkbox
              GestureDetector(
                onTap: () => provider.toggleTodoStatus(todo),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 24,
                  width: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: todo.isCompleted ? AppColors.completedIcon : AppColors.textSecondary.withOpacity(0.6),
                      width: 2,
                    ),
                    color: todo.isCompleted ? AppColors.completedIcon : Colors.transparent,
                  ),
                  child: todo.isCompleted
                      ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              
              // Title & Category/Description Details
              // Title & Category/Description Details
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showTaskDetailsBottomSheet(context, todo, provider),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo.title,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: todo.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                          decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (hasCategory) ...[
                            Icon(Icons.folder_open_outlined, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              todo.categoryDetail!.name,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          
                          // Tag Dot + Description Tag if present
                          if (todo.description.isNotEmpty) ...[
                            Container(
                              height: 6,
                              width: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: hasCategory ? catColor : AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                todo.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              
              // Right Column: Priority + Star and Date Time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Priority Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: priorityBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          priorityText,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: priorityColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Star Icon
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => provider.toggleTodoImportant(todo),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Icon(
                            todo.isImportant ? Icons.star_rounded : Icons.star_border_rounded,
                            color: todo.isImportant ? const Color(0xFFFFD166) : AppColors.textSecondary.withOpacity(0.5),
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Time Alarm Text Row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        displayTime,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.alarm_rounded,
                        size: 13,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _showTaskDetailsBottomSheet(BuildContext context, TodoModel todo, TodoProvider provider) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: Duration.zero,
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              // Fetch updated version from provider to reflect changes live in the sheet!
              final currentTodo = provider.todos.firstWhere((t) => t.id == todo.id, orElse: () => todo);
              final hasCategory = currentTodo.categoryDetail != null;
              final catColor = currentTodo.categoryDetail?.colorValue ?? AppColors.primary;
              final mediaQuery = MediaQuery.of(context);
              final isKeyboardOpen = mediaQuery.viewInsets.bottom > 100;
              final sheetHeight = isKeyboardOpen ? mediaQuery.size.height * 0.8 : null;
              
              return Material(
                type: MaterialType.transparency,
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: Container(
                    height: sheetHeight,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    padding: EdgeInsets.only(
                      left: 24.0,
                      right: 24.0,
                      top: 24.0,
                      bottom: 24.0 + mediaQuery.padding.bottom + mediaQuery.viewInsets.bottom,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Task Details",
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.bgStart,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded, size: 20, color: AppColors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Task Title
                          Text(
                            currentTodo.title,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              decoration: currentTodo.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Category & Due Date Row
                          Row(
                            children: [
                              if (hasCategory) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: catColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.folder_open_rounded, size: 14, color: catColor),
                                      const SizedBox(width: 6),
                                      Text(
                                        currentTodo.categoryDetail!.name,
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: catColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              
                              if (currentTodo.dueDate != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.alarm_rounded, size: 14, color: AppColors.primary),
                                      const SizedBox(width: 6),
                                      Text(
                                        DateFormat('d MMM y, hh:mm a').format(currentTodo.dueDate!),
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Description Box
                          Text(
                            "Description / Notes",
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.bgStart,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.12)),
                            ),
                            child: Text(
                              currentTodo.description.isNotEmpty 
                                  ? currentTodo.description 
                                  : "No detailed description added for this task.",
                              style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: currentTodo.description.isNotEmpty ? AppColors.textPrimary : AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Quick Action toggles row
                            Row(
                              children: [
                                // Complete Toggle Button
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      await provider.toggleTodoStatus(currentTodo);
                                      setModalState(() {});
                                    },
                                    child: Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: currentTodo.isCompleted 
                                            ? AppColors.completedIcon.withValues(alpha: 0.1) 
                                            : AppColors.completedIcon,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: AppColors.completedIcon),
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            currentTodo.isCompleted ? Icons.undo_rounded : Icons.check_circle_outline_rounded,
                                            color: currentTodo.isCompleted ? AppColors.completedIcon : Colors.white,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            currentTodo.isCompleted ? "Mark Pending" : "Mark Completed",
                                            style: GoogleFonts.outfit(
                                              color: currentTodo.isCompleted ? AppColors.completedIcon : Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                
                                // Star Toggle Button
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      await provider.toggleTodoImportant(currentTodo);
                                      setModalState(() {});
                                    },
                                    child: Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: currentTodo.isImportant 
                                            ? const Color(0xFFFFD166).withValues(alpha: 0.1) 
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: currentTodo.isImportant ? const Color(0xFFFFD166) : AppColors.textSecondary.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            currentTodo.isImportant ? Icons.star_rounded : Icons.star_border_rounded,
                                            color: currentTodo.isImportant ? const Color(0xFFFFB703) : AppColors.textSecondary,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            currentTodo.isImportant ? "Unstar Task" : "Star Task",
                                            style: GoogleFonts.outfit(
                                              color: currentTodo.isImportant ? const Color(0xFFFFB703) : AppColors.textPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Danger Zone Delete button
                            GestureDetector(
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text("Delete Task?", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                    content: Text("Are you sure you want to delete this task permanently?", style: GoogleFonts.outfit()),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: Text("Cancel", style: GoogleFonts.outfit(color: AppColors.textSecondary)),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: Text("Delete", style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await provider.deleteTodo(currentTodo.id);
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                }
                              },
                              child: Container(
                                height: 50,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Delete Task Permanently",
                                      style: GoogleFonts.outfit(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
          ),
        );
      },
    );
  }

  // --- LOADING SHIMMER EFFECT ---
  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      itemCount: 4,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 14.0),
        child: Shimmer.fromColors(
          baseColor: Colors.white.withOpacity(0.8),
          highlightColor: Colors.grey.withOpacity(0.1),
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }

  // --- FLOATING BOTTOM NAVIGATION BAR ---
  Widget _buildBottomNavigationBar() {
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    
    return Container(
      height: 70,
      margin: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: bottomInset > 0 ? bottomInset + 8 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.08), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildPillTabItem(0, Icons.home_rounded, "Home", todoProvider),
          _buildPillTabItem(1, Icons.calendar_today_rounded, "Today", todoProvider),
          _buildPillTabItem(2, Icons.grid_view_rounded, "Categories", todoProvider),
          _buildPillTabItem(3, Icons.person_rounded, "Profile", todoProvider),
        ],
      ),
    );
  }

  Widget _buildPillTabItem(int index, IconData icon, String label, TodoProvider todoProvider) {
    final isActive = _currentTab == index;
    
    return Expanded(
      flex: isActive ? 4 : 3,
      child: GestureDetector(
        onTap: () {
          if (_currentTab != index) {
            setState(() {
              _currentTab = index;
              _tabHistory.add(index);
            });
            _fetchDataForTab(index, todoProvider);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: isActive ? AppColors.primary : AppColors.primary.withValues(alpha: 0.4),
                    size: 20,
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- DIALOGS & BOTTOM SHEETS ---
  void _openAddTaskSheet() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: Duration.zero,
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: const Material(
            type: MaterialType.transparency,
            child: AddTaskBottomSheet(),
          ),
        );
      },
    );
  }

  void _openCreateCategoryDialog(TodoProvider provider) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    Color selectedColor = AppColors.primary;
    
    // Simple mock values for colors and icons
    final colors = [const Color(0xFF6C63FF), const Color(0xFFE91E63), const Color(0xFF4CAF50), const Color(0xFFFF9800), const Color(0xFF9C27B0)];
    int selectedIconCode = 57415; // default list icon

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text("New Category", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  validator: (value) => (value == null || value.trim().isEmpty) ? "Category name required" : null,
                  decoration: InputDecoration(
                    labelText: "Category Name",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 16),
                // Color picker block
                Text("Select Color", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: colors.map((col) => GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = col),
                    child: Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        color: col,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selectedColor == col ? Colors.black87 : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: GoogleFonts.outfit(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                
                final hexString = "#${selectedColor.value.toRadixString(16).substring(2).toUpperCase()}";
                final success = await provider.createCategory(
                  name: nameController.text.trim(),
                  colorHex: hexString,
                  iconCode: selectedIconCode,
                );
                if (success && context.mounted) {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text("Create", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _openUpdatePersonalBottomSheet(AuthProvider auth) {
    final firstNameController = TextEditingController(text: auth.user?.firstName);
    final lastNameController = TextEditingController(text: auth.user?.lastName);
    final emailController = TextEditingController(text: auth.user?.email);
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            final sheetBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
            final fillBg = isDark ? const Color(0xFF2E2E3E) : AppColors.bgStart;
            final textColor = isDark ? Colors.white : AppColors.textPrimary;
            final mediaQuery = MediaQuery.of(context);

            return Container(
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 20.0,
                bottom: 24.0 + mediaQuery.padding.bottom + mediaQuery.viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top handle bar
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        "Update Personal Information",
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // First Name
                      TextFormField(
                        controller: firstNameController,
                        validator: (v) => (v == null || v.trim().isEmpty) ? "First Name is required" : null,
                        decoration: InputDecoration(
                          hintText: "First Name",
                          prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: fillBg,
                        ),
                        style: GoogleFonts.outfit(fontSize: 16, color: textColor),
                      ),
                      const SizedBox(height: 12),

                      // Last Name
                      TextFormField(
                        controller: lastNameController,
                        validator: (v) => (v == null || v.trim().isEmpty) ? "Last Name is required" : null,
                        decoration: InputDecoration(
                          hintText: "Last Name",
                          prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: fillBg,
                        ),
                        style: GoogleFonts.outfit(fontSize: 16, color: textColor),
                      ),
                      const SizedBox(height: 12),
                      
                      // Email Address
                      TextFormField(
                        controller: emailController,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return "Email is required";
                          if (!v.contains('@')) return "Invalid email format";
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: "Email Address",
                          prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: fillBg,
                        ),
                        style: GoogleFonts.outfit(fontSize: 16, color: textColor),
                      ),
                      const SizedBox(height: 28),
                      
                      // Save Button
                      GestureDetector(
                        onTap: isSaving ? null : () async {
                          if (formKey.currentState!.validate()) {
                            setSheetState(() => isSaving = true);
                            final success = await auth.updateProfile(
                              firstName: firstNameController.text.trim(),
                              lastName: lastNameController.text.trim(),
                              email: emailController.text.trim(),
                            );
                            if (success && mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Profile updated successfully!"),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            } else {
                              setSheetState(() => isSaving = false);
                            }
                          }
                        },
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: isSaving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  "Save Changes",
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openChangePasswordBottomSheet(AuthProvider auth) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            final sheetBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
            final fillBg = isDark ? const Color(0xFF2E2E3E) : AppColors.bgStart;
            final textColor = isDark ? Colors.white : AppColors.textPrimary;
            final mediaQuery = MediaQuery.of(context);

            return Container(
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 20.0,
                bottom: 24.0 + mediaQuery.padding.bottom + mediaQuery.viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top handle bar
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        "Change Password",
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Old Password
                      TextFormField(
                        controller: oldPasswordController,
                        obscureText: true,
                        validator: (v) => (v == null || v.trim().isEmpty) ? "Old password is required" : null,
                        decoration: InputDecoration(
                          hintText: "Old Password",
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: fillBg,
                        ),
                        style: GoogleFonts.outfit(fontSize: 16, color: textColor),
                      ),
                      const SizedBox(height: 12),
                      
                      // New Password
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: true,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return "New password is required";
                          if (v.length < 6) return "Password must be at least 6 characters";
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: "New Password",
                          prefixIcon: const Icon(Icons.vpn_key_outlined, color: AppColors.textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: fillBg,
                        ),
                        style: GoogleFonts.outfit(fontSize: 16, color: textColor),
                      ),
                      const SizedBox(height: 12),
                      
                      // Confirm Password
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return "Please confirm password";
                          if (v != newPasswordController.text) return "Passwords do not match";
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: "Confirm Password",
                          prefixIcon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: fillBg,
                        ),
                        style: GoogleFonts.outfit(fontSize: 16, color: textColor),
                      ),
                      const SizedBox(height: 28),
                      
                      // Save Button
                      GestureDetector(
                        onTap: isSaving ? null : () async {
                          if (formKey.currentState!.validate()) {
                            setSheetState(() => isSaving = true);
                            final success = await auth.changePassword(
                              oldPassword: oldPasswordController.text,
                              newPassword: newPasswordController.text,
                            );
                            if (success && mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Password changed successfully!"),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            } else {
                              setSheetState(() => isSaving = false);
                            }
                          }
                        },
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: isSaving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  "Change Password",
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openHelpSupportBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final sheetBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
        final fillBg = isDark ? const Color(0xFF2E2E3E) : AppColors.bgStart;
        final textColor = isDark ? Colors.white : AppColors.textPrimary;
        final subtitleColor = isDark ? Colors.white70 : AppColors.textSecondary;
        final mediaQuery = MediaQuery.of(context);

        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          padding: EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 20.0,
            bottom: 24.0 + mediaQuery.padding.bottom,
          ),
          constraints: BoxConstraints(
            maxHeight: mediaQuery.size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top handle bar
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                "Help & Support",
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              
              // Contact Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: fillBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mail_outline_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Developer Email",
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          SelectableText(
                            "samarjitkashyp@gmail.com",
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              Text(
                "Frequently Asked Questions (FAQs)",
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              
              // FAQs list in scroll view
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildFaqItem(
                      question: "What can I do in this app?",
                      answer: "You can create daily schedules, add details/notes, set categories, prioritize items as 'Important', manage task status updates instantly, search across your tasks database, and customize your app preferences.",
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      fillBg: fillBg,
                    ),
                    const SizedBox(height: 12),
                    _buildFaqItem(
                      question: "How do I toggle Dark Mode?",
                      answer: "Tap the theme sun/moon icon at the top right of the Profile screen header row to dynamically toggle light/dark modes.",
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      fillBg: fillBg,
                    ),
                    const SizedBox(height: 12),
                    _buildFaqItem(
                      question: "Does the app support offline mode?",
                      answer: "Yes! All tasks are managed dynamically in memory first (optimistic rendering). Modifications sync with the server database silently in the background.",
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      fillBg: fillBg,
                    ),
                    const SizedBox(height: 12),
                    _buildFaqItem(
                      question: "How do I filter tasks by category?",
                      answer: "Go to the Categories tab, tap on any category card, and it will instantly redirect you to the Dashboard showing only tasks belonging to that category.",
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      fillBg: fillBg,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFaqItem({
    required String question,
    required String answer,
    required Color textColor,
    required Color subtitleColor,
    required Color fillBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fillBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Q: $question",
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "A: $answer",
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: subtitleColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _openAboutAppBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final sheetBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
        final fillBg = isDark ? const Color(0xFF2E2E3E) : AppColors.bgStart;
        final textColor = isDark ? Colors.white : AppColors.textPrimary;
        final subtitleColor = isDark ? Colors.white70 : AppColors.textSecondary;
        final mediaQuery = MediaQuery.of(context);

        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          padding: EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 20.0,
            bottom: 24.0 + mediaQuery.padding.bottom,
          ),
          constraints: BoxConstraints(
            maxHeight: mediaQuery.size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top handle bar
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                "About App & Release History",
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              
              // App Logo Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: fillBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "TodoPedia",
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Your personal productivity companion.",
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              Text(
                "Version History",
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              
              // Versions timeline
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildVersionHistoryItem(
                      version: "v1.0.0 (Latest Release)",
                      date: "August 20, 2026",
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      fillBg: fillBg,
                      changes: [
                        "Redesigned premium clean Profile card & setting items.",
                        "Introduced App theme mode switcher for Light and Dark Modes.",
                        "Connected Personal Information & Security Bottom Sheets.",
                        "Added Contact details & Developer FAQs information panel."
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildVersionHistoryItem(
                      version: "v0.9.0 (Beta)",
                      date: "July 12, 2026",
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      fillBg: fillBg,
                      changes: [
                        "Configured horizontal active day scrolling autolocus behavior.",
                        "Restructured Categories grid design with unified sticky properties.",
                        "Integrated sequential back-navigation history flow handlers.",
                        "Enabled platform native back-gesture app close warning prompts."
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildVersionHistoryItem(
                      version: "v0.8.0 (Alpha)",
                      date: "June 05, 2026",
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      fillBg: fillBg,
                      changes: [
                        "Built initial core CRUD controllers for task management.",
                        "Added optimistic local caches for instant task filter response.",
                        "Registered user secure token session login/register gateways.",
                        "Implemented category creators and search parameter queries."
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVersionHistoryItem({
    required String version,
    required String date,
    required Color textColor,
    required Color subtitleColor,
    required Color fillBg,
    required List<String> changes,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fillBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                version,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                date,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: subtitleColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...changes.map((change) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("•  ", style: TextStyle(color: AppColors.primary, fontSize: 14)),
                    Expanded(
                      child: Text(
                        change,
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          color: textColor,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  void _openPrivacyPolicyBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final sheetBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
        final fillBg = isDark ? const Color(0xFF2E2E3E) : AppColors.bgStart;
        final textColor = isDark ? Colors.white : AppColors.textPrimary;
        final subtitleColor = isDark ? Colors.white70 : AppColors.textSecondary;
        final mediaQuery = MediaQuery.of(context);

        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          padding: EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 20.0,
            bottom: 24.0 + mediaQuery.padding.bottom,
          ),
          constraints: BoxConstraints(
            maxHeight: mediaQuery.size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top handle bar
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                "Privacy Policy",
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              
              // Privacy Info Scrollable view
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildPrivacySection(
                      title: "1. Information We Collect",
                      content: "We collect information you provide directly to us when creating an account, updating your profile, or creating tasks. This includes your name, email address, and task descriptions.",
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      fillBg: fillBg,
                    ),
                    const SizedBox(height: 14),
                    _buildPrivacySection(
                      title: "2. How We Use Your Information",
                      content: "Your data is used to provide, maintain, and personalize your experience in TodoPedia. This includes displaying your tasks, managing category filters, and keeping your session secure.",
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      fillBg: fillBg,
                    ),
                    const SizedBox(height: 14),
                    _buildPrivacySection(
                      title: "3. Data Security",
                      content: "We take reasonable measures to protect your personal information from loss, theft, misuse, and unauthorized access. Your tokens are stored securely in local secure storage.",
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      fillBg: fillBg,
                    ),
                    const SizedBox(height: 14),
                    _buildPrivacySection(
                      title: "4. Contact Us",
                      content: "If you have any questions or suggestions about our Privacy Policy, do not hesitate to contact us at samarjitkashyp@gmail.com.",
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      fillBg: fillBg,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrivacySection({
    required String title,
    required String content,
    required Color textColor,
    required Color subtitleColor,
    required Color fillBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fillBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              color: subtitleColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
