import 'dart:async';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/toast.dart';
import '../shared/crud_helpers.dart';

// 月份常量
const List<String> _months = [
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December"
];

class BudgetView extends StatefulWidget {
  const BudgetView({super.key});

  @override
  State<BudgetView> createState() => _BudgetViewState();
}

class _BudgetViewState extends State<BudgetView> {
  bool _isLoading = true;
  bool _isAnalyzing = false;
  
  List<BudgetModel> _allBudgets = [];
  List<BudgetModel> _displayedBudgets = [];
  List<CategoryLite> _categories = [];

  int? _selectedMonth; // null 代表 'all'
  int? _selectedYear;  // null 代表 'all'

  // 动态生成前 10 年至后 10 年的年份数组
  List<int> get _filterYears {
    final currentYear = DateTime.now().year;
    return List.generate(21, (index) => (currentYear - 10) + index);
  }

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchBudgets();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await ApiClient().dio.get('/categories', queryParameters: {'status': '1'});
      final dynamic payload = response.data;
      final List<dynamic> rawItems = payload is Map<String, dynamic>
          ? (payload['data'] as List<dynamic>? ?? payload['items'] ?? [])
          : (payload as List<dynamic>? ?? []);

      if (mounted) {
        setState(() {
          _categories = rawItems.map((item) => CategoryLite.fromJson(Map<String, dynamic>.from(item))).toList();
        });
      }
    } catch (e) {
      debugPrint("fetchCategories error: $e");
    }
  }

  Future<void> _fetchBudgets() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient().dio.get('/budget/list');
      final dynamic payload = response.data;
      final List<dynamic> rawItems = payload is Map<String, dynamic>
          ? (payload['data'] as List<dynamic>? ?? payload['budgets'] ?? payload['result'] ?? [])
          : (payload as List<dynamic>? ?? []);

      _allBudgets = rawItems.map((item) => BudgetModel.fromJson(Map<String, dynamic>.from(item))).toList();
      _applyFilters();
    } catch (e) {
      if (mounted) {
        SunsetToast.show(context, 'Failed to load budgets.', type: SunsetToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🌟 核心：过滤并按照“越靠近当前年月排在越上方”的算法进行排序
  void _applyFilters() {
    final now = DateTime.now();
    final currentMonthVal = now.year * 12 + now.month;

    final filtered = _allBudgets.where((b) {
      final matchMonth = _selectedMonth == null || b.month == _selectedMonth;
      final matchYear = _selectedYear == null || b.year == _selectedYear;
      return matchMonth && matchYear;
    }).toList();

    // 智能排序：距当前时间绝对值越小的，优先排在前面
    filtered.sort((a, b) {
      final valA = a.year * 12 + a.month;
      final valB = b.year * 12 + b.month;

      final diffA = (valA - currentMonthVal).abs();
      final diffB = (valB - currentMonthVal).abs();

      if (diffA != diffB) {
        return diffA.compareTo(diffB);
      }
      return valB.compareTo(valA); // 距离相同时，最新的在前
    });

    setState(() {
      _displayedBudgets = filtered;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedMonth = null;
      _selectedYear = null;
    });
    _applyFilters();
    SunsetToast.show(context, 'Filters reset to default', type: SunsetToastType.success);
  }

  Future<void> _handleReanalyze() async {
    setState(() => _isAnalyzing = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() => _isAnalyzing = false);
      SunsetToast.show(context, 'AI analysis refreshed!', type: SunsetToastType.success);
    }
  }

  Future<void> _saveBudget(Map<String, dynamic> payload, {int? budgetId}) async {
    try {
      if (budgetId == null) {
        await ApiClient().dio.post('/budget/create', data: payload);
        if (mounted) SunsetToast.show(context, 'Budget created successfully!');
      } else {
        await ApiClient().dio.post('/budget/update/$budgetId', data: payload);
        if (mounted) SunsetToast.show(context, 'Budget updated successfully!');
      }
      await _fetchBudgets();
    } on DioException {
      rethrow;
    }
  }

  Future<void> _deleteBudget(int id) async {
    try {
      await ApiClient().dio.delete('/budget/delete/$id');
      if (mounted) SunsetToast.show(context, 'Budget deleted successfully');
      await _fetchBudgets();
    } on DioException catch (e) {
      final message = e.response?.data is Map ? (e.response?.data['message'] ?? e.response?.data['error']) : null;
      if (mounted) {
        SunsetToast.show(context, message?.toString() ?? 'Failed to delete budget', type: SunsetToastType.error);
      }
    }
  }

  Map<String, List<BudgetModel>> get _groupedBudgets {
    final Map<String, List<BudgetModel>> groups = {};

    for (var b in _displayedBudgets) {
      final typeName = b.category.typeName;
      if (!groups.containsKey(typeName)) {
        groups[typeName] = [];
      }
      groups[typeName]!.add(b);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SunsetColors.bgStart,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isWide = width >= 900;
            
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(isWide ? 32 : 18, 24, isWide ? 32 : 18, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(width),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    _buildLoading(width)
                  else if (_displayedBudgets.isEmpty)
                    _buildEmptyState()
                  else
                    _buildGroupedBudgetContent(width),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(double width) {
    final isMobile = width < 700;
    return Flex(
      direction: isMobile ? Axis.vertical : Axis.horizontal,
      crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Budgets', style: TextStyle(color: SunsetColors.dark, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            SizedBox(height: 4),
            Text('Set limits & track your spending with AI insights', style: TextStyle(color: Color(0x992D2520), fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
        SizedBox(height: isMobile ? 16 : 0, width: isMobile ? 0 : 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SunsetColors.primary.withValues(alpha: 0.80), width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFilterDropdown(
                    value: _selectedMonth,
                    hint: 'All Months',
                    items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(_months[i]))),
                    onChanged: (val) => setState(() { _selectedMonth = val; _applyFilters(); }),
                  ),
                  Container(width: 1, height: 16, color: SunsetColors.primary.withValues(alpha: 0.2), margin: const EdgeInsets.symmetric(horizontal: 6)),
                  _buildFilterDropdown(
                    value: _selectedYear,
                    hint: 'All Years',
                    items: _filterYears.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                    onChanged: (val) => setState(() { _selectedYear = val; _applyFilters(); }),
                  ),
                ],
              ),
            ),
            
            InkWell(
              onTap: _clearFilters,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SunsetColors.primary.withValues(alpha: 0.80), width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)],
                ),
                child: const Center(
                  child: Icon(Icons.filter_alt_off_outlined, size: 18, color: SunsetColors.dark),
                ),
              ),
            ),

            InkWell(
              onTap: _isAnalyzing ? null : _handleReanalyze,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SunsetColors.primary.withValues(alpha: 0.80), width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)],
                ),
                child: Center(
                  child: _isAnalyzing
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: SunsetColors.primary))
                      : const Icon(Icons.sync, size: 18, color: SunsetColors.dark),
                ),
              ),
            ),

            ElevatedButton.icon(
              onPressed: () => _openFormDialog(null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Budget'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SunsetColors.secondary,
                foregroundColor: Colors.white,
                elevation: 4,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterDropdown({required int? value, required String hint, required List<DropdownMenuItem<int>> items, required Function(int?) onChanged}) {
    return DropdownButton<int>(
      value: value,
      dropdownColor: Colors.white,
      hint: Text(hint, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: SunsetColors.dark)),
      items: [
        DropdownMenuItem<int>(value: null, child: Text(hint)),
        ...items,
      ],
      onChanged: onChanged,
      underline: const SizedBox(),
      icon: const SizedBox.shrink(),
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: SunsetColors.dark),
      alignment: Alignment.center,
    );
  }

  Widget _buildLoading(double width) {
    int cols = width >= 1100 ? 2 : 1;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols, 
        mainAxisSpacing: 20, 
        crossAxisSpacing: 20, 
        mainAxisExtent: 290
      ),
      itemCount: 2,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SunsetColors.primary.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.error_outline, size: 28, color: SunsetColors.primary),
          ),
          const SizedBox(height: 16),
          const Text('No budgets found', style: TextStyle(color: SunsetColors.dark, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Try changing your filters or create a new one.', style: TextStyle(color: Color(0x992D2520), fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openFormDialog(null),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create First Budget'),
            style: ElevatedButton.styleFrom(
              backgroundColor: SunsetColors.secondary, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedBudgetContent(double width) {
    int cols = width >= 1100 ? 2 : 1;
    final grouped = _groupedBudgets;

    return Column(
      children: grouped.entries.map((entry) {
        final typeName = entry.key;
        final items = entry.value;
        final isIncome = typeName.toLowerCase().contains('income');
        final headerColor = isIncome ? const Color(0xFF059669) : SunsetColors.expense;
        final badgeBg = isIncome ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);

        return Padding(
          padding: const EdgeInsets.only(bottom: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                child: Row(
                  children: [
                    Text(typeName, style: TextStyle(color: headerColor, fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(99)),
                      child: Text('(${items.length})', style: TextStyle(color: headerColor, fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols, 
                  mainAxisSpacing: 20, 
                  crossAxisSpacing: 20, 
                  mainAxisExtent: 290, 
                ),
                itemBuilder: (context, index) => _buildBudgetCard(items[index]),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBudgetCard(BudgetModel budget) {
    final insight = _getAiInsight(budget);
    final daysLeftText = _getDaysLeftText(budget.year, budget.month);
    
    double safePercent = budget.percentage;
    if (safePercent.isNaN || safePercent.isInfinite) safePercent = 0.0;
    final widthFactor = (safePercent / 100).clamp(0.0, 1.0);

    final isOver = budget.spent > budget.amount;
    final overAmount = math.max(0.0, budget.spent - budget.amount);
    final typeName = budget.category.typeName;
    final isIncome = typeName.toLowerCase().contains('income');

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: insight.borderColor, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: budget.category.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                child: Icon(_iconForName(budget.category.icon), color: budget.category.color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            budget.category.name, 
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis, 
                            style: const TextStyle(color: SunsetColors.dark, fontSize: 17, fontWeight: FontWeight.w900)
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isIncome ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: isIncome ? const Color(0xFFA7F3D0) : const Color(0xFFFFEDD5)),
                          ),
                          child: Text(
                            typeName.toUpperCase(),
                            style: TextStyle(
                              color: isIncome ? const Color(0xFF059669) : SunsetColors.secondary,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedMonth == null || _selectedYear == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('${_months[budget.month - 1]} ${budget.year}'.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  _actionButton(Icons.edit_outlined, Colors.blue, () => _openFormDialog(budget)),
                  const SizedBox(width: 6),
                  _actionButton(Icons.delete_outline, Colors.red, () => _openDeleteDialog(budget)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Text('RM ${budget.spent.toStringAsFixed(2)}', style: const TextStyle(color: SunsetColors.dark, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text('of RM ${budget.amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          Container(
            height: 10, width: double.infinity,
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: widthFactor,
              child: Container(decoration: BoxDecoration(color: insight.barColor, borderRadius: BorderRadius.circular(10))),
            ),
          ),
          const SizedBox(height: 10),
          
          // 🌟 进度条下方提醒：超支金额展现常亮鲜红字
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${safePercent.toStringAsFixed(0)}% Used · $daysLeftText', style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w700)),
              if (isOver)
                Text(
                  'RM ${overAmount.toStringAsFixed(2)} over limit',
                  style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w900),
                )
              else
                Text(
                  'RM ${(budget.remaining > 0 ? budget.remaining : 0).toStringAsFixed(2)} left',
                  style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w700),
                ),
            ],
          ),
          
          const SizedBox(height: 14),
          
          // 🌟 AI 洞察提示：带有单独着色的富文本 RichText 数字
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.only(top: 2), child: Icon(insight.icon, size: 18, color: insight.textColor)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(insight.status, style: TextStyle(color: insight.textColor, fontSize: 13, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600, height: 1.3),
                        children: insight.spans,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, Color hoverColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
        child: Icon(icon, size: 16, color: Colors.grey.shade500),
      ),
    );
  }

  void _openFormDialog(BudgetModel? budget) {
    showDialog<void>(
      context: context,
      barrierColor: SunsetColors.dark.withValues(alpha: 0.42),
      builder: (context) => BudgetFormDialog(categories: _categories, editing: budget, onSave: (payload) => _saveBudget(payload, budgetId: budget?.id)),
    );
  }

  void _openDeleteDialog(BudgetModel budget) {
    showDialog<void>(
      context: context,
      barrierColor: SunsetColors.dark.withValues(alpha: 0.42),
      builder: (context) => BudgetDeleteDialog(budget: budget, icon: _iconForName(budget.category.icon), onDelete: () => _deleteBudget(budget.id)),
    );
  }

  String _getDaysLeftText(int year, int month) {
    final now = DateTime.now();
    if (year < now.year || (year == now.year && month < now.month)) return "Month ended";
    if (year > now.year || (year == now.year && month > now.month)) return "Upcoming";
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final daysLeft = daysInMonth - now.day;
    return daysLeft == 0 ? "Last day" : "$daysLeft days left";
  }

  // 🌟 核心升级：带有不同颜色 Highlight TextSpan 的 AI 洞察分析器
  AiInsight _getAiInsight(BudgetModel b) {
    final remainingRatio = 100 - b.percentage;
    final daysLeftText = _getDaysLeftText(b.year, b.month);
    final catName = b.category.name;
    final overAmount = math.max(0.0, b.spent - b.amount);

    if (b.percentage >= 100) {
      return AiInsight(
        status: "Over Budget", 
        icon: Icons.error_outline, 
        textColor: Colors.red.shade600, 
        barColor: Colors.red.shade500, 
        borderColor: Colors.red.shade200, 
        spans: [
          const TextSpan(text: "You've exceeded your "),
          TextSpan(text: catName, style: const TextStyle(fontWeight: FontWeight.bold, color: SunsetColors.dark)),
          const TextSpan(text: " budget limit by "),
          TextSpan(
            text: "RM ${overAmount.toStringAsFixed(2)}",
            style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.w900),
          ),
          const TextSpan(text: "! Please stop spending."),
        ],
      );
    }
    if (remainingRatio <= 20) {
      return AiInsight(
        status: "Warning", 
        icon: Icons.warning_amber_rounded, 
        textColor: Colors.red.shade500, 
        barColor: Colors.red.shade500, 
        borderColor: Colors.red.shade200, 
        spans: [
          const TextSpan(text: "Only "),
          TextSpan(text: "${remainingRatio.toStringAsFixed(1)}%", style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.w900)),
          const TextSpan(text: " remaining! You've spent "),
          TextSpan(text: "RM ${b.spent.toStringAsFixed(2)}", style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.w900)),
          TextSpan(text: " with $daysLeftText."),
        ],
      );
    }
    if (remainingRatio <= 50) {
      return AiInsight(
        status: "Watch It", 
        icon: Icons.warning_amber_rounded, 
        textColor: Colors.amber.shade700, 
        barColor: Colors.amber.shade400, 
        borderColor: Colors.amber.shade200, 
        spans: [
          const TextSpan(text: "Halfway through your "),
          TextSpan(text: catName, style: const TextStyle(fontWeight: FontWeight.bold, color: SunsetColors.dark)),
          const TextSpan(text: " limit. You've spent "),
          TextSpan(
            text: "RM ${b.spent.toStringAsFixed(2)}",
            style: TextStyle(color: Colors.amber.shade700, fontWeight: FontWeight.w900),
          ),
          TextSpan(text: " with $daysLeftText."),
        ],
      );
    }
    return AiInsight(
      status: "On Track", 
      icon: Icons.check_circle_outline, 
      textColor: Colors.teal.shade600, 
      barColor: Colors.teal.shade400, 
      borderColor: Colors.grey.shade200, 
      spans: [
        const TextSpan(text: "Looking good! You have "),
        TextSpan(
          text: "RM ${b.remaining.toStringAsFixed(2)}",
          style: TextStyle(color: Colors.teal.shade600, fontWeight: FontWeight.w900),
        ),
        const TextSpan(text: " left."),
      ],
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
      case 'Tag': default: return Icons.sell_outlined;
    }
  }
}

// ---------------- Dialogs ----------------

class BudgetFormDialog extends StatefulWidget {
  final List<CategoryLite> categories;
  final BudgetModel? editing;
  final Future<void> Function(Map<String, dynamic> payload) onSave;

  const BudgetFormDialog({super.key, required this.categories, this.editing, required this.onSave});

  @override
  State<BudgetFormDialog> createState() => _BudgetFormDialogState();
}

class _BudgetFormDialogState extends State<BudgetFormDialog> {
  late TextEditingController _amountController;
  int? _selectedCategoryId;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isSaving = false;
  Map<String, List<String>> _errors = {};

  List<int> get _filterYears {
    final currentYear = DateTime.now().year;
    return List.generate(21, (index) => (currentYear - 10) + index);
  }

  @override
  void initState() {
    super.initState();
    if (widget.editing != null) {
      _amountController = TextEditingController(text: widget.editing!.amount.toStringAsFixed(2));
      _selectedCategoryId = widget.editing!.category.id;
      _selectedMonth = widget.editing!.month;
      _selectedYear = widget.editing!.year;
    } else {
      _amountController = TextEditingController();
      if (widget.categories.isNotEmpty) {
        _selectedCategoryId = widget.categories.first.id;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (widget.categories.isEmpty) return;

    setState(() { _errors = {}; _isSaving = true; });
    try {
      final payload = { 
        'category_id': _selectedCategoryId, 
        'amount': double.tryParse(_amountController.text.trim()) ?? 0, 
        'month': _selectedMonth, 
        'year': _selectedYear 
      };
      await widget.onSave(payload);
      if (mounted) Navigator.pop(context);
    } on DioException catch (e) {
      if (e.response?.statusCode == 422 && e.response?.data['errors'] != null) {
        if (mounted) setState(() { _errors = (e.response?.data['errors'] as Map<String, dynamic>).map((key, value) => MapEntry(key, List<String>.from(value))); });
      } else {
        final message = e.response?.data is Map ? (e.response?.data['message'] ?? e.response?.data['error']) : null;
        if (mounted) SunsetToast.show(context, message?.toString() ?? 'Operation failed.', type: SunsetToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // 🌟 按 Type 进行分组渲染 Dropdown 列表，保证带有干净的标题与纯白背景
  List<DropdownMenuItem<int>> _buildGroupedCategoryMenuItems(List<CategoryLite> categories) {
    final Map<String, List<CategoryLite>> groups = {};
    for (var c in categories) {
      final typeName = c.typeName;
      groups.putIfAbsent(typeName, () => []).add(c);
    }

    final List<DropdownMenuItem<int>> items = [];

    groups.forEach((typeName, catList) {
      // 1. 分组 Section 标题
      items.add(
        DropdownMenuItem<int>(
          value: -1 * typeName.hashCode,
          enabled: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              typeName.toUpperCase(),
              style: const TextStyle(
                color: SunsetColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      );

      // 2. 该分组下的各个分类
      for (var c in catList) {
        final isIncome = c.typeName.toLowerCase().contains('income');
        items.add(
          DropdownMenuItem<int>(
            value: c.id,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: SunsetColors.dark)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isIncome ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isIncome ? const Color(0xFFA7F3D0) : const Color(0xFFFFEDD5)),
                    ),
                    child: Text(
                      c.typeName.toUpperCase(),
                      style: TextStyle(
                        color: isIncome ? const Color(0xFF059669) : SunsetColors.secondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    });

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final bool hasNoCategories = widget.categories.isEmpty;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogHeader(widget.editing == null ? 'Create Budget' : 'Edit Budget'),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Category'),

                    if (hasNoCategories)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFDE68A))),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                            SizedBox(width: 8),
                            Expanded(child: Text("No active Category found. Please add a category first.", style: TextStyle(color: Color(0xFF92400E), fontSize: 12, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      )
                    else
                      DropdownButtonFormField<int>(
                        value: _selectedCategoryId,
                        dropdownColor: Colors.white, // 🌟 修复：背景设为纯白
                        decoration: _fieldDecoration('Select Category'),
                        items: _buildGroupedCategoryMenuItems(widget.categories),
                        onChanged: (val) {
                          if (val != null && val > 0) {
                            setState(() => _selectedCategoryId = val);
                          }
                        },
                      ),
                    _errorText('category_id'),
                    
                    const SizedBox(height: 18),
                    _label('Limit Amount (RM)'),
                    TextField(
                      controller: _amountController, 
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                      decoration: _fieldDecoration('e.g. 500.00')
                    ),
                    _errorText('amount'),

                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('Month'), DropdownButtonFormField<int>(value: _selectedMonth, dropdownColor: Colors.white, decoration: _fieldDecoration(''), items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(_months[i]))), onChanged: (val) => setState(() => _selectedMonth = val!)), _errorText('month')])),
                        const SizedBox(width: 16),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('Year'), DropdownButtonFormField<int>(value: _selectedYear, dropdownColor: Colors.white, decoration: _fieldDecoration(''), items: _filterYears.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(), onChanged: (val) => setState(() => _selectedYear = val!)), _errorText('year')])),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.grey.shade50, border: Border(top: BorderSide(color: SunsetColors.primary.withValues(alpha: 0.10))), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(foregroundColor: SunsetColors.dark.withValues(alpha: 0.66), side: BorderSide(color: Colors.grey.shade200), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: (_isSaving || hasNoCategories) ? null : _handleSave,
                    style: ElevatedButton.styleFrom(backgroundColor: SunsetColors.secondary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [if (_isSaving) ...[const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)), const SizedBox(width: 8)], Text(_isSaving ? 'Saving...' : 'Save Budget', style: const TextStyle(fontWeight: FontWeight.w800))]),
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
      child: Row(children: [Expanded(child: Text(title, style: const TextStyle(color: SunsetColors.dark, fontSize: 20, fontWeight: FontWeight.w800))), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close), color: Colors.grey)]),
    );
  }

  Widget _label(String text) => Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(text.toUpperCase(), style: const TextStyle(color: Color(0xB32D2520), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8)));

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint, filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: SunsetColors.primary.withValues(alpha: 0.80))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: SunsetColors.primary, width: 1.5)),
    );
  }

  Widget _errorText(String key) {
    if (_errors[key] == null || _errors[key]!.isEmpty) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(top: 6, left: 4), child: Text(_errors[key]!.first, style: const TextStyle(color: Colors.red, fontSize: 12)));
  }
}

class BudgetDeleteDialog extends StatefulWidget {
  final BudgetModel budget; final IconData icon; final Future<void> Function() onDelete;
  const BudgetDeleteDialog({super.key, required this.budget, required this.icon, required this.onDelete});
  @override
  State<BudgetDeleteDialog> createState() => _BudgetDeleteDialogState();
}

class _BudgetDeleteDialogState extends State<BudgetDeleteDialog> {
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 18, 16, 18),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: SunsetColors.primary.withValues(alpha: 0.10)))),
              child: Row(children: [const Expanded(child: Text('Delete Budget', style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.w900))), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close), color: Colors.grey)]),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Are you sure you want to delete this budget? This action cannot be undone.', style: TextStyle(color: SunsetColors.dark, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFEE2E2))),
                    child: Row(
                      children: [
                        Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)), child: Icon(widget.icon, color: Colors.red)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('DELETING BUDGET LIMIT', style: TextStyle(color: Colors.red.withValues(alpha: 0.55), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)), const SizedBox(height: 3), Text('${widget.budget.category.name} - RM ${widget.budget.amount.toStringAsFixed(2)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.w900))])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.grey.shade50, border: Border(top: BorderSide(color: SunsetColors.primary.withValues(alpha: 0.10))), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isDeleting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(foregroundColor: SunsetColors.dark.withValues(alpha: 0.66), side: BorderSide(color: Colors.grey.shade200), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isDeleting ? null : _handleDelete,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: Text(_isDeleting ? 'Deleting...' : 'Delete', style: const TextStyle(fontWeight: FontWeight.w800)),
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

// ---------------- Models & Helpers ----------------

class AiInsight { 
  final String status; 
  final IconData icon; 
  final Color textColor; 
  final Color barColor; 
  final Color borderColor; 
  final List<InlineSpan> spans; 

  AiInsight({required this.status, required this.icon, required this.textColor, required this.barColor, required this.borderColor, required this.spans}); 
}

class CategoryLite { 
  final int id; 
  final String name; 
  final String icon; 
  final Color color; 
  final int typeId; 
  final String typeName;

  CategoryLite({required this.id, required this.name, required this.icon, required this.color, required this.typeId, required this.typeName}); 

  factory CategoryLite.fromJson(Map<String, dynamic> json) { 
    final typeMap = json['type'] is Map ? json['type'] : {};
    final tName = '${typeMap['name'] ?? ''}';
    final tId = int.tryParse('${json['type_id'] ?? typeMap['id'] ?? 1}') ?? 1;

    return CategoryLite(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0, 
      name: '${json['name'] ?? ''}', 
      icon: '${json['icon'] ?? 'Tag'}', 
      color: _colorFromHex('${json['color'] ?? '#f97316'}'),
      typeId: tId,
      typeName: tName.isNotEmpty ? tName : (tId == 2 ? 'Income' : 'Expense'),
    ); 
  } 
}

class BudgetModel { 
  final int id; 
  final CategoryLite category; 
  final double amount; 
  final int month; 
  final int year; 
  final double spent; 
  final double remaining; 
  final double percentage; 

  BudgetModel({required this.id, required this.category, required this.amount, required this.month, required this.year, required this.spent, required this.remaining, required this.percentage}); 

  factory BudgetModel.fromJson(Map<String, dynamic> json) { 
    return BudgetModel(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0, 
      category: CategoryLite.fromJson(Map<String, dynamic>.from(json['category'] ?? {})), 
      amount: double.tryParse('${json['amount'] ?? 0}') ?? 0.0, 
      month: int.tryParse('${json['month'] ?? 1}') ?? 1, 
      year: int.tryParse('${json['year'] ?? DateTime.now().year}') ?? DateTime.now().year, 
      spent: double.tryParse('${json['spent'] ?? 0}') ?? 0.0, 
      remaining: double.tryParse('${json['remaining'] ?? 0}') ?? 0.0, 
      percentage: double.tryParse('${json['percentage'] ?? 0}') ?? 0.0
    ); 
  } 
}

Color _colorFromHex(String value) { final cleaned = value.replaceAll('#', '').trim(); final hex = cleaned.length == 6 ? 'FF$cleaned' : cleaned; return Color(int.tryParse(hex, radix: 16) ?? 0xFFF97316); }