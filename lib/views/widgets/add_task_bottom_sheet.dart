import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../viewmodels/todo_provider.dart';
import '../../data/models/category_model.dart';

class AddTaskBottomSheet extends StatefulWidget {
  const AddTaskBottomSheet({super.key});

  @override
  State<AddTaskBottomSheet> createState() => _AddTaskBottomSheetState();
}

class _AddTaskBottomSheetState extends State<AddTaskBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  
  DateTime? _selectedDate;
  CategoryModel? _selectedCategory;
  bool _isImportant = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // Open Flutter date picker
  void _presentDatePicker() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _submitTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    final success = await todoProvider.createTodo(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      dueDate: _selectedDate,
      categoryId: _selectedCategory?.id,
      isImportant: _isImportant,
    );

    if (success && mounted) {
      Navigator.pop(context);
    } else {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to save task. Please try again."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    final mediaQuery = MediaQuery.of(context);
    final isKeyboardOpen = mediaQuery.viewInsets.bottom > 100;
    final sheetHeight = isKeyboardOpen ? mediaQuery.size.height * 0.8 : null;

    return Padding(
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
          child: Form(
            key: _formKey,
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
                  "Create New Task",
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Title Input
                TextFormField(
                  controller: _titleController,
                  autofocus: false,
                  validator: (value) => (value == null || value.trim().isEmpty) ? "Task title is required" : null,
                  decoration: InputDecoration(
                    hintText: "What do you need to do?",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.bgStart,
                  ),
                  style: GoogleFonts.outfit(fontSize: 16, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                
                // Description Input
                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: "Add details or description...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.bgStart,
                  ),
                  style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 20),
                
                // Category Picker
                Text(
                  "Assign Category",
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                todoProvider.categories.isEmpty
                    ? Text("No categories available.", style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary))
                    : SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: todoProvider.categories.length,
                          itemBuilder: (context, index) {
                            final cat = todoProvider.categories[index];
                            final isSelected = _selectedCategory?.id == cat.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 10.0),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = isSelected ? null : cat;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected ? cat.colorValue : cat.colorValue.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? cat.colorValue : cat.colorValue.withValues(alpha: 0.18),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    cat.name,
                                    style: GoogleFonts.outfit(
                                      color: isSelected ? Colors.white : cat.colorValue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                const SizedBox(height: 20),
                
                // Custom Actions: Date Picker & Importance toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Date button picker
                    GestureDetector(
                      onTap: _presentDatePicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.bgStart,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.12)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _selectedDate == null
                                  ? "Set Due Date"
                                  : DateFormat('d MMMM y').format(_selectedDate!),
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Important star toggle
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isImportant = !_isImportant;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.bgStart,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.12)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isImportant ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: _isImportant ? AppColors.pendingIcon : AppColors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Important",
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                
                // Create Button
                GestureDetector(
                  onTap: _isSaving ? null : _submitTask,
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
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "Create Task",
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
      ),
    );
  }
}
