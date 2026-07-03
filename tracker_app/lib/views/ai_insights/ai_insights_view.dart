import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/toast.dart';

class AiInsightsView extends StatefulWidget {
  const AiInsightsView({super.key});

  @override
  State<AiInsightsView> createState() => _AiInsightsViewState();
}

class _AiInsightsViewState extends State<AiInsightsView> with SingleTickerProviderStateMixin {
  late DateTime _startDate;
  late DateTime _endDate;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  bool _isLoadingData = true;
  bool _isSendingMsg = false;

  MetricStats _metrics = MetricStats();
  List<ChartItem> _chartData = [];
  List<PieItem> _categoryData = [];
  List<TransactionItem> _recentExpenses = [];
  List<TransactionItem> _recentIncomes = [];
  List<BudgetItem> _budgets = [];

  List<ChatMessage> _messages = [
    ChatMessage(
      role: 'model',
      text: 'Hello! I am your **Sunset AI Insights Coach**. Ask me anything about your filtered transaction metrics, and I will analyze them dynamically!',
    )
  ];
  
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _endDate = now;
    _startDate = DateTime(now.year, now.month, 1);
    
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _loadInsightsData();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _chatScrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _normalizeMarkdown(String text) {
    return text.replaceAllMapped(RegExp(r'([^\n])\n([^\n])'), (match) => '${match[1]}\n\n${match[2]}');
  }

  Future<void> _loadInsightsData() async {
    setState(() => _isLoadingData = true);
    try {
      final startStr = _dateFormat.format(_startDate);
      final endStr = _dateFormat.format(_endDate);
      
      final response = await ApiClient().dio.get('/ai-insights?start_date=$startStr&end_date=$endStr');
      final data = response.data;

      setState(() {
        _metrics = MetricStats.fromJson(data['metrics'] ?? {});
        _chartData = (data['chartData'] as List?)?.map((e) => ChartItem.fromJson(e)).toList() ?? [];
        _categoryData = (data['categoryData'] as List?)?.map((e) => PieItem.fromJson(e)).toList() ?? [];
        _recentExpenses = (data['recentExpenses'] as List?)?.map((e) => TransactionItem.fromJson(e)).toList() ?? [];
        _recentIncomes = (data['recentIncomes'] as List?)?.map((e) => TransactionItem.fromJson(e)).toList() ?? [];
        _budgets = (data['budgets'] as List?)?.map((e) => BudgetItem.fromJson(e)).toList() ?? [];
      });
    } catch (e) {
      debugPrint("Failed to load insights analytics: $e");
      if (mounted) SunsetToast.show(context, 'Unable to load financial insights.', type: SunsetToastType.error);
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  String _getMonthName(int monthNum) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    if (monthNum < 1 || monthNum > 12) return "Month";
    return months[monthNum - 1];
  }

  String _buildFinancialContext() {
    final expensesSummary = _recentExpenses.isNotEmpty
        ? _recentExpenses.map((e) => '- ${e.title} (${e.category}, ${e.date}): -RM ${e.price.toStringAsFixed(2)}').join('\n')
        : '- No recent expenses.';

    final incomesSummary = _recentIncomes.isNotEmpty
        ? _recentIncomes.map((i) => '- ${i.title} (${i.category}, ${i.date}): +RM ${i.price.toStringAsFixed(2)}').join('\n')
        : '- No recent incomes.';

    final budgetsSummary = _budgets.isNotEmpty
        ? _budgets.map((b) {
            final remaining = b.budgetAmount - b.spentAmount;
            final status = b.spentAmount > b.budgetAmount
                ? 'OVERSPENT by RM ${remaining.abs().toStringAsFixed(2)}'
                : 'RM ${remaining.toStringAsFixed(2)} remaining';
            return '- ${b.category} (${_getMonthName(b.month)} ${b.year}): Budget RM ${b.budgetAmount.toStringAsFixed(2)}, Spent RM ${b.spentAmount.toStringAsFixed(2)}, ${b.percentage}% used — $status';
          }).join('\n')
        : '- No active budgets.';

    final categorySummary = _categoryData.isNotEmpty
        ? _categoryData.map((c) => '- ${c.name}: RM ${c.value.toStringAsFixed(2)}').join('\n')
        : '- No category data.';

    return '''
You are Sunset AI Insights Coach, a personal finance advisor. You MUST base your analysis and advice primarily on the user's ACTUAL financial data provided below. Always reference specific numbers, categories, and budget statuses from their data before giving general advice. Format your response with clear sections using markdown headings (##) and bullet points for readability.

=== USER'S FINANCIAL DATA (${_dateFormat.format(_startDate)} to ${_dateFormat.format(_endDate)}) ===

**Summary Metrics:**
- Total Income: RM ${_metrics.totalIncome.toStringAsFixed(2)}
- Total Expenses: RM ${_metrics.totalExpense.toStringAsFixed(2)}
- Net Balance: RM ${_metrics.netBalance.toStringAsFixed(2)}
- Savings Rate: ${_metrics.savingsRate}%

**Recent Expenses:**
$expensesSummary

**Recent Incomes:**
$incomesSummary

**Budget Status:**
$budgetsSummary

**Spending by Category:**
$categorySummary

=== END OF USER DATA ===

Instructions:
1. ALWAYS start by referencing the user's actual data above.
2. Use specific RM amounts and category names from their data.
3. Only after addressing their real data, offer general financial tips.
4. Use ## headings and bullet points to make the response easy to read.
5. Keep the tone friendly, concise, and actionable.
'''.trim();
  }

  Future<void> _handleSendMessage() async {
    final userText = _chatController.text.trim();
    if (userText.isEmpty || _isSendingMsg) return;

    setState(() {
      _messages.add(ChatMessage(role: 'user', text: userText));
      _chatController.clear();
      _isSendingMsg = true;
    });
    
    _scrollToBottom();

    try {
      final response = await ApiClient().dio.post('/ai-insights/chat', data: {
        'messages': _messages.map((m) => m.toJson()).toList(),
        'start_date': _dateFormat.format(_startDate),
        'end_date': _dateFormat.format(_endDate),
        'financial_context': _buildFinancialContext(),
      });

      final aiResponseText = response.data['reply'] ?? "No response generated.";
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(role: 'model', text: aiResponseText));
        });
        _scrollToBottom();
      }
    } on DioException catch (e) {
      debugPrint("Direct Backend AI Connect Error: $e");
      final backendError = e.response?.data is Map ? e.response?.data['message'] : e.message;
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            role: 'model', 
            text: '⚠️ **无法连接到 AI 服务器。**\n\n*错误详情: $backendError*\n\n请检查后端 `.env` 中的 `GROQ_API_KEY` 配置是否正确。'
          ));
        });
        _scrollToBottom();
      }
    } finally {
      if (mounted) setState(() => _isSendingMsg = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent + 100, 
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: SunsetColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startDate = picked;
        else _endDate = picked;
      });
      _loadInsightsData();
    }
  }

  String _formatCurrency(double val) {
    final isNegative = val < 0;
    final formatted = NumberFormat("#,##0.00", "en_US").format(val.abs());
    return isNegative ? "-RM $formatted" : "RM $formatted";
  }

  @override
  Widget build(BuildContext context) {
    final double overallSpendingLimit = _budgets.fold(0, (sum, item) => sum + item.budgetAmount);
    final double overallSpendingSpent = _budgets.fold(0, (sum, item) => sum + item.spentAmount);
    final double overallSpendingPercentage = overallSpendingLimit > 0 ? ((overallSpendingSpent / overallSpendingLimit) * 100).clamp(0, 100) : 0;

    return Scaffold(
      backgroundColor: SunsetColors.bgStart,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1024;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(isWide ? 32 : 18, 24, isWide ? 32 : 18, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isWide),
                  const SizedBox(height: 24),
                  if (_isLoadingData)
                    _buildLoading()
                  else ...[
                    _buildMetricsGrid(isWide),
                    const SizedBox(height: 24),
                    _buildChartsSection(isWide, overallSpendingLimit),
                    const SizedBox(height: 24),
                    _buildTransactionsAndBudget(isWide, overallSpendingLimit, overallSpendingSpent, overallSpendingPercentage),
                    const SizedBox(height: 32),
                    _buildAiChatSection(),
                  ]
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
            Text('AI Insights', style: TextStyle(color: SunsetColors.dark, fontSize: 26, fontWeight: FontWeight.w900)),
            SizedBox(height: 4),
            Text('Deep dive into your financial health with Sunset AI.', style: TextStyle(color: Color(0x992D2520), fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
        SizedBox(height: isWide ? 0 : 16, width: isWide ? 12 : 0),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: SunsetColors.primary.withValues(alpha: 0.1)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)]),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dateButton(_startDate, true),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('-', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
              _dateButton(_endDate, false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dateButton(DateTime date, bool isStart) {
    return InkWell(
      onTap: () => _pickDate(isStart),
      child: Text(_dateFormat.format(date), style: const TextStyle(color: SunsetColors.dark, fontSize: 12, fontWeight: FontWeight.w800)),
    );
  }

  Widget _buildLoading() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: SunsetColors.primary),
            SizedBox(height: 16),
            Text('Analyzing financial databases...', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ✅ 完美修复：放弃根据比例计算高度，全平台强制锁定卡片高度为 72px，彻底干掉多余 Padding
  Widget _buildMetricsGrid(bool isWide) {
    final double width = MediaQuery.of(context).size.width;
    final int columns = isWide ? 4 : (width > 600 ? 2 : 1);

    return GridView(
      shrinkWrap: true, 
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 76, // 🌟 核心修改：绝对固定高度 76px！绝不会再被拉高！
      ),
      children: [
        _metricCard('Balance', _formatCurrency(_metrics.netBalance), Icons.account_balance_wallet, const Color(0xFF7C3AED)),
        _metricCard('Income', _formatCurrency(_metrics.totalIncome), Icons.trending_up, const Color(0xFF0D9488)),
        _metricCard('Expenses', _formatCurrency(_metrics.totalExpense), Icons.trending_down, const Color(0xFFEF4444)),
        _metricCard('Savings Rate', '${_metrics.savingsRate}%', Icons.savings_outlined, const Color(0xFF2563EB)),
      ],
    );
  }

  // ✅ 紧凑型横向 Row 布局：Icon 在左，Data 在右，纯靠 Row 完美对齐
  Widget _metricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16), // 去除上下 Padding，靠 Row 的 center 自动绝对居中
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)), 
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6)]
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // 🌟 保证 Icon 和 文字绝对在同一水平线居中
        children: [
          Container(
            width: 44, height: 44, 
            decoration: BoxDecoration(
              color: color, 
              borderRadius: BorderRadius.circular(12), 
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))]
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // 极致包裹内容
              children: [
                Text(title.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 2), // 极小的上下间距
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: SunsetColors.dark, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChartsSection(bool isWide, double overallSpendingLimit) {
    return Flex(
      direction: isWide ? Axis.horizontal : Axis.vertical,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: isWide ? 2 : 0, child: _buildCashflowChart()),
        if (isWide) const SizedBox(width: 24),
        if (!isWide) const SizedBox(height: 24),
        Expanded(flex: isWide ? 1 : 0, child: _buildCategoryChart(overallSpendingLimit)),
      ],
    );
  }

  Widget _buildCashflowChart() {
    return Container(
      height: 340, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: SunsetColors.primary.withValues(alpha: 0.1)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cashflow Overview', style: TextStyle(color: SunsetColors.dark, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          Expanded(
            child: _chartData.isEmpty 
              ? const Center(child: Text('No transactions recorded for this period.', style: TextStyle(color: Colors.grey, fontSize: 12)))
              : LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true, reservedSize: 30, interval: 1,
                          getTitlesWidget: (val, meta) {
                            if (val.toInt() >= 0 && val.toInt() < _chartData.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(_chartData[val.toInt()].name, style: TextStyle(color: SunsetColors.dark.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.bold)),
                              );
                            }
                            return const SizedBox();
                          }
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true, reservedSize: 40,
                          getTitlesWidget: (val, meta) => Text(NumberFormat.compact().format(val), style: TextStyle(color: SunsetColors.dark.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      _buildLineChartBarData(isIncome: true),
                      _buildLineChartBarData(isIncome: false),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _buildLineChartBarData({required bool isIncome}) {
    final color = isIncome ? const Color(0xFF0D9488) : const Color(0xFFEF4444);
    return LineChartBarData(
      spots: _chartData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), isIncome ? e.value.income : e.value.expense)).toList(),
      isCurved: true, color: color, barWidth: 3, isStrokeCapRound: true, dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
    );
  }

  Widget _buildCategoryChart(double overallLimit) {
    return Container(
      height: 340, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: SunsetColors.primary.withValues(alpha: 0.1)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Category Spending', style: TextStyle(color: SunsetColors.dark, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Expanded(
            child: _categoryData.isEmpty
                ? const Center(child: Text('No categories expenditure records.', style: TextStyle(color: Colors.grey, fontSize: 12)))
                : Column(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2, centerSpaceRadius: 40,
                            sections: _categoryData.map((e) => PieChartSectionData(
                              color: e.color, value: e.value, title: '', radius: 25,
                            )).toList(),
                          )
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._categoryData.take(3).map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: c.color, shape: BoxShape.circle)), const SizedBox(width: 6), Text(c.name, style: const TextStyle(color: Color(0xB32D2520), fontSize: 12, fontWeight: FontWeight.bold))]),
                                Text('RM ${c.value.toStringAsFixed(2)}', style: const TextStyle(color: SunsetColors.dark, fontSize: 12, fontWeight: FontWeight.w900)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 6, width: double.infinity, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(99)),
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: overallLimit > 0 ? (c.value / overallLimit).clamp(0.0, 1.0) : 0,
                                child: Container(decoration: BoxDecoration(color: c.color, borderRadius: BorderRadius.circular(99))),
                              ),
                            )
                          ],
                        ),
                      )),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsAndBudget(bool isWide, double overallLimit, double overallSpent, double overallPercentage) {
    return Flex(
      direction: isWide ? Axis.horizontal : Axis.vertical,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: isWide ? 1 : 0, child: _buildTransactionList('Recent Expenses', _recentExpenses, false)),
        if (isWide) const SizedBox(width: 24),
        if (!isWide) const SizedBox(height: 24),
        Expanded(flex: isWide ? 1 : 0, child: _buildTransactionList('Recent Incomes', _recentIncomes, true)),
        if (isWide) const SizedBox(width: 24),
        if (!isWide) const SizedBox(height: 24),
        Expanded(flex: isWide ? 1 : 0, child: _buildBudgetStatus(overallLimit, overallSpent, overallPercentage)),
      ],
    );
  }

  Widget _buildTransactionList(String title, List<TransactionItem> items, bool isIncome) {
    final color = isIncome ? const Color(0xFF0D9488) : const Color(0xFFEF4444);
    final icon = isIncome ? Icons.trending_up : Icons.trending_down;
    final prefix = isIncome ? '+' : '-';

    return Container(
      height: 400, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: SunsetColors.primary.withValues(alpha: 0.1)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: SunsetColors.dark, fontSize: 16, fontWeight: FontWeight.w800)),
              Text('View all', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: items.isEmpty
              ? const Center(child: Text('No recent records found.', style: TextStyle(color: Colors.grey, fontSize: 12)))
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(color: Color(0xFFF3F4F6), height: 24),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Row(
                      children: [
                        Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 18)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: SunsetColors.dark, fontSize: 14, fontWeight: FontWeight.bold)),
                              Text('${item.category} • ${item.date}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                        ),
                        Text('$prefix RM ${item.price.toStringAsFixed(2)}', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetStatus(double overallLimit, double overallSpent, double overallPercentage) {
    return Container(
      height: 400, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: SunsetColors.primary.withValues(alpha: 0.1)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Budget Status', style: TextStyle(color: SunsetColors.dark, fontSize: 16, fontWeight: FontWeight.w800)),
              Text('View all', style: TextStyle(color: SunsetColors.primary, fontSize: 12, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: SunsetColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: SunsetColors.primary.withValues(alpha: 0.1))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TOTAL SPENT', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text(_formatCurrency(overallSpent), style: const TextStyle(color: SunsetColors.dark, fontSize: 20, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: SunsetColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text('of ${_formatCurrency(overallLimit)}', style: const TextStyle(color: SunsetColors.primary, fontSize: 10, fontWeight: FontWeight.bold))),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 8, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(99)),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(widthFactor: (overallPercentage / 100).clamp(0.0, 1.0), child: Container(decoration: BoxDecoration(color: SunsetColors.primary, borderRadius: BorderRadius.circular(99)))),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _budgets.isEmpty
              ? const Center(child: Text('No active budgets for this month.', style: TextStyle(color: Colors.grey, fontSize: 12)))
              : ListView.separated(
                  itemCount: _budgets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final b = _budgets[index];
                    final isOverspent = b.spentAmount > b.budgetAmount;
                    final remaining = (b.budgetAmount - b.spentAmount).abs();
                    final barColor = b.percentage >= 80 ? const Color(0xFFEF4444) : const Color(0xFF0D9488);

                    return Container(
                      padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: b.categoryColor, shape: BoxShape.circle)), const SizedBox(width: 8), Text(b.category, style: const TextStyle(color: SunsetColors.dark, fontSize: 13, fontWeight: FontWeight.bold))]),
                              Text('${b.percentage.toStringAsFixed(0)}% used', style: TextStyle(color: barColor, fontSize: 11, fontWeight: FontWeight.w900)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 8, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(99)),
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(widthFactor: (b.percentage / 100).clamp(0.0, 1.0), child: Container(decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(99)))),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Spent: RM ${b.spentAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                              Text('Limit: RM ${b.budgetAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiChatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome, color: SunsetColors.primary, size: 22),
            SizedBox(width: 8),
            Text('AI Insights Advisor', style: TextStyle(color: SunsetColors.dark, fontSize: 18, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 800,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: SunsetColors.primary.withValues(alpha: 0.1)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)]),
          child: Column(
            children: [
              // Header with glowing effect
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(color: SunsetColors.bgStart, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), border: Border(bottom: BorderSide(color: SunsetColors.primary.withValues(alpha: 0.1)))),
                child: Center(
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) => Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [SunsetColors.primary, Colors.orangeAccent]),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: SunsetColors.primary.withValues(alpha: 0.3 * _pulseController.value), blurRadius: 15 * _pulseController.value, spreadRadius: 5 * _pulseController.value)],
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Sunset AI Engine Synced', style: TextStyle(color: SunsetColors.dark, fontSize: 14, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text('REALTIME SCOPE: ${_dateFormat.format(_startDate)} ~ ${_dateFormat.format(_endDate)}', style: TextStyle(color: SunsetColors.dark.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ],
                  ),
                ),
              ),
              
              // Chat List
              Expanded(
                child: Container(
                  color: const Color(0xFFFFFCFB),
                  child: ListView.builder(
                    controller: _chatScrollController,
                    padding: const EdgeInsets.all(24),
                    itemCount: _messages.length + (_isSendingMsg ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) return _buildTypingIndicator();
                      final msg = _messages[index];
                      final isUser = msg.role == 'user';
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            if (!isUser) _chatAvatar(false),
                            if (!isUser) const SizedBox(width: 12),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isUser ? SunsetColors.primary : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isUser ? 16 : 4), bottomRight: Radius.circular(isUser ? 4 : 16),
                                  ),
                                  border: isUser ? null : Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))],
                                ),
                                child: isUser
                                  ? Text(msg.text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))
                                  : MarkdownBody(
                                      data: _normalizeMarkdown(msg.text),
                                      styleSheet: MarkdownStyleSheet(
                                        p: const TextStyle(color: Color(0xFF1F2937), fontSize: 14, height: 1.6, fontWeight: FontWeight.w500),
                                        strong: const TextStyle(color: SunsetColors.primary, fontWeight: FontWeight.bold),
                                        h1: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w900, height: 2),
                                        h2: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900, height: 2),
                                        listBullet: const TextStyle(color: Colors.black),
                                        blockquote: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                                      ),
                                    ),
                              ),
                            ),
                            if (isUser) const SizedBox(width: 12),
                            if (isUser) _chatAvatar(true),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ✅ 完美精细修正：纯净 Flex 横排布局，输入框小字体13，高度精准对齐为44px，不重叠
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: SunsetColors.primary.withValues(alpha: 0.1))),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end, // 多行时按钮底部对齐
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatController,
                        enabled: !_isSendingMsg,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), // 字体缩小到 13
                        minLines: 1, // 最小 1 行
                        maxLines: 4, // 最大伸缩 4 行
                        keyboardType: TextInputType.multiline, // 支持多行换行
                        textInputAction: TextInputAction.send, // 回车键为发送
                        onSubmitted: (_) => _handleSendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Ask AI Advisor about your monthly expenses...',
                          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                          hintMaxLines: 1, // 🌟 核心修复：禁止提示词在手机端换行撑高框！
                          filled: true,
                          fillColor: const Color(0xFFFFFCFB),
                          isDense: true, // 这是高度精准控制的秘密武器
                          // 上下内间距设为 13.5，加上 13 像素字体，整体高度刚好是 44px
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10), // 🌟 图4同款微圆角 (16px)
                            borderSide: BorderSide(color: SunsetColors.primary.withValues(alpha: 0.2)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10), // 🌟 图4同款微圆角 (16px)
                            borderSide: BorderSide(color: SunsetColors.primary.withValues(alpha: 0.4)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12), // 彻底杜绝重叠的关键间隔
                    InkWell(
                      onTap: _isSendingMsg ? null : _handleSendMessage,
                      borderRadius: BorderRadius.circular(10), // 🌟 图4同款微圆角
                      child: Container(
                        width: 38, // 宽度设为 44px
                        height: 38, // 🌟 严格与单行输入框保持 44px 1:1 等高
                        decoration: BoxDecoration(
                          color: _isSendingMsg ? Colors.grey : SunsetColors.primary,
                          borderRadius: BorderRadius.circular(10), // 🌟 图4同款微圆角 (15px)
                        ),
                        child: const Icon(Icons.send, color: Colors.white, size: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chatAvatar(bool isUser) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: isUser ? SunsetColors.primary : SunsetColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: isUser ? null : Border.all(color: SunsetColors.primary.withValues(alpha: 0.2)),
      ),
      child: Icon(isUser ? Icons.person_outline : Icons.smart_toy_outlined, size: 18, color: isUser ? Colors.white : SunsetColors.primary),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _chatAvatar(false),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(16)), border: Border.all(color: Colors.orange.withValues(alpha: 0.2))),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _bouncingDot(0), const SizedBox(width: 4), _bouncingDot(100), const SizedBox(width: 4), _bouncingDot(200),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bouncingDot(int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1), duration: const Duration(milliseconds: 600),
      builder: (context, value, child) => Transform.translate(offset: Offset(0, -4 * value), child: child),
      onEnd: () {}, 
      child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: SunsetColors.primary, shape: BoxShape.circle)),
    );
  }
}

// ---------------- Data Models ----------------

class MetricStats {
  final double totalIncome; final double totalExpense; final double netBalance; final double savingsRate;
  MetricStats({this.totalIncome = 0, this.totalExpense = 0, this.netBalance = 0, this.savingsRate = 0});

  factory MetricStats.fromJson(Map<String, dynamic> json) {
    return MetricStats(
      totalIncome: double.tryParse('${json['income'] ?? 0}') ?? 0,
      totalExpense: double.tryParse('${json['expense'] ?? 0}') ?? 0,
      netBalance: double.tryParse('${json['balance'] ?? 0}') ?? 0,
      savingsRate: double.tryParse('${json['savingsRate'] ?? 0}') ?? 0,
    );
  }
}

class ChartItem {
  final String name; final double income; final double expense;
  ChartItem({required this.name, required this.income, required this.expense});
  factory ChartItem.fromJson(Map<String, dynamic> json) => ChartItem(name: '${json['name'] ?? ''}', income: double.tryParse('${json['income'] ?? 0}') ?? 0, expense: double.tryParse('${json['expense'] ?? 0}') ?? 0);
}

class PieItem {
  final String name; final double value; final Color color;
  PieItem({required this.name, required this.value, required this.color});
  factory PieItem.fromJson(Map<String, dynamic> json) {
    return PieItem(name: '${json['name'] ?? ''}', value: double.tryParse('${json['value'] ?? 0}') ?? 0, color: _colorFromHex('${json['color'] ?? '#000000'}'));
  }
}

class TransactionItem {
  final int id; final String title; final String category; final String date; final double price; final String type;
  TransactionItem({required this.id, required this.title, required this.category, required this.date, required this.price, required this.type});
  factory TransactionItem.fromJson(Map<String, dynamic> json) => TransactionItem(
    id: json['id'] ?? 0, title: '${json['title'] ?? ''}', category: '${json['category'] ?? ''}',
    date: '${json['date'] ?? ''}', price: double.tryParse('${json['price'] ?? 0}') ?? 0, type: '${json['type'] ?? ''}',
  );
}

class BudgetItem {
  final int id; final String category; final Color categoryColor; final double budgetAmount; final double spentAmount; final double percentage; final int month; final int year;
  BudgetItem({required this.id, required this.category, required this.categoryColor, required this.budgetAmount, required this.spentAmount, required this.percentage, required this.month, required this.year});
  factory BudgetItem.fromJson(Map<String, dynamic> json) => BudgetItem(
    id: json['id'] ?? 0, category: '${json['category'] ?? ''}', categoryColor: _colorFromHex('${json['category_color'] ?? '#f97316'}'),
    budgetAmount: double.tryParse('${json['budget_amount'] ?? 0}') ?? 0, spentAmount: double.tryParse('${json['spent_amount'] ?? 0}') ?? 0,
    percentage: double.tryParse('${json['percentage'] ?? 0}') ?? 0, month: json['month'] ?? 1, year: json['year'] ?? 2024,
  );
}

class ChatMessage {
  final String role; final String text;
  ChatMessage({required this.role, required this.text});
  Map<String, dynamic> toJson() => {'role': role, 'text': text};
}

Color _colorFromHex(String value) {
  final cleaned = value.replaceAll('#', '').trim();
  final hex = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
  return Color(int.tryParse(hex, radix: 16) ?? 0xFFF97316);
}