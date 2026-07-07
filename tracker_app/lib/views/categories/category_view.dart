import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/toast.dart';

class CategoryView extends StatefulWidget {
  const CategoryView({super.key});

  @override
  State<CategoryView> createState() => _CategoryViewState();
}

class _CategoryViewState extends State<CategoryView> {
  static const List<String> _availableIcons = [
    'Tag', 'Utensils', 'ShoppingCart', 'Briefcase', 'Car', 'Home', 'Bolt',
    'Clapperboard', 'Heart', 'Book', 'Plane', 'Laptop', 'TrendingUp', 'Sparkles', 'Gift', 'Coffee',
  ];

  static const List<Color> _availableColors = [
    Color(0xFF10B981), Color(0xFF22C55E), Color(0xFF14B8A6), Color(0xFF06B6D4),
    Color(0xFF0EA5E9), Color(0xFF3B82F6), Color(0xFF4F46E5), Color(0xFF6366F1),
    Color(0xFF8B5CF6), Color(0xFFA855F7), Color(0xFFD946EF), Color(0xFFEC4899),
    Color(0xFFF43F5E), Color(0xFFEF4444), Color(0xFFF97316), Color(0xFFF59E0B),
    Color(0xFFEAB308), Color(0xFF64748B),
  ];

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<CategoryItem> _categories = [];
  bool _isLoading = true;
  String _filterStatus = 'all';
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiClient().dio.get(
        '/categories',
        queryParameters: {
          'page': _currentPage,
          if (_searchController.text.trim().isNotEmpty) 'search': _searchController.text.trim(),
          if (_filterStatus != 'all') 'status': _filterStatus,
        },
      );

      final dynamic payload = response.data;
      final List<dynamic> rawItems = payload is Map<String, dynamic>
          ? (payload['data'] as List<dynamic>? ?? [])
          : (payload as List<dynamic>? ?? []);

      setState(() {
        _categories = rawItems.map((item) => CategoryItem.fromJson(Map<String, dynamic>.from(item))).toList();
        _totalPages = payload is Map<String, dynamic> ? int.tryParse('${payload['last_page'] ?? 1}') ?? 1 : 1;
      });
    } catch (_) {
      if (mounted) {
        SunsetToast.show(context, 'Failed to fetch categories.', type: SunsetToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _currentPage = 1);
      _fetchCategories();
    });
  }

  Future<void> _saveCategory(CategoryFormData form, {CategoryItem? editing}) async {
    try {
      if (editing == null) {
        await ApiClient().dio.post('/categories', data: form.toJson());
        if (mounted) SunsetToast.show(context, 'Category added successfully!');
      } else {
        await ApiClient().dio.put('/categories/${editing.id}', data: form.toJson());
        if (mounted) SunsetToast.show(context, 'Category updated successfully!');
      }
      await _fetchCategories();
    } on DioException catch (e) {
      final message = e.response?.data is Map ? (e.response?.data['message'] ?? e.response?.data['error']) : null;
      if (mounted) {
        SunsetToast.show(context, message?.toString() ?? 'Operation failed.', type: SunsetToastType.error);
      }
      rethrow;
    }
  }

  Future<void> _deleteCategory(CategoryItem category) async {
    try {
      await ApiClient().dio.delete('/categories/${category.id}');
      if (mounted) SunsetToast.show(context, 'Category deleted successfully');
      await _fetchCategories();
    } on DioException catch (e) {
      final message = e.response?.data is Map ? (e.response?.data['message'] ?? e.response?.data['error']) : null;
      if (mounted) {
        SunsetToast.show(context, message?.toString() ?? 'Failed to delete category', type: SunsetToastType.error);
      }
    }
  }

  List<CategoryItem> get _incomeCategories => _categories.where((c) => c.typeId == 2).toList();
  List<CategoryItem> get _expenseCategories => _categories.where((c) => c.typeId == 1).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SunsetColors.bgStart,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            return SingleChildScrollView(
                clipBehavior: Clip.none,
                padding: EdgeInsets.fromLTRB(isWide ? 32 : 18, 24, isWide ? 32 : 18, 32),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isWide),
                  const SizedBox(height: 20),
                  _buildResponsiveToolbar(), // 🌟 核心修复：调用全新的响应式工具栏
                  const SizedBox(height: 24),
                  if (_isLoading)
                    _buildLoading()
                  else ...[
                    _buildCategorySection(
                      title: 'Income',
                      titleColor: const Color(0xFF059669),
                      badgeColor: const Color(0xFFECFDF5),
                      categories: _incomeCategories,
                      emptyText: 'No income categories.',
                      columns: isWide ? 2 : 1,
                    ),
                    const SizedBox(height: 28),
                    _buildCategorySection(
                      title: 'Expense',
                      titleColor: SunsetColors.expense,
                      badgeColor: const Color(0xFFFEF2F2),
                      categories: _expenseCategories,
                      emptyText: 'No expense categories.',
                      columns: isWide ? 2 : 1,
                    ),
                    if (_totalPages > 1) ...[
                      const SizedBox(height: 24),
                      _buildPagination(),
                    ],
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isWide) {
    return Flex(
      direction: isWide ? Axis.horizontal : Axis.vertical,
      crossAxisAlignment: isWide ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Categories', style: TextStyle(color: SunsetColors.dark, fontSize: 26, fontWeight: FontWeight.w800)),
            SizedBox(height: 6),
            Text('Organize transactions by category dynamically.', style: TextStyle(color: Color(0x992D2520), fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
        SizedBox(height: isWide ? 0 : 16, width: isWide ? 12 : 0),
        ElevatedButton.icon(
          onPressed: _openAddDialog,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Category'),
          style: ElevatedButton.styleFrom(
            backgroundColor: SunsetColors.secondary,
            foregroundColor: Colors.white,
            elevation: 8,
            shadowColor: SunsetColors.secondary.withValues(alpha: 0.24),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  // 🌟 核心修复：严格控制 Row 和 Column 布局，防止边框被挤压裁切
  Widget _buildResponsiveToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SunsetColors.primary.withValues(alpha: 0.10)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          
          if (isMobile) {
            return Column(
              children: [
                _buildSearchField(),
                const SizedBox(height: 12),
                _buildStatusFilter(),
              ],
            );
          } else {
            return Row(
              children: [
                Expanded(child: _buildSearchField()),
                const SizedBox(width: 12),
                Expanded(child: _buildStatusFilter()),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: 'Search categories...',
        prefixIcon: const Icon(Icons.search, size: 20, color: Color(0x662D2520)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: SunsetColors.primary.withValues(alpha: 0.30)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: SunsetColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return DropdownButtonFormField<String>(
      initialValue: _filterStatus,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: SunsetColors.primary.withValues(alpha: 0.30)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: SunsetColors.primary, width: 1.5),
        ),
      ),
      style: const TextStyle(color: SunsetColors.dark, fontSize: 13, fontWeight: FontWeight.w800),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('All Status')),
        DropdownMenuItem(value: '1', child: Text('Active')),
        DropdownMenuItem(value: '0', child: Text('Inactive')),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _filterStatus = value;
          _currentPage = 1;
        });
        _fetchCategories();
      },
    );
  }

  Widget _buildLoading() {
    return Container(
      height: 180,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.black.withValues(alpha: 0.06))),
      child: const CircularProgressIndicator(color: SunsetColors.primary),
    );
  }

  Widget _buildCategorySection({
    required String title,
    required Color titleColor,
    required Color badgeColor,
    required List<CategoryItem> categories,
    required String emptyText,
    required int columns,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
          child: Row(
            children: [
              Text(title, style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(99)),
                child: Text('(${categories.length})', style: TextStyle(color: titleColor, fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (categories.isEmpty)
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(color: const Color(0x80F8FAFC), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.shade200)),
            child: Text(emptyText, style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w700)),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisSpacing: 14, crossAxisSpacing: 14, mainAxisExtent: 86),
            itemBuilder: (context, index) => _buildCategoryCard(categories[index]),
          ),
      ],
    );
  }

  Widget _buildCategoryCard(CategoryItem category) {
    final color = category.color;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.025), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 58,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(17)),
            child: Icon(_iconForName(category.icon), color: color, size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: SunsetColors.dark, fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(category.description.isEmpty ? 'No description' : category.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0x662D2520), fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _smallActionButton(icon: Icons.visibility_outlined, color: Colors.blue, onTap: () => _openViewDialog(category)),
                _smallActionButton(icon: Icons.edit_outlined, color: const Color(0xFF10B981), onTap: () => _openEditDialog(category)),
                _smallActionButton(icon: Icons.delete_outline, color: Colors.red, onTap: () => _openDeleteDialog(category)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallActionButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10), child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, size: 18, color: color.withValues(alpha: 0.82))));
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: SunsetColors.primary.withValues(alpha: 0.10)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Page $_currentPage of $_totalPages', style: const TextStyle(color: Color(0x992D2520), fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(width: 16),
          _pageButton(
            icon: Icons.chevron_left,
            enabled: _currentPage > 1,
            onTap: () {
              setState(() => _currentPage--);
              _fetchCategories();
            },
          ),
          const SizedBox(width: 8),
          ...List.generate(_totalPages, (index) {
            final page = index + 1;
            final selected = page == _currentPage;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () {
                  setState(() => _currentPage = page);
                  _fetchCategories();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? SunsetColors.primary.withValues(alpha: 0.10) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected ? SunsetColors.primary.withValues(alpha: 0.30) : Colors.grey.shade200),
                  ),
                  child: Text('$page', style: TextStyle(color: selected ? SunsetColors.primary : const Color(0x992D2520), fontWeight: FontWeight.w900)),
                ),
              ),
            );
          }),
          _pageButton(
            icon: Icons.chevron_right,
            enabled: _currentPage < _totalPages,
            onTap: () {
              setState(() => _currentPage++);
              _fetchCategories();
            },
          ),
        ],
      ),
    );
  }

  Widget _pageButton({required IconData icon, required bool enabled, required VoidCallback onTap}) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: Icon(icon, size: 18, color: SunsetColors.dark),
        ),
      ),
    );
  }

  void _openAddDialog() { _openFormDialog(CategoryFormData()); }
  void _openEditDialog(CategoryItem category) { _openFormDialog(CategoryFormData.fromCategory(category), editing: category); }

  Future<void> _openFormDialog(CategoryFormData initial, {CategoryItem? editing}) async {
    await showDialog<void>(
      context: context,
      barrierColor: SunsetColors.dark.withValues(alpha: 0.42),
      builder: (context) {
        return CategoryFormDialog(
          initial: initial, editing: editing, availableIcons: _availableIcons,
          availableColors: _availableColors, iconForName: _iconForName,
          onSave: (form) => _saveCategory(form, editing: editing),
        );
      },
    );
  }

  void _openViewDialog(CategoryItem category) {
    showDialog<void>(
      context: context,
      barrierColor: SunsetColors.dark.withValues(alpha: 0.42),
      builder: (context) => CategoryDetailsDialog(category: category, icon: _iconForName(category.icon)),
    );
  }

  void _openDeleteDialog(CategoryItem category) {
    showDialog<void>(
      context: context,
      barrierColor: SunsetColors.dark.withValues(alpha: 0.42),
      builder: (context) => CategoryDeleteDialog(category: category, icon: _iconForName(category.icon), onDelete: () => _deleteCategory(category)),
    );
  }

  IconData _iconForName(String name) {
    switch (name) {
      case 'Utensils': return Icons.restaurant;
      case 'ShoppingCart': return Icons.shopping_cart_outlined;
      case 'Briefcase': return Icons.business_center_outlined;
      case 'Car': return Icons.directions_car_outlined;
      case 'Home': return Icons.home_outlined;
      case 'Bolt': return Icons.bolt_outlined;
      case 'Clapperboard': return Icons.movie_creation_outlined;
      case 'Heart': return Icons.favorite_border;
      case 'Book': return Icons.menu_book_outlined;
      case 'Plane': return Icons.flight_takeoff_outlined;
      case 'Laptop': return Icons.laptop_mac_outlined;
      case 'TrendingUp': return Icons.trending_up;
      case 'Sparkles': return Icons.auto_awesome;
      case 'Gift': return Icons.card_giftcard_outlined;
      case 'Coffee': return Icons.local_cafe_outlined;
      case 'Tag':
      default: return Icons.sell_outlined;
    }
  }
}

class CategoryFormDialog extends StatefulWidget {
  final CategoryFormData initial; final CategoryItem? editing; final List<String> availableIcons;
  final List<Color> availableColors; final IconData Function(String name) iconForName; final Future<void> Function(CategoryFormData form) onSave;

  const CategoryFormDialog({super.key, required this.initial, required this.editing, required this.availableIcons, required this.availableColors, required this.iconForName, required this.onSave});

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  late CategoryFormData _form; late TextEditingController _nameController; late TextEditingController _descriptionController;
  bool _isSaving = false; String? _nameError;

  @override
  void initState() {
    super.initState();
    _form = widget.initial.copy();
    _nameController = TextEditingController(text: _form.name);
    _descriptionController = TextEditingController(text: _form.description);
  }

  @override
  void dispose() { _nameController.dispose(); _descriptionController.dispose(); super.dispose(); }

  Future<void> _handleSave() async {
    setState(() {
      _nameError = null;
      _form = _form.copy(name: _nameController.text.trim(), description: _descriptionController.text.trim());
    });

    if (_form.name.isEmpty) {
      setState(() => _nameError = 'Category name is required.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.onSave(_form);
      if (mounted) Navigator.pop(context);
    } on DioException catch (e) {
      final errors = e.response?.data is Map ? e.response?.data['errors'] : null;
      if (errors is Map && errors['name'] is List && mounted) {
        setState(() => _nameError = errors['name'].first.toString());
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            _dialogHeader(widget.editing == null ? 'Add Category' : 'Edit Category'),
            Flexible(
              child: SingleChildScrollView(
                clipBehavior: Clip.none,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Category Name'),
                    TextField(controller: _nameController, decoration: _fieldDecoration('E.g. Food, Salary')),
                    if (_nameError != null) ...[
                      const SizedBox(height: 6),
                      Text(_nameError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ],
                    const SizedBox(height: 18),
                    _label('Select Type'),
                    DropdownButtonFormField<int>(
                      initialValue: _form.typeId, decoration: _fieldDecoration('Select Type'),
                      items: const [DropdownMenuItem(value: 1, child: Text('Expense')), DropdownMenuItem(value: 2, child: Text('Income'))],
                      onChanged: (value) { if (value != null) setState(() => _form = _form.copy(typeId: value)); },
                    ),
                    const SizedBox(height: 18),
                    _label('Select Icon'),
                    Container(
                      padding: const EdgeInsets.all(12), decoration: _pickerBoxDecoration(),
                      child: Wrap(
                        spacing: 8, runSpacing: 8,
                        children: widget.availableIcons.map((name) {
                          final selected = _form.icon == name;
                          return InkWell(
                            onTap: () => setState(() => _form = _form.copy(icon: name)), borderRadius: BorderRadius.circular(13),
                            child: Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(color: selected ? SunsetColors.secondary : Colors.white, borderRadius: BorderRadius.circular(13), border: Border.all(color: Colors.grey.shade100), boxShadow: selected ? [BoxShadow(color: SunsetColors.secondary.withValues(alpha: 0.24), blurRadius: 8, offset: const Offset(0, 3))] : []),
                              child: Icon(widget.iconForName(name), color: selected ? Colors.white : SunsetColors.dark, size: 22),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _label('Select Color'),
                    Container(
                      padding: const EdgeInsets.all(12), decoration: _pickerBoxDecoration(),
                      child: Wrap(
                        spacing: 12, runSpacing: 12,
                        children: widget.availableColors.map((color) {
                          final selected = _form.color == color;
                          return InkWell(
                            onTap: () => setState(() => _form = _form.copy(color: color)), borderRadius: BorderRadius.circular(99),
                            child: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle,
                                border: Border.all(color: selected ? SunsetColors.secondary : Colors.transparent, width: 3),
                                boxShadow: selected ? [BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 8, offset: const Offset(0, 3))] : [],
                              ),
                              child: selected ? Center(child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))) : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _descriptionField(),
                    const SizedBox(height: 18),
                    _statusField(),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)), border: Border(top: BorderSide(color: SunsetColors.primary.withValues(alpha: 0.10)))),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SunsetColors.dark.withValues(alpha: 0.66),
                        side: BorderSide(color: Colors.grey.shade200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w800)),
                    )
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SunsetColors.secondary, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isSaving) ...[
                            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                            const SizedBox(width: 8),
                          ],
                          Text(_isSaving ? 'Saving...' : 'Save Category', style: const TextStyle(fontWeight: FontWeight.w800)),
                        ],
                      ),
                    )
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogHeader(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 16, 18),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: SunsetColors.primary.withValues(alpha: 0.10)))),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(color: SunsetColors.dark, fontSize: 22, fontWeight: FontWeight.w800))),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close), color: Colors.grey),
        ],
      ),
    );
  }

  Widget _descriptionField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('Description'), TextField(controller: _descriptionController, decoration: _fieldDecoration('Brief description...'))]);
  }

  Widget _statusField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Status'),
        DropdownButtonFormField<int>(
          initialValue: _form.status, decoration: _fieldDecoration('Select Status'),
          items: const [DropdownMenuItem(value: 1, child: Text('Active')), DropdownMenuItem(value: 0, child: Text('Inactive'))],
          onChanged: (value) { if (value != null) setState(() => _form = _form.copy(status: value)); },
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(text, style: const TextStyle(color: Color(0xB32D2520), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.8)));
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint, filled: true, fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: SunsetColors.primary.withValues(alpha: 0.25))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: SunsetColors.primary, width: 1.5)),
    );
  }

  BoxDecoration _pickerBoxDecoration() {
    return BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100));
  }
}

class CategoryDetailsDialog extends StatelessWidget {
  final CategoryItem category; final IconData icon;
  const CategoryDetailsDialog({super.key, required this.category, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(18), backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _simpleHeader(context, 'Category Details'),
            Flexible(
              child: SingleChildScrollView(
                clipBehavior: Clip.none,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(width: 82, height: 96, decoration: BoxDecoration(color: category.color.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(20)), child: Icon(icon, size: 42, color: category.color)),
                    const SizedBox(height: 18),
                    Text(category.name, textAlign: TextAlign.center, style: const TextStyle(color: SunsetColors.dark, fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(10)),
                      child: Text(category.typeId == 2 ? 'Income' : 'Expense', style: const TextStyle(color: SunsetColors.primary, fontSize: 12, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
                      child: Text(category.description.isEmpty ? 'No description provided.' : category.description, textAlign: TextAlign.center, style: const TextStyle(color: Color(0x992D2520), fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
            _closeFooter(context),
          ],
        ),
      ),
    );
  }
}

class CategoryDeleteDialog extends StatefulWidget {
  final CategoryItem category; final IconData icon; final Future<void> Function() onDelete;
  const CategoryDeleteDialog({super.key, required this.category, required this.icon, required this.onDelete});
  @override
  State<CategoryDeleteDialog> createState() => _CategoryDeleteDialogState();
}

class _CategoryDeleteDialogState extends State<CategoryDeleteDialog> {
  bool _isDeleting = false;

  Future<void> _handleDelete() async {
    setState(() => _isDeleting = true);
    await widget.onDelete();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(18), backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _simpleHeader(context, 'Delete Category', titleColor: Colors.red),
            Flexible(
              child: SingleChildScrollView(
                clipBehavior: Clip.none,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Are you sure you want to delete this category? This action cannot be undone.', style: TextStyle(color: SunsetColors.dark, fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFFEE2E2))),
                      child: Row(
                        children: [
                          Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(14)), child: Icon(widget.icon, color: Colors.red)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('DELETING CATEGORY', style: TextStyle(color: Colors.red.withValues(alpha: 0.55), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                                const SizedBox(height: 3),
                                Text(widget.category.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)), border: Border(top: BorderSide(color: SunsetColors.primary.withValues(alpha: 0.10)))),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isDeleting ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SunsetColors.dark.withValues(alpha: 0.66),
                        side: BorderSide(color: Colors.grey.shade200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w800)),
                    )
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isDeleting ? null : _handleDelete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(_isDeleting ? 'Deleting...' : 'Delete', style: const TextStyle(fontWeight: FontWeight.w800)),
                    )
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _simpleHeader(BuildContext context, String title, {Color? titleColor}) {
  return Container(
    padding: const EdgeInsets.fromLTRB(24, 18, 16, 18),
    decoration: BoxDecoration(color: Colors.grey.shade50.withValues(alpha: 0.55), border: Border(bottom: BorderSide(color: SunsetColors.primary.withValues(alpha: 0.10)))),
    child: Row(
      children: [
        Expanded(child: Text(title, style: TextStyle(color: titleColor ?? SunsetColors.dark, fontSize: 20, fontWeight: FontWeight.w900))),
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close), color: Colors.grey),
      ],
    ),
  );
}

Widget _closeFooter(BuildContext context) {
  return Container(
    width: double.infinity, padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)), border: Border(top: BorderSide(color: SunsetColors.primary.withValues(alpha: 0.10)))),
    child: ElevatedButton(
      onPressed: () => Navigator.pop(context),
      style: ElevatedButton.styleFrom(backgroundColor: SunsetColors.dark, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w800)),
    ),
  );
}

class CategoryItem {
  final int id; final String name; final int typeId; final String icon; final Color color; final String description; final int status;
  CategoryItem({required this.id, required this.name, required this.typeId, required this.icon, required this.color, required this.description, required this.status});

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      name: '${json['name'] ?? ''}',
      typeId: int.tryParse('${json['type_id'] ?? 1}') ?? 1,
      icon: '${json['icon'] ?? 'Tag'}',
      color: _colorFromHex('${json['color'] ?? '#f97316'}'),
      description: '${json['description'] ?? ''}',
      status: int.tryParse('${json['status'] ?? 1}') ?? 1,
    );
  }
}

class CategoryFormData {
  final String name; final int typeId; final String icon; final Color color; final String description; final int status;
  CategoryFormData({this.name = '', this.typeId = 1, this.icon = 'Tag', this.color = const Color(0xFFF97316), this.description = '', this.status = 1});

  factory CategoryFormData.fromCategory(CategoryItem category) {
    return CategoryFormData(name: category.name, typeId: category.typeId, icon: category.icon, color: category.color, description: category.description, status: category.status);
  }

  CategoryFormData copy({String? name, int? typeId, String? icon, Color? color, String? description, int? status}) {
    return CategoryFormData(
      name: name ?? this.name, typeId: typeId ?? this.typeId, icon: icon ?? this.icon,
      color: color ?? this.color, description: description ?? this.description, status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return { 'name': name, 'type_id': '$typeId', 'icon': icon, 'color': _hexFromColor(color), 'description': description, 'status': '$status' };
  }
}

Color _colorFromHex(String value) {
  final cleaned = value.replaceAll('#', '').trim();
  final hex = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
  return Color(int.tryParse(hex, radix: 16) ?? 0xFFF97316);
}

String _hexFromColor(Color color) {
  final value = color.toARGB32() & 0x00FFFFFF;
  return '#${value.toRadixString(16).padLeft(6, '0')}';
}